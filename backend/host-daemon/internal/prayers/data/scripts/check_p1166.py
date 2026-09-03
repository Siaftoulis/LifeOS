import sys
import pymupdf

sys.stdout.reconfigure(encoding='utf-8')
pdf_path = r'C:\Users\PDS_Dev\Downloads\ΚΑΙΝΗ ΔΙΑΘΗΚΗ 2η ΕΚΔΟΣΗ.pdf'
doc = pymupdf.open(pdf_path)

for p in range(1165, min(1175, len(doc))):
    print(f"=== PAGE {p+1} ===")
    print(doc[p].get_text())
