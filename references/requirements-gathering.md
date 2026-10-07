# Requirements Gathering & Discovery Questionnaire

Before writing any scraper code, the ScrapeCraft Virtual Engineering Team must complete a structured **Requirements Discovery** process. The goal: the generated scraper matches exactly what the user wants, not what the AI assumes.

---

## The 3-Gate Requirements Model

```
[ User Request: "scrape X from Y" ]
              │
              ▼
┌─────────────────────────────────────────┐
│ GATE 1: DATA REQUIREMENTS               │
│ Q1-Q3: What data, how much, which scope │
│ (Asked immediately, BEFORE deep recon)  │
└─────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│ [Silent Target Reconnaissance]          │
│ SSR state, APIs, DOM, anti-bot audit    │
└─────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│ GATE 2: TECHNICAL STACK                 │
│ Q4-Q7: Language, format, stealth, rate  │
│ (With Reconnaissance Dossier)           │
└─────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│ GATE 3: RUNTIME EXPERIENCE              │
│ Q8-Q10: Interactive menu, features, log │
│ (Before writing code)                   │
└─────────────────────────────────────────┘
              │
              ▼
      [ Write Production Code ]
```

**Golden Rule**: Send all questions of a gate in ONE `question` tool call (multi-question array). Never ask one question at a time. Never skip a gate.

---

## GATE 1: Data Requirements (Q1-Q3)

Ask immediately after parsing the user request, before deep reconnaissance.

### Q1: What to Scrape? (Data Fields Selection)

Present the fields you detected or expect on the target:

```json
{
  "questions": [
    {
      "header": "Data Fields",
      "question": "Which data fields do you want to extract from the target?",
      "multiple": true,
      "options": [
        { "label": "All available fields (Recommended)", "description": "Extract every field detected: title, artist, album, price, rating, etc." },
        { "label": "Core identity fields", "description": "Title, ID/URL, and primary classification only." },
        { "label": "Identity + metrics", "description": "Title, ID, plus counts (views, plays, rating, review count)." },
        { "label": "Identity + media", "description": "Title, ID, plus thumbnail/image URLs." },
        { "label": "Let me specify", "description": "You list the exact fields you need in your reply." }
      ]
    }
  ]
}
```

### Q2: Data Coverage / Volume

```json
{
  "questions": [
    {
      "header": "Coverage",
      "question": "How much data should the scraper collect?",
      "multiple": false,
      "options": [
        { "label": "Single page / first batch only", "description": "One request, fastest, good for quick tests." },
        { "label": "First N pages (specify count)", "description": "Crawl a limited number of pages, e.g. 5 pages." },
        { "label": "All pages (auto-stop at end)", "description": "Full pagination traversal with automatic stop detection." },
        { "label": "Infinite scroll until stopped", "description": "Continuous scroll collection with stall detection." }
      ]
    }
  ]
}
```

### Q3: Filters / Categories

```json
{
  "questions": [
    {
      "header": "Filters",
      "question": "Do you need specific filters, categories, or search parameters?",
      "multiple": true,
      "options": [
        { "label": "No filter, everything", "description": "Collect all results as-is." },
        { "label": "Category filter (e.g. songs/albums/videos)", "description": "Target provides category tabs or params." },
        { "label": "Sort order (newest/cheapest/rating)", "description": "Apply sorting parameters to results." },
        { "label": "Search query driven", "description": "Scraper accepts a --query argument to search." }
      ]
    }
  ]
}
```

---

## GATE 2: Technical Stack (Q4-Q7)

Ask together with the Reconnaissance Dossier presentation.

### Q4: Language Selection (with recommendation)

```json
{
  "questions": [
    {
      "header": "Language",
      "question": "Recon findings: [TARGET_TYPE]. I recommend [RECOMMENDED] because [REASON]. Which language?",
      "multiple": false,
      "options": [
        { "label": "Python (Recommended)", "description": "httpx/parsel/playwright - fast SSR parsing, rich scraping ecosystem." },
        { "label": "Node.js (JavaScript)", "description": "got-scraping/cheerio/playwright - JS-native, good for npm projects." }
      ]
    }
  ]
}
```

### Q5: Output Format

```json
{
  "questions": [
    {
      "header": "Output Format",
      "question": "In what format should the scraped data be saved?",
      "multiple": false,
      "options": [
        { "label": "JSON (Recommended)", "description": "Structured array file, universal, easy to post-process." },
        { "label": "JSONL (JSON Lines)", "description": "One record per line, streaming-friendly for big datasets." },
        { "label": "CSV / Excel", "description": "Spreadsheet-compatible flat table with headers." },
        { "label": "SQLite database", "description": "Queryable local database with dedup support." },
        { "label": "stdout only", "description": "Print to terminal, no file written." }
      ]
    }
  ]
}
```

### Q6: Stealth Level

