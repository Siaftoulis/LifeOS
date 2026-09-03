import urllib.request
import bs4
import sys
import json

sys.stdout.reconfigure(encoding='utf-8')

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'el,en;q=0.9',
}

# Fetch sample prayer page
url = "https://www.proseyxi.com/category/proseyxes/diafores-proseyxes/"
req = urllib.request.Request(url, headers=headers)
html = urllib.request.urlopen(req, timeout=15).read().decode('utf-8', errors='ignore')
soup = bs4.BeautifulSoup(html, 'html.parser')

print("Page title:", soup.title.string if soup.title else "")
articles = soup.find_all('article')
print("Articles found on category page:", len(articles))
for art in articles[:5]:
    title_tag = art.find(['h2', 'h1', 'h3'])
    a_tag = art.find('a', href=True)
    title = title_tag.get_text(strip=True) if title_tag else (a_tag.get_text(strip=True) if a_tag else "")
    link = a_tag['href'] if a_tag else ""
    print(f"- {title} -> {link}")

# If we found links, inspect the first one
if articles and articles[0].find('a', href=True):
    sample_url = articles[0].find('a', href=True)['href']
    print(f"\n--- Testing sample prayer: {sample_url} ---")
    sreq = urllib.request.Request(sample_url, headers=headers)
    shtml = urllib.request.urlopen(sreq, timeout=15).read().decode('utf-8', errors='ignore')
    ssoup = bs4.BeautifulSoup(shtml, 'html.parser')
    
    content = ssoup.find('div', class_='entry-content') or ssoup.find('article')
    if content:
        # Remove scripts, styles, share buttons, ads
        for bad in content.find_all(['script', 'style', 'nav', 'aside', 'div.sharedaddy', 'div.jp-relatedposts']):
            bad.decompose()
        print("Content preview:")
        print(content.get_text(separator="\n", strip=True)[:500])
