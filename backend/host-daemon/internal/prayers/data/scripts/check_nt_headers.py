import sys
import pymupdf
import re

sys.stdout.reconfigure(encoding='utf-8')
pdf_path = r'C:\Users\PDS_Dev\Downloads\ΚΑΙΝΗ ΔΙΑΘΗΚΗ 2η ΕΚΔΟΣΗ.pdf'
doc = pymupdf.open(pdf_path)

header_samples = []
for pno in range(40, 70):
    page = doc[pno]
    data = page.get_text('dict')
    for b in data['blocks']:
        if 'lines' not in b:
            continue
        for l in b['lines']:
            if l['bbox'][1] < 45: # Header line
                txt = "".join(s['text'] for s in l['spans']).strip()
                if txt and ('κεφ' in txt.lower() or 'ματθ' in txt.lower()):
                    header_samples.append((pno+1, txt))

print(f"Header samples ({len(header_samples)}):")
for s in header_samples[:20]:
    print(f"  Page {s[0]}: {s[1]}")
