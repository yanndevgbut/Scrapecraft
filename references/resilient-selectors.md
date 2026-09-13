# Resilient Multi-Tier Selector Architecture

A primary point of failure in web scrapers is CSS selector drift caused by website frontend redesigns, A/B testing variations, or dynamic framework class hashing (e.g., Tailwind, styled-components, CSS modules).

ScrapeCraft employs a **multi-tier fallback selector architecture** that tries semantic tiers in priority order.

---

## The 4-Tier Selector Hierarchy

```
Tier 1: Embedded State (JSON-LD, __NEXT_DATA__, Microdata)
   │ (Immune to CSS redesigns)
   ▼
Tier 2: Semantic Test & Data Attributes ([data-testid], [data-sku], [itemprop])
   │ (Rarely modified by visual style updates)
   ▼
Tier 3: Semantic HTML + BEM Class Patterns (article.product-card h2.title)
   │ (Human-readable classes, ignoring auto-hashed classes)
   ▼
Tier 4: Robust Relative XPath (//article[contains(@class, "card")]//h2)
     (Text anchoring and structural relationships)
```

---

## Python Resilient Parser Implementation

```python
from parsel import Selector


class ResilientExtractor:
    def __init__(self, node: Selector, base_url: str = ""):
        self.node = node
        self.base_url = base_url

    def extract_first(self, selectors: list[str], default: str = "") -> str:
        """Tries a list of CSS/XPath selectors in order, returning the first non-empty match."""
        for sel in selectors:
            if sel.startswith("/") or sel.startswith("("):
                # XPath
                val = self.node.xpath(sel).get()
            else:
                # CSS
                val = self.node.css(sel).get()

            if val and str(val).strip():
                return str(val).strip()
        return default

    def extract_all(self, selectors: list[str]) -> list[str]:
        for sel in selectors:
            if sel.startswith("/") or sel.startswith("("):
                vals = self.node.xpath(sel).getall()
            else:
                vals = self.node.css(sel).getall()

            cleaned = [str(v).strip() for v in vals if v and str(v).strip()]
            if cleaned:
                return cleaned
        return []
```

### Usage in Production Scraper

```python
def parse_item(card_selector: Selector, base_url: str) -> dict:
    ex = ResilientExtractor(card_selector, base_url)

    title = ex.extract_first([
        "[data-testid='product-title']::text",
        "[itemprop='name']::text",
        "h2.product-title::text",
        "h3.title::text",
        "a.product-link::text",
        ".//h2//text()",
    ])

    price = ex.extract_first([
        "[data-testid='product-price']::text",
        "[itemprop='price']::text",
        "span.price-current::text",
        "span.price::text",
        ".//span[contains(@class, 'price')]//text()",
    ])

    image_url = ex.extract_first([
        "img[data-testid='product-image']::attr(src)",
        "img[itemprop='image']::attr(src)",
        "img.product-image::attr(src)",
        "img::attr(data-src)",
        "img::attr(src)",
    ])

    return {
        "title": title,
        "price": price,
        "image_url": image_url,
    }
```

---

## Node.js Resilient Parser Implementation

```javascript
class ResilientExtractor {
  constructor($, element, baseUrl = "") {
    this.$ = $;
    this.el = $(element);
    this.baseUrl = baseUrl;
  }

  first(selectorList, defaultValue = "") {
    for (const sel of selectorList) {
      const match = this.el.find(sel);
      if (match.length > 0) {
        const text = match.text().trim();
        if (text) return text;
      }
    }
    return defaultValue;
  }

  attr(selectorList, attributeName, defaultValue = "") {
    for (const sel of selectorList) {
      const match = this.el.find(sel);
      if (match.length > 0) {
        const val = match.attr(attributeName);
        if (val && val.trim()) return val.trim();
      }
    }
    return defaultValue;
  }
}
```

---

## Anti-Patterns: Forbidden Selector Types

| Bad Selector Pattern | Why It Breaks | Preferred Alternative |
|---|---|---|
| `div.css-1r9vx7 > div > span` | Hashed Emotion/styled-components class will change on rebuild | `[data-testid="price"]` or `div[class*="price"]` |
| `/html/body/div[1]/div[2]/main/div[4]` | Hardcoded absolute DOM path breaks on any banner/notice addition | `//main//div[contains(@class, "product-grid")]` |
| `#ember1482` / `#react-root-4` | Dynamic runtime session IDs change on every page load | `[data-component="ProductCard"]` |
