import urllib.request
import re
from bs4 import BeautifulSoup
import time

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'el-GR,el;q=0.9,en;q=0.8',
}

test_urls = [
    'https://www.proseyxi.com/proseyxi-ston-agelo-fylaka/',
    'https://www.proseyxi.com/eyxi-eis-pasan-astheneian/',
    'https://www.proseyxi.com/proseyxi-gia-tin-oikogeneia/',
]

for url in test_urls:
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=15) as resp:
            html = resp.read().decode('utf-8', errors='ignore')
            soup = BeautifulSoup(html, 'html.parser')
            
            title = soup.find('h1')
            title_text = title.get_text().strip() if title else 'No title'
            
            # Find content in elementor text editor or entry-content
            content_divs = soup.find_all('div', class_='elementor-widget-text-editor')
            paragraphs = []
            for d in content_divs:
                ps = [p.get_text().strip() for p in d.find_all(['p', 'h2', 'h3']) if p.get_text().strip()]
                paragraphs.extend(ps)
                
            print(f"\nURL: {url}")
            print(f"Title: {title_text}")
            print(f"Paragraphs count: {len(paragraphs)}")
            if paragraphs:
                print(f"First paragraph: {paragraphs[0][:80]}...")
        time.sleep(1.2)
    except Exception as e:
        print(f"Error fetching {url}: {e}")
