# GraphQL API Scraping

GraphQL endpoints consolidate data querying into single POST requests (`/graphql`). Scraping GraphQL is vastly cleaner and more reliable than HTML scraping because it directly returns typed JSON payloads.

---

## 1. Discovering GraphQL Endpoints & Operations

During live inspection (via Playwright or browser network panel), filter network traffic for:
- URL containing `/graphql` or `/api/graphql`
- POST requests with JSON payload containing `"query"` or `"operationName"`

### Capturing Schema & Query with Playwright

```python
import json
from playwright.sync_api import sync_playwright

captured_operations = []


def on_request(request):
    if "/graphql" in request.url and request.method == "POST":
        try:
            payload = json.loads(request.post_data)
            captured_operations.append({
                "url": request.url,
                "operationName": payload.get("operationName"),
                "query": payload.get("query"),
                "variables": payload.get("variables"),
                "headers": dict(request.headers),
            })
        except Exception:
            pass


with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.on("request", on_request)
    page.goto("TARGET_URL", wait_until="networkidle")
    browser.close()

print(json.dumps(captured_operations, indent=2))
```

---

## 2. Production Python GraphQL Scraper Template

```python
#!/usr/bin/env python3
import json
import sys
import time
import httpx

GRAPHQL_URL = "https://target-site.com/graphql"

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
    "Content-Type": "application/json",
    "Accept": "application/json",
    "Origin": "https://target-site.com",
    "Referer": "https://target-site.com/search",
}

QUERY = """
query SearchItems($query: String!, $cursor: String, $limit: Int!) {
  search(query: $query, after: $cursor, first: $limit) {
    pageInfo {
      hasNextPage
      endCursor
    }
    totalCount
    edges {
      node {
        id
        title
        price {
          amount
          currency
        }
        publishedAt
        url
      }
    }
  }
}
"""


def fetch_graphql_page(client: httpx.Client, query_term: str, cursor: str = None, limit: int = 50) -> dict:
    payload = {
        "operationName": "SearchItems",
        "query": QUERY,
        "variables": {
            "query": query_term,
            "cursor": cursor,
            "limit": limit,
        },
    }

    response = client.post(GRAPHQL_URL, headers=HEADERS, json=payload, timeout=30)
    if response.status_code != 200:
        print(f"GraphQL HTTP {response.status_code}: {response.text}", file=sys.stderr)
        return {}

    data = response.json()
    if "errors" in data:
        print(f"GraphQL Execution Errors: {data['errors']}", file=sys.stderr)
        return {}

    return data.get("data", {}).get("search", {})


def scrape_all_items(query_term: str, max_items: int = 200) -> list[dict]:
    all_results = []
    cursor = None
    has_next = True

    with httpx.Client() as client:
        while has_next and len(all_results) < max_items:
            data = fetch_graphql_page(client, query_term, cursor=cursor, limit=50)
            if not data:
                break

            edges = data.get("edges", [])
            for edge in edges:
                node = edge.get("node", {})
                all_results.append(node)

            page_info = data.get("pageInfo", {})
            has_next = page_info.get("hasNextPage", False)
            cursor = page_info.get("endCursor")

            print(f"Fetched {len(all_results)} items...", file=sys.stderr)
            time.sleep(1.0)

    return all_results
```
