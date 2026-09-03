import sys
import os
import json
import re
import pymupdf

sys.stdout.reconfigure(encoding='utf-8')

def normalize_greek(text):
    # Replace micro sign with greek mu
    text = text.replace('\u00b5', 'μ')
    # Normalize multiple spaces
    text = re.sub(r'[ \t]+', ' ', text)
    return text.strip()

def parse_psalter(pdf_path):
    doc = pymupdf.open(pdf_path)
    print(f"Reading {len(doc)} pages...")
    
    # Extract left and right text streams across all pages
    # We will accumulate tokens/lines
    all_pages_left = []
    all_pages_right = []
    
    for pno in range(len(doc)):
        page = doc[pno]
        data = page.get_text('dict')
        
        left_lines = []
        right_lines = []
        
        for b in data['blocks']:
            if 'lines' not in b:
                continue
            for l in b['lines']:
                y = l['bbox'][1]
                # Filter out headers and footers
                if y < 45 or y > 785:
                    continue
                    
                line_text = "".join(s['text'] for s in l['spans']).strip()
                if not line_text:
                    continue
                    
                x_start = l['bbox'][0]
                if x_start < 260:
                    left_lines.append((y, l['bbox'][0], line_text))
                else:
                    right_lines.append((y, l['bbox'][0], line_text))
                    
        left_lines.sort(key=lambda s: s[0])
        right_lines.sort(key=lambda s: s[0])
        
        all_pages_left.append((pno + 1, [normalize_greek(s[2]) for s in left_lines]))
        all_pages_right.append((pno + 1, [normalize_greek(s[2]) for s in right_lines]))
        
    return all_pages_left, all_pages_right

if __name__ == "__main__":
    pdf_path = r'C:\Users\PDS_Dev\Downloads\Ψαλτήρι.pdf'
    left_pages, right_pages = parse_psalter(pdf_path)
    
    # Flatten right text (the translation)
    full_right_lines = []
    for pno, lines in right_pages:
        full_right_lines.extend(lines)
    full_right_text = "\n".join(full_right_lines)
    
    # Check length
    print(f"Total right translation lines: {len(full_right_lines)}")
    print(f"Total characters: {len(full_right_text)}")
