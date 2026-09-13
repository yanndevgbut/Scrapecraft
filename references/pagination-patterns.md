# Pagination & Infinite Scroll Architecture

Production scrapers must systematically traverse multi-page catalogs without losing records, entering infinite loops, or getting blocked.

---

## The 4 Universal Pagination Architectures

```
Pagination Model
├── 1. Offset / Page Number (?page=2&limit=50)
├── 2. Next-Page Link Traversal (<a rel="next" href="...">)
├── 3. Cursor / Token-Based (?cursor=eyJpZCI6MTIzfQ==)
└── 4. Dynamic Infinite Scroll (Virtual Window or Trigger Buttons)
```

---

## Architecture 1: Offset & Page Number Pagination (Python httpx)

```python
import sys
import time
from urllib.parse import urlencode, parse_qs, urlsplit, urlunsplit
import httpx
from parsel import Selector


def update_query_param(url: str, **params) -> str:
    scheme, netloc, path, query_string, fragment = urlsplit(url)
    query_params = parse_qs(query_string)
    for k, v in params.items():
        query_params[k] = [str(v)]
    new_query = urlencode(query_params, doseq=True)
    return urlunsplit((scheme, netloc, path, new_query, fragment))


def scrape_offset_pages(base_url: str, max_pages: int = 10, delay: float = 1.0) -> list[dict]:
    all_records = []

    with httpx.Client(timeout=30) as client:
        for page_idx in range(1, max_pages + 1):
            target_url = update_query_param(base_url, page=page_idx)
            print(f"Scraping page {page_idx}: {target_url}", file=sys.stderr)

            response = client.get(target_url)
            if response.status_code != 200:
                print(f"Stopping: HTTP {response.status_code}", file=sys.stderr)
                break

            sel = Selector(text=response.text)
            items = sel.css("div.product-card")
            if not items:
                print("Stopping: Zero items found on page.", file=sys.stderr)
                break

            for item in items:
                all_records.append({
                    "title": item.css("h2::text").get("").strip(),
                })

            time.sleep(delay)

    return all_records
```

---

## Architecture 2: Follow Next-Link Traversal

```python
from urllib.parse import urljoin
import httpx
from parsel import Selector


def scrape_follow_next(start_url: str, max_pages: int = 20) -> list[dict]:
    all_records = []
    current_url = start_url
    page_count = 0
    visited = set()

    with httpx.Client(timeout=30) as client:
        while current_url and page_count < max_pages:
            if current_url in visited:
                break
            visited.add(current_url)

            response = client.get(current_url)
            if response.status_code != 200:
                break

            sel = Selector(text=response.text)
            # Parse page items...
            items = sel.css("article.item")
            for item in items:
                all_records.append({"title": item.css("h2::text").get("").strip()})

            # Extract next link using resilient selectors
            next_href = (
                sel.css("a[rel='next']::attr(href)").get()
                or sel.css("a.pagination__next::attr(href)").get()
                or sel.xpath("//a[contains(translate(text(), 'NEXT', 'next'), 'next')]/@href").get()
            )

            if next_href:
                current_url = urljoin(current_url, next_href)
                page_count += 1
            else:
                current_url = None

    return all_records
```

---

## Architecture 3: Playwright Infinite Scroll with Dynamic Wait

```python
from playwright.sync_api import sync_playwright


def scrape_infinite_scroll(url: str, max_items: int = 150) -> list[dict]:
    results = {}
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        page.goto(url, wait_until="networkidle", timeout=30000)

        consecutive_stalls = 0
        while len(results) < max_items and consecutive_stalls < 4:
            prev_len = len(results)

            cards = page.query_selector_all("div.card, [data-testid='card']")
            for card in cards:
                item_id = card.get_attribute("data-id") or card.inner_text()[:30]
                if item_id not in results:
                    results[item_id] = {
                        "id": item_id,
                        "text": card.inner_text().strip(),
                    }

            # Check if there is a 'Load More' button before scrolling
            load_more = page.query_selector("button.load-more, [data-testid='load-more']")
            if load_more and load_more.is_visible():
                load_more.click()
                page.wait_for_timeout(1000)
            else:
                page.evaluate("window.scrollTo(0, document.body.scrollHeight);")
                page.wait_for_timeout(1500)

            if len(results) == prev_len:
                consecutive_stalls += 1
            else:
                consecutive_stalls = 0

        browser.close()
    return list(results.values())
```
