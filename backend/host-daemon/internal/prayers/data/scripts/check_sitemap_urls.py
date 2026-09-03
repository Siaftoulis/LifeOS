import urllib.request
import xml.etree.ElementTree as ET

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
}

req = urllib.request.Request('https://www.proseyxi.com/post-sitemap1.xml', headers=headers)
with urllib.request.urlopen(req, timeout=15) as resp:
    xml_data = resp.read()

root = ET.fromstring(xml_data)
urls = []
for child in root:
    loc = child.find('{http://www.sitemaps.org/schemas/sitemap/0.9}loc')
    if loc is not None and loc.text:
        urls.append(loc.text)

print(f"Found {len(urls)} URLs in post-sitemap1.xml")
for u in urls[:15]:
    print(" ", u)
