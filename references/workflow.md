# Workflow: ScrapeCraft Execution Flow

This document defines the strict 8-phase execution lifecycle. **The AI agent is strictly forbidden from writing or generating code before Phase 3 is completed and the user selects/confirms the programming language.**

```
[ User Prompt with Target URL ]
               │
               ▼
┌──────────────────────────────────────────────────────────┐
│  Phase 1: Parse & Clarify Extraction Requirements        │
└──────────────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────┐
│  Phase 2: Target Reconnaissance & Architecture Sniffing  │
└──────────────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────┐
│  Phase 3: MANDATORY RECON DOSSIER & LANGUAGE GATE        │
│                                                          │
│  1. Present Reconnaissance Dossier findings.             │
│  2. State 1-sentence technical recommendation.           │
│  3. PROMPT USER: "Which language would you like to use?" │
│     - Python (Recommended)                               │
│     - Node.js (JavaScript)                               │
│                                                          │
│  [STOP] HALT EXECUTION: DO NOT WRITE CODE BEFORE USER ANSWERS │
└──────────────────────────────────────────────────────────┘
               │
               ▼ (User confirms/selects language)
┌──────────────────────────────────────────────────────────┐
│  Phase 4: Write Production CLI Code                      │
└──────────────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────┐
│  Phase 5: Isolated Local Sandbox Execution (45s timeout) │
└──────────────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────┐
│  Phase 6: Automated Pre-Delivery Quality Validation      │
└──────────────────────────────────────────────────────────┘
               │
               ├─► [ Failed ] ── Linear correction (max 3 tries) ──┐
               │                                                   │
               ▼                                                   ▼
┌──────────────────────────────────────────────────────────┐  ┌────────────────┐
│  Phase 7: Deliver Tested Production Script & Run Command │  │ Escalate Issue │
└──────────────────────────────────────────────────────────┘  └────────────────┘
```

---

## Phase 1: Receive & Clarify

1. Parse the incoming request for:
   - **Target URL** (required)
   - **Fields to extract** (e.g. title, price, SKU, variants, dates, links)
   - **Output format** (default: JSON; optional: JSONL, CSV, SQLite)
   - **Volume** (single page vs. multi-page crawl)
2. If any critical parameter is ambiguous, ask ONE brief clarifying question.

---

## Phase 2: Target Reconnaissance & Architecture Sniffing

Perform silent, non-intrusive inspection of the target site:
- **Step 2.1: Check SSR Hydration State**: Inspect for `script#__NEXT_DATA__`, `__NUXT_DATA__`, `window.__INITIAL_STATE__`, or Schema.org JSON-LD (see `references/state-extraction.md`).
- **Step 2.2: Sniff Background APIs**: Check network panel for internal REST or GraphQL JSON endpoints (see `references/api-sniffing.md` and `references/graphql-scraping.md`).
- **Step 2.3: Analyze HTML DOM**: If no state or API is exposed, inspect DOM structure, container elements, and multi-tier selectors (see `references/browser-inspection.md` and `references/resilient-selectors.md`).
- **Step 2.4: Anti-Bot Audit**: Detect Cloudflare Turnstile, perimeter WAFs, or rate limiters (see `references/anti-detection.md` and `references/anti-blocking-checklist.md`).

---

## Phase 3: MANDATORY RECON DOSSIER & LANGUAGE SELECTION GATE

**CRITICAL RULE: The AI agent MUST STOP here. Do NOT write code yet.**

1. Output the **Reconnaissance Dossier** (see `references/recon-report.md`).
2. Provide a clear technical recommendation with rationale.
3. **Ask the user which language they prefer**:
   - If interactive tool `question` is available: Call `question` with options `Python (Recommended)` and `Node.js (JavaScript)`.
   - If in standard terminal: Print the recommendation and prompt the user directly:
     ```text
     "Based on my inspection, I recommend Python (httpx + parsel) because [technical reason]. 
     Which language would you prefer to use?
     1. Python (Recommended)
     2. Node.js (JavaScript)"
     ```
4. **Wait for user confirmation or choice before proceeding to Phase 4.**

---

## Phase 4: Write Production Code

Only after the user selects or confirms the language, the Core Developer writes the code:
1. Initialize isolated sandbox:
   ```bash
   mkdir -p /tmp/scrapecraft_$(date +%s)
   ```
2. Generate code enforcing:
   - Standard CLI arguments (`--url`, `--format`, `--output`, `--delay`, `--max-pages`).
   - Self-healing multi-tier fallback selectors (see `references/self-healing-code.md`).
   - Built-in data normalizers (`clean_text`, `parse_price`, `resolve_url`).
   - Pure stdout data streams (logging strictly directed to stderr).
   - Zero forbidden tokens (no mock arrays, no TODOs, no emojis).

---

## Phase 5: Execute in Sandbox

Run with process isolation and timeout:
```bash
timeout 45 python3 /tmp/scrapecraft_<session>/scraper.py > /tmp/scrapecraft_<session>/output.json 2> /tmp/scrapecraft_<session>/stderr.log
```

---

## Phase 6: Validate Output

Run `scripts/validate-output.sh`:
- Exit code equals `0`.
- Output is valid JSON/JSONL/CSV.
- Record count > 0.
- Missing field ratio < 50%.
- 100% of extracted URLs are absolute HTTPS links.
- Zero unescaped HTML entities.

---

## Phase 7: Linear Error Correction (If Needed)

If validation fails, execute `references/error-correction.md`:
- Maximum 3 iterations.
- Isolate root cause from stderr.
- Never wrap failing code in bare `except: pass`.

---

## Phase 8: Deliver to User

1. Output the final, tested code in a clean markdown code block.
2. Provide dependency install and CLI execution commands:
   ```bash
   pip install httpx parsel
   python3 scraper.py --format json --output results.json
   ```
3. Provide execution telemetry: records extracted, target type, and response latency.
4. Clean up temporary sandbox directory.
