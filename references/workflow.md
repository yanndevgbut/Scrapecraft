# Workflow: ScrapeCraft Execution Flow

This document defines the strict 8-phase execution lifecycle. **The AI agent is strictly forbidden from writing or generating code before all three requirement gates are resolved and the user has confirmed the technical stack.**

```
[ User Prompt with Target URL ]
               │
               ▼
┌──────────────────────────────────────────────────────────┐
│  Phase 1: REQUIREMENTS DISCOVERY - GATE 1 (Q1-Q3)        │
│  What data? How much? Which filters?                     │
│  [STOP] One question tool call, HALT for answers         │
└──────────────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────┐
│  Phase 2: Target Reconnaissance & Architecture Sniffing  │
│  (Silent: SSR state, APIs, DOM, anti-bot, bootstrap keys)│
└──────────────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────┐
│  Phase 3: RECON DOSSIER + GATE 2 (Q4-Q7)                 │
│  Language? Format? Stealth? Rate?                        │
│  [STOP] One question tool call, HALT for answers         │
└──────────────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────┐
│  Phase 4: RUNTIME EXPERIENCE - GATE 3 (Q8-Q10)           │
│  Interactive menu? Menu features? Logging?               │
│  [STOP] One question tool call, HALT for answers         │
└──────────────────────────────────────────────────────────┘
               │
               ▼ (All gates resolved)
┌──────────────────────────────────────────────────────────┐
│  Phase 5: Write Production Code                          │
│  (Menu mode, CLI mode, or mixed - per Gate 3 answers)    │
└──────────────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────┐
│  Phase 6: Isolated Sandbox Execution (45s timeout)       │
└──────────────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────┐
│  Phase 7: Automated Pre-Delivery Quality Validation      │
└──────────────────────────────────────────────────────────┘
               │
               ├─► [ Failed ] ── Linear correction (max 3 tries) ──┐
               │                                                   │
               ▼                                                   ▼
┌──────────────────────────────────────────────────────────┐  ┌────────────────┐
│  Phase 8: Deliver Tested Script + Run Instructions       │  │ Escalate Issue │
└──────────────────────────────────────────────────────────┘  └────────────────┘
```

Full question catalog with tool schemas: `references/requirements-gathering.md`.

---

## Phase 1: Receive & REQUIREMENTS DISCOVERY (GATE 1)

1. Parse the incoming request for the target URL.
2. **Ask Gate 1 questions in ONE `question` tool call** (see `references/requirements-gathering.md`):
   - **Q1 Data fields**: which fields to extract (present detected/expected fields; options: all / core identity / identity+metrics / identity+media / user-specified).
   - **Q2 Coverage**: single page / first N pages / all pages / infinite scroll.
   - **Q3 Filters**: none / category / sort order / search-driven.
3. Never re-ask what the user's original message already answered (e.g. "scrape titles and prices as CSV" pre-answers Q1 and part of Q5).
4. **HALT until answers arrive.**

---

## Phase 2: Target Reconnaissance & Architecture Sniffing

Perform silent, non-intrusive inspection of the target site:
- **Step 2.1: Check SSR Hydration State**: Inspect for `script#__NEXT_DATA__`, `__NUXT_DATA__`, `window.__INITIAL_STATE__`, or Schema.org JSON-LD (see `references/state-extraction.md`).
- **Step 2.2: Sniff Background APIs**: Check network panel for internal REST or GraphQL JSON endpoints (see `references/api-sniffing.md` and `references/graphql-scraping.md`).
- **Step 2.3: Bootstrap Audit**: For session-based APIs (Innertube-style), check homepage for embedded API keys, client context, visitor tokens (see `references/internal-api-bootstrap.md`).
- **Step 2.4: Analyze HTML DOM**: If no state or API is exposed, inspect DOM structure, container elements, and multi-tier selectors (see `references/browser-inspection.md` and `references/resilient-selectors.md`).
- **Step 2.5: Anti-Bot Audit**: Detect Cloudflare Turnstile, perimeter WAFs, or rate limiters (see `references/anti-detection.md` and `references/anti-blocking-checklist.md`).
- **Step 2.6: Unknown JSON payloads**: Map tree structure with `python3 scripts/json-explorer.py --url <endpoint> --renderers` before designing parsers.

