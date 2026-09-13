# Advanced Playwright Deep-Dive & Optimization

Playwright is the premier engine for modern Single-Page Applications (SPAs). Optimizing Playwright scripts reduces bandwidth consumption by **80%**, accelerates page loads by **4x**, and ensures deterministic wait synchronization.

---

## 1. Network Route Aborting (Block Images, Fonts & CSS)

Block unnecessary network assets to speed up extraction and save proxy bandwidth:

```python
from playwright.sync_api import sync_playwright

BLOCKED_RESOURCE_TYPES = ["image", "media", "font", "stylesheet"]
BLOCKED_DOMAINS = ["google-analytics.com", "doubleclick.net", "facebook.net", "hotjar.com"]


def intercept_route(route):
    req = route.request
    if req.resource_type in BLOCKED_RESOURCE_TYPES:
        route.abort()
    elif any(domain in req.url for domain in BLOCKED_DOMAINS):
        route.abort()
    else:
        route.continue_()


with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.route("**/*", intercept_route)

    page.goto("https://heavy-spa-site.com", wait_until="domcontentloaded")
    # Data is extracted without downloading MBs of images and video assets
    browser.close()
```

---

## 2. Deterministic Wait Strategies (No Arbitrary `time.sleep()`)

Avoid brittle `time.sleep(5)`. Use Playwright's built-in predicate waits:

```python
# 1. Wait for specific selector visibility
page.wait_for_selector("div.product-grid", state="visible", timeout=15000)

# 2. Wait for network requests to settle
page.wait_for_load_state("networkidle")

# 3. Wait for specific JSON API response
with page.expect_response(lambda r: "/api/products" in r.url and r.status == 200) as response_info:
    page.click("button#filter-apply")
response = response_info.value
data = response.json()

# 4. Wait for custom JavaScript condition
page.wait_for_function("() => window.__DATA_LOADED__ === true")
```

---

## 3. Chrome DevTools Protocol (CDP) Direct Commands

```python
# Open low-level CDP session
client = page.context.new_cdp_session(page)

# Set custom geolocation and network emulation
client.send("Emulation.setGeolocationOverride", {
    "latitude": 37.7749,
    "longitude": -122.4194,
    "accuracy": 100,
})

# Clear browser cache and cookies on demand
client.send("Network.clearBrowserCookies")
client.send("Network.clearBrowserCache")
```
