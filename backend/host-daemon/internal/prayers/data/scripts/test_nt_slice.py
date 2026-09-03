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

# Let's test extracting Matthew 1 & 2 (pages 43 to 50)
extracted_verses = {} # (ch, verse) -> text
current_ch = 1

for pno in range(43, 51):
    page = doc[pno]
    data = page.get_text('dict')
    
    # Check chapter change
    for b in data['blocks']:
        if 'lines' not in b:
            continue
        for l in b['lines']:
            txt = "".join(s['text'] for s in l['spans']).strip()
            m = re.search(r'ΚΕΦΑΛΑΙΟΝ\s+([^\(\n]+)\(([0-9]+)\)', txt)
            if m:
                current_ch = int(m.group(2))
                
    # Collect right column lines (translation)
    # Right column lines: x >= 155, y >= 45, font size >= 7.0
    right_lines = []
    for b in data['blocks']:
        if 'lines' not in b:
            continue
        for l in b['lines']:
            if l['bbox'][1] < 45:
                continue
            for s in l['spans']:
                if s['size'] < 7.0:
                    continue
                if l['bbox'][0] >= 155:
                    t = s['text'].strip()
                    if t:
                        right_lines.append((l['bbox'][1], t))
                        
    right_lines.sort(key=lambda x: x[0])
    
    # Now parse verses
    current_v = 1
    for y, t in right_lines:
        # Check if line starts with a verse number, e.g. "2 Ὁ Ἀβραάμ" or "25 Καί δέν"
        # Or if it's drop cap like "Γ" followed by "ενεαλογικός"
        m_v = re.match(r'^([0-9]{1,3})\s+(.*)$', t)
        if m_v:
            v_num = int(m_v.group(1))
            # sanity check: v_num shouldn't jump wildly
            if v_num == current_v + 1 or (current_v == 1 and v_num in [2, 3]):
                current_v = v_num
                key = (current_ch, current_v)
                extracted_verses[key] = m_v.group(2)
                continue
        # If not a new verse, append to current verse
        key = (current_ch, current_v)
        if key not in extracted_verses:
            extracted_verses[key] = t
        else:
            extracted_verses[key] += " " + t

print("Extracted Matthew sampled verses:")
for k in sorted(extracted_verses.keys()):
    if k[1] in [1, 2, 17, 18, 25]:
        print(f"  Ch {k[0]}:{k[1]} -> {extracted_verses[k][:70]}...")
