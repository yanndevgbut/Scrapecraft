# Reconnaissance Dossier Specification

Before asking the user to confirm the implementation language and before writing a single line of scraper code, the **Recon & Sniffer Engineer** compiles a concise, structured **Reconnaissance Dossier**.

---

## Standard Dossier Template

```text
================================================================================
                    SCRAPECRAFT RECONNAISSANCE DOSSIER
================================================================================
Target URL:          [URL]
Page Architecture:   [Static HTML | Next.js SSR | Nuxt SSR | React/Vue SPA | API-Backed]
Data Access Route:   [1. State Extraction | 2. Internal JSON API | 3. Resilient DOM | 4. Browser]
Anti-Bot Security:   [None / Standard | Cloudflare Turnstile | Akamai | Rate Limited]
Est. Item Density:   [Number of items detected on initial payload, e.g., 24 items/page]

Key Technical Findings:
- Payload Analysis:  [e.g., Complete catalog embedded in <script id="__NEXT_DATA__">]
- Background APIs:   [e.g., Discovered internal REST endpoint: /api/v1/products]
- Selector Health:   [e.g., Primary container [data-testid="product-grid"] verified]

Principal Recommendation:
"I recommend [Python | Node.js] using [libraries, e.g., httpx and parsel] because
[1-sentence technical reason, e.g., data is 100% available in preloaded SSR state,
making browser automation unnecessary]."
================================================================================
```

---

## Architecture Classification Matrix

The Recon Engineer assigns one of the following architectural classifications:

| Classification | Diagnostic Evidence | Optimal Strategy |
|---|---|---|
| **Next.js SSR** | `<script id="__NEXT_DATA__">` in raw HTML | Direct JSON state extraction from `props.pageProps` |
| **Nuxt SSR** | `window.__NUXT__` or `<script id="__NUXT_DATA__">` | Regex parsing of serialized Nuxt state payload |
| **Schema.org JSON-LD** | `<script type="application/ld+json">` present | Parsing standard Schema (`Product`, `JobPosting`, `Article`) |
| **Internal REST API** | XHR/Fetch request returning JSON detected | Querying internal endpoint directly with minimal headers |
| **Internal GraphQL** | POST requests to `/graphql` detected | Replicating GraphQL query with query variables |
| **Static HTML** | Pure HTML containing target elements without JS | Lightweight HTTP client + CSS/XPath parser |
| **Dynamic SPA** | Empty HTML shell, heavy client-side hydration | Headless browser (Playwright) with route blocking |
| **Protected WAF** | HTTP 403/503 or Cloudflare challenge HTML | `curl_cffi` TLS impersonation or Stealth Playwright |

---

## Example Live Dossier

```text
================================================================================
                    SCRAPECRAFT RECONNAISSANCE DOSSIER
================================================================================
Target URL:          https://store.example.com/collections/laptops
Page Architecture:   Shopify Storefront (SSR + JSON Catalog)
Data Access Route:   1. Direct State / Public JSON Endpoint
Anti-Bot Security:   Standard (No WAF challenges)
Est. Item Density:   30 products on first page

Key Technical Findings:
- Payload Analysis:  Exposes public storefront catalog at /products.json?limit=250
- Data Completeness: Full variant prices, SKU, image arrays, and inventory status present
- Efficiency Gain:   Direct API fetch bypasses DOM parsing entirely (0.2s response time)

Principal Recommendation:
"I recommend Python using httpx because the target exposes a clean Shopify JSON endpoint,
allowing us to extract all variants without rendering overhead."
================================================================================
```
