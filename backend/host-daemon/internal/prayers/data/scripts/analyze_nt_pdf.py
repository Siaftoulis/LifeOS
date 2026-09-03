import sys
import os
import json
import re
import pymupdf

sys.stdout.reconfigure(encoding='utf-8')

pdf_path = r'C:\Users\PDS_Dev\Downloads\ΚΑΙΝΗ ΔΙΑΘΗΚΗ 2η ΕΚΔΟΣΗ.pdf'
nt_json_path = r'backend\host-daemon\internal\prayers\data\nt_raw.json'

with open(nt_json_path, 'r', encoding='utf-8') as f:
    nt_data = json.load(f)

print(f"Total NT books in json: {len(nt_data['books'])}")
for b in nt_data['books']:
    print(f"  {b['number']}: {b['nameGreek']} ({b['nameEnglish']}) - {len(b['chapters'])} ch")

doc = pymupdf.open(pdf_path)
print(f"Total pages in NT PDF: {len(doc)}")

# Search for the start of each book in the PDF
# Books usually have a title page or large header: "ΤΟ ΚΑΤΑ ΜΑΤΘΑΙΟΝ", "ΠΡΟΣ ΡΩΜΑΙΟΥΣ", "ΑΠΟΚΑΛΥΨΙΣ"
book_names = [b['nameGreek'] for b in nt_data['books']]

# Let's see the Table of Contents if present in the first 40 pages
print("\n--- Searching for TOC in first 40 pages ---")
for pno in range(40):
    txt = doc[pno].get_text()
    if "ΠΕΡΙΕΧΟΜΕΝΑ" in txt.upper() or "ΠΙΝΑΞ" in txt.upper():
        print(f"TOC found on page {pno+1}:")
        print(txt[:400])
