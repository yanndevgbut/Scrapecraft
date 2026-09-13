# Data Normalization & Schema Cleaning

Raw scraped data is frequently dirty: currency strings with mixed symbols (`"$ 1,299.00 USD"`), unescaped HTML entities (`&amp;`, `&quot;`), relative URLs (`/item/42`), messy whitespace with line breaks, and inconsistent date formats.

ScrapeCraft guarantees **production-grade output** by normalizing every field before output serialization.

---

## Standard Normalization Utilities

### Python Normalizer (`normalizer.py`)

```python
import html
import re
from urllib.parse import urljoin
from datetime import datetime


def clean_text(text: str) -> str:
    """Strips excessive whitespace, resolves HTML entities, and removes control characters."""
    if not text:
        return ""
    unescaped = html.unescape(str(text))
    normalized_whitespace = re.sub(r"\s+", " ", unescaped)
    return normalized_whitespace.strip()


def parse_price(price_str: str) -> float | None:
    """Extracts numeric float value from currency strings like '$ 1,499.99' or '€ 1.499,99'."""
    if not price_str:
        return None
    cleaned = re.sub(r"[^\d.,]", "", str(price_str)).strip()
    if not cleaned:
        return None

    # Handle European format: 1.499,99 -> 1499.99
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
        return None


def resolve_url(relative_or_absolute: str, base_url: str) -> str:
    """Resolves relative links to fully qualified absolute HTTP/HTTPS URLs."""
    if not relative_or_absolute:
        return ""
    relative_or_absolute = relative_or_absolute.strip()
    if relative_or_absolute.startswith("//"):
        return f"https:{relative_or_absolute}"
    return urljoin(base_url, relative_or_absolute)


def parse_iso_date(date_str: str) -> str | None:
    """Attempts to parse varied human-readable date strings into ISO-8601 (YYYY-MM-DD)."""
    if not date_str:
        return None
    cleaned = clean_text(date_str)
    formats = [
        "%Y-%m-%d",
        "%Y-%m-%dT%H:%M:%S%z",
        "%d/%m/%Y",
        "%m/%d/%Y",
        "%B %d, %Y",
        "%b %d, %Y",
        "%d %B %Y",
    ]
    for fmt in formats:
        try:
            return datetime.strptime(cleaned, fmt).date().isoformat()
        except ValueError:
            continue
    return cleaned
```

---

### Node.js Normalizer (`normalizer.js`)

```javascript
const { URL } = require("url");

function cleanText(text) {
  if (!text) return "";
  return String(text)
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/\s+/g, " ")
    .trim();
}

function parsePrice(priceStr) {
  if (!priceStr) return null;
  let cleaned = String(priceStr).replace(/[^\d.,]/g, "").trim();
  if (!cleaned) return null;

  if (cleaned.includes(",") && cleaned.includes(".")) {
    if (cleaned.lastIndexOf(",") > cleaned.lastIndexOf(".")) {
      cleaned = cleaned.replace(/\./g, "").replace(",", ".");
    } else {
      cleaned = cleaned.replace(/,/g, "");
    }
  } else if (cleaned.includes(",") && !cleaned.includes(".")) {
    cleaned = cleaned.replace(",", ".");
  }

  const num = parseFloat(cleaned);
  return isNaN(num) ? null : num;
}

function resolveUrl(relativeOrAbsolute, baseUrl) {
  if (!relativeOrAbsolute) return "";
  const trimmed = String(relativeOrAbsolute).trim();
  if (trimmed.startsWith("//")) return `https:${trimmed}`;
  try {
    return new URL(trimmed, baseUrl).href;
  } catch (_) {
    return trimmed;
  }
}

module.exports = { cleanText, parsePrice, resolveUrl };
```

---

## Schema Enforcement Patterns

### Python Pydantic Model Pattern

```python
from pydantic import BaseModel, Field, field_validator


class ProductRecord(BaseModel):
    id: str
    title: str
    url: str
    price: float | None = None
    currency: str = "USD"
    in_stock: bool = True
    images: list[str] = Field(default_factory=list)

    @field_validator("title", mode="before")
    def sanitize_title(cls, v):
        return clean_text(v)

    @field_validator("price", mode="before")
    def sanitize_price(cls, v):
        if isinstance(v, (int, float)):
            return float(v)
        return parse_price(v)
```

---

## Export Format Specifications

Every ScrapeCraft scraper must support structured output to stdout or file:

| Format | Option Flag | Implementation |
|---|---|---|
| **JSON Array** (Default) | `--format json` | `json.dumps(records, indent=2, ensure_ascii=False)` |
| **NDJSON / JSON Lines** | `--format jsonl` | Stream one JSON object per line (`sys.stdout.write(json.dumps(r) + "\n")`) |
| **CSV** | `--format csv` | `csv.DictWriter` with UTF-8 BOM and explicit quoting |
