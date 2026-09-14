# Anti-Blocking Pre-Flight Checklist

Before deploying scraping code at production scale, the **Stealth & Evasion Engineer** validates the implementation against this 10-Point Pre-Flight Security Audit.

---

## The 10-Point Pre-Flight Security Audit

```
┌─────┬───────────────────────────┬─────────────────────────────────────────────────────────┐
│ No. │ Security Check            │ Verification Criteria                                   │
├─────┼───────────────────────────┼─────────────────────────────────────────────────────────┤
│ 01  │ TLS Fingerprint (JA3/JA4) │ Uses curl_cffi or browser-grade TLS handshakes          │
│ 02  │ HTTP Header Ordering      │ Host -> User-Agent -> Accept -> Accept-Language -> ... │
│ 03  │ Realistic User-Agent      │ Matches current Chrome/Edge release (e.g. Chrome 131)   │
│ 04  │ Client Hints (Sec-CH-UA)  │ Sec-Ch-Ua, Sec-Ch-Ua-Platform, Sec-Fetch-Dest included  │
│ 05  │ Navigator Masking         │ navigator.webdriver stripped, plugins array populated   │
│ 06  │ Randomized Jitter Delay   │ Delays between requests randomized (1.5s - 3.5s)        │
│ 07  │ Explicit Request Timeouts │ 25-30s timeout per HTTP request, 45s per browser action │
│ 08  │ Error Status Handlers     │ Exponential backoff on HTTP 429, 503, 403 responses     │
│ 09  │ Resource Filtering        │ Images, fonts, and stylesheets blocked in headless runs │
│ 10  │ IP / Session Isolation    │ Sticky sessions for auth; rotating IPs for mass crawls  │
└─────┴───────────────────────────┴─────────────────────────────────────────────────────────┘
```

---

## Security Level Determination Matrix

```
Is the Target Protected?
├── Level 1: Open / Unprotected
│   └── Architecture: Standard httpx / axios with realistic User-Agent and jitter delays
├── Level 2: Rate-Limited (HTTP 429)
│   └── Architecture: Token bucket rate limiter, exponential backoff, User-Agent rotation
├── Level 3: Cloudflare / WAF Protected (JS Challenges)
│   └── Architecture: curl_cffi (impersonate='chrome131') + full header set
├── Level 4: Cloudflare Turnstile / Advanced CAPTCHA
│   └── Architecture: Playwright with Stealth plugins + dynamic wait for challenge resolution
└── Level 5: High-Frequency Enterprise Crawl
    └── Architecture: Residential proxy gateway pool + sticky session routing
```

---

## Canonical Browser Header Suite

Always inject this complete header suite for standard HTTP scrapers:

```python
CANONICAL_BROWSER_HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
    "Accept-Encoding": "gzip, deflate, br, zstd",
    "Sec-Ch-Ua": '"Google Chrome";v="131", "Chromium";v="131", "Not_A Brand";v="24"',
    "Sec-Ch-Ua-Mobile": "?0",
    "Sec-Ch-Ua-Platform": '"Windows"',
    "Sec-Fetch-Dest": "document",
    "Sec-Fetch-Mode": "navigate",
    "Sec-Fetch-Site": "none",
    "Sec-Fetch-User": "?1",
    "Upgrade-Insecure-Requests": "1",
}
```
