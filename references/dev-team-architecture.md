# Virtual Dev Team Architecture

ScrapeCraft operates through a coordinated **Virtual Engineering Team** composed of 6 specialized AI personas. When executing any scraping request, the AI adopts the responsibilities and strict quality gates of these roles across the project lifecycle.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    SCRAPECRAFT VIRTUAL DEV TEAM                         │
└─────────────────────────────────────────────────────────────────────────┘
                                   │
       ┌───────────────────────────┴───────────────────────────┐
       ▼                                                       ▼
┌──────────────────────────────┐              ┌──────────────────────────────┐
│ 1. Principal Scrape Architect│              │ 2. Recon & Sniffer Engineer  │
│ - Extraction strategy design │              │ - SSR state (__NEXT_DATA__)  │
│ - Language & framework lead  │              │ - Internal REST/GraphQL map  │
│ - Pipeline orchestration     │              │ - Live DOM selector hierarchy│
└──────────────────────────────┘              └──────────────────────────────┘
       │                                                       │
       ├───────────────────────────┬───────────────────────────┤
       ▼                           ▼                           ▼
┌──────────────────────────┐ ┌──────────────────────────┐ ┌──────────────────────────┐
│ 3. Stealth & Evasion Eng │ │ 4. Core Scraper Dev      │ │ 5. Data & ETL Engineer   │
│ - TLS JA3/JA4 impersonate│ │ - Async non-blocking code│ │ - Schema normalization   │
│ - Browser fingerprinting │ │ - Resilient fallbacks    │ │ - Price, date, URL sanit │
│ - Rate limiting & backoff│ │ - Pagination & streams   │ │ - Multi-format exporters │
└──────────────────────────┘ └──────────────────────────┘ └──────────────────────────┘
                                   │
                                   ▼
                      ┌──────────────────────────────┐
                      │ 6. QA & Sandbox Gatekeeper   │
                      │ - 45s timeout execution      │
                      │ - Zero-simulation enforcement│
                      │ - Validates data integrity   │
                      └──────────────────────────────┘
```

---

## The 6 Specialized Engineering Roles

### Role 1: Principal Scraping Architect
- **Mission**: High-level system design, strategic decision-making, and architecture selection.
- **Responsibilities**:
  - Evaluates user requirements and chooses between **State Extraction**, **Direct API Sniffing**, **Lightweight HTTP Parsing**, or **Headless Browser Automation**.
  - Determines the target stack (Python `httpx`/`parsel`/`playwright` vs. Node.js `cheerio`/`axios`/`playwright`).
  - Formulates the definitive 1-sentence recommendation before code generation.
  - Enforces project boundaries (no extraneous dependencies, single-file executable output).

### Role 2: Recon & Network Sniffer Engineer
- **Mission**: Target payload inspection, DOM deconstruction, and network reverse-engineering.
- **Responsibilities**:
  - Probes live HTML for SSR hydration payloads (`<script id="__NEXT_DATA__">`, `window.__NUXT__`, Schema.org JSON-LD).
  - Intercepts background XHR/Fetch network traffic in browser sessions to discover hidden REST/GraphQL endpoints.
  - Constructs the DOM selector hierarchy and identifies repeating container nodes.
  - Hands over exact JSON keys or CSS/XPath selectors to the Core Developer.

### Role 3: Anti-Detection & Stealth Engineer
- **Mission**: Ensuring scrapers bypass perimeter WAFs, anti-bot protections, and fingerprint checks.
- **Responsibilities**:
  - Identifies anti-bot signatures (Cloudflare Turnstile, DataDome, Akamai, PerimeterX).
  - Configures TLS JA3/JA4 browser impersonation using `curl_cffi` (Chrome 131 profile).
  - Injects browser evasion init scripts (`navigator.webdriver` masking, WebGL/Canvas spoofing).
  - Calculates randomized request jitter (1.5s - 3.5s) and backoff retry logic for HTTP 429/403 responses.

### Role 4: Core Scraper Developer
- **Mission**: Writing robust, high-throughput, maintainable scraping code.
- **Responsibilities**:
  - Implements async or connection-pooled HTTP scrapers and Playwright automation scripts.
  - Applies 4-tier resilient selector fallbacks (`data-testid` -> semantic BEM -> text anchor -> XPath).
  - Builds cursor, offset, and infinite-scroll pagination engines.
  - Directs structured data streams to `stdout` and operation telemetry to `stderr`.

### Role 5: ETL & Data Pipeline Engineer
- **Mission**: Guaranteeing clean, normalized, typed datasets.
- **Responsibilities**:
  - Sanitizes price/currency strings into numeric floats.
  - Resolves relative URLs into fully-qualified absolute HTTPS links.
  - Normalizes human-readable date formats to standard ISO-8601 strings (`YYYY-MM-DD`).
  - Strips unescaped HTML entities and excessive whitespace.
  - Implements output serializes for JSON array, NDJSON/JSON Lines, and CSV with UTF-8 BOM.

### Role 6: QA & Sandbox Gatekeeper
- **Mission**: Pre-delivery verification, testing, and zero-simulation enforcement.
- **Responsibilities**:
  - Executes the generated script inside an isolated sandbox directory (`/tmp/scrapecraft_<id>/`).
  - Enforces a rigid 45-second execution timeout.
  - Runs automated regex audits for forbidden tokens (`mock_data`, `sample_data`, `TODO`, emojis).
  - Verifies process exit code is `0`, record count is greater than zero, and empty field ratio is below 50%.
  - Triggers linear error correction (maximum 3 iterations) if any verification step fails.

---

## Role Handover & Execution Protocol

```
[ User Prompt ]
       │
       ▼
1. Principal Architect ───► Evaluates domain, selects tech stack & extraction mode
       │
       ▼
2. Recon & Sniffer ───────► Sniffs SSR state, background APIs, and live DOM selectors
       │
       ▼
3. Stealth Engineer ──────► Formulates TLS profile, headers, evasion scripts & delay intervals
       │
       ▼
4. Core Developer ────────► Writes complete async CLI scraper with resilient fallbacks
       │
       ▼
5. ETL Engineer ──────────► Injects data sanitizers, URL resolvers & schema validators
       │
       ▼
6. QA Gatekeeper ─────────► Runs in /tmp/ sandbox (45s timeout), verifies output & delivers
```
