# Internal API Bootstrapping (Session Init Pattern)

Many high-value targets (YouTube Music, TikTok, Tokopedia, Shopee, Spotify) expose clean internal APIs, but those APIs require **session credentials harvested from the site's own HTML or JS payloads** before any API call succeeds.

The **Bootstrapping Pattern**: fetch the site once, extract embedded API credentials and client context, then replay them in every subsequent API request.

---

## The Bootstrap Sequence

```
[Step 1] GET homepage (plain HTTP, no API call)
    │
    ▼
[Step 2] Regex/parse embedded credentials from HTML/JS:
    │   - API key / INNERTUBE_API_KEY
    │   - Client context (INNERTUBE_CONTEXT)
    │   - Visitor/session token (VISITOR_DATA)
    │   - CSRF tokens, build IDs, app versions
    ▼
[Step 3] Inject credentials into session state:
    │   - this.apiKey = extracted key
    │   - this.headers["X-Goog-Visitor-Id"] = visitor token
    │   - this.context = parsed client context
    ▼
[Step 4] All subsequent requests reuse this session state
```

---

## Worked Example: YouTube Music (Innertube API)

YouTube Music's frontend talks to the **Innertube API** at `https://music.youtube.com/youtubei/v1/<endpoint>`. The full bootstrap:

```javascript
#!/usr/bin/env node
const { gotScraping } = require("got-scraping");

class InnertubeScraper {
  constructor(options = {}) {
    this.baseUrl = "https://music.youtube.com/youtubei/v1";
    this.apiKey = "";
    this.context = {};
    this.debug = options.debug || false;
    this.delay = options.delay || 500;
    this.headers = {
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
      "Accept": "*/*",
      "Accept-Language": "id,en-US;q=0.9,en;q=0.8",
      "Content-Type": "application/json",
      "Origin": "https://music.youtube.com",
      "Referer": "https://music.youtube.com/",
      "sec-ch-ua": '"Chromium";v="131", "Google Chrome";v="131"',
      "sec-ch-ua-platform": '"Windows"',
      "sec-fetch-dest": "empty",
      "sec-fetch-mode": "cors",
      "sec-fetch-site": "same-origin",
    };
  }

  async init() {
    console.error("[*] Bootstrapping session from homepage...");

    const { body: html, statusCode } = await gotScraping({
      url: "https://music.youtube.com/",
      responseType: "text",
      timeout: { request: 30000 },
    });

    if (statusCode !== 200) {
      throw new Error(`Homepage fetch failed: HTTP ${statusCode}`);
    }

    // Step 2a: extract API key
    const keyMatch = html.match(/"INNERTUBE_API_KEY":"([a-zA-Z0-9_-]+)"/);
    if (keyMatch) {
      this.apiKey = keyMatch[1];
    } else {
      throw new Error("INNERTUBE_API_KEY not found in homepage payload");
    }

    // Step 2b: extract client context (embeds clientName, clientVersion, gl, hl)
    const ctxMatch = html.match(/"INNERTUBE_CONTEXT":(\{.+?\})\},\s*"INNERTUBE_CONTEXT_CLIENT_NAME"/);
    if (ctxMatch) {
      try {
        this.context = JSON.parse(ctxMatch[1]);
      } catch (parseErr) {
        this.context = this.defaultContext();
      }
    } else {
      this.context = this.defaultContext();
    }

    // Step 2c: extract visitor token and inject into headers + context
    const visMatch = html.match(/"VISITOR_DATA":"([a-zA-Z0-9_-]+)"/);
    if (visMatch) {
      this.headers["X-Goog-Visitor-Id"] = visMatch[1];
      if (this.context.client) {
        this.context.client.visitorData = visMatch[1];
      }
    }

    console.error(`[OK] Session ready. Client: ${this.context.client?.clientName || "unknown"}`);
    return this;
  }

  defaultContext() {
    return {
      client: {
        clientName: "WEB_REMIX",
        clientVersion: "1.20250101.01.00",
        hl: "id",
        gl: "ID",
      },
    };
  }

  sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  async request(endpoint, body = {}) {
    await this.sleep(this.delay);

    const url = `${this.baseUrl}/${endpoint}?prettyPrint=false`;
    const payload = {
      context: this.context.client ? { client: this.context.client } : this.context,
      ...body,
    };

    const { statusCode, body: data } = await gotScraping({
      url,
      method: "POST",
      json: payload,
      headers: this.headers,
      responseType: "json",
      timeout: { request: 30000 },
    });

    if (statusCode !== 200) {
      throw new Error(`API ${endpoint} failed: HTTP ${statusCode}`);
    }
    return data;
  }
}
```

---

## Generic Bootstrap Extractor (Any Site)

The same pattern applies to any site embedding session state:

```python
#!/usr/bin/env python3
import json
import re
import sys
import httpx

BOOTSTRAP_PATTERNS = {
    "api_key": r'"(?:api_key|apiKey|API_KEY|INNERTUBE_API_KEY)"\s*:\s*"([a-zA-Z0-9_-]{20,})"',
    "csrf_token": r'name="csrf[_-]?token"\s+content="([^"]+)"',
    "visitor_id": r'"(?:VISITOR_DATA|visitorId|visitor_id)"\s*:\s*"([a-zA-Z0-9_%=-]+)"',
    "build_id": r'"buildId"\s*:\s*"([^"]+)"',
    "app_version": r'"(?:app_version|clientVersion|appVersion)"\s*:\s*"([\d.]+)"',
    "access_token": r'"(?:access_token|accessToken)"\s*:\s*"([a-zA-Z0-9_.-]{30,})"',
}


def bootstrap_session(homepage_url: str) -> dict:
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
    }
    response = httpx.get(homepage_url, headers=headers, timeout=30, follow_redirects=True)
    if response.status_code != 200:
        print(f"Homepage fetch failed: HTTP {response.status_code}", file=sys.stderr)
        sys.exit(1)

    html = response.text
    credentials = {}
    for name, pattern in BOOTSTRAP_PATTERNS.items():
        match = re.search(pattern, html)
        if match:
            credentials[name] = match.group(1)

    if not credentials:
        print("No bootstrap credentials found in homepage payload.", file=sys.stderr)
        sys.exit(1)

    for name, value in credentials.items():
        print(f"Extracted {name}: {value[:12]}...", file=sys.stderr)
    return credentials
```

---

## Bootstrap Anti-Patterns (Forbidden)

| Anti-Pattern | Why Forbidden |
|---|---|
| Hardcoded fallback API keys (`'AIzaSy...'`) | Keys rotate; hardcoded values silently fail and leak secrets |
| Falling back to hardcoded credentials on extraction failure | Mask the real problem; if bootstrap fails, the target changed and must be re-inspected |
| Skipping visitor/session tokens | APIs return empty or bot-challenge responses without them |
| Bootstrapping inside every request | Bootstrap once per session; re-bootstrap only on 401/403 |
| Logging full credentials to stdout | Secrets must never enter data streams; log only truncated prefixes to stderr |
