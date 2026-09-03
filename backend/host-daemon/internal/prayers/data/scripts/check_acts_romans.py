import sys
import pymupdf

sys.stdout.reconfigure(encoding='utf-8')
pdf_path = r'C:\Users\PDS_Dev\Downloads\ΚΑΙΝΗ ΔΙΑΘΗΚΗ 2η ΕΚΔΟΣΗ.pdf'
doc = pymupdf.open(pdf_path)

# Let's inspect page 550 (Acts) and page 650 (Romans)
for pno in [548, 684]:
    page = doc[pno]
    print(f"\n================ PAGE {pno+1} ================")
    data = page.get_text('dict')
    for b in data['blocks']:
        if 'lines' not in b:
            continue
        for l in b['lines']:
            line_text = "".join(s['text'] for s in l['spans']).strip()
            bbox = l['bbox']
            # Only print first few lines of each column
            if bbox[1] < 300:
                print(f"[{bbox[0]:5.1f}, {bbox[1]:5.1f}] {line_text[:70]}")