---

## Phase 3: RECON DOSSIER + TECHNICAL STACK (GATE 2)

**CRITICAL RULE: The AI agent MUST STOP here. Do NOT write code yet.**

1. Output the **Reconnaissance Dossier** (see `references/recon-report.md`).
2. **Ask Gate 2 questions in ONE `question` tool call**:
   - **Q4 Language**: with 1-sentence recommendation and reason (Python / Node.js).
   - **Q5 Output format**: JSON / JSONL / CSV / SQLite / stdout.
   - **Q6 Stealth level**: standard headers / TLS impersonation / +auto-proxy rotation / stealth browser (escalate recommendation if recon found WAF).
   - **Q7 Request rate**: safe (2-3s + jitter) / normal (1s) / fast (0.3s).
3. **HALT until answers arrive.**

---

## Phase 4: RUNTIME EXPERIENCE (GATE 3)

**Ask Gate 3 questions in ONE `question` tool call**:

1. **Q8 Interactive menu**: full menu / CLI args only / both (menu when no args).
2. **Q9 Menu features** (skip silently if Q8 = CLI only): search loop / filter switch / item detail / export / crawl mode.
3. **Q10 Logging**: normal / debug verbose / quiet.
4. **HALT until answers arrive.**

Default protocol if the user explicitly declines questions ("you decide"): apply defaults (all fields, full pagination, recommended language, JSON, standard stealth - escalate if WAF, safe rate, CLI-only, normal logging) and state them in one sentence.

---

## Phase 5: Write Production Code

Only after ALL gates are resolved:

1. Initialize isolated sandbox:
   ```bash
   mkdir -p /tmp/scrapecraft_$(date +%s)
   ```
2. Generate code enforcing:
   - **Mode per Gate 3**: interactive menu loop (`references/interactive-cli-menu.md`), CLI-only, or mixed dispatcher.
   - Class-based session architecture for API-backed targets (`references/multi-endpoint-orchestration.md`), with bootstrap in `init()` (`references/internal-api-bootstrap.md`) and consistent client identity (`references/client-identity-spoofing.md`).
   - Standard CLI arguments (`--url`, `--query`, `--format`, `--output`, `--delay`, `--max-pages`).
   - Explicit timeouts: 30s HTTP, 45s browser. No timeout = bug.
   - Self-healing multi-tier fallback selectors (see `references/self-healing-code.md`).
   - Deep JSON parsing with per-item isolation and dedup (see `references/json-tree-parsing.md`).
   - Built-in data normalizers (`clean_text`, `parse_price`, `resolve_url`).
   - Pure stdout data streams; all diagnostics to stderr.
   - Logging mode per Q10; zero forbidden tokens (no mock arrays, no TODOs, no emojis).

---

## Phase 6: Execute in Sandbox

Run with process isolation and timeout (CLI arguments forwarded):
```bash
bash scripts/sandbox-run.sh 45 /tmp/scrapecraft_<session>/scraper.py --url "https://target.com" > /tmp/scrapecraft_<session>/output.json 2> /tmp/scrapecraft_<session>/stderr.log
```

---

## Phase 7: Validate Output

Run `scripts/validate-output.sh`:
- Exit code equals `0`.
- Output is valid JSON/JSONL/CSV.
- Record count > 0.
- Missing field ratio < 50%.
- 100% of extracted URLs are absolute HTTPS links.
- Zero unescaped HTML entities.

---

## Phase 8: Linear Error Correction (If Needed)

If validation fails, execute `references/error-correction.md`:
- Maximum 3 iterations.
- Isolate root cause from stderr (now fully visible, never suppressed).
- Unknown payload shapes: re-map with `scripts/json-explorer.py` before touching parser code.
- Never wrap failing code in bare `except: pass`.

---

## Phase 9: Deliver to User

1. Output the final, tested code in a clean markdown code block.
2. Provide dependency install and CLI execution commands:
   ```bash
   pip install -r requirements.txt
   python3 scraper.py                 # interactive menu (per Gate 3)
   python3 scraper.py search "query"  # CLI mode (mixed mode build)
   ```
3. Provide execution telemetry: records extracted, target type, and response latency.
4. Clean up temporary sandbox directory.
