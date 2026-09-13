# Domain: Business Directories & Lead Generation

Business directories and registries (Google Maps, Yelp, YellowPages, Crunchbase, Kompass, D&B Hoovers) contain commercial lead information: company names, phone numbers, verified emails, operating hours, and social profiles.

---

## Core Data Schema

| Field | Type | Description |
|---|---|---|
| `business_id` | `str` | Directory identifier |
| `name` | `str` | Official registered business name |
| `category` | `str` | Primary industry or commercial category |
| `phone` | `str | null` | Normalized E.164 phone number |
| `email` | `str | null` | Extracted corporate contact email |
| `website` | `str | null` | Official company website URL |
| `address` | `dict` | Structured street address, city, state, zip code |
| `rating` | `float | null` | Directory review score |
| `review_count` | `int | null` | Total review count |
| `social_links` | `dict` | Social profiles (`linkedin`, `twitter`, `facebook`, `instagram`) |
| `url` | `str` | Directory listing URL |

---

## Strategy 1: Contact Detail Sanitization & Parsing

Scraped directory text often conceals emails and obfuscated phone numbers:

```python
import re


def extract_emails(text: str) -> list[str]:
    pattern = r"[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+"
    matches = re.findall(pattern, text)
    valid_emails = [
        m.lower()
        for m in matches
        if not m.endswith((".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg"))
    ]
    return list(set(valid_emails))


def normalize_phone_number(phone_str: str) -> str | None:
    if not phone_str:
        return None
    digits = re.sub(r"[^\d+]", "", phone_str)
    if len(digits) < 7:
        return None
    return digits


def extract_social_links(html: str) -> dict:
    socials = {}
    patterns = {
        "linkedin": r"https?://(?:www\.)?linkedin\.com/(?:company|in)/[a-zA-Z0-9_-]+",
        "twitter": r"https?://(?:www\.)?(?:twitter|x)\.com/[a-zA-Z0-9_]+",
        "facebook": r"https?://(?:www\.)?facebook\.com/[a-zA-Z0-9_.-]+",
        "instagram": r"https?://(?:www\.)?instagram\.com/[a-zA-Z0-9_.]+",
    }
    for platform, pat in patterns.items():
        match = re.search(pat, html)
        if match:
            socials[platform] = match.group(0)
    return socials
```

---

## Strategy 2: LocalBusiness Schema.org Extraction

```python
import json
from parsel import Selector


def extract_local_business_schema(html: str) -> dict:
    sel = Selector(text=html)
    scripts = sel.css('script[type="application/ld+json"]::text').getall()

    for raw in scripts:
        try:
            data = json.loads(raw)
            if "Business" in data.get("@type", "") or data.get("@type") in ["Store", "Restaurant", "Organization"]:
                addr = data.get("address", {})
                return {
                    "name": data.get("name"),
                    "category": data.get("@type"),
                    "phone": normalize_phone_number(data.get("telephone")),
                    "email": data.get("email"),
                    "website": data.get("url"),
                    "rating": float(data.get("aggregateRating", {}).get("ratingValue", 0)) or None,
                    "review_count": int(data.get("aggregateRating", {}).get("reviewCount", 0)) or None,
                    "address": {
                        "street": addr.get("streetAddress") if isinstance(addr, dict) else str(addr),
                        "city": addr.get("addressLocality") if isinstance(addr, dict) else "",
                        "state": addr.get("addressRegion") if isinstance(addr, dict) else "",
                        "zip": addr.get("postalCode") if isinstance(addr, dict) else "",
                    },
                }
        except json.JSONDecodeError:
            continue
    return {}
```
