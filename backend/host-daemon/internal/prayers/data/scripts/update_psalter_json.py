import sys
import os
import json
import re
import pymupdf

sys.stdout.reconfigure(encoding='utf-8')

def normalize_greek(text):
    text = text.replace('\u00b5', 'μ')
    text = re.sub(r'[ \t]+', ' ', text)
    return text.strip()

pdf_path = r'C:\Users\PDS_Dev\Downloads\Ψαλτήρι.pdf'
json_path = r'backend\host-daemon\internal\prayers\data\psalter_raw.json'

doc = pymupdf.open(pdf_path)

psalm_markers = []
for pno in range(len(doc)):
    page = doc[pno]
    data = page.get_text('dict')
    for b in data['blocks']:
        if 'lines' not in b:
            continue
        for l in b['lines']:
            y = l['bbox'][1]
            if y < 45 or y > 785:
                continue
            x_start = l['bbox'][0]
            if x_start < 260:
                line_text = "".join(s['text'] for s in l['spans']).strip()
                m = re.match(r'^([0-9]{1,3})\.?$', line_text)
                if m:
                    num = int(m.group(1))
                    if 1 <= num <= 151:
                        psalm_markers.append({
                            'num': num,
                            'pno': pno,
                            'y': y
                        })

psalm_markers.sort(key=lambda m: (m['pno'], m['y']))

clean_markers = []
expected = 1
for m in psalm_markers:
    if m['num'] == expected:
        clean_markers.append(m)
        expected += 1

all_right_lines = []
for pno in range(len(doc)):
    page = doc[pno]
    data = page.get_text('dict')
    page_right = []
    for b in data['blocks']:
        if 'lines' not in b:
            continue
        for l in b['lines']:
            y = l['bbox'][1]
            if y < 45 or y > 785:
                continue
            x_start = l['bbox'][0]
            if x_start >= 260:
                line_text = "".join(s['text'] for s in l['spans']).strip()
                if line_text:
                    page_right.append((y, normalize_greek(line_text)))
    page_right.sort(key=lambda x: x[0])
    for y, txt in page_right:
        all_right_lines.append((pno, y, txt))

psalm_translations = {}
for idx in range(len(clean_markers)):
    cur = clean_markers[idx]
    num = cur['num']
    pno_start = cur['pno']
    y_start = cur['y']
    
    if idx + 1 < len(clean_markers):
        nxt = clean_markers[idx + 1]
        pno_end = nxt['pno']
        y_end = nxt['y']
    else:
        pno_end = len(doc)
        y_end = 9999
        
    lines = []
    for pno, y, txt in all_right_lines:
        after_start = (pno > pno_start) or (pno == pno_start and y >= y_start - 25)
        before_end = (pno < pno_end) or (pno == pno_end and y < y_end - 25)
        if after_start and before_end:
            lines.append(txt)
            
    psalm_translations[num] = " ".join(lines)

with open(json_path, 'r', encoding='utf-8') as f:
    psalter_data = json.load(f)

matched_count = 0
for k in psalter_data.get('kathismata', []):
    for p in k.get('psalms', []):
        num = p.get('number')
        if num in psalm_translations:
            p['translation'] = psalm_translations[num]
            matched_count += 1

print(f"Matched {matched_count} psalms with translations in psalter_raw.json")

# Write backup first
with open(json_path + '.bak', 'w', encoding='utf-8') as f:
    json.dump(psalter_data, f, ensure_ascii=False, indent=2)

with open(json_path, 'w', encoding='utf-8') as f:
    json.dump(psalter_data, f, ensure_ascii=False, indent=2)

print("psalter_raw.json successfully updated!")
