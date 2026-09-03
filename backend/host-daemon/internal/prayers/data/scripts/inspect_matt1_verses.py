import sys
import pymupdf
import re
import json

sys.stdout.reconfigure(encoding='utf-8')
pdf_path = r'C:\Users\PDS_Dev\Downloads\ΚΑΙΝΗ ΔΙΑΘΗΚΗ 2η ΕΚΔΟΣΗ.pdf'
doc = pymupdf.open(pdf_path)

# Let's inspect pages 44 to 47 (Matthew ch 1 and start of ch 2)
for pno in range(43, 48):
    page = doc[pno]
    data = page.get_text('dict')
    print(f"\n--- PAGE {pno+1} ---")
    for b in data['blocks']:
        if 'lines' not in b:
            continue
        for l in b['lines']:
            if l['bbox'][1] < 45 or l['bbox'][1] > 475:
                continue
            for s in l['spans']:
                if s['size'] >= 7.0 and l['bbox'][0] >= 155:
                    txt = s['text'].strip()
                    # Print if has digit or starts line
                    if any(c.isdigit() for c in txt[:5]):
                        print(f"  [y={l['bbox'][1]:.1f}, sz={s['size']:.1f}, font={s['font']}] -> {txt}")
