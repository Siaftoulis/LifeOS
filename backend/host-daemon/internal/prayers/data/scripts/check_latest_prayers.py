import json
import sys

sys.stdout.reconfigure(encoding='utf-8')
data = json.load(open('backend/host-daemon/internal/prayers/data/euchologion_raw.json', encoding='utf-8'))
print(f"Total prayers: {len(data['prayers'])}")
print("\nLatest 5 prayers added:")
for p in data['prayers'][-5:]:
    print(f"- [{p.get('category')}] {p.get('title')} ({len(p.get('sections', []))} sections)")
