import sys
import pymupdf

sys.stdout.reconfigure(encoding='utf-8')

doc = pymupdf.open(r'C:\Users\PDS_Dev\Downloads\ΚΑΙΝΗ ΔΙΑΘΗΚΗ 2η ΕΚΔΟΣΗ.pdf')
print("Total pages in NT:", len(doc))

# Let's inspect Matthew chapter 1 (around page 25-35)
for p in range(20, 35):
    txt = doc[p].get_text()
    if "ΜΑΤΘΑΙΟΝ" in txt.upper() or "ΒΙΒΛΟΣ ΓΕΝΕΣΕΩΣ" in txt.upper() or "Βίβλος γενέσεως" in txt:
        print(f"=== FOUND MATTHEW ON PAGE {p+1} ===")
        page = doc[p]
        data = page.get_text('dict')
        all_lines = []
        for b in data['blocks']:
            if 'lines' in b:
                for l in b['lines']:
                    text = "".join(s['text'] for s in l['spans']).strip()
                    if text:
                        all_lines.append((l['bbox'], text))
        all_lines.sort(key=lambda x: (x[0][1], x[0][0]))
        for bbox, text in all_lines[:40]:
            print(f"[{bbox[0]:5.1f}, {bbox[1]:5.1f}, {bbox[2]:5.1f}, {bbox[3]:5.1f}] {text}")
        break
