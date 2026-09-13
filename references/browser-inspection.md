# Browser Inspection Guide

This document defines how to inspect a target website's DOM to extract accurate selectors.

## Inspection Strategy

### Step 1: Determine Page Type

Fetch the page with a simple HTTP GET first:

```bash
curl -s -o /tmp/scrapecraft_page.html -w "%{http_code}" -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36" "<URL>"
```

Check the response:

| Response Pattern | Page Type | Action |
|---|---|---|
| HTTP 200, HTML contains target data | Static | Use HTTP-based scraping |
| HTTP 200, HTML is a shell with JS bundles | JS-rendered SPA | Use headless browser |
| HTTP 403/503, Cloudflare challenge page | Protected | See `references/anti-detection.md` |
| HTTP 429 | Rate-limited | Add delays, rotate User-Agent |

### Step 2: Extract DOM Structure

**For static pages:**

Use `WebFetch` or read the downloaded HTML to identify:
- The container element that wraps all target items (e.g., `div.product-list`, `ul.results`).
- The repeating element for each item (e.g., `div.product-card`, `li.result-item`).
- The specific child elements containing each data field.

**For JS-rendered pages:**

Launch a headless browser to get the fully rendered DOM:

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto("<URL>", wait_until="networkidle")
    content = page.content()
    browser.close()
```

Or with Node.js:

```javascript
const { chromium } = require('playwright');

(async () => {
    const browser = await chromium.launch({ headless: true });
    const page = await browser.newPage();
    await page.goto('<URL>', { waitUntil: 'networkidle' });
    const content = await page.content();
    await browser.close();
})();
```

### Step 3: Identify Selectors

From the DOM content, identify selectors using this priority order:

1. **`data-*` attributes** (most stable): `[data-testid="product-name"]`
2. **Semantic HTML + unique classes**: `article.product-card h2.title`
3. **ARIA attributes**: `[aria-label="Price"]`
4. **Structural selectors** (less stable): `div > ul > li:nth-child(2)`
5. **XPath** (last resort): `//div[@class="product"]//span[@class="price"]`

Rules:
- Never use auto-generated class names (e.g., `css-1a2b3c`, `sc-dkzDqf`, `_1x2y3z`).
- Never use `id` attributes that contain session tokens or random hashes.
- Prefer selectors that survive minor DOM restructuring.

### Step 4: Verify Selectors

Before writing the final scraper, verify each selector returns the expected data:

```python
from parsel import Selector

sel = Selector(text=html_content)
items = sel.css("div.product-card")
print(f"Found {len(items)} items")
for item in items[:3]:
    print(item.css("h2.title::text").get())
    print(item.css("span.price::text").get())
```

If a selector returns 0 results, the selector is wrong. Re-inspect the DOM. Do NOT add a try-except to hide the failure.

## Using Companion Browser Skills

If `agent-browser` or `playwright-cli` is installed, use them for interactive inspection:

```
# With agent-browser
browser navigate <URL>
browser extract "div.product-card"

# With playwright-cli
playwright navigate <URL>
playwright evaluate "document.querySelectorAll('div.product-card').length"
```

## Network Request Analysis

For API-backed pages, inspect network requests:

1. Look for XHR/fetch calls returning JSON data.
2. If the data comes from an API endpoint, scrape the API directly instead of parsing HTML.
3. API scraping is always preferred over DOM scraping when available.

```python
# Intercept network requests with Playwright
def handle_response(response):
    if "/api/" in response.url and response.status == 200:
        print(f"API: {response.url}")
        print(response.json())

page.on("response", handle_response)
page.goto("<URL>", wait_until="networkidle")
```
