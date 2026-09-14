# Proxy Rotation, Gateway Pools & Auto-Discovery

When scraping enterprise volumes (10,000+ pages) or navigating IP-restricted targets, rotating residential proxies or auto-discovering live SOCKS5/HTTP proxies prevents rate limiting (HTTP 429), regional geo-blocking, and WAF escalation.

---

## 1. Proxy Pool Architecture

```
Scraper Request ──► Proxy Dispatcher
                          │
                          ├─► Option A: Commercial Residential Pool (Sticky/Rotating Gateway)
                          │
                          └─► Option B: Auto Free Proxy Engine (60 Endpoints Aggregator)
                                          │
                                          ▼
                               [Async Live Health-Check]
                                          │
                                          ▼
                               [Verified Active Proxies] ──► Target Website
```

---

## 2. Option A: Custom / Commercial Proxy Configuration

ScrapeCraft scrapers accept proxy configurations via CLI arguments (`--proxy`) or environment variables (`SCRAPER_PROXY`):

```python
import argparse
import os
import httpx

parser = argparse.ArgumentParser()
parser.add_argument("--proxy", default=os.getenv("SCRAPER_PROXY"), help="Proxy URL (http://user:pass@host:port or socks5://host:port)")
args = parser.parse_args()

proxies = {"http://": args.proxy, "https://": args.proxy} if args.proxy else None

with httpx.Client(proxies=proxies, timeout=30) as client:
    response = client.get("https://target.com/catalog")
```

### Playwright Proxy Configuration

```python
from urllib.parse import urlsplit
from playwright.sync_api import sync_playwright

def get_playwright_proxy_config(proxy_url: str) -> dict | None:
    if not proxy_url:
        return None
    parsed = urlsplit(proxy_url)
    config = {"server": f"{parsed.scheme}://{parsed.hostname}:{parsed.port}"}
    if parsed.username:
        config["username"] = parsed.username
        config["password"] = parsed.password
    return config

with sync_playwright() as p:
    proxy_cfg = get_playwright_proxy_config(args.proxy)
    browser = p.chromium.launch(headless=True, proxy=proxy_cfg)
    page = browser.new_page()
    page.goto("https://target.com")
```

---

## 3. Option B: Built-in 60-Source Auto Proxy Engine

When no commercial proxy is supplied and the target blocks standard requests, use the integrated **Free Proxy Aggregator & Health-Check Engine** (see `references/free-proxy-engine.md`).

Scrapers can invoke the health checker directly from `scripts/proxy-checker.py` or embed the async probe:

```python
import subprocess
import json

def get_live_proxies_from_engine(limit: int = 5, protocol: str = "socks5") -> list[str]:
    cmd = [
        "python3", "scripts/proxy-checker.py",
        "--protocol", protocol,
        "--limit", str(limit),
        "--format", "uris"
    ]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
        if proc.returncode == 0:
            return [line.strip() for line in proc.stdout.splitlines() if line.strip()]
    except Exception:
        pass
    return []
```

---

## 4. Backoff & Automatic Proxy Rotation Logic

```python
import random
import time
import httpx


def fetch_with_retry_and_proxy_rotation(url: str, proxy_list: list[str], max_retries: int = 3) -> httpx.Response | None:
    for attempt in range(1, max_retries + 1):
        selected_proxy = random.choice(proxy_list) if proxy_list else None
        proxies = {"http://": selected_proxy, "https://": selected_proxy} if selected_proxy else None

        try:
            with httpx.Client(proxies=proxies, timeout=20) as client:
                resp = client.get(url)
                if resp.status_code == 200:
                    return resp
                elif resp.status_code in [403, 429, 503]:
                    # Exponential backoff with jitter
                    backoff = (2 ** attempt) + random.uniform(0.5, 1.5)
                    time.sleep(backoff)
        except Exception:
            time.sleep(1.0)
    return None
```
