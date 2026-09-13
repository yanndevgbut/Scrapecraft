<div align="center">

<img src="assets/banner.jpg" alt="ScrapeCraft" width="640">

# ScrapeCraft 

**A high-precision, production-grade web scraping AI agent skill.**

Eliminates selector hallucinations, simulated mock data, nested try-catch masking, and circular reasoning loops in AI-generated scrapers. Powered by an integrated **6-Role Virtual Engineering Team** with live DOM inspection, SSR state extraction, internal API reverse-engineering, and sandboxed self-correction.

[![Stars](https://img.shields.io/github/stars/yanndevgbut/scrapecraft?style=flat-square&color=2b3af6)](https://github.com/yanndevgbut/scrapecraft/stargazers)
[![Forks](https://img.shields.io/github/forks/yanndevgbut/scrapecraft?style=flat-square&color=2b3af6)](https://github.com/yanndevgbut/scrapecraft/network/members)
[![Issues](https://img.shields.io/github/issues/yanndevgbut/scrapecraft?style=flat-square)](https://github.com/yanndevgbut/scrapecraft/issues)
[![Last Commit](https://img.shields.io/github/last-commit/yanndevgbut/scrapecraft?style=flat-square)](https://github.com/yanndevgbut/scrapecraft/commits)
[![Repo Size](https://img.shields.io/github/repo-size/yanndevgbut/scrapecraft?style=flat-square)](https://github.com/yanndevgbut/scrapecraft)
[![License](https://img.shields.io/github/license/yanndevgbut/scrapecraft?style=flat-square)](LICENSE)

[Overview](#overview) · [Virtual Dev Team](#virtual-dev-team-architecture) · [Playbooks](#35-specialized-engineering-playbooks) · [Structure](#repository-structure) · [Installation](#installation) · [Workflow](#execution-workflow) · [Quality Policy](#quality--accuracy-policy) · [Contributing](#contributing)

</div>

---

## Overview

AI coding agents frequently generate fragile, non-functional web scraping scripts. They guess DOM selectors without inspecting real pages, inject mock data or placeholder variables (`TODO`, `your_api_key`), pollute code with emojis and decorative comments, wrap failing logic in nested `try-except: pass` blocks, and become trapped in circular reasoning when encountering anti-bot mechanisms.

**ScrapeCraft resolves this completely.** It is an enterprise skill and knowledge pack engineered for AI coding agents (OpenCode, Claude Code, Codex, Antigravity, Cursor) that enforces the collective discipline of a **6-Role Virtual Engineering Team**:

- **Direct State Extraction**: Discovers and parses SSR hydration state (`__NEXT_DATA__`, `__NUXT_DATA__`, JSON-LD) directly for 100x faster, redesign-immune extraction.
- **Internal API Reverse-Engineering**: Sniffs XHR/Fetch network traffic to extract clean JSON REST/GraphQL endpoints before resorting to heavy browser rendering.
- **Resilient Multi-Tier Selectors**: Implements 4-tier fallback selector chains (Data attributes → Semantic classes → XPath anchors) to prevent selector breakage.
- **Automated Data Normalization**: Sanitizes currency strings to floats, cleans whitespace and HTML entities, and resolves all relative URLs to absolute HTTPS links.
- **Domain-Specific Scrapers**: Tailored extraction engines for E-Commerce, Social Media, Real Estate, Financial Markets, Job Portals, Travel, News, and Business Leads.
- **Document & Stream Pipelines**: Extracts tabular data from PDFs, parses massive XML Sitemaps/RSS feeds, downloads high-res media streams, and captures live WebSockets.
- **Sandboxed Verification**: Executes draft code inside an isolated local runtime (`/tmp/scrapecraft_<session>/`) with strict 45-second timeout constraints.
- **Deterministic Self-Correction**: Enforces a strict linear correction protocol (maximum 3 iterations) with fail-fast escalation when encountering structural blockers.
- **Zero Simulation**: Permanently bans mock datasets, placeholder tokens, and decorative comments from final output.

---

## Virtual Dev Team Architecture

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

| Role | Core Responsibility | Quality Standard |
|---|---|---|
| **1. Principal Architect** | High-level system design, extraction paradigm selection, tech stack recommendation | Evaluates State vs. API vs. DOM; formulates definitive 1-sentence recommendation |
| **2. Recon & Sniffer** | Target payload inspection, SSR state discovery, background API interception | Captures `__NEXT_DATA__`, hidden endpoints, and verified DOM selectors |
| **3. Stealth Engineer** | Anti-bot bypass, TLS fingerprinting, browser evasion, rate limiting | Configures `curl_cffi` JA3/JA4 impersonation, stealth flags, and jitter delays |
| **4. Core Scraper Dev** | Production-ready script authoring, resilient fallbacks, streaming pagination | Clean async code, 4-tier selector hierarchy, stdout data streams |
| **5. Data & ETL Engineer** | Data sanitization, schema typing, price/date normalizers, absolute URL resolution | Pydantic/Zod schemas, floats for prices, ISO-8601 timestamps, HTTPS links |
| **6. QA Gatekeeper** | Isolated sandbox test runs, timeout enforcement, token audits, pre-delivery sign-off | Exit code 0, non-empty results, zero forbidden tokens, verified JSON schema |

---

## 35 Specialized Engineering Playbooks

The `references/` directory contains 35 drill-down engineering specifications loaded on demand by the agent to conserve context window while providing expert-grade depth:

### 1. Core Architecture & Workflow
| Playbook | Focus Area | Key Technologies |
|---|---|---|
| `references/workflow.md` | 8-phase execution lifecycle | End-to-end task orchestration |
| `references/dev-team-architecture.md` | Multi-role virtual team protocol | Handover contracts & quality gates |
| `references/browser-inspection.md` | Live DOM & network panel analysis | Headless browser DOM capture |
| `references/resilient-selectors.md` | 4-tier fallback selector hierarchy | Data attributes, BEM classes, XPath anchors |

### 2. Domain-Specific Data Scraping
| Playbook | Focus Area | Key Technologies |
|---|---|---|
| `references/domain-ecommerce.md` | Catalogs, variants, stock, reviews | Shopify JSON, Amazon, Shopee, Tokopedia |
| `references/domain-social-media.md` | Feeds, comments, author profiles | Reddit JSON, X/Twitter, TikTok, YouTube |
| `references/domain-jobs-recruitment.md` | Job listings, salaries, skill tags | JobPosting Schema, Greenhouse, LinkedIn |
| `references/domain-real-estate.md` | Property specs, map bounding boxes | Zillow, Redfin, SingleFamilyResidence Schema |
| `references/domain-news-articles.md` | Article text, author bylines, dates | NewsArticle Schema, Readability body parsing |
| `references/domain-financial-market.md` | Real-time tickers, OHLCV, SEC EDGAR | Yahoo Finance API, SEC CIK company facts |
| `references/domain-travel-hospitality.md` | Hotel date matrices, room availability | Booking.com, Agoda, LodgingBusiness Schema |
| `references/domain-directories-leads.md` | Business directories, emails, phones | LocalBusiness Schema, E.164 phone cleaner |

### 3. Extraction Strategies & Network Protocols
| Playbook | Focus Area | Key Technologies |
|---|---|---|
| `references/state-extraction.md` | SSR hydration state parsing | Next.js `__NEXT_DATA__`, Nuxt, JSON-LD |
| `references/api-sniffing.md` | Reverse-engineering hidden REST APIs | XHR/Fetch network interception |
| `references/graphql-scraping.md` | GraphQL queries & cursor pagination | GraphQL POST operations & variables |
| `references/websocket-stream-scraping.md` | Real-time WebSocket & SSE streams | `wss://` listeners, Server-Sent Events |
| `references/iframe-shadow-dom.md` | Nested iframes & Web Components | Playwright FrameLocators, Shadow DOM |
| `references/pagination-patterns.md` | Cursors, offset/pages, infinite scroll | Next-link traversal, dynamic scroll wait |
| `references/authentication-sessions.md` | Persistent login sessions & cookies | Playwright `storage_state`, session cookies |

### 4. Documents & Media Pipelines
| Playbook | Focus Area | Key Technologies |
|---|---|---|
| `references/document-pdf-table-extraction.md` | Tabular PDF extraction | `pdfplumber`, `pypdf`, stream parsing |
| `references/xml-sitemap-rss-scraping.md` | Mass URL discovery & RSS feeds | `sitemap.xml`, sitemap index, Atom feeds |
| `references/media-asset-downloading.md` | Chunked high-res media streams | Async chunked downloading, MD5 hashing |

### 5. Frameworks & Libraries
| Playbook | Focus Area | Key Technologies |
|---|---|---|
| `references/python-scraping.md` | Production Python CLI standard | `httpx`, `parsel`, `pydantic`, `argparse` |
| `references/scrapy-architecture.md` | Distributed Scrapy crawling | `scrapy.Spider`, `CrawlerProcess`, Pipelines |
| `references/playwright-deepdive.md` | Route aborting & CDP commands | Block images/CSS (80% bandwidth save), CDP |
| `references/nodejs-scraping.md` | Production Node.js CLI standard | `cheerio`, `axios`, `got`, CLI args |
| `references/puppeteer-stealth.md` | Node.js stealth automation | `puppeteer-extra-plugin-stealth`, CDP |
| `references/httpx-curl-cffi.md` | TLS JA3/JA4 browser impersonation | `curl_cffi` (Chrome 131 profile), HTTP/2 |

### 6. Anti-Detection, ETL & Quality Control
| Playbook | Focus Area | Key Technologies |
|---|---|---|
| `references/anti-detection.md` | Cloudflare Turnstile & WAF bypass | Fingerprint spoofing, header ordering |
| `references/proxy-rotation-gateways.md` | Residential proxy pools & backoff | Sticky/rotating proxy pools, jitter retry |
| `references/concurrency-rate-limiting.md` | Asyncio semaphores & token bucket | Concurrency controls, exponential backoff |
| `references/data-normalization.md` | Currency parsing, ISO dates, URLs | `clean_text`, `parse_price`, `resolve_url` |
| `references/storage-database-pipelines.md` | Relational & analytics storage | SQLite, PostgreSQL, DuckDB, Parquet |
| `references/validation.md` | 6-stage automated quality pipeline | Exit code, token hygiene, schema audit |
| `references/error-correction.md` | Linear self-correction protocol | Bounded 3-iteration root cause fixes |

---

## Repository Structure

```
scrapecraft/
├── SKILL.md                          # Master skill entry point (YAML frontmatter + system prompt)
├── install.sh                        # Universal installer for Claude Code, OpenCode, and .agents
├── README.md                         # Project documentation and multi-agent setup guide
├── LICENSE                           # MIT License
├── .gitignore                        # Cache, environment, and temp directory exclusions
├── assets/
│   └── banner.jpg                    # Repository hero banner
├── references/                       # 35 Specialized engineering playbooks
│   ├── workflow.md                   # 8-phase execution lifecycle
│   ├── dev-team-architecture.md      # 6-role virtual team protocol
│   ├── browser-inspection.md         # Live DOM & network panel analysis
│   ├── resilient-selectors.md        # 4-tier fallback selector hierarchy
│   ├── domain-ecommerce.md           # E-commerce product catalogs & variants
│   ├── domain-social-media.md        # Social feeds & recursive comment trees
│   ├── domain-jobs-recruitment.md    # Job listings, salary ranges & skills
│   ├── domain-real-estate.md         # Property specs & map bounding boxes
│   ├── domain-news-articles.md       # Article readability & author bylines
│   ├── domain-financial-market.md    # Real-time tickers & SEC EDGAR filings
│   ├── domain-travel-hospitality.md  # Hotel date matrices & room availability
│   ├── domain-directories-leads.md   # Business directories & lead extraction
│   ├── state-extraction.md           # Next.js __NEXT_DATA__, Nuxt, JSON-LD
│   ├── api-sniffing.md               # Reverse-engineering background REST APIs
│   ├── graphql-scraping.md           # GraphQL queries & cursor pagination
│   ├── websocket-stream-scraping.md  # WebSocket (WSS) & SSE streaming data
│   ├── iframe-shadow-dom.md          # Penetrating nested iframes & Shadow DOM
│   ├── pagination-patterns.md        # Cursors, offset/pages, infinite scroll
│   ├── authentication-sessions.md    # StorageState, cookies, login automation
│   ├── document-pdf-table-extraction.md # Tabular PDF extraction with pdfplumber
│   ├── xml-sitemap-rss-scraping.md   # XML sitemaps index & RSS feed parser
│   ├── media-asset-downloading.md    # Chunked media streaming & MD5 hashing
│   ├── python-scraping.md            # Python CLI architecture (httpx, parsel)
│   ├── scrapy-architecture.md        # Standalone Scrapy spiders & pipelines
│   ├── playwright-deepdive.md        # Route aborts, CDP commands, wait strategies
│   ├── nodejs-scraping.md            # Node.js CLI architecture (cheerio, axios)
│   ├── puppeteer-stealth.md          # Puppeteer Extra Stealth & evasion
│   ├── httpx-curl-cffi.md            # TLS JA3/JA4 browser impersonation
│   ├── anti-detection.md             # Cloudflare Turnstile & WAF bypass
│   ├── proxy-rotation-gateways.md    # Residential proxy pools & backoff
│   ├── concurrency-rate-limiting.md  # Asyncio semaphores & token bucket limiters
│   ├── data-normalization.md         # Price parsing, ISO dates, absolute URLs
│   ├── storage-database-pipelines.md # SQLite, PostgreSQL, DuckDB, Parquet
│   ├── validation.md                 # 6-stage pre-delivery quality pipeline
│   └── error-correction.md           # Linear self-correction protocol (max 3 tries)
└── scripts/
    ├── sandbox-run.sh                # Isolated script execution runner (45s timeout)
    └── validate-output.sh            # Automated syntax, token, and data density auditor
```

---

## Installation

ScrapeCraft works across all standard AI coding agents. `SKILL.md` carries standard YAML frontmatter (`name`, `description`, `allowed-tools`), which is parsed natively by Claude Code, OpenCode, and the open skills ecosystem.

| Agent | Mechanism | Default Path |
|---|---|---|
| **Claude Code** | Native skills (`SKILL.md` frontmatter) | `~/.claude/skills/scrapecraft` or `.claude/skills/scrapecraft` |
| **OpenCode** | Native skills (`skill` tool) | `~/.config/opencode/skills/scrapecraft` or `.opencode/skills/scrapecraft` |
| **Codex** | `AGENTS.md` context pointer | `.agents/skills/scrapecraft` + pointer snippet |
| **Antigravity** | `GEMINI.md` / `AGENTS.md` pointer | `.agents/skills/scrapecraft` + pointer snippet |
| **Cursor** | `AGENTS.md` or `.cursor/rules/` | `.agents/skills/scrapecraft` + rule file |
| **Windsurf** | `AGENTS.md` or `.windsurf/rules/` | `.agents/skills/scrapecraft` + rule file |
| **Generic CLI** | Workspace file access | `.agents/skills/scrapecraft` + system prompt |

### Quick Install (Recommended)

#### Option A: Via `npx skills` (Cross-Agent Registry)

```bash
npx skills add yanndevgbut/scrapecraft
```

#### Option B: Via Bundled Universal Installer

```bash
git clone https://github.com/yanndevgbut/scrapecraft.git
cd scrapecraft

# Install globally (available across all projects):
./install.sh

# Or install only into the current project:
./install.sh --project

# Or install into a custom location:
./install.sh --dir /custom/skills/path
```

---

### Manual Setup by Agent

#### Claude Code

```bash
# Global
git clone https://github.com/yanndevgbut/scrapecraft.git ~/.claude/skills/scrapecraft

# Per-project
git clone https://github.com/yanndevgbut/scrapecraft.git .claude/skills/scrapecraft
```

Verify the skill inside a Claude Code session by typing `/skills`.

#### OpenCode

```bash
# Global
git clone https://github.com/yanndevgbut/scrapecraft.git ~/.config/opencode/skills/scrapecraft

# Per-project
git clone https://github.com/yanndevgbut/scrapecraft.git .opencode/skills/scrapecraft
```

OpenCode loads ScrapeCraft on demand via the native `skill({ name: "scrapecraft" })` call.

#### Codex (OpenAI)

```bash
git clone https://github.com/yanndevgbut/scrapecraft.git .agents/skills/scrapecraft
```

Add to your `AGENTS.md` (or `~/.codex/AGENTS.md`):

```markdown
## ScrapeCraft

When a task involves web scraping, data extraction, HTML parsing, or building crawlers,
read `.agents/skills/scrapecraft/SKILL.md` first and follow its execution workflow.
Always inspect the target DOM before writing selectors and test code in a sandbox before delivery.
```

#### Antigravity (Google)

```bash
git clone https://github.com/yanndevgbut/scrapecraft.git .agents/skills/scrapecraft
```

Add to your `GEMINI.md` or `AGENTS.md`:

```markdown
## Web Scraping Tasks

Before writing any web scraping code, read `.agents/skills/scrapecraft/SKILL.md`.
Follow its 8-phase execution workflow, enforce zero-simulation rules, and validate
scripts in the sandbox before returning code to the user.
```

#### Cursor / Windsurf

- **Cursor:** Place the pointer snippet in `.cursor/rules/scrapecraft.mdc` or within the root `AGENTS.md`.
- **Windsurf:** Add the pointer snippet to `.windsurf/rules/scrapecraft.md` or within the root `AGENTS.md`.

---

## Execution Workflow

```
[ User Request ]
       │
       ▼
┌──────────────────────────────────────┐
│  1. Receive & Clarify Schema         │ ── Principal Architect: Extract target parameters
└──────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  2. Target Inspection & Sniffing     │ ── Recon Engineer: 1. Check SSR State (__NEXT_DATA__)
└──────────────────────────────────────┘                    2. Sniff background REST/GraphQL APIs
       │                                                    3. Analyze DOM & multi-tier fallbacks
       ▼
┌──────────────────────────────────────┐
│  3. Recommend Optimal Strategy       │ ── Principal Architect: 1-sentence technical justification
└──────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  4. Write Production CLI Code        │ ── Core Dev & ETL Engineer: Normalizers, fallbacks, CLI args
└──────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  5. Sandboxed Test Run               │ ── QA Gatekeeper: Execute in /tmp/ (timeout: 45s)
└──────────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────┐
│  6. Validate Output & Quality        │ ── QA Gatekeeper: Check exit code 0, density, JSON schema
└──────────────────────────────────────┘
       │
       ├─► [ Failed ] ── Linear correction (max 3 attempts) ──┐
       │                                                      │
       ▼                                                      ▼
┌──────────────────────────────────────┐             ┌──────────────────┐
│  7. Deliver Tested CLI Scraper       │             │  Escalate Issue  │
└──────────────────────────────────────┘             └──────────────────┘
```

---

## Quality & Accuracy Policy

### Forbidden Tokens (`FORBIDDEN_TOKENS`)

ScrapeCraft strictly prohibits the following patterns in all generated scripts and agent outputs:

| Violation Category | Forbidden Patterns | Enforced Standard |
|---|---|---|
| **Mock Data** | `mock_data`, `sample_data`, `fake_`, `dummy_`, `test_data` | All data must come from real DOM/API extraction |
| **Placeholders** | `TODO`, `FIXME`, `HACK`, `your_api_key`, `<INSERT_HERE>` | Code must be 100% complete and runnable |
| **Emoji & Slop** | Any unicode emoji character in code or comments | Clean, professional, production-grade syntax |
| **Decorative Banners** | Comment dividers (`####`, `====`, `----`), ASCII art | Strictly functional comments only |
| **Lazy Error Swallowing** | Bare `except: pass`, empty `catch (e) {}` | Explicit error reporting to `stderr` and non-zero exit |

### Pre-Delivery Validation Pipeline

Every script generated by ScrapeCraft must pass the automated validator (`scripts/validate-output.sh`):

1. **Syntax Check**: Code parses with zero syntax errors (`ast.parse` / `node --check`).
2. **Token Audit**: Zero matches against the `FORBIDDEN_TOKENS` regex suite.
3. **Execution Exit Code**: Script exits cleanly with return code `0`.
4. **Data Density Ratio**: Less than 50% empty/null fields across extracted records.
5. **URL Absolute Verification**: 100% of extracted links must be resolved to absolute URLs.
6. **Entity Hygiene**: Zero unescaped HTML entities in output values.

---

## Companion Skills

ScrapeCraft can be combined with other modular agent skills for advanced multi-agent workflows:

```bash
# Browser automation for interactive sessions
npx skills add vercel-labs/agent-browser

# Official Playwright CLI harness
npx skills add microsoft/playwright-cli

# Advanced anti-bot browser evasion
npx skills add changeflowhq/skills@stealth-browser

# Structured error handling patterns
npx skills add sickn33/agentic-awesome-skills@error-handling-patterns

# Full-spectrum scraping CLI reference
npx skills add scrapegraphai/just-scrape
```

---

## Contributing

Contributions are welcome. Please adhere to the following standards:

1. **Source Grounding**: Every selector strategy or evasion pattern must be verified against current web standards.
2. **No Hallucinations**: Do not submit experimental APIs or undocumented flags.
3. **Validation**: Ensure all shell scripts pass `bash -n` and python scripts pass AST validation.

To contribute:
- Fork the repository and create a feature branch (`git checkout -b feature/new-playbook`).
- Test changes using the validation test suite in `scripts/validate-output.sh`.
- Submit a pull request with a concise technical description.

---

## Disclaimer

ScrapeCraft is an open-source development skill intended for legal, authorized web data extraction, academic research, and public data collection.

Users are responsible for ensuring that their scraping activities comply with:
- The target website's Terms of Service and `robots.txt` directives.
- Applicable data privacy regulations (e.g., GDPR, CCPA).
- Responsible crawling practices (rate limiting, non-destructive traffic loads).

---

## Credits

- [Playwright](https://playwright.dev/) by Microsoft for reliable browser automation.
- [Parsel](https://parsel.readthedocs.io/) & [Scrapy](https://scrapy.org/) by the Zyte / Scrapy team.
- [HTTPX](https://www.python-httpx.org/) & [Cheerio](https://cheerio.js.org/) for fast HTTP and DOM parsing.
- [curl_cffi](https://github.com/yifeikong/curl_cffi) for TLS fingerprint impersonation.
- [pdfplumber](https://github.com/jsvine/pdfplumber) for table extraction from PDF documents.

---

<div align="center">

**If ScrapeCraft helped your AI agent write clean, working scrapers, consider leaving a star.**

[![Star this repo](https://img.shields.io/github/stars/yanndevgbut/scrapecraft?style=for-the-badge&logo=github&color=2b3af6&label=Star%20ScrapeCraft)](https://github.com/yanndevgbut/scrapecraft)

Maintained by [@yanndevgbut](https://github.com/yanndevgbut)

</div>
