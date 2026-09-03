import sys
import pymupdf

sys.stdout.reconfigure(encoding='utf-8')

doc = pymupdf.open(r'C:\Users\PDS_Dev\Downloads\Ψαλτήρι.pdf')
page0 = doc[0]
data = page0.get_text('dict')

print("=== LINES ON PAGE 1 ===")
all_lines = []
for b in data['blocks']:
    if 'lines' in b:
        for l in b['lines']:
            text = "".join(s['text'] for s in l['spans']).strip()
            if text:
                all_lines.append((l['bbox'], text))

all_lines.sort(key=lambda x: (x[0][1], x[0][0]))
for bbox, text in all_lines:
    print(f"[{bbox[0]:5.1f}, {bbox[1]:5.1f}, {bbox[2]:5.1f}, {bbox[3]:5.1f}] {text}")
