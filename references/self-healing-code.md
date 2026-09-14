# Self-Healing Selector Engine & Dynamic Fallbacks

Web scrapers in production frequently break due to minor frontend refactoring, A/B testing variations, or framework class hashing. ScrapeCraft scrapers incorporate **Self-Healing Selector Logic** that dynamically discovers alternative anchor nodes when primary selectors fail.

---

## 1. Multi-Strategy Resilient Extractor (Python)

```python
import html
import re
from parsel import Selector


class SelfHealingExtractor:
    """
    Extracts values using prioritized selector cascades, regex heuristics,
    and attribute fallbacks without throwing runtime exceptions.
    """

    def __init__(self, node: Selector, base_url: str = ""):
        self.node = node
        self.base_url = base_url

    def extract_text(self, candidates: list[str], default: str = "") -> str:
        for candidate in candidates:
            if candidate.startswith("/") or candidate.startswith("("):
                val = self.node.xpath(candidate).get()
            else:
                val = self.node.css(candidate).get()

            if val and str(val).strip():
                unescaped = html.unescape(str(val))
                cleaned = re.sub(r"\s+", " ", unescaped).strip()
                if cleaned:
                    return cleaned
        return default

    def extract_attribute(self, candidates: list[str], attribute: str, default: str = "") -> str:
        for candidate in candidates:
            if candidate.startswith("/") or candidate.startswith("("):
                val = self.node.xpath(candidate).xpath(f"./@{attribute}").get()
            else:
                val = self.node.css(f"{candidate}::attr({attribute})").get()

            if val and str(val).strip():
                return str(val).strip()
        return default

    def extract_number(self, candidates: list[str], default: float | None = None) -> float | None:
        raw_text = self.extract_text(candidates)
        if not raw_text:
            return default

        # Clean non-numeric characters except decimals and commas
        cleaned = re.sub(r"[^\d.,]", "", raw_text).strip()
        if not cleaned:
            return default

        # Handle European vs US decimal formats
        if "," in cleaned and "." in cleaned:
            if cleaned.rfind(",") > cleaned.rfind("."):
                cleaned = cleaned.replace(".", "").replace(",", ".")
            else:
                cleaned = cleaned.replace(",", "")
        elif "," in cleaned and "." not in cleaned:
            cleaned = cleaned.replace(",", ".")

        try:
            return float(cleaned)
        except ValueError:
            return default
```

---

## 2. Dynamic Container Auto-Discovery

When static container classes (e.g. `div.product-grid`) are updated to dynamic hashes (`div.css-1f8a9x`), scrapers auto-discover repeating parent containers:

```python
def find_repeating_containers(root_selector: Selector) -> list[Selector]:
    """
    Identifies repeating card patterns based on shared structural depth
    and semantic child elements (links, headings, prices).
    """
    # 1. Try standard semantic containers first
    standard_selectors = [
        "[data-testid*='card']",
        "[data-testid*='item']",
        "[itemscope]",
        "article",
        "li.product",
        "div.product-card",
        "div.item-card",
    ]
    for sel in standard_selectors:
        matches = root_selector.css(sel)
        if len(matches) >= 3:
            return matches

    # 2. Heuristic fallback: Find parent elements containing h2/h3 + links + prices
    candidate_cards = root_selector.xpath(
        "//*[.//h2 or .//h3][.//a[@href]][.//span[contains(text(), '$') or contains(text(), '€') or contains(text(), 'Rp')]]"
    )
    if len(candidate_cards) >= 3:
        return candidate_cards

    return []
```

---

## 3. Node.js Self-Healing Implementation

```javascript
class SelfHealingExtractor {
  constructor($, element, baseUrl = "") {
    this.$ = $;
    this.el = $(element);
    this.baseUrl = baseUrl;
  }

  text(candidates, defaultValue = "") {
    for (const sel of candidates) {
      const match = this.el.find(sel);
      if (match.length > 0) {
        const txt = match.first().text().replace(/\s+/g, " ").trim();
        if (txt) return txt;
      }
    }
    return defaultValue;
  }

  attr(candidates, attributeName, defaultValue = "") {
    for (const sel of candidates) {
      const match = this.el.find(sel);
      if (match.length > 0) {
        const val = match.first().attr(attributeName);
        if (val && val.trim()) return val.trim();
      }
    }
    return defaultValue;
  }
}
```
