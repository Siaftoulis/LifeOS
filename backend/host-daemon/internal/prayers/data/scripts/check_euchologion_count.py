import json
data = json.load(open('backend/host-daemon/internal/prayers/data/euchologion_raw.json', encoding='utf-8'))
print(f"Current euchologion prayers: {len(data['prayers'])}")
