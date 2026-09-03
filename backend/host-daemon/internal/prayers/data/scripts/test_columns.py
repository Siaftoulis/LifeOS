import sys
import pymupdf

sys.stdout.reconfigure(encoding='utf-8')
doc = pymupdf.open(r'C:\Users\PDS_Dev\Downloads\Ψαλτήρι.pdf')

for pno in range(5):
    page = doc[pno]
    data = page.get_text('dict')
    
    left_spans = []
    right_spans = []
    
    for b in data['blocks']:
        if 'lines' not in b:
            continue
        for l in b['lines']:
            y = l['bbox'][1]
            if y < 45 or y > 785:
                continue # Skip header and footer
            
            line_text = "".join(s['text'] for s in l['spans']).strip()
            if not line_text:
                continue
                
            x_mid = (l['bbox'][0] + l['bbox'][2]) / 2.0
            x_start = l['bbox'][0]
            
            # Left column text starts at x < 260
            # Right column text starts at x >= 260
            if x_start < 260:
                left_spans.append((y, l['bbox'][0], line_text))
            else:
                right_spans.append((y, l['bbox'][0], line_text))
                
    left_spans.sort(key=lambda s: s[0])
    right_spans.sort(key=lambda s: s[0])
    
    print(f"\n================ PAGE {pno+1} ================")
    print("--- LEFT (Original) ---")
    for s in left_spans[:8]:
        print(f"  {s[2]}")
    print("--- RIGHT (Translation) ---")
    for s in right_spans[:8]:
        print(f"  {s[2]}")
