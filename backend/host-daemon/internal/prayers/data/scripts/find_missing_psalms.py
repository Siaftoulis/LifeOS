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

psalm_splits = []

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
                # Check if this line is a psalm number
                # It can be alone, e.g. "2", "3", "150", or "150 ."
                m = re.match(r'^([0-9]{1,3})\.?$', line_text)
                if m:
                    num = int(m.group(1))
                    if 1 <= num <= 151:
                        psalm_splits.append((num, pno, y, line_text))

print(f"Total numeric psalm markers found on left: {len(psalm_splits)}")
found_nums = set(x[0] for x in psalm_splits)
missing = [n for n in range(1, 151) if n not in found_nums]
print("Missing psalm numbers from strict single-number line regex:", missing)
