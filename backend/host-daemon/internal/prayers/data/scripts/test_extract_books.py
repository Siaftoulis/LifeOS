import sys
import pymupdf
import re
import json

sys.stdout.reconfigure(encoding='utf-8')
pdf_path = r'C:\Users\PDS_Dev\Downloads\ΚΑΙΝΗ ΔΙΑΘΗΚΗ 2η ΕΚΔΟΣΗ.pdf'
nt_json_path = r'backend\host-daemon\internal\prayers\data\nt_raw.json'

with open(nt_json_path, 'r', encoding='utf-8') as f:
    nt_data = json.load(f)

doc = pymupdf.open(pdf_path)

def extract_book(doc, start_page, end_page, total_chapters):
    # Returns {chapter_num: {verse_num: text}}
    chapters = {c: {} for c in range(1, total_chapters + 1)}
    current_ch = 1
    current_v = 1
    
    for pno in range(start_page - 1, end_page):
        page = doc[pno]
        data = page.get_text('dict')
        
        # 1. Check if header or content has chapter number
        # Look for "ΚΕΦΑΛΑΙΟΝ ... (N)"
        for b in data['blocks']:
            if 'lines' not in b:
                continue
            for l in b['lines']:
                txt = "".join(s['text'] for s in l['spans']).strip()
                m = re.search(r'ΚΕΦΑΛΑΙΟΝ\s+([^\(\n]+)\(([0-9]+)\)', txt)
                if m:
                    new_ch = int(m.group(2))
                    if 1 <= new_ch <= total_chapters:
                        current_ch = new_ch
                        current_v = 1
                        
        # 2. Extract right-column lines
        right_lines = []
        for b in data['blocks']:
            if 'lines' not in b:
                continue
            for l in b['lines']:
                y = l['bbox'][1]
                if y < 45 or y > 472: # Skip headers and footnotes
                    continue
                for s in l['spans']:
                    if s['size'] < 7.0: # Skip footnote superscripts / references
                        continue
                    if l['bbox'][0] >= 155:
                        t = s['text'].strip()
                        if t:
                            right_lines.append((y, l['bbox'][0], s['size'], t))
                            
        right_lines.sort(key=lambda x: x[0])
        
        # 3. Parse verses from lines
        for y, x, sz, t in right_lines:
            # Skip introductory chapter summaries like "Στίχ. 1-17. Ἡ γενεαλογία..."
            if t.startswith("Στίχ.") or t.startswith("ΚΕΦΑΛΑΙΟΝ"):
                continue
            # Check if line starts with a verse number
            # e.g. "2 Ὁ Ἀβραάμ" or "2. Ὁ Ἀβραάμ" or "25 Καί δέν"
            m_v = re.match(r'^([0-9]{1,3})[\.\s]+(.*)$', t)
            if m_v:
                v_candidate = int(m_v.group(1))
                rest = m_v.group(2).strip()
                # Reasonable verse progression check
                if (1 <= v_candidate <= 180) and (v_candidate == current_v + 1 or v_candidate == 1 or (current_v == 1 and v_candidate in [2, 3])):
                    current_v = v_candidate
                    if current_ch in chapters:
                        chapters[current_ch][current_v] = rest
                    continue
            
            # Normal continuation line
            if current_ch in chapters:
                if current_v not in chapters[current_ch]:
                    chapters[current_ch][current_v] = t
                else:
                    chapters[current_ch][current_v] += " " + t
                    
    # Clean up verse texts
    for c in chapters:
        for v in chapters[c]:
            txt = chapters[c][v]
            # remove soft hyphens or line-break hyphens
            txt = re.sub(r'(\w+)-\s+(\w+)', r'\1\2', txt)
            txt = re.sub(r'[ \t]+', ' ', txt).strip()
            chapters[c][v] = txt
            
    return chapters

# Test on Matthew (Book 1)
print("Testing extraction on Matthew (28 chapters, p.42-179)...")
matthew_trans = extract_book(doc, 43, 179, 28)
total_extracted_v = sum(len(matthew_trans[c]) for c in matthew_trans)
matthew_json = nt_data['books'][0]
total_json_v = sum(len(c['verses']) for c in matthew_json['chapters'])
print(f"Matthew extracted verses: {total_extracted_v} / {total_json_v}")

# Test on Romans (Book 6, p.682-745, 16 chapters)
print("Testing extraction on Romans (16 chapters, p.684-745)...")
romans_trans = extract_book(doc, 684, 745, 16)
total_extracted_v_rom = sum(len(romans_trans[c]) for c in romans_trans)
romans_json = nt_data['books'][5]
total_json_v_rom = sum(len(c['verses']) for c in romans_json['chapters'])
print(f"Romans extracted verses: {total_extracted_v_rom} / {total_json_v_rom}")
