# Anti-Detection Strategies

This document covers techniques for scraping sites protected by anti-bot systems (Cloudflare, Akamai, DataDome, PerimeterX, reCAPTCHA).

## Detection Signals & Countermeasures

### 1. HTTP-Level Fingerprinting

| Signal | Detection Method | Countermeasure |
|---|---|---|
| User-Agent | Missing or bot-like UA string | Use current Chrome UA: `Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36` |
| Headers order | Non-browser header ordering | Send headers in browser-canonical order: `Host`, `Connection`, `User-Agent`, `Accept`, etc. |
| TLS fingerprint | JA3/JA4 hash mismatch | Use `curl_cffi` (Python) or `got-scraping` (Node.js) for browser-like TLS |
| Missing headers | No `Accept-Language`, `Accept-Encoding` | Always include full header set |

### 2. JavaScript-Level Fingerprinting

| Signal | Detection Method | Countermeasure |
|---|---|---|
| `navigator.webdriver` | Set to `true` in automation | Playwright: `--disable-blink-features=AutomationControlled` |
| Missing plugins | `navigator.plugins` is empty array | Use stealth plugins (`playwright-extra` + `stealth`) |
| Canvas fingerprint | Inconsistent canvas rendering | Use `playwright-extra` stealth plugin |
| WebGL renderer | Headless returns `SwiftShader` | Configure Playwright to use GPU rendering |

### 3. Behavioral Fingerprinting

| Signal | Detection Method | Countermeasure |
|---|---|---|
| Request speed | Sub-human page load intervals | Add random delays: `1.5 + random() * 2` seconds |
| No mouse/keyboard | Zero input events | Inject `page.mouse.move()` with random paths |
| Linear navigation | Accessing deep pages without visiting parent | Navigate naturally: homepage -> listing -> detail |

## Implementation Patterns

### Python: Stealth Playwright

```python
#!/usr/bin/env python3
import json
import sys
import random
import asyncio
from playwright.async_api import async_playwright


async def scrape_stealth(url):
    async with async_playwright() as p:
        browser = await p.chromium.launch(
            headless=True,
            args=[
                "--disable-blink-features=AutomationControlled",
                "--disable-dev-shm-usage",
                "--no-sandbox",
            ],
        )
        context = await browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
            viewport={"width": 1920, "height": 1080},
            locale="en-US",
            timezone_id="America/New_York",
        )

        await context.add_init_script("""
            Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
            Object.defineProperty(navigator, 'plugins', { get: () => [1, 2, 3, 4, 5] });
            Object.defineProperty(navigator, 'languages', { get: () => ['en-US', 'en'] });
            window.chrome = { runtime: {} };
        """)

        page = await context.new_page()
        await page.goto(url, wait_until="networkidle", timeout=30000)
        await page.wait_for_timeout(random.randint(1000, 3000))

        content = await page.content()
        await browser.close()
        return content


def main():
    url = "TARGET_URL"
    html = asyncio.run(scrape_stealth(url))
    print(html[:500])


if __name__ == "__main__":
    main()
```

### Python: HTTP with TLS Fingerprint (curl_cffi)

```python
#!/usr/bin/env python3
import json
import sys
from curl_cffi import requests as cffi_requests

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
    "Accept-Encoding": "gzip, deflate, br",
}


def scrape(url):
    response = cffi_requests.get(
        url,
        headers=HEADERS,
        impersonate="chrome131",
        timeout=30,
    )
    if response.status_code != 200:
        print(f"HTTP {response.status_code}", file=sys.stderr)
        sys.exit(1)
    return response.text


def main():
    url = "TARGET_URL"
    html = scrape(url)
    print(html[:500])


if __name__ == "__main__":
    main()
```

### Node.js: Stealth Playwright

```javascript
#!/usr/bin/env node
const { chromium } = require("playwright");

async function scrape(url) {
  const browser = await chromium.launch({
    headless: true,
    args: [
      "--disable-blink-features=AutomationControlled",
      "--disable-dev-shm-usage",
      "--no-sandbox",
    ],
  });

  const context = await browser.newContext({
    userAgent:
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
    viewport: { width: 1920, height: 1080 },
    locale: "en-US",
    timezoneId: "America/New_York",
  });

  await context.addInitScript(() => {
    Object.defineProperty(navigator, "webdriver", { get: () => undefined });
    Object.defineProperty(navigator, "plugins", {
      get: () => [1, 2, 3, 4, 5],
    });
    window.chrome = { runtime: {} };
  });

  const page = await context.newPage();
  await page.goto(url, { waitUntil: "networkidle", timeout: 30000 });
  await page.waitForTimeout(1000 + Math.random() * 2000);

  const content = await page.content();
  await browser.close();
  return content;
}

async function main() {
  const url = "TARGET_URL";
  const html = await scrape(url);
  console.log(html.substring(0, 500));
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
```

## Decision Tree: Which Anti-Detection Method?

```
Is the site protected?
├── No → Use standard httpx/axios
├── Cloudflare (JS challenge only)
│   ├── Try curl_cffi with impersonate first
│   └── If blocked → Stealth Playwright
├── Cloudflare (Turnstile CAPTCHA)
│   ├── Stealth Playwright + manual wait for challenge
│   └── Report to user if unsolvable
├── DataDome / PerimeterX
│   ├── curl_cffi with impersonate
│   └── If blocked → Stealth Playwright with init scripts
└── Rate limiting (429)
    ├── Add delays (1.5-3s between requests)
    ├── Rotate User-Agent per request
    └── If persistent → Report to user, suggest proxy rotation
```

## Important Notes

- Proxy rotation is beyond MVP scope. If needed, instruct the user to provide proxy configuration.
- Never attempt to solve CAPTCHAs automatically. Report to the user and suggest alternative approaches.
- Always respect `robots.txt` where applicable and note when a site explicitly forbids scraping.
- If a site requires authentication, ask the user for credentials. Never attempt to bypass login systems.
