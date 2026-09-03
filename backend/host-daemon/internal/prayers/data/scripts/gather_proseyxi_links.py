import urllib.request
from bs4 import BeautifulSoup
import re
import time
import json
import unicodedata

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'el-GR,el;q=0.9,en;q=0.8',
}

categories_to_scrape = [
    ("occasional", "https://www.proseyxi.com/category/proseyxes/diafores-proseyxes/"),
    ("saints", "https://www.proseyxi.com/category/proseyxes/proseyxes-agion/"),
    ("akolouthies", "https://www.proseyxi.com/category/akolouthies/"),
    ("akolouthies_saints", "https://www.proseyxi.com/category/akolouthies-agion/"),
    ("paraklisis", "https://www.proseyxi.com/category/paraklisis/"),
    ("xairetismoi", "https://www.proseyxi.com/category/xairetismoi/"),
]

def get_articles_from_category(cat_url, max_pages=3):
    article_links = []
    for p in range(1, max_pages + 1):
        page_url = cat_url if p == 1 else f"{cat_url.rstrip('/')}/page/{p}/"
        try:
            req = urllib.request.Request(page_url, headers=headers)
            with urllib.request.urlopen(req, timeout=15) as resp:
                html = resp.read().decode('utf-8', errors='ignore')
                soup = BeautifulSoup(html, 'html.parser')
                articles = soup.find_all('article')
                if not articles:
                    break
                for a in articles:
                    title_el = a.find(['h2', 'h1', 'h3'])
                    link = a.find('a')
                    if link and 'href' in link.attrs:
                        title = title_el.get_text().strip() if title_el else ''
                        href = link['href']
                        if href and href not in [l[1] for l in article_links]:
                            article_links.append((title, href))
            time.sleep(1.0)
        except Exception as e:
            print(f"Error reading {page_url}: {e}")
            break
    return article_links

all_to_fetch = []
for cat_name, cat_url in categories_to_scrape:
    print(f"Scanning category: {cat_name} ({cat_url})...")
    links = get_articles_from_category(cat_url, max_pages=3)
    print(f"  Found {len(links)} articles in {cat_name}")
    for title, href in links:
        all_to_fetch.append({
            "category": cat_name,
            "title": title,
            "url": href
        })

print(f"\nTotal articles queued to scrape: {len(all_to_fetch)}")
with open('backend/host-daemon/internal/prayers/data/proseyxi_queue.json', 'w', encoding='utf-8') as f:
    json.dump(all_to_fetch, f, ensure_ascii=False, indent=2)
print("Saved queue to proseyxi_queue.json")
