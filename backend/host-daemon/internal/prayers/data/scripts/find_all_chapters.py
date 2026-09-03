import sys
import pymupdf
import re

sys.stdout.reconfigure(encoding='utf-8')
pdf_path = r'C:\Users\PDS_Dev\Downloads\ΚΑΙΝΗ ΔΙΑΘΗΚΗ 2η ΕΚΔΟΣΗ.pdf'
doc = pymupdf.open(pdf_path)

chapter_headers = []
for pno in range(40, 1165):
    page = doc[pno]
    data = page.get_text('dict')
    for b in data['blocks']:
        if 'lines' not in b:
            continue
        for l in b['lines']:
            line_text = "".join(s['text'] for s in l['spans']).strip()
            # Chapter title like "ΚΕΦΑΛΑΙΟΝ Α΄ (1)" or "ΚΕΦΑΛΑΙΟΝ 1" or similar
            if "ΚΕΦΑΛΑΙΟΝ" in line_text:
                m = re.search(r'ΚΕΦΑΛΑΙΟΝ\s+([^\(\n]+)(?:\(([0-9]+)\))?', line_text)
                if m:
                    chapter_headers.append((pno+1, line_text, m.group(2)))

print(f"Total ΚΕΦΑΛΑΙΟΝ headers found: {len(chapter_headers)}")
for h in chapter_headers[:25]:
    print(f"  Page {h[0]}: {repr(h[1])} -> ch_num={h[2]}")
