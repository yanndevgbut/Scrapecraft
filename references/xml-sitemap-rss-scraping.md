# XML Sitemap & RSS Feed Scraping

Before scraping millions of pages via brute-force crawling, smart scrapers inspect `sitemap.xml` and RSS/Atom feeds. Sitemaps provide clean inventories of all URLs on a domain, complete with publication timestamps and priority scores.

---

## 1. Sitemap & Sitemap Index Parser (Python)

```python
#!/usr/bin/env python3
import gzip
import io
import sys
import xml.etree.ElementTree as ET
import httpx

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
}


def parse_sitemap(url: str, max_urls: int = 1000) -> list[dict]:
    urls = []
    response = httpx.get(url, headers=HEADERS, timeout=30, follow_redirects=True)
    if response.status_code != 200:
        print(f"HTTP {response.status_code}: {url}", file=sys.stderr)
        return []

    content = response.content
    if url.endswith(".gz"):
        content = gzip.decompress(content)

    root = ET.fromstring(content)
    # Remove XML namespaces
    tag = root.tag.split("}")[-1]

    # Check if sitemap index (contains other sitemaps)
    if tag == "sitemapindex":
        sitemap_tags = root.findall(".//{*}loc")
        for loc in sitemap_tags:
            sub_url = loc.text.strip()
            print(f"Traversing nested sitemap: {sub_url}", file=sys.stderr)
            urls.extend(parse_sitemap(sub_url, max_urls=max_urls - len(urls)))
            if len(urls) >= max_urls:
                break
    elif tag == "urlset":
        for url_node in root.findall(".//{*}url"):
            loc = url_node.find("{*}loc")
            lastmod = url_node.find("{*}lastmod")
            if loc is not None and loc.text:
                urls.append({
                    "loc": loc.text.strip(),
                    "lastmod": lastmod.text.strip() if lastmod is not None and lastmod.text else None,
                })
                if len(urls) >= max_urls:
                    break

    return urls
```

---

## 2. RSS / Atom Feed Extraction

```python
import xml.etree.ElementTree as ET
import httpx


def parse_rss_feed(feed_url: str) -> list[dict]:
    response = httpx.get(feed_url, timeout=30, follow_redirects=True)
    root = ET.fromstring(response.content)

    items = []
    # Standard RSS 2.0
    for item in root.findall(".//item"):
        items.append({
            "title": item.findtext("title", "").strip(),
            "link": item.findtext("link", "").strip(),
            "pub_date": item.findtext("pubDate", "").strip(),
            "description": item.findtext("description", "").strip(),
        })

    # Atom Feed Support
    for entry in root.findall(".//{*}entry"):
        link_node = entry.find("{*}link")
        link_href = link_node.get("href") if link_node is not None else ""
        items.append({
            "title": entry.findtext("{*}title", "").strip(),
            "link": link_href,
            "pub_date": entry.findtext("{*}published", entry.findtext("{*}updated", "")).strip(),
            "description": entry.findtext("{*}summary", "").strip(),
        })

    return items
```