```json
{
  "questions": [
    {
      "header": "Stealth Level",
      "question": "Anti-bot detection level needed for this target?",
      "multiple": false,
      "options": [
        { "label": "Standard headers (Recommended if open)", "description": "Realistic User-Agent, sec-ch-ua, sec-fetch headers." },
        { "label": "TLS impersonation", "description": "curl_cffi (Python) / got-scraping (Node.js) for WAF-protected targets." },
        { "label": "TLS + auto-proxy rotation", "description": "Adds 60-source proxy aggregator with live health-checks." },
        { "label": "Full stealth browser", "description": "Playwright with stealth flags, route aborting, fingerprint masking." }
      ]
    }
  ]
}
```

### Q7: Request Rate / Politeness

```json
{
  "questions": [
    {
      "header": "Request Rate",
      "question": "How aggressive should the request pacing be?",
      "multiple": false,
      "options": [
        { "label": "Safe (2-3s + random jitter, Recommended)", "description": "Human-like pacing, minimal block risk." },
        { "label": "Normal (1s)", "description": "Balanced speed and safety." },
        { "label": "Fast (0.3s)", "description": "High throughput, higher 429 risk, needs proxy rotation." }
      ]
    }
  ]
}
```

---

## GATE 3: Runtime Experience (Q8-Q10)

Ask before writing code. Q8 changes the entire shape of the deliverable.

### Q8: Interactive Menu

```json
{
  "questions": [
    {
      "header": "Interactive Menu",
      "question": "Should the scraper have an interactive menu when you run it in the terminal?",
      "multiple": false,
      "options": [
        { "label": "Yes, full interactive menu (Recommended)", "description": "Numbered menu at runtime: choose action, enter query, pick filters, export results." },
        { "label": "CLI arguments only", "description": "No prompts; configure via --url/--query/--format flags." },
        { "label": "Both (menu if no args, CLI if args)", "description": "Interactive mode when run without arguments, CLI mode when flags given." }
      ]
    }
  ]
}
```

### Q9: Menu Features (ask only if Q8 = interactive)

```json
{
  "questions": [
    {
      "header": "Menu Features",
      "question": "Which features should the interactive menu include?",
      "multiple": true,
      "options": [
        { "label": "Search / re-search loop", "description": "Enter new queries without restarting the script." },
        { "label": "Filter / category switching", "description": "Change category or filter between searches." },
        { "label": "Item detail view", "description": "Pick a result number to see full details." },
        { "label": "Export results (json/csv)", "description": "Save current result set to file from the menu." },
        { "label": "Continuous crawl mode", "description": "Menu option to run full multi-page collection." }
      ]
    }
  ]
}
```

### Q10: Logging Verbosity

```json
{
  "questions": [
    {
      "header": "Logging",
      "question": "How verbose should runtime logging be?",
      "multiple": false,
      "options": [
        { "label": "Normal progress (Recommended)", "description": "Status lines: page progress, request counts, final summary." },
        { "label": "Debug verbose", "description": "Request URLs, payload previews, response keys, parse diagnostics." },
        { "label": "Quiet (results only)", "description": "Silent except errors; data only." }
      ]
    }
  ]
}
```

---

## Question Grouping Rules

1. **One gate = one `question` tool call.** Q1+Q2+Q3 in a single call. Q4+Q5+Q6+Q7 in a single call. Q8+Q9+Q10 in a single call.
2. **Skip logic is allowed**: If Q8 answer is "CLI arguments only", drop Q9 silently and do not ask it.
3. **Defaults when user says "just do it"**: If the user explicitly declines questions ("you decide", "whatever works"), apply defaults: all fields, full pagination, no filter, recommended language, JSON output, standard stealth (escalate if recon shows WAF), safe rate, CLI args only, normal logging. State the applied defaults in one sentence.
4. **Never re-ask** a question the user already answered in their original request (e.g. "scrape titles and prices as CSV" pre-answers Q1 and Q5).

---

## Example Complete Dialog

```
USER: "scrape lagu-lagu dari youtube music"

AGENT (Gate 1, one question call):
  Q1 fields, Q2 coverage, Q3 filters

USER: "semua field, 1 halaman per search, search driven"

AGENT: [recon: menemukan Innertube API + WEB_REMIX client, tanpa WAF]

AGENT (Gate 2, one question call):
  Q4 language, Q5 format, Q6 stealth, Q7 rate

USER: "Node.js, JSON, standard, fast"

AGENT (Gate 3, one question call):
  Q8 menu, Q9 features, Q10 logging

USER: "menu interaktif penuh, semua fitur, debug verbose"

AGENT: [menulis class-based session scraper dengan menu readline,
        menjalankan sandbox test, validasi, deliver]
```

---

## Violation Protocol

Writing code with any unanswered gate:
- Gate 1 unanswered = wrong data shape guaranteed.
- Gate 2 unanswered = wrong language/format risk.
- Gate 3 unanswered = deliverable shape mismatch (user wanted a menu, got a bare CLI).

Any violation: halt, discard draft, return to the unanswered gate.
