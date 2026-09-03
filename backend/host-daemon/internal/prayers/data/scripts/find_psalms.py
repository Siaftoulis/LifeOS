import sys
import pymupdf
import re

sys.stdout.reconfigure(encoding='utf-8')

doc = pymupdf.open(r'C:\Users\PDS_Dev\Downloads\Ψαλτήρι.pdf')
print("Total pages in Psalter:", len(doc))

# Find where each Psalm appears
psalm_locations = []
# Left column is x0 < 265, right column is x0 >= 265

for pno in range(len(doc)):
    page = doc[pno]
    blocks = page.get_text('blocks')
    for b in blocks:
        # Check if block is in left column or centered
        txt = b[4].strip()
        # Large psalm number like "1", "2", ... "150" alone on a line or block
        if re.match(r'^[0-9]{1,3}$', txt) and b[1] < 750:
            val = int(txt)
            if 1 <= val <= 151:
                psalm_locations.append((pno + 1, val, b[0], b[1]))

print(f"Found {len(psalm_locations)} potential psalm headers:")
for loc in psalm_locations[:30]:
    print(f"  Page {loc[0]}: Psalm {loc[1]} at x={loc[2]:.1f}, y={loc[3]:.1f}")
