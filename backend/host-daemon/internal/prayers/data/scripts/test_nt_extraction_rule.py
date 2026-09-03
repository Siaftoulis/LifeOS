import sys
import pymupdf

sys.stdout.reconfigure(encoding='utf-8')
pdf_path = r'C:\Users\PDS_Dev\Downloads\ΚΑΙΝΗ ΔΙΑΘΗΚΗ 2η ΕΚΔΟΣΗ.pdf'
doc = pymupdf.open(pdf_path)

# Test pages: 44 (Matt 1), 181 (Mark 1), 548 (Acts 1), 686 (Rom 1), 1091 (Rev 1)
test_pages = [43, 180, 547, 685, 1090]

for pno in test_pages:
    print(f"\n================ PAGE {pno+1} ================")
    page = doc[pno]
    data = page.get_text('dict')
    
    trans_lines = []
    for b in data['blocks']:
        if 'lines' not in b:
            continue
        for l in b['lines']:
            if l['bbox'][1] < 45: # Header
                continue
            for s in l['spans']:
                # Filter out footnotes (size < 7.0)
                if s['size'] < 7.0:
                    continue
                # Check if in right column (x >= 155)
                if l['bbox'][0] >= 155:
                    txt = s['text'].strip()
                    if txt:
                        trans_lines.append(f"[{l['bbox'][1]:.1f}] {txt}")
                        
    print(f"Extracted {len(trans_lines)} spans in right column:")
    for tl in trans_lines[:15]:
        print(" ", tl)
