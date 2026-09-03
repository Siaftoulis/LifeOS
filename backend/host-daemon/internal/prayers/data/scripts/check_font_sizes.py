import sys
import pymupdf

sys.stdout.reconfigure(encoding='utf-8')
pdf_path = r'C:\Users\PDS_Dev\Downloads\ΚΑΙΝΗ ΔΙΑΘΗΚΗ 2η ΕΚΔΟΣΗ.pdf'
doc = pymupdf.open(pdf_path)

p = doc[43]
for b in p.get_text('dict')['blocks']:
    if 'lines' in b:
        for l in b['lines'][:2]:
            s = l['spans'][0]
            print(f"y={l['bbox'][1]:.1f}, x={l['bbox'][0]:.1f}, sz={s['size']:.1f}, font={s['font']}: {repr(s['text'][:35])}")
