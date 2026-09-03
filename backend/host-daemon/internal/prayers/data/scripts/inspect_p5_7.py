import sys
import pymupdf

sys.stdout.reconfigure(encoding='utf-8')
doc = pymupdf.open(r'C:\Users\PDS_Dev\Downloads\Ψαλτήρι.pdf')
for p in [4, 5, 6, 7]:
    print(f"=== PAGE {p+1} ===")
    page = doc[p]
    for b in page.get_text('blocks'):
        txt = b[4].strip()
        if len(txt) < 30:
            print(f"  ({b[0]:.1f}, {b[1]:.1f}) -> {repr(txt)}")
