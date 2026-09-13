# Internal API Sniffing & Reverse Engineering

Over 90% of dynamic, JS-heavy web applications (React, Vue, Angular, Next.js, Svelte) load data via internal REST or GraphQL API endpoints. Scraping the internal API directly is **100x more efficient** than automating a browser, consumes **95% less RAM/CPU**, and produces perfectly typed, clean JSON datasets.

---

## Inspection & Discovery Procedure

### Step 1: Record Network Traffic During Inspection

Use Playwright to capture all JSON network responses during page load:

```python
import json
from playwright.sync_api import sync_playwright

discovered_endpoints = []


def on_response(response):
    content_type = response.headers.get("content-type", "")
    if "application/json" in content_type and response.status == 200:
        if any(keyword in response.url for keyword in ["api", "graphql", "v1", "v2", "v3", "query", "data", "list"]):
            try:
                data = response.json()
                discovered_endpoints.append({
                    "url": response.url,
                    "method": response.request.method,
                    "headers": dict(response.request.headers),
                    "post_data": response.request.post_data,
                    "sample_keys": list(data.keys()) if isinstance(data, dict) else f"list({len(data)})",
                })
            except Exception:
                pass


with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.on("response", on_response)
    page.goto("TARGET_URL", wait_until="networkidle", timeout=30000)
    browser.close()

print(json.dumps(discovered_endpoints, indent=2))
```

---

## Step 2: Reverse-Engineer Headers & Auth

Internal APIs usually require a subset of browser headers. Test with minimal headers:

### Critical Headers Checklist

| Header | Required? | Purpose |
|---|---|---|
| `User-Agent` | Always | Matches browser identity |
| `Accept` | Always | `application/json, text/plain, */*` |
| `Referer` | Often | Target site origin URL |
| `Origin` | Often for POST/GraphQL | `https://targetsite.com` |
| `Authorization` | Sometimes | Bearer token (often found in HTML/cookies/localStorage) |
| `X-CSRF-Token` / `X-API-Key` | Sometimes | Extracted from HTML `<meta>` or cookie jar |

---

## Step 3: Production API Scraper Template (Python)

```python
#!/usr/bin/env python3
import json
import sys
import time
import httpx

API_ENDPOINT = "https://api.targetsite.com/v1/items"
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
    "Accept": "application/json, text/plain, */*",
    "Accept-Language": "en-US,en;q=0.9",
    "Referer": "https://targetsite.com/catalog",
    "Origin": "https://targetsite.com",
}


def fetch_api_page(client: httpx.Client, page: int = 1, page_size: int = 50) -> list:
    params = {
        "page": page,
        "limit": page_size,
        "sort": "date_desc",
    }
    response = client.get(API_ENDPOINT, headers=HEADERS, params=params, timeout=30)
    if response.status_code != 200:
        print(f"API Error HTTP {response.status_code}: {response.text}", file=sys.stderr)
        return []

    data = response.json()
    items = data.get("items", data.get("results", data.get("data", [])))
    return items


def main():
    all_records = []
    max_pages = 5
    delay_between_requests = 1.0

    with httpx.Client() as client:
        for page_num in range(1, max_pages + 1):
            print(f"Fetching API page {page_num}...", file=sys.stderr)
            items = fetch_api_page(client, page=page_num)
            if not items:
                break
            all_records.extend(items)
            time.sleep(delay_between_requests)

    print(json.dumps(all_records, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
```

---

## Step 4: GraphQL Endpoint Extraction

For GraphQL-backed APIs:

```python
import httpx

GRAPHQL_ENDPOINT = "https://targetsite.com/graphql"

QUERY = """
query GetProducts($first: Int!, $after: String) {
  products(first: $first, after: $after) {
    pageInfo {
      hasNextPage
      endCursor
    }
    edges {
      node {
        id
        title
        priceRange {
          minVariantPrice {
            amount
            currencyCode
          }
        }
      }
    }
  }
}
"""


def fetch_graphql(client: httpx.Client, cursor: str = None) -> dict:
    payload = {
        "query": QUERY,
        "variables": {"first": 50, "after": cursor},
    }
    response = client.post(GRAPHQL_ENDPOINT, json=payload, timeout=30)
    return response.json()
```
