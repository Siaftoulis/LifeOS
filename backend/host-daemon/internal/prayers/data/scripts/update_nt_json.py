import sys
import os
import pymupdf
import re
import json

sys.stdout.reconfigure(encoding='utf-8')
pdf_path = r'C:\Users\PDS_Dev\Downloads\ΚΑΙΝΗ ΔΙΑΘΗΚΗ 2η ΕΚΔΟΣΗ.pdf'
nt_json_path = r'backend\host-daemon\internal\prayers\data\nt_raw.json'

with open(nt_json_path, 'r', encoding='utf-8') as f:
    nt_data = json.load(f)

doc = pymupdf.open(pdf_path)

book_ranges = [
    (1, "ΚΑΤΑ ΜΑΤΘΑΙΟΝ", 43, 179, 28),
    (2, "ΚΑΤΑ ΜΑΡΚΟΝ", 181, 265, 16),
    (3, "ΚΑΤΑ ΛΟΥΚΑΝ", 267, 423, 24),
    (4, "ΚΑΤΑ ΙΩΑΝΝΗΝ", 425, 545, 21),
    (5, "ΠΡΑΞΕΙΣ ΑΠΟΣΤΟΛΩΝ", 547, 681, 28),
    (6, "ΠΡΟΣ ΡΩΜΑΙΟΥΣ", 683, 745, 16),
    (7, "ΠΡΟΣ ΚΟΡΙΝΘΙΟΥΣ Α", 747, 801, 16),
    (8, "ΠΡΟΣ ΚΟΡΙΝΘΙΟΥΣ Β", 803, 839, 13),
    (9, "ΠΡΟΣ ΓΑΛΑΤΑΣ", 841, 861, 6),
    (10, "ΠΡΟΣ ΕΦΕΣΙΟΥΣ", 863, 883, 6),
    (11, "ΠΡΟΣ ΦΙΛΙΠΠΗΣΙΟΥΣ", 885, 899, 4),
    (12, "ΠΡΟΣ ΚΟΛΟΣΣΑΕΙΣ", 901, 913, 4),
    (13, "ΠΡΟΣ ΘΕΣΣΑΛΟΝΙΚΕΙΣ Α", 915, 926, 5),
    (14, "ΠΡΟΣ ΘΕΣΣΑΛΟΝΙΚΕΙΣ Β", 927, 933, 3),
    (15, "ΠΡΟΣ ΤΙΜΟΘΕΟΝ Α", 935, 949, 6),
    (16, "ΠΡΟΣ ΤΙΜΟΘΕΟΝ Β", 950, 959, 4),
    (17, "ΠΡΟΣ ΤΙΤΟΝ", 961, 965, 3),
    (18, "ΠΡΟΣ ΦΙΛΗΜΟΝΑ", 967, 969, 1),
    (19, "ΠΡΟΣ ΕΒΡΑΙΟΥΣ", 971, 1013, 13),
    (20, "ΙΑΚΩΒΟΥ", 1015, 1033, 5),
    (21, "ΠΕΤΡΟΥ Α", 1035, 1049, 5),
    (22, "ΠΕΤΡΟΥ Β", 1051, 1061, 3),
    (23, "ΙΩΑΝΝΟΥ Α", 1063, 1076, 5),
    (24, "ΙΩΑΝΝΟΥ Β", 1077, 1080, 1),
    (25, "ΙΩΑΝΝΟΥ Γ", 1081, 1083, 1),
    (26, "ΙΟΥΔΑ", 1084, 1089, 1),
    (27, "ΑΠΟΚΑΛΥΨΙΣ ΙΩΑΝΝΟΥ", 1091, 1165, 22),
]

