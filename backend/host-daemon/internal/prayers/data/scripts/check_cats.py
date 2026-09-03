import urllib.request
import bs4
import sys
import warnings
from bs4 import XMLParsedAsHTMLWarning
warnings.filterwarnings('ignore', category=XMLParsedAsHTMLWarning)

sys.stdout.reconfigure(encoding='utf-8')

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36'
}

# Let's inspect category pages to get all articles per category
categories = [
    ('Διάφορες Προσευχές', 'https://www.proseyxi.com/category/proseyxes/diafores-proseyxes/'),
    ('Προσευχές Αγίων', 'https://www.proseyxi.com/category/proseyxes/proseyxes-agion/'),
    ('Ακολουθίες', 'https://www.proseyxi.com/category/akolouthies/'),
    ('Ακολουθίες Αγίων', 'https://www.proseyxi.com/category/akolouthies-agion/'),
    ('Παρακλήσεις Αγίων', 'https://www.proseyxi.com/category/paraklisis/parakliseis-eis-tous-agious/'),
    ('Χαιρετισμοί Αγίων', 'https://www.proseyxi.com/category/xairetismoi/xairetismoi-eis-tous-agious/'),
    ('Χαιρετισμοί Παναγίας', 'https://www.proseyxi.com/category/xairetismoi/xairetismoi-eis-ta-onomata-tis-yperagias-theotokou/'),
]

for cat_name, cat_url in categories:
    try:
        req = urllib.request.Request(cat_url, headers=headers)
        html = urllib.request.urlopen(req, timeout=10).read().decode('utf-8', errors='ignore')
        soup = bs4.BeautifulSoup(html, 'html.parser')
        articles = soup.find_all('article')
        
        # Check pagination
        pagination = soup.find('ul', class_='page-numbers') or soup.find('div', class_='pagination')
        last_page = 1
        if pagination:
            pages = [int(a.text) for a in pagination.find_all(['a', 'span']) if a.text.isdigit()]
            if pages:
                last_page = max(pages)
        print(f"{cat_name}: {len(articles)} on page 1, total pages ~{last_page}")
    except Exception as e:
        print(f"{cat_name} error: {e}")
