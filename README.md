<div align="center">

<img src="assets/banner.jpg" alt="ScrapeCraft" width="640">

# ScrapeCraft

**A high-precision, production-grade web scraping AI agent skill.**

Eliminates selector hallucinations, simulated mock data, nested try-catch masking, and circular reasoning loops in AI-generated scrapers. Built for terminal-ready execution with live DOM inspection and sandboxed self-correction.

[![Stars](https://img.shields.io/github/stars/anomalyco/scrapecraft?style=flat-square&color=2b3af6)](https://github.com/anomalyco/scrapecraft/stargazers)
[![Forks](https://img.shields.io/github/forks/anomalyco/scrapecraft?style=flat-square&color=2b3af6)](https://github.com/anomalyco/scrapecraft/network/members)
[![Issues](https://img.shields.io/github/issues/anomalyco/scrapecraft?style=flat-square)](https://github.com/anomalyco/scrapecraft/issues)
[![Last Commit](https://img.shields.io/github/last-commit/anomalyco/scrapecraft?style=flat-square)](https://github.com/anomalyco/scrapecraft/commits)
[![Repo Size](https://img.shields.io/github/repo-size/anomalyco/scrapecraft?style=flat-square)](https://github.com/anomalyco/scrapecraft)
[![License](https://img.shields.io/github/license/anomalyco/scrapecraft?style=flat-square)](LICENSE)

[Overview](#overview) · [What's Inside](#whats-inside) · [Structure](#repository-structure) · [Installation](#installation) · [Workflow](#execution-workflow) · [Capabilities](#capabilities--stacks) · [Quality Policy](#quality--accuracy-policy) · [Contributing](#contributing)

</div>

---

## Overview

AI coding agents frequently generate fragile, non-functional web scraping scripts. They guess DOM selectors without inspecting real pages, inject mock data or placeholder variables (`TODO`, `your_api_key`), pollute code with emojis and decorative comments, wrap failing logic in nested `try-except: pass` blocks, and become trapped in circular reasoning when encountering anti-bot mechanisms.

**ScrapeCraft resolves this completely.** It is a modular skill and knowledge pack engineered for AI coding agents (OpenCode, Claude Code, Codex, Antigravity, Cursor) that enforces the discipline of a **Senior Web Scraping Engineer**:

- **Real-Time DOM Inspection**: Derives 100% of selectors from live DOM snapshots rather than training-data hallucination.
- **Production-Ready Code**: Generates clean, robust Python and Node.js scrapers with explicit error handling and structured JSON/CSV output.
- **Sandboxed Verification**: Executes draft code inside an isolated local runtime (`/tmp/scrapecraft_<session>/`) with strict 45-second timeout constraints.
- **Deterministic Self-Correction**: Enforces a strict linear correction protocol (maximum 3 iterations) with fail-fast escalation when encountering structural blockers.
- **Zero Simulation**: Permanently bans mock datasets, placeholder tokens, and decorative comments from final output.

---

## What's Inside

| Layer | Component | Description |
|---|---|---|
| `SKILL.md` | Master System Prompt | Core agent instructions, persona enforcement, forbidden token filters, tool permissions, and reference routing |
| `references/` | Task Playbooks | 7 drill-down engineering specifications loaded on demand to conserve context window |
| `scripts/` | Execution Tooling | Native bash sandbox runner with process isolation and output quality verification scripts |
| `install.sh` | Universal Installer | One-command installation script supporting all standard agent skill directories |
| `assets/` | Visual Assets | Repository branding and visual documentation artifacts |

### Reference Playbook Details

- **`references/workflow.md`**: 8-phase execution lifecycle from request clarification to sandboxed delivery.
- **`references/browser-inspection.md`**: Protocol for headless browser DOM extraction, selector stability hierarchy, and API interception.
- **`references/python-scraping.md`**: Production templates for `httpx`, `parsel`, `selectolax`, `playwright`, and `scrapy`.
- **`references/nodejs-scraping.md`**: Production templates for `playwright`, `puppeteer`, `cheerio`, `axios`, and `got`.
- **`references/anti-detection.md`**: Evasion patterns for Cloudflare challenges, TLS JA3/JA4 fingerprinting via `curl_cffi`, and browser stealth flags.
- **`references/validation.md`**: 6-step automated validation pipeline checking exit codes, JSON validity, data density, and token hygiene.
- **`references/error-correction.md`**: Linear self-correction protocol with bounded iteration budgets and diagnostic escalation schemas.

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
├── references/                       # Subsystem playbooks (loaded on demand)
│   ├── workflow.md                   # 8-phase linear execution lifecycle
│   ├── browser-inspection.md         # Live DOM analysis & selector hierarchy
│   ├── python-scraping.md            # Python architectures (httpx, parsel, playwright)
│   ├── nodejs-scraping.md            # Node.js architectures (playwright, cheerio, axios)
│   ├── anti-detection.md             # Evasion strategies (TLS impersonation, stealth)
│   ├── validation.md                 # 6-stage pre-delivery quality pipeline
│   └── error-correction.md           # Linear self-correction rules (max 3 iterations)
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
npx skills add <owner>/scrapecraft
```

#### Option B: Via Bundled Universal Installer

```bash
git clone https://github.com/<owner>/scrapecraft.git
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

Claude Code auto-discovers skills placed in user or project skill directories:

```bash
# Global
git clone https://github.com/<owner>/scrapecraft.git ~/.claude/skills/scrapecraft

# Per-project
git clone https://github.com/<owner>/scrapecraft.git .claude/skills/scrapecraft
```

Verify the skill inside a Claude Code session by typing `/skills`.

#### OpenCode

OpenCode scans configured skill paths and native directories automatically:

```bash
# Global
git clone https://github.com/<owner>/scrapecraft.git ~/.config/opencode/skills/scrapecraft

# Per-project
git clone https://github.com/<owner>/scrapecraft.git .opencode/skills/scrapecraft
```

OpenCode loads ScrapeCraft on demand via the native `skill({ name: "scrapecraft" })` call.

#### Codex (OpenAI)

Clone into your workspace and reference via `AGENTS.md`:

```bash
git clone https://github.com/<owner>/scrapecraft.git .agents/skills/scrapecraft
```

Add the following block to your `AGENTS.md` (or `~/.codex/AGENTS.md`):

```markdown
## ScrapeCraft

When a task involves web scraping, data extraction, HTML parsing, or building crawlers,
read `.agents/skills/scrapecraft/SKILL.md` first and follow its execution workflow.
Always inspect the target DOM before writing selectors and test code in a sandbox before delivery.
```

#### Antigravity (Google)

Install to `.agents/skills/scrapecraft` and add the pointer snippet to your `GEMINI.md` or `AGENTS.md`:

```bash
git clone https://github.com/<owner>/scrapecraft.git .agents/skills/scrapecraft
```

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
┌──────────────────────┐
│  1. Receive & Parse  │ ── Extract URL, target fields, output schema, and volume
└──────────────────────┘
       │
       ▼
┌──────────────────────┐
│  2. Inspect Target   │ ── Live DOM snapshot via headless browser / HTTP probe
└──────────────────────┘
       │
       ▼
┌──────────────────────┐
│  3. Recommend Stack  │ ── 1-sentence technical justification (Python vs Node.js)
└──────────────────────┘
       │
       ▼
┌──────────────────────┐
│  4. Write Code       │ ── Production-ready script using exact DOM selectors
└──────────────────────┘
       │
       ▼
┌──────────────────────┐
│  5. Sandbox Run      │ ── Execute in /tmp/scrapecraft_<id>/ (timeout: 45s)
└──────────────────────┘
       │
       ▼
┌──────────────────────┐
│  6. Validate Output  │ ── Check exit code 0, non-empty data, JSON validity
└──────────────────────┘
       │
       ├─► [ Failed ] ── Linear correction (max 3 attempts) ──┐
       │                                                      │
       ▼                                                      ▼
┌──────────────────────┐                             ┌──────────────────┐
│  7. Deliver Code     │                             │  Escalate Issue  │
└──────────────────────┘                             └──────────────────┘
```

---

## Capabilities & Stacks

### Python Scraping Ecosystem

| Library | Role | Primary Use Case |
|---|---|---|
| `httpx` + `parsel` | Fast HTTP Parser | Default recommendation for static web pages and high-concurrency jobs |
| `selectolax` | C-Engine Parser | Ultra-high-speed parsing for large HTML documents |
| `playwright` | Headless Browser | Single-Page Applications (SPAs), hydration-dependent DOMs, dynamic scrolling |
| `curl_cffi` | TLS Impersonation | Bypassing JA3/JA4 TLS fingerprinting and Cloudflare JS challenges |
| `scrapy` | Enterprise Framework | Large-scale multi-tier crawling with middleware pipelines |

### Node.js Scraping Ecosystem

| Library | Role | Primary Use Case |
|---|---|---|
| `cheerio` + `axios` | Fast HTTP Parser | Lightweight, high-throughput extraction for static HTML |
| `playwright` | Headless Engine | Multi-browser automation (Chromium, Firefox, WebKit) with network interception |
| `puppeteer` | Chrome Engine | Direct Chrome DevTools Protocol (CDP) manipulation and extraction |
| `got` | Advanced HTTP | Resilient HTTP streaming, automatic retries, and pagination |

### Anti-Detection Capabilities

| Threat Vector | Mitigation Strategy | Reference Implementation |
|---|---|---|
| **TLS Fingerprinting** | Chrome 131 JA3/JA4 cipher suite impersonation | `curl_cffi` impersonate engine |
| **Automation Flags** | Mask `navigator.webdriver`, mock `navigator.plugins` | Playwright init scripts & launch flags |
| **Rate Limiting (429)** | Jittered exponential delay scheduling (`1.5s - 3.5s`) | Built-in sleep and backoff loops |
| **Dynamic SPAs** | `networkidle` lifecycle event synchronization | Playwright explicit wait strategies |

---

## Quality & Accuracy Policy

### Forbidden Tokens (`FORBIDDEN_TOKENS`)

ScrapeCraft strictly prohibits the following patterns in all generated scripts and agent outputs:

| Violation Category | Forbidden Patterns | Enforced Standard |
|---|---|---|
| **Mock Data** | `mock_data`, `sample_data`, `fake_`, `dummy_`, `test_data` | All data must come from real DOM extraction |
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
5. **Output Integrity**: Valid JSON array/object structure written to standard output.

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

---

<div align="center">

**If ScrapeCraft helped your AI agent write clean, working scrapers, consider leaving a star.**

[![Star this repo](https://img.shields.io/github/stars/anomalyco/scrapecraft?style=for-the-badge&logo=github&color=2b3af6&label=Star%20ScrapeCraft)](https://github.com/anomalyco/scrapecraft)

</div>
