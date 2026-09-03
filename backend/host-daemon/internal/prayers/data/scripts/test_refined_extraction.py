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

def extract_book_refined(doc, start_page, end_page, total_chapters):
    chapters = {c: {} for c in range(1, total_chapters + 1)}
    current_ch = 1
    current_v = 1
    
    for pno in range(start_page - 1, end_page):
        page = doc[pno]
        data = page.get_text('dict')
        
        # Collect all spans with size >= 7.5 and y >= 45 and x >= 155
        # Also detect chapter headers that might be centered or span across columns
        lines = []
        for b in data['blocks']:
            if 'lines' not in b:
                continue
            for l in b['lines']:
                y = l['bbox'][1]
                x = l['bbox'][0]
                if y < 45:
                    continue
                line_text = "".join(s['text'] for s in l['spans']).strip()
                # Check for chapter title anywhere on page
                m_ch = re.search(r'ΚΕΦΑΛΑΙΟΝ\s+([^\(\n]+)\(([0-9]+)\)', line_text)
                if m_ch:
                    n_ch = int(m_ch.group(2))
                    lines.append((y, 100, 10.0, f"__NEW_CH_{n_ch}__"))
                    continue
                
                # Check for right-column translation text
                for s in l['spans']:
                    if s['size'] >= 7.5 and x >= 155:
                        t = s['text'].strip()
                        if t:
                            lines.append((y, x, s['size'], t))
                            
        lines.sort(key=lambda item: (item[0], item[1]))
        
        for y, x, sz, t in lines:
            if t.startswith("__NEW_CH_"):
                new_ch = int(t.replace("__NEW_CH_", "").replace("__", ""))
                if 1 <= new_ch <= total_chapters:
                    current_ch = new_ch
                    current_v = 1
                continue
                
            if t.startswith("Στίχ.") or "ΚΕΦΑΛΑΙΟΝ" in t:
                continue
                
            m_v = re.match(r'^([0-9]{1,3})\s+(.*)$', t)
            if m_v:
                v_num = int(m_v.group(1))
                # Accept new verse if reasonable
                if (1 <= v_num <= 180) and (v_num == current_v + 1 or v_num == 1 or (current_v == 1 and v_num in [2, 3]) or (v_num > current_v and v_num <= current_v + 3)):
                    current_v = v_num
                    rest = m_v.group(2).strip()
                    if current_ch in chapters:
                        chapters[current_ch][current_v] = rest
                    continue
                    
            if current_ch in chapters:
                if current_v not in chapters[current_ch]:
                    chapters[current_ch][current_v] = t
                else:
                    # Drop cap single letter merger
                    if len(chapters[current_ch][current_v]) <= 2:
                        chapters[current_ch][current_v] += t
                    else:
                        chapters[current_ch][current_v] += " " + t

    # Clean
    for c in chapters:
        for v in chapters[c]:
            txt = chapters[c][v]
            txt = re.sub(r'(\w+)-\s+(\w+)', r'\1\2', txt)
            txt = re.sub(r'[ \t]+', ' ', txt).strip()
            chapters[c][v] = txt

    return chapters

print("Extracting Matthew...")
m_trans = extract_book_refined(doc, 43, 179, 28)
tot_m = sum(len(m_trans[c]) for c in m_trans)
tot_m_expected = sum(len(c['verses']) for c in nt_data['books'][0]['chapters'])
print(f"Matthew: {tot_m} / {tot_m_expected} verses ({tot_m*100/tot_m_expected:.1f}%)")

print("Extracting Romans...")
r_trans = extract_book_refined(doc, 684, 745, 16)
tot_r = sum(len(r_trans[c]) for c in r_trans)
tot_r_expected = sum(len(c['verses']) for c in nt_data['books'][5]['chapters'])
print(f"Romans: {tot_r} / {tot_r_expected} verses ({tot_r*100/tot_r_expected:.1f}%)")
