# Proxy Rotation & Gateway Pools

When scraping enterprise volumes (10,000+ pages), rotating residential and datacenter proxies prevents IP-based rate limiting, geo-blocking, and CAPTCHA escalation.

---

## 1. Proxy Pool Architecture

```
Scraper Request ──► Proxy Gateway Pool ──► [Residential IP Rotator] ──► Target Website
                          │
                          ├─► Sticky Session (same IP for 10 minutes)
                          └─► Rotating Session (new IP per request)
```

---

## 2. Python Proxy Integration (httpx & curl_cffi)

```python
import httpx

# Format: http://username:password@proxy.provider.com:port
PROXIES = {
    "http://": "http://user_session-rand123:pass@residential-proxy.net:8080",
    "https://": "http://user_session-rand123:pass@residential-proxy.net:8080",
}

with httpx.Client(proxies=PROXIES, timeout=30) as client:
    response = client.get("https://httpbin.org/ip")
    print(response.json())
```

### Playwright Proxy Configuration

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(
        headless=True,
        proxy={
            "server": "http://residential-proxy.net:8080",
            "username": "user_session-123",
            "password": "SecretPassword",
        },
    )
    page = browser.new_page()
    page.goto("https://target.com")
    browser.close()
```

---

## 3. Backoff & Automatic Proxy Rotation Logic

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
