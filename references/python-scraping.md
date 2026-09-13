# Python Scraping Playbook

## Library Selection

| Library | Use Case | Install |
|---|---|---|
| `httpx` | HTTP requests (async-capable, HTTP/2) | `pip install httpx` |
| `parsel` | CSS/XPath selector parsing (Scrapy's engine) | `pip install parsel` |
| `selectolax` | Ultra-fast HTML parsing (C-based) | `pip install selectolax` |
| `beautifulsoup4` | Forgiving HTML parsing | `pip install beautifulsoup4 lxml` |
| `playwright` | JS-rendered pages, browser automation | `pip install playwright && playwright install chromium` |
| `scrapy` | Large-scale crawling with pipelines | `pip install scrapy` |
| `httpx` + `parsel` | Default combo for static pages | `pip install httpx parsel` |

## Code Templates

### Template 1: Static Page (httpx + parsel)

```python
#!/usr/bin/env python3
import json
import sys
import httpx
from parsel import Selector

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
}


def scrape(url):
    response = httpx.get(url, headers=HEADERS, timeout=30, follow_redirects=True)
    if response.status_code != 200:
        print(f"HTTP {response.status_code}: {url}", file=sys.stderr)
        sys.exit(1)

    sel = Selector(text=response.text)
    items = sel.css("CONTAINER_SELECTOR")

    if not items:
        print("No items found. Selector may be incorrect.", file=sys.stderr)
        sys.exit(1)

    results = []
    for item in items:
        results.append({
            "field_1": item.css("FIELD_1_SELECTOR::text").get("").strip(),
            "field_2": item.css("FIELD_2_SELECTOR::text").get("").strip(),
        })

    return results


def main():
    url = "TARGET_URL"
    data = scrape(url)
    print(json.dumps(data, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
```

### Template 2: JS-Rendered Page (Playwright)

```python
#!/usr/bin/env python3
import json
import sys
from playwright.sync_api import sync_playwright


def scrape(url):
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
            viewport={"width": 1920, "height": 1080},
        )
        page = context.new_page()
        page.goto(url, wait_until="networkidle", timeout=30000)

        items = page.query_selector_all("CONTAINER_SELECTOR")

        if not items:
            print("No items found. Selector may be incorrect.", file=sys.stderr)
            browser.close()
            sys.exit(1)

        results = []
        for item in items:
            results.append({
                "field_1": (item.query_selector("FIELD_1_SELECTOR") or _empty()).inner_text().strip(),
                "field_2": (item.query_selector("FIELD_2_SELECTOR") or _empty()).inner_text().strip(),
            })

        browser.close()
        return results


class _empty:
    def inner_text(self):
        return ""

    def get_attribute(self, _):
        return ""


def main():
    url = "TARGET_URL"
    data = scrape(url)
    print(json.dumps(data, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
```

### Template 3: API Interception (Playwright)

```python
#!/usr/bin/env python3
import json
import sys
from playwright.sync_api import sync_playwright

captured_data = []


def intercept_response(response):
    if "API_ENDPOINT_PATTERN" in response.url and response.status == 200:
        try:
            captured_data.append(response.json())
        except Exception:
            pass


def scrape(url):
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        page.on("response", intercept_response)
        page.goto(url, wait_until="networkidle", timeout=30000)
        browser.close()

    if not captured_data:
        print("No API responses captured.", file=sys.stderr)
        sys.exit(1)

    return captured_data


def main():
    url = "TARGET_URL"
    data = scrape(url)
    print(json.dumps(data, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
```

### Template 4: Multi-Page Crawl (httpx + parsel)

```python
#!/usr/bin/env python3
import json
import sys
import time
import httpx
from parsel import Selector

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
}

DELAY_SECONDS = 1.5


def fetch_page(client, url):
    response = client.get(url, headers=HEADERS, timeout=30, follow_redirects=True)
    if response.status_code != 200:
        print(f"HTTP {response.status_code}: {url}", file=sys.stderr)
        return None
    return response.text


def parse_listing(html):
    sel = Selector(text=html)
    items = sel.css("CONTAINER_SELECTOR")
    results = []
    for item in items:
        results.append({
            "field_1": item.css("FIELD_1_SELECTOR::text").get("").strip(),
            "field_2": item.css("FIELD_2_SELECTOR::text").get("").strip(),
        })
    return results


def get_next_page_url(html):
    sel = Selector(text=html)
    next_link = sel.css("NEXT_PAGE_SELECTOR::attr(href)").get()
    return next_link


def main():
    start_url = "TARGET_URL"
    all_results = []

    with httpx.Client() as client:
        current_url = start_url
        page_num = 1
        max_pages = 10

        while current_url and page_num <= max_pages:
            print(f"Scraping page {page_num}: {current_url}", file=sys.stderr)
            html = fetch_page(client, current_url)
            if html is None:
                break

            results = parse_listing(html)
            all_results.extend(results)

            next_url = get_next_page_url(html)
            if next_url and not next_url.startswith("http"):
                from urllib.parse import urljoin
                next_url = urljoin(current_url, next_url)

            current_url = next_url
            page_num += 1
            time.sleep(DELAY_SECONDS)

    print(json.dumps(all_results, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
```

## Python Code Conventions

- Always use `#!/usr/bin/env python3` shebang.
- Always define a `main()` function with `if __name__ == "__main__":` guard.
- Use `httpx` over `requests` (async-ready, HTTP/2 support, better timeouts).
- Use `parsel` over `beautifulsoup4` for speed (unless the HTML is severely malformed).
- Print results to stdout as JSON. Print diagnostic messages to stderr.
- Always set explicit `timeout` on every HTTP request.
- Always send a realistic `User-Agent` header.
- Use `sys.exit(1)` for failures, never silent returns of empty data.
