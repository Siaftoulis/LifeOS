import sys
import os
import re
import pymupdf

sys.stdout.reconfigure(encoding='utf-8')

def normalize_greek(text):
    text = text.replace('\u00b5', 'μ')
    text = re.sub(r'[ \t]+', ' ', text)
    return text.strip()

doc = pymupdf.open(r'C:\Users\PDS_Dev\Downloads\Ψαλτήρι.pdf')

# 1. Collect markers
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

# Collect all right-column lines with their (pno, y, text)
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

# For each psalm, slice the lines
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
        # Check if within [start, end)
        after_start = (pno > pno_start) or (pno == pno_start and y >= y_start - 25)
        before_end = (pno < pno_end) or (pno == pno_end and y < y_end - 25)
        if after_start and before_end:
            lines.append(txt)
            
    psalm_translations[num] = " ".join(lines)

print("Check sampled psalm translations:")
for n in [1, 2, 3, 22, 50, 90, 103, 148, 150]:
    t = psalm_translations.get(n, "")
    print(f"\n--- PSALM {n} (len={len(t)}) ---")
    print("Start:", t[:120])
    print("End:  ", t[-100:])