def extract_book_complete(doc, start_page, end_page, total_chapters):
    chapters = {c: {} for c in range(1, total_chapters + 1)}
    current_ch = 1
    current_v = 1
    
    for pno in range(start_page - 1, end_page):
        page = doc[pno]
        data = page.get_text('dict')
        
        lines = []
        for b in data['blocks']:
            if 'lines' not in b:
                continue
            for l in b['lines']:
                y = l['bbox'][1]
                x = l['bbox'][0]
                if y < 45:
                    continue
                line_text = "".join(s['text'] for s in l['spans']).strip()
                
                # Check for chapter header
                m_ch = re.search(r'ΚΕΦΑΛΑΙΟΝ\s+([^\(\n]+)\(([0-9]+)\)', line_text)
                if m_ch:
                    n_ch = int(m_ch.group(2))
                    lines.append((y, 100, 10.0, f"__NEW_CH_{n_ch}__"))
                    continue
                
                # Check right column spans
                for s in l['spans']:
                    if s['size'] >= 7.5 and x >= 155:
                        t = s['text'].strip()
                        if t:
                            lines.append((y, x, s['size'], t))
                            
        lines.sort(key=lambda item: (item[0], item[1]))
        
        for y, x, sz, t in lines:
            if t.startswith("__NEW_CH_"):
                new_ch = int(t.replace("__NEW_CH_", "").replace("__", ""))
                if 1 <= new_ch <= total_chapters:
                    current_ch = new_ch
                    current_v = 1
                continue
                
            if t.startswith("Στίχ.") or "ΚΕΦΑΛΑΙΟΝ" in t:
                continue
                
            # Match verse numbers e.g. "2 ", "2. ", "2-3 "
            m_v = re.match(r'^([0-9]{1,3})(?:-[0-9]{1,3})?[\.\s]+(.*)$', t)
            if m_v:
                v_num = int(m_v.group(1))
                if (1 <= v_num <= 180) and (v_num == current_v + 1 or v_num == 1 or (current_v == 1 and v_num in [2, 3]) or (v_num > current_v and v_num <= current_v + 4)):
                    current_v = v_num
                    rest = m_v.group(2).strip()
                    if current_ch in chapters:
                        chapters[current_ch][current_v] = rest
                    continue
                    
            if current_ch in chapters:
                if current_v not in chapters[current_ch]:
                    chapters[current_ch][current_v] = t
                else:
                    if len(chapters[current_ch][current_v]) <= 2:
                        chapters[current_ch][current_v] += t
                    else:
                        chapters[current_ch][current_v] += " " + t

    for c in chapters:
        for v in list(chapters[c].keys()):
            txt = chapters[c][v]
            txt = re.sub(r'(\w+)-\s+(\w+)', r'\1\2', txt)
            txt = re.sub(r'[ \t]+', ' ', txt).strip()
            chapters[c][v] = txt

    return chapters

all_extracted = {}
total_all_extracted = 0
total_all_expected = 0

for b_idx, (b_num, b_name, s_p, e_p, tot_ch) in enumerate(book_ranges):
    b_dict = extract_book_complete(doc, s_p, e_p, tot_ch)
    all_extracted[b_num] = b_dict
    
    b_json = nt_data['books'][b_idx]
    tot_ext = sum(len(b_dict[c]) for c in b_dict)
    tot_exp = sum(len(c['verses']) for c in b_json['chapters'])
    total_all_extracted += tot_ext
    total_all_expected += tot_exp
    pct = (tot_ext * 100.0 / tot_exp) if tot_exp > 0 else 0
    print(f"Book {b_num:2d} ({b_name:24s}): {tot_ext:4d} / {tot_exp:4d} ({pct:5.1f}%)")

print("="*60)
print(f"TOTAL EXTRACTED: {total_all_extracted} / {total_all_expected} ({total_all_extracted*100.0/total_all_expected:.1f}%)")

# Enrich nt_data with translations
matched_in_json = 0
for b_idx, b in enumerate(nt_data['books']):
    b_num = b['number']
    b_trans = all_extracted.get(b_num, {})
    for ch in b['chapters']:
        ch_num = ch['number']
        ch_trans = b_trans.get(ch_num, {})
        last_known_trans = ""
        for v in ch['verses']:
            v_num = v['number']
            if v_num in ch_trans and ch_trans[v_num]:
                v['translation'] = ch_trans[v_num]
                last_known_trans = ch_trans[v_num]
                matched_in_json += 1
            else:
                # If verse was combined into previous verse (e.g. 25-26)
                if last_known_trans:
                    v['translation'] = last_known_trans + " [Συνέχεια]"
                else:
                    v['translation'] = ""

print(f"Matched and enriched {matched_in_json} verses in nt_raw.json")

# Write backup and update
with open(nt_json_path + '.bak', 'w', encoding='utf-8') as f:
    json.dump(nt_data, f, ensure_ascii=False, indent=2)

with open(nt_json_path, 'w', encoding='utf-8') as f:
    json.dump(nt_data, f, ensure_ascii=False, indent=2)

print("nt_raw.json successfully updated with translations!")
