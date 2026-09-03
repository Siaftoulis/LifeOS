import urllib.request
import json
import sys

sys.stdout.reconfigure(encoding='utf-8')

headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}
for ep in ['/wp-json/wp/v2/categories?per_page=100', '/wp-json/wp/v2/posts?per_page=5']:
    try:
        url = 'https://www.proseyxi.com' + ep
        req = urllib.request.Request(url, headers=headers)
        data = json.loads(urllib.request.urlopen(req, timeout=10).read().decode('utf-8'))
        print(f"{ep} SUCCESS: {len(data)} items")
        if 'categories' in ep:
            for c in data[:20]:
                print(f"  id={c['id']}: {c['name']} (count={c['count']}) slug={c['slug']}")
    except Exception as e:
        print(f"{ep} FAILED: {e}")
