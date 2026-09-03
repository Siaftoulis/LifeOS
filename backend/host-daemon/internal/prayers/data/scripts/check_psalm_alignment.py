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

# 1. Collect all left psalm markers in order
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

# Sort psalm markers by pno, then y
psalm_markers.sort(key=lambda m: (m['pno'], m['y']))

# Check consecutive order: 1, 2, 3, ... 150
print("First 10 psalm markers:")
for m in psalm_markers[:10]:
    print(f"  Psalm {m['num']} on page {m['pno']+1} at y={m['y']:.1f}")

# Check duplicates or out-of-order
expected = 1
clean_markers = []
for m in psalm_markers:
    if m['num'] == expected:
        clean_markers.append(m)
        expected += 1
    elif m['num'] == expected - 1:
        # duplicate
        pass
    else:
        print(f"Unexpected marker: {m} while expecting {expected}")

print(f"Clean sequential markers count: {len(clean_markers)}")
