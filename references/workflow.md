# Workflow: ScrapeCraft Execution Flow

This document defines the step-by-step execution flow for every scraping task.

## Phase 1: Receive & Clarify

1. Parse the user's request to extract:
   - **Target URL** (required)
   - **Data to extract** (required: what fields/elements the user wants)
   - **Output format** (default: JSON to stdout)
   - **Language preference** (optional: Python or Node.js)
   - **Volume** (single page vs. multi-page crawl)

2. If any required parameter is missing, ask the user ONE clarifying question. Do not ask multiple questions or present long option lists.

## Phase 2: Inspect Target

1. Fetch the target URL using the most appropriate method:
   - **Static pages**: Use `WebFetch` or `curl -s` to retrieve raw HTML.
   - **Dynamic pages (JS-rendered)**: Use headless browser via `playwright` or a companion browser skill.
   - See `references/browser-inspection.md` for detailed inspection procedures.

2. From the fetched content, extract:
   - Page title and meta information.
   - DOM structure around the target data (container elements, repeating patterns).
   - Exact CSS selectors or XPath expressions for each data field.
   - Whether the page requires JavaScript rendering.
   - Whether anti-bot measures are present (Cloudflare challenge page, CAPTCHA tokens, WAF signatures).

3. Store the DOM snapshot mentally. Every selector you write MUST trace back to this snapshot.

## Phase 3: Recommend Stack

Based on the inspection results, recommend the technology stack:

- State the recommendation in one definitive sentence.
- Wait for user acknowledgment before proceeding. If the user disagrees, adapt immediately.

Example: "This is a JS-rendered SPA with infinite scroll; I will use Python with Playwright for reliable dynamic content extraction."

## Phase 4: Write Code

1. Create the sandbox directory:
   ```bash
   mkdir -p /tmp/scrapecraft_$(date +%s)
   ```

2. Write the scraping script following these rules:
   - Import only what you use.
   - Use descriptive variable names (`product_cards`, `price_element`, not `x`, `el`, `d`).
   - Structure the code as a single executable script with a `main()` function.
   - Include a proper shebang line (`#!/usr/bin/env python3` or `#!/usr/bin/env node`).
   - Output results as structured JSON to stdout by default.
   - Handle HTTP errors explicitly (check status codes, report failures clearly).
   - Include a `User-Agent` header that mimics a real browser.
   - Add request timeouts (30 seconds for HTTP, 45 seconds for browser operations).

3. See language-specific playbooks:
   - Python: `references/python-scraping.md`
   - Node.js: `references/nodejs-scraping.md`

## Phase 5: Execute in Sandbox

1. Install dependencies if needed:
   - Python: `pip install <package> --quiet`
   - Node.js: `npm install <package> --save --silent`

2. Run the script with timeout enforcement:
   ```bash
   timeout 45 python3 /tmp/scrapecraft_<session>/scraper.py
   ```

3. Capture both stdout and stderr.

## Phase 6: Validate

Run validation checks (see `references/validation.md`):

- Exit code is 0.
- Stdout contains non-empty output.
- Output is valid JSON (or valid CSV if specified).
- Data fields are not null/empty strings.
- Number of extracted records matches expected range.

## Phase 7: Fix (If Needed)

If validation fails, enter the correction loop (see `references/error-correction.md`):

- **Max 3 iterations.** No exceptions.
- Each iteration must address a DIFFERENT root cause.
- If the same error persists after 2 attempts, the issue is structural. Report it to the user.

## Phase 8: Deliver

1. Present the final, tested code to the user in a code block.
2. Include execution instructions:
   ```
   # Install dependencies
   pip install httpx parsel

   # Run
   python3 scraper.py
   ```
3. State what the code does in one sentence.
4. State the number of records extracted in the test run.
5. Clean up the sandbox directory.
