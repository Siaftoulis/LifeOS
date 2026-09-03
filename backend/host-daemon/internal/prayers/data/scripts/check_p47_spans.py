import sys
import pymupdf
import re

sys.stdout.reconfigure(encoding='utf-8')
pdf_path = r'C:\Users\PDS_Dev\Downloads\ΚΑΙΝΗ ΔΙΑΘΗΚΗ 2η ΕΚΔΟΣΗ.pdf'
doc = pymupdf.open(pdf_path)

# Let's inspect page 47 (end of Matt 1, start of Matt 2)
p = doc[46]
data = p.get_text('dict')
for b in data['blocks']:
    if 'lines' not in b:
        continue
    for l in b['lines']:
        for s in l['spans']:
            if s['size'] >= 7.5 and l['bbox'][0] >= 155 and l['bbox'][1] >= 45:
                print(f"y={l['bbox'][1]:.1f}, x={l['bbox'][0]:.1f}: {repr(s['text'])}")
