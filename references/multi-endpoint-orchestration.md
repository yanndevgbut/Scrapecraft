# Multi-Endpoint Orchestration (Class-Based Session Scraper)

Complex scraping targets require **coordinated calls across multiple API endpoints**: search leads to detail, detail reveals lyrics/related IDs, browse IDs open album/artist/playlist pages. This playbook defines the class-based session architecture (matching the Node.js production standard) that orchestrates these flows.

---

## Architecture Overview

```
┌────────────────────────────────────────────────────┐
│              SessionScraper (class)                │
├────────────────────────────────────────────────────┤
│ STATE (survives across all requests)               │
│  - apiKey, context, visitorId   (from bootstrap)   │
│  - headers (with session tokens)                   │
│  - delay, debug, lastResponse                      │
├────────────────────────────────────────────────────┤
│ CORE (private)                                     │
│  - init()         one-time bootstrap               │
│  - _request()     single HTTP call + delay + retry │
│  - _sleep()       pacing                           │
├────────────────────────────────────────────────────┤
│ PARSERS (private, pure functions)                  │
│  - _text() _thumbs() _findAll() _parseListItem()   │
├────────────────────────────────────────────────────┤
│ PUBLIC FLOW (orchestrated)                         │
│  - search() getSuggestions() getHome()             │
│  - getDetail() getLyrics() getAlbum()              │
│  - getArtist() getPlaylist()                       │
└────────────────────────────────────────────────────┘
```

---

## Endpoint Flow Graph (YouTube Music Example)

```
search(query)
  ├── returns: videoId, browseId, artistId, albumId
  │
  ├─► getDetail(videoId)          [endpoint: next]
  │     ├── returns: title, artist, duration, queue
  │     └── returns: lyricsBrowseId ──► getLyrics(lyricsBrowseId)   [endpoint: browse]
  │
  ├─► getAlbum(albumId)           [endpoint: browse]
  │     └── returns: track list
  │
  ├─► getArtist(artistId)         [endpoint: browse]
  │     └── returns: sections (songs, albums, singles)
  │
  └─► getPlaylist(browseId)       [endpoint: browse]
        └── returns: track list
```

**Design rule**: every public method returns plain data dicts containing the IDs needed to traverse deeper (`videoId`, `browseId`, `lyricsBrowseId`). The caller (menu or CLI) decides which endpoint to visit next.

---

## Core Class Template (Node.js)

```javascript
#!/usr/bin/env node
const { gotScraping } = require("got-scraping");

class SessionScraper {
  constructor(options = {}) {
    this.debug = options.debug || false;
    this.delay = options.delay || 500;
    this.maxRetries = 3;
    this.headers = { /* ... browser headers ... */ };
    this.apiKey = "";
    this.context = {};
  }

  async init() {
    // Bootstrap: extract API key, context, visitor token from homepage
    // See references/internal-api-bootstrap.md
  }

  sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  async _request(endpoint, body = {}, attempt = 1) {
    await this.sleep(this.delay);

    const url = `${this.baseUrl}/${endpoint}?prettyPrint=false`;
    const payload = {
      context: this.context.client ? { client: this.context.client } : this.context,
      ...body,
    };

    try {
      const { statusCode, body: data } = await gotScraping({
        url,
        method: "POST",
        json: payload,
        headers: this.headers,
        responseType: "json",
        timeout: { request: 30000 },
      });

      if (statusCode === 200) return data;

      // Retry on transient blocks with backoff
      if (statusCode === 429 || statusCode === 503) {
        if (attempt < this.maxRetries) {
          const backoff = 1000 * Math.pow(2, attempt) + Math.random() * 500;
          console.error(`[WARN] HTTP ${statusCode} on ${endpoint}; retry ${attempt + 1}/${this.maxRetries} in ${Math.round(backoff)}ms`);
          await this.sleep(backoff);
          return this._request(endpoint, body, attempt + 1);
        }
      }
      throw new Error(`API ${endpoint} failed: HTTP ${statusCode}`);
    } catch (err) {
      if (attempt < this.maxRetries && (err.code === "ETIMEDOUT" || err.code === "ECONNRESET")) {
        await this.sleep(1000 * attempt);
        return this._request(endpoint, body, attempt + 1);
      }
      throw err;
    }
  }

  // ---- PUBLIC FLOW ----

  async search(query, filter = "") {
    const body = { query };
    if (filter) body.params = FILTER_PARAMS[filter];
    const data = await this._request("search", body);
    return this._parseSearchResults(data);
  }

  async getDetail(videoId) {
    const data = await this._request("next", { videoId, isAudioOnly: true });
    const detail = this._parseDetail(data);
    detail.videoId = videoId;
    return detail;
  }

  async getLyrics(browseId) {
    if (!browseId) return null;
    const data = await this._request("browse", { browseId });
    return this._parseLyrics(data);
  }

  async getAlbum(browseId) {
    const data = await this._request("browse", { browseId });
    return this._parseAlbum(data, browseId);
  }

  async getArtist(browseId) {
    const data = await this._request("browse", { browseId });
    return this._parseArtist(data, browseId);
  }
}
```

