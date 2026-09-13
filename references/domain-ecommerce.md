# Domain: E-Commerce Web Scraping

E-commerce websites present unique challenges: multi-attribute product variations (color, size, storage), dynamic pricing and stock availability, nested customer reviews with pagination, and anti-scraping perimeter security (Amazon, Shopify, Tokopedia, Shopee, eBay, Walmart).

---

## Critical Data Schema

Every e-commerce scraper must attempt to extract:

| Field | Type | Description |
|---|---|---|
| `sku` / `product_id` | `str` | Unique catalog identifier |
| `title` | `str` | Cleaned, normalized product title |
| `brand` | `str | null` | Brand or manufacturer name |
| `price` | `float` | Current sale price parsed to numeric value |
| `original_price` | `float | null` | Strikethrough/list price if discounted |
| `currency` | `str` | ISO 3-letter currency code (e.g. `USD`, `IDR`, `EUR`) |
| `availability` | `bool` | `True` if in stock, `False` if out of stock |
| `rating` | `float | null` | Product review average (0.0 - 5.0) |
| `review_count` | `int | null` | Total number of customer reviews |
| `images` | `list[str]` | High-resolution image URLs |
| `variants` | `list[dict]` | Variant options (size, color, price differentials) |
| `url` | `str` | Canonical product URL |

---

## Strategy 1: Shopify Storefront JSON Extraction

Shopify stores universally expose product catalog data via direct `.json` endpoint access:

```python
#!/usr/bin/env python3
import argparse
import json
import sys
import time
import httpx

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
    "Accept": "application/json",
}


def scrape_shopify_catalog(base_url: str, max_pages: int = 5) -> list[dict]:
    clean_base = base_url.rstrip("/")
    products = []

    with httpx.Client(headers=HEADERS, timeout=30) as client:
        for page in range(1, max_pages + 1):
            url = f"{clean_base}/products.json?limit=250&page={page}"
            response = client.get(url)
            if response.status_code != 200:
                break

            data = response.json()
            items = data.get("products", [])
            if not items:
                break

            for item in items:
                variants = item.get("variants", [])
                primary_price = float(variants[0]["price"]) if variants else None
                compare_price = float(variants[0]["compare_at_price"]) if variants and variants[0].get("compare_at_price") else None

                products.append({
                    "sku": str(item.get("id")),
                    "title": item.get("title", "").strip(),
                    "handle": item.get("handle"),
                    "vendor": item.get("vendor"),
                    "price": primary_price,
                    "original_price": compare_price,
                    "available": any(v.get("available", False) for v in variants),
                    "images": [img.get("src") for img in item.get("images", []) if img.get("src")],
                    "url": f"{clean_base}/products/{item.get('handle')}",
                })
            time.sleep(1.0)

    return products
```

---

## Strategy 2: Schema.org Product JSON-LD Extraction

Most major e-commerce platforms embed comprehensive `Product` Schema markup:

```python
import json
from parsel import Selector


def extract_ecommerce_schema(html: str, base_url: str) -> dict:
    sel = Selector(text=html)
    scripts = sel.css('script[type="application/ld+json"]::text').getall()

    for raw in scripts:
        try:
            data = json.loads(raw)
            items = data if isinstance(data, list) else [data]
            for item in items:
                if item.get("@type") == "Product":
                    offers = item.get("offers", {})
                    if isinstance(offers, list):
                        offers = offers[0] if offers else {}

                    price_val = offers.get("price") or offers.get("lowPrice")
                    return {
                        "title": item.get("name"),
                        "brand": item.get("brand", {}).get("name") if isinstance(item.get("brand"), dict) else item.get("brand"),
                        "sku": str(item.get("sku") or item.get("productID") or ""),
                        "price": float(price_val) if price_val is not None else None,
                        "currency": offers.get("priceCurrency", "USD"),
                        "availability": "InStock" in offers.get("availability", ""),
                        "rating": float(item.get("aggregateRating", {}).get("ratingValue", 0)) or None,
                        "review_count": int(item.get("aggregateRating", {}).get("reviewCount", 0)) or None,
                        "images": item.get("image", []) if isinstance(item.get("image"), list) else [item.get("image")] if item.get("image") else [],
                        "url": offers.get("url") or base_url,
                    }
        except json.JSONDecodeError:
            continue
    return {}
```

---

## Strategy 3: Dynamic Variant Switching (Playwright)

For modern SPAs where variant prices change dynamically via DOM interaction:

```python
from playwright.sync_api import sync_playwright


def extract_dynamic_variants(url: str) -> list[dict]:
    variants_data = []
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        page.goto(url, wait_until="networkidle", timeout=30000)

        # Query all size option buttons
        size_buttons = page.query_selector_all("button.size-option, [data-testid='size-selector'] button")
        for btn in size_buttons:
            size_name = btn.inner_text().strip()
            btn.click()
            page.wait_for_timeout(500)  # Brief UI settle

            price_el = page.query_selector(".price-current, [data-testid='product-price']")
            price_text = price_el.inner_text().strip() if price_el else ""

            stock_el = page.query_selector(".stock-status, [data-testid='stock-message']")
            in_stock = "in stock" in stock_el.inner_text().lower() if stock_el else True

            variants_data.append({
                "size": size_name,
                "price": price_text,
                "in_stock": in_stock,
            })

        browser.close()
    return variants_data
```
