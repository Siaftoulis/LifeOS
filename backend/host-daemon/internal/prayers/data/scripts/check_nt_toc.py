import sys
import pymupdf

sys.stdout.reconfigure(encoding='utf-8')
pdf_path = r'C:\Users\PDS_Dev\Downloads\ΚΑΙΝΗ ΔΙΑΘΗΚΗ 2η ΕΚΔΟΣΗ.pdf'
doc = pymupdf.open(pdf_path)

toc = doc.get_toc()
print(f"TOC items: {len(toc)}")
for item in toc[:35]:
    print(f"Level {item[0]}: {item[1]} -> Page {item[2]}")
