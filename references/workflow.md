# Workflow: ScrapeCraft Execution Flow

This document defines the 8-phase step-by-step execution flow for every scraping task.

## Phase 1: Receive & Clarify

1. Parse the user's request:
   - **Target URL** (required)
   - **Fields to extract** (e.g. title, price, SKU, images, date)
   - **Output format** (default: JSON; optional: JSONL, CSV)
   - **Language preference** (optional: Python or Node.js)
   - **Volume** (single page vs. multi-page crawl)

2. If any required parameter is missing, ask ONE brief clarifying question.

## Phase 2: Inspect Target & Sniff Architecture

1. Fetch target HTML and sniff network responses simultaneously:
   - **Step 2.1: Check Embedded State:** Inspect for `script#__NEXT_DATA__`, `__NUXT_DATA__`, or `script[type="application/ld+json"]` (see `references/state-extraction.md`).
   - **Step 2.2: Sniff Background APIs:** If page is dynamic SPA, check network panel for JSON REST / GraphQL endpoints (see `references/api-sniffing.md`).
   - **Step 2.3: Analyze HTML DOM:** If no state or API is exposed, inspect DOM structure, container elements, and multi-tier selectors (see `references/browser-inspection.md` and `references/resilient-selectors.md`).
   - **Step 2.4: Anti-Bot Audit:** Detect Cloudflare Turnstile, perimeter WAFs, or rate limiters (see `references/anti-detection.md`).

## Phase 3: Recommend Optimal Strategy

State the technical strategy in one definitive sentence:
- *Example (State)*: "Target is a Next.js application; I will extract structured data directly from `__NEXT_DATA__` using Python and httpx for maximum speed and stability."
- *Example (API)*: "Target loads items via an internal JSON REST endpoint; I will query the API directly using Python httpx."
- *Example (DOM)*: "Target is a static catalog; I will use Python with httpx, parsel, and multi-tier fallback selectors."

## Phase 4: Write Production Code

1. Initialize isolated sandbox:
   ```bash
   mkdir -p /tmp/scrapecraft_$(date +%s)
   ```

2. Generate code enforcing:
   - Standard CLI arguments (`--url`, `--format`, `--output`, `--delay`, `--max-pages`).
   - Resilient multi-tier selector arrays.
   - Built-in data normalizers (`clean_text`, `parse_price`, `resolve_url`).
   - Pure stdout streams (logging routed strictly to stderr).
   - Zero forbidden tokens (no mock arrays, no TODOs, no emojis).

## Phase 5: Execute in Sandbox

Run with process isolation and timeout:
```bash
timeout 45 python3 /tmp/scrapecraft_<session>/scraper.py > /tmp/scrapecraft_<session>/output.json 2> /tmp/scrapecraft_<session>/stderr.log
```

## Phase 6: Validate Output

Run `scripts/validate-output.sh`:
- Exit code equals `0`.
- Output is valid JSON/JSONL/CSV.
- Record count > 0.
- Missing field ratio < 50%.
- Zero relative URLs in extracted link fields.

## Phase 7: Linear Error Correction (If Needed)

If validation fails, execute `references/error-correction.md`:
- Maximum 3 iterations.
- Isolate root cause from stderr.
- Never wrap failing code in bare `except: pass`.

## Phase 8: Deliver to User

1. Output final code in clean markdown code block.
2. Provide dependency install and CLI run commands:
   ```bash
   pip install httpx parsel
   python3 scraper.py --format json --output results.json
   ```
3. State execution summary: records extracted, target type, and response latency.
4. Clean up temporary sandbox directory.
