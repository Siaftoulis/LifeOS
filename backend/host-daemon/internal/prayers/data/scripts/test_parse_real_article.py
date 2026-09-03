import urllib.request
from bs4 import BeautifulSoup
import sys

sys.stdout.reconfigure(encoding='utf-8')

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
}

url = 'https://www.proseyxi.com/mikros-paraklitikos-kanon/'
req = urllib.request.Request(url, headers=headers)
with urllib.request.urlopen(req, timeout=15) as resp:
    html = resp.read().decode('utf-8', errors='ignore')

soup = BeautifulSoup(html, 'html.parser')
title = soup.find('h1')
print(f"TITLE: {title.get_text().strip() if title else 'None'}")

# Content search
widgets = soup.find_all('div', class_='elementor-widget-container')
print(f"Total widget containers: {len(widgets)}")
for i, w in enumerate(widgets):
    text = w.get_text().strip()
    if len(text) > 100:
        print(f"Widget {i} (len={len(text)}): {text[:150]}...\n")
