# Performance Benchmarks & Token Optimization

High-performance scraping requires minimizing CPU overhead, reducing memory footprint, and optimizing network bandwidth.

---

## 1. Performance Comparison Matrix

| Approach | Memory per Worker | Network Bandwidth | Latency per Page | Stability |
|---|---|---|---|---|
| **Direct State Extraction (`__NEXT_DATA__`)** | **~15 MB** | **~50 KB** | **0.1s - 0.3s** | **100% (Immune to DOM drift)** |
| **Internal REST/GraphQL API** | **~18 MB** | **~20 KB** | **0.1s - 0.4s** | **98% (Clean typed JSON)** |
| **Lightweight HTML Parser (`httpx` + `parsel`)** | **~35 MB** | **~150 KB** | **0.4s - 0.8s** | **92% (Multi-tier fallbacks)** |
| **Ultra-Fast C-Parser (`selectolax`)** | **~22 MB** | **~150 KB** | **0.2s - 0.5s** | **92% (High CPU efficiency)** |
| **Optimized Playwright (Route Aborted)** | **~120 MB** | **~300 KB** | **1.2s - 2.5s** | **88% (Dynamic SPAs)** |
| **Naive Browser Automation (Full Assets)** | ~450 MB | ~3.5 MB | 4.5s - 8.0s | 75% (Fragile timeouts) |

---

## 2. Bandwidth & Resource Optimization Rules

### Rule 1: Route Aborting Saves 80% Network Load
In Playwright or Puppeteer, always abort non-essential assets:

```python
BLOCKED_RESOURCES = {"image", "media", "font", "stylesheet"}

def block_assets(route):
    if route.request.resource_type in BLOCKED_RESOURCES:
        route.abort()
    else:
        route.continue_()

page.route("**/*", block_assets)
```

### Rule 2: Stream Massive Datasets with NDJSON (JSON Lines)
For scraping >5,000 records, avoid holding full arrays in RAM:

```python
import json
import sys

def stream_record(record: dict):
    # Stream one record per line immediately to stdout
    sys.stdout.write(json.dumps(record, ensure_ascii=False) + "\n")
    sys.stdout.flush()
```

### Rule 3: Use HTTP/2 Connection Pooling
Reusing TCP sockets avoids repeated SSL handshake latency (150ms saved per request):

```python
import httpx

limits = httpx.Limits(max_keepalive_connections=20, max_connections=50)
with httpx.Client(http2=True, limits=limits) as client:
    # TCP connection is multiplexed across all requests
    pass
```
