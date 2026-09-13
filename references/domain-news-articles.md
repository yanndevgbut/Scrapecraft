# Domain: News, Articles & Content Scraping

News outlets and editorial platforms (NYTimes, BBC, Medium, Substack, TechCrunch, Bloomberg, WordPress blogs) require accurate extraction of full body text while filtering out advertisements, newsletter popups, related article embeds, and social sharing widgets.

---

## Core Data Schema

| Field | Type | Description |
|---|---|---|
| `article_id` | `str` | URL slug or CMS article ID |
| `headline` | `str` | Main article title |
| `subtitle` | `str | null` | Subheading or dek |
| `author` | `list[str]` | Authors and byline credits |
| `published_at` | `str` | ISO-8601 publication timestamp |
| `modified_at` | `str | null` | ISO-8601 last update timestamp |
| `section` | `str | null` | Topic or category (e.g., Technology, Politics) |
| `body_text` | `str` | Clean, continuous article paragraphs |
| `body_html` | `str | null` | Sanitized semantic HTML body |
| `lead_image` | `dict | null` | Lead photo object (`url`, `caption`, `credit`) |
| `canonical_url`| `str` | Official canonical URL |

---

## Strategy 1: NewsArticle Schema.org Extraction

Editorial publications universally implement Google News compliant `NewsArticle` schema:

```python
import json
from parsel import Selector


def extract_news_schema(html: str) -> dict:
    sel = Selector(text=html)
    scripts = sel.css('script[type="application/ld+json"]::text').getall()

    for raw in scripts:
        try:
            data = json.loads(raw)
            items = data if isinstance(data, list) else [data]
            for item in items:
                if item.get("@type") in ["NewsArticle", "Article", "BlogPosting", "TechArticle"]:
                    # Extract authors
                    author_raw = item.get("author", [])
                    if isinstance(author_raw, dict):
                        authors = [author_raw.get("name", "")]
                    elif isinstance(author_raw, list):
                        authors = [a.get("name", "") if isinstance(a, dict) else str(a) for a in author_raw]
                    else:
                        authors = [str(author_raw)]

                    # Extract lead image
                    img_data = item.get("image", [])
                    lead_img = None
                    if isinstance(img_data, list) and img_data:
                        lead_img = img_data[0].get("url") if isinstance(img_data[0], dict) else str(img_data[0])
                    elif isinstance(img_data, dict):
                        lead_img = img_data.get("url")
                    elif isinstance(img_data, str):
                        lead_img = img_data

                    return {
                        "headline": item.get("headline", "").strip(),
                        "description": item.get("description", "").strip(),
                        "authors": [a.strip() for a in authors if a.strip()],
                        "published_at": item.get("datePublished"),
                        "modified_at": item.get("dateModified"),
                        "section": item.get("articleSection"),
                        "lead_image": lead_img,
                        "body_text": item.get("articleBody", "").strip(),
                    }
        except json.JSONDecodeError:
            continue
    return {}
```

---

## Strategy 2: Clean DOM Article Body Extraction

When Schema markup does not contain the full `articleBody`, extract paragraphs from the semantic `<article>` container while stripping extraneous elements:

```python
import re
from parsel import Selector


def extract_clean_article_body(html: str) -> str:
    sel = Selector(text=html)

    # Priority article container selectors
    container = sel.css("article, [itemprop='articleBody'], .article-content, .post-content, main")
    if not container:
        container = sel

    # Select all paragraph elements inside the container
    paragraphs = container.css("p::text").getall()

    cleaned_paragraphs = []
    for p in paragraphs:
        text = re.sub(r"\s+", " ", p).strip()
        # Filter out short disclaimers, cookie notices, and ads
        if len(text) > 25 and not any(skip in text.lower() for skip in ["subscribe", "sign up", "read more:", "all rights reserved"]):
            cleaned_paragraphs.append(text)

    return "\n\n".join(cleaned_paragraphs)
```