---

## Public Method Contract

Every public method MUST:

1. Accept only stable identifiers (query strings or IDs from previous responses).
2. Call `_request()` exactly once per API call (pagination loops are the exception and manage their own retries).
3. Return plain serializable dicts - never raw response objects.
4. Include the IDs needed to continue traversal in the returned data.
5. Never print to stdout (logging goes to stderr; the caller owns stdout).

---

## Retry & Backoff Rules

| Condition | Action |
|---|---|
| HTTP 200 | Return data immediately |
| HTTP 429 / 503 (rate limit / overload) | Exponential backoff `1000 * 2^attempt` + jitter, max 3 attempts |
| HTTP 403 (WAF block) | Do NOT retry blindly; escalate to stealth escalation path |
| HTTP 404 (endpoint gone) | Fail fast; structural change, re-inspect |
| Network errors (ETIMEDOUT, ECONNRESET) | Retry with linear backoff, max 3 attempts |
| Empty 200 but missing expected keys | Shape drift; log response keys to stderr, run `json-explorer.py` |

---

## Session Re-Bootstrap Rule

Re-run `init()` (bootstrap) when:

- Any request returns HTTP 401/403 after successful init (session expired or invalidated).
- Visitor token rejection is detected (consistent empty payloads).
- More than 30 minutes have passed on long crawls (session tokens often expire).

```javascript
async _requestWithSessionRenewal(endpoint, body) {
  try {
    return await this._request(endpoint, body);
  } catch (err) {
    if (err.message.includes("HTTP 403") || err.message.includes("HTTP 401")) {
      console.error("[*] Session rejected; re-bootstrapping...");
      await this.init();
      return this._request(endpoint, body);
    }
    throw err;
  }
}
```

---

## CLI Entrypoint Pattern (Non-Interactive Mode)

When Gate 3 answer is "CLI arguments only":

```javascript
async function runCliMode(args) {
  const target = args[0];
  const scraper = new SessionScraper({ debug: false, delay: 500 });
  await scraper.init();

  if (target === "search") {
    const results = await scraper.search(args[1], args[2] || "");
    process.stdout.write(JSON.stringify(results, null, 2) + "\n");
  } else if (target === "detail") {
    const detail = await scraper.getDetail(args[1]);
    process.stdout.write(JSON.stringify(detail, null, 2) + "\n");
  } else if (target === "lyrics") {
    const detail = await scraper.getDetail(args[1]);
    const lyrics = await scraper.getLyrics(detail.lyricsBrowseId);
    process.stdout.write(JSON.stringify(lyrics, null, 2) + "\n");
  } else {
    console.error("Usage: scraper.js search <query> [filter] | detail <videoId> | lyrics <videoId>");
    process.exit(1);
  }
}
```

Wire this into the Mixed Mode dispatcher from `references/interactive-cli-menu.md`.
