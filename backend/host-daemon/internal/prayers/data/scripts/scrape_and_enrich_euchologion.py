import urllib.request
from bs4 import BeautifulSoup
import re
import time
import json
import os
import sys

sys.stdout.reconfigure(encoding='utf-8')

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'el-GR,el;q=0.9,en;q=0.8',
}

euchologion_path = r'backend\host-daemon\internal\prayers\data\euchologion_raw.json'
queue_path = r'backend\host-daemon\internal\prayers\data\proseyxi_queue.json'

with open(euchologion_path, 'r', encoding='utf-8') as f:
    euchologion = json.load(f)

with open(queue_path, 'r', encoding='utf-8') as f:
    queue = json.load(f)

existing_ids = {p.get('id', '') for p in euchologion.get('prayers', [])}
existing_titles = {p.get('title', '').strip().lower() for p in euchologion.get('prayers', [])}

print(f"Loaded existing euchologion with {len(euchologion['prayers'])} prayers.")
print(f"Total articles in queue: {len(queue)}")

category_map = {
    "occasional": "occasional",
    "saints": "saints",
    "akolouthies": "akolouthies",
    "akolouthies_saints": "akolouthies",
    "paraklisis": "paraklisis",
    "xairetismoi": "xairetismoi",
}

added_count = 0
skipped_count = 0

for idx, item in enumerate(queue):
    url = item['url']
    cat = category_map.get(item['category'], 'occasional')
    
    slug_match = re.search(r'proseyxi\.com/([^/]+)/?', url)
    slug = slug_match.group(1) if slug_match else f"item_{idx}"
    prayer_id = f"proseyxi_{slug.replace('-', '_')}"
    
    if prayer_id in existing_ids:
        skipped_count += 1
        continue

    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=15) as resp:
            html = resp.read().decode('utf-8', errors='ignore')
            
        soup = BeautifulSoup(html, 'html.parser')
        
        # 1. Extract title
        title_el = soup.find('h1')
        title = title_el.get_text().strip() if title_el else item.get('title', '')
        if not title:
            title = slug.replace('-', ' ').title()
            
        if title.lower() in existing_titles:
            skipped_count += 1
            continue
            
        # 2. Extract content from elementor or entry-content
        content_divs = soup.find_all('div', class_='elementor-widget-text-editor')
        if not content_divs:
            content_divs = soup.find_all('div', class_='entry-content')
            
        sections = []
        current_header = title
        current_paras = []
        
        for cd in content_divs:
            for child in cd.find_all(['p', 'h2', 'h3', 'h4']):
                tag = child.name
                txt = child.get_text().strip()
                
                # Filter out boilerplate
                if not txt or len(txt) < 3:
                    continue
                if any(bp in txt.lower() for bp in [
                    'κάντε εγγραφή', 'youtube', 'facebook', 'cookie', 'πολιτική απορρήτου',
                    'μοιραστείτε το', 'σχετικά άρθρα', 'διαβάστε επίσης', 'copyright'
                ]):
                    continue
                    
                if tag in ['h2', 'h3', 'h4']:
                    if current_paras:
                        sections.append({
                            "header": current_header,
                            "content": "\n\n".join(current_paras),
                            "is_rubric": False
                        })
                        current_paras = []
                    current_header = txt
                else:
                    # Check if text looks like rubric (instructions in red or brackets)
                    current_paras.append(txt)
                    
        if current_paras:
            sections.append({
                "header": current_header,
                "content": "\n\n".join(current_paras),
                "is_rubric": False
            })
            
        # Only add if we actually extracted content
        total_len = sum(len(s['content']) for s in sections)
        if total_len < 50:
            print(f"[{idx+1}/{len(queue)}] Skipping (too short): {title}")
            continue
            
        prayer_obj = {
            "id": prayer_id,
            "title": title,
            "title_english": title,
            "category": cat,
            "source_url": url,
            "sections": sections
        }
        
        euchologion['prayers'].append(prayer_obj)
        existing_ids.add(prayer_id)
        existing_titles.add(title.lower())
        added_count += 1
        
        print(f"[{idx+1}/{len(queue)}] Added: {title[:50]} ({len(sections)} sections, {total_len} chars)")
        
        # Periodic save every 20 articles
        if added_count % 20 == 0:
            with open(euchologion_path, 'w', encoding='utf-8') as f:
                json.dump(euchologion, f, ensure_ascii=False, indent=2)
            print(f"--> Checkpoint saved: {len(euchologion['prayers'])} total prayers in euchologion.")
            
        time.sleep(0.9)
        
    except Exception as e:
        print(f"[{idx+1}/{len(queue)}] Error on {url}: {e}")
        time.sleep(2.0)

# Final save
with open(euchologion_path, 'w', encoding='utf-8') as f:
    json.dump(euchologion, f, ensure_ascii=False, indent=2)

print("\n" + "="*60)
print(f"COMPLETE! Added {added_count} new prayers. Euchologion now has {len(euchologion['prayers'])} total prayers.")
