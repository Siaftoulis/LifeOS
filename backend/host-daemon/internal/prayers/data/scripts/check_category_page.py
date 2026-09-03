import urllib.request
from bs4 import BeautifulSoup
import sys

sys.stdout.reconfigure(encoding='utf-8')

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
}

url = 'https://www.proseyxi.com/category/proseyxes/diafores-proseyxes/'
req = urllib.request.Request(url, headers=headers)
with urllib.request.urlopen(req, timeout=15) as resp:
    html = resp.read().decode('utf-8', errors='ignore')

soup = BeautifulSoup(html, 'html.parser')
articles = soup.find_all('article')
print(f"Found {len(articles)} articles on page 1")
for a in articles[:10]:
    title_el = a.find(['h2', 'h1', 'h3'])
    link = a.find('a')
    t = title_el.get_text().strip() if title_el else 'No title'
    href = link['href'] if link and 'href' in link.attrs else 'No href'
    print(f"  {t} -> {href}")

# Check pagination
pagination = soup.find('div', class_='nav-links') or soup.find('ul', class_='page-numbers')
print(f"Pagination: {pagination.get_text().strip() if pagination else 'None'}")
