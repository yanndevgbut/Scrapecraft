# Domain: Social Media & Forum Scraping

Social media platforms (X/Twitter, Reddit, Instagram, TikTok, YouTube, Threads, Mastodon) rely heavily on infinite-scrolling feeds, dynamic API hydration, virtualized DOM lists, and nested conversation trees.

---

## Core Data Schema

| Field | Type | Description |
|---|---|---|
| `post_id` | `str` | Platform-specific post/tweet/thread ID |
| `author` | `dict` | Author object (`username`, `display_name`, `avatar_url`, `is_verified`) |
| `content` | `str` | Full text payload with clean line breaks |
| `published_at` | `str` | ISO-8601 formatted publication timestamp |
| `metrics` | `dict` | Engagement metrics (`likes`, `reposts`, `replies`, `views`) |
| `media` | `list[dict]` | Attached media objects (`type: image|video`, `url`, `thumbnail`) |
| `url` | `str` | Direct permalink to the post |
| `reply_to_id` | `str | null` | Parent post ID if item is part of a reply thread |

---

## Strategy 1: Reddit JSON API Extraction (No Auth Required)

Reddit exposes clean JSON endpoints by appending `.json` to standard community and post URLs:

```python
#!/usr/bin/env python3
import json
import sys
import time
from datetime import datetime, timezone
import httpx

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36 ScrapeCraft/2.0",
}


def scrape_subreddit(subreddit: str, sort: str = "hot", limit: int = 50) -> list[dict]:
    url = f"https://www.reddit.com/r/{subreddit}/{sort}.json?limit={limit}"
    posts = []

    with httpx.Client(headers=HEADERS, timeout=30, follow_redirects=True) as client:
        response = client.get(url)
        if response.status_code != 200:
            print(f"HTTP {response.status_code}: {url}", file=sys.stderr)
            return []

        data = response.json()
        children = data.get("data", {}).get("children", [])

        for child in children:
            p = child.get("data", {})
            created_utc = p.get("created_utc")
            iso_date = datetime.fromtimestamp(created_utc, timezone.utc).isoformat() if created_utc else None

            posts.append({
                "post_id": p.get("id"),
                "title": p.get("title", "").strip(),
                "author": p.get("author"),
                "content": p.get("selftext", "").strip(),
                "published_at": iso_date,
                "metrics": {
                    "score": p.get("score", 0),
                    "upvote_ratio": p.get("upvote_ratio", 0.0),
                    "num_comments": p.get("num_comments", 0),
                },
                "url": f"https://reddit.com{p.get('permalink')}",
            })

    return posts
```

---

## Strategy 2: Infinite Scroll & Virtual DOM Feed Scraping

Modern platforms virtualize feeds (unmounting DOM elements outside the active viewport). To scrape all items without losing unmounted nodes, accumulate items into an in-memory dictionary keyed by `post_id`:

```python
import time
from playwright.sync_api import sync_playwright


def scrape_infinite_feed(url: str, target_count: int = 100) -> list[dict]:
    captured = {}

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        page.goto(url, wait_until="networkidle", timeout=30000)

        consecutive_zero_growth = 0
        while len(captured) < target_count and consecutive_zero_growth < 5:
            current_len = len(captured)

            # Query visible post cards
            cards = page.query_selector_all("article, [data-testid='post-card']")
            for card in cards:
                post_id = card.get_attribute("data-post-id") or card.get_attribute("id")
                if not post_id or post_id in captured:
                    continue

                text_el = card.query_selector("[data-testid='post-text'], .content")
                author_el = card.query_selector("[data-testid='author-name'], .author")

                captured[post_id] = {
                    "post_id": post_id,
                    "author": author_el.inner_text().strip() if author_el else "",
                    "content": text_el.inner_text().strip() if text_el else "",
                }

            # Scroll down to trigger next virtualization batch
            page.evaluate("window.scrollBy(0, window.innerHeight * 1.5);")
            page.wait_for_timeout(1200)

            if len(captured) == current_len:
                consecutive_zero_growth += 1
            else:
                consecutive_zero_growth = 0

        browser.close()

    return list(captured.values())
```

---

## Strategy 3: YouTube Metadata & Comment Tree Sniffing

YouTube delivers video details and initial comments via `window["ytInitialData"]`:

```python
import json
import re


def extract_youtube_initial_data(html: str) -> dict:
    match = re.search(r"var\s+ytInitialData\s*=\s*({.*?});</script>", html, re.DOTALL)
    if not match:
        match = re.search(r"ytInitialData\s*=\s*({.*?});", html, re.DOTALL)
    if match:
        try:
            return json.loads(match.group(1))
        except json.JSONDecodeError:
            pass
    return {}
```
