# Interactive Question Protocol & User Decision Gates

ScrapeCraft enforces a strict **Human-in-the-Loop Confirmation** system through three structured gates. The AI agent is **strictly prohibited from writing, scaffolding, or executing code immediately** without completing all gates. The full question catalog lives in `references/requirements-gathering.md`; this document defines the tool mechanics.

---

## 1. The Three-Gate Model Overview

```
GATE 1: DATA REQUIREMENTS (Q1-Q3)      -> immediately after parsing the request
GATE 2: TECHNICAL STACK (Q4-Q7)        -> with the Reconnaissance Dossier
GATE 3: RUNTIME EXPERIENCE (Q8-Q10)    -> before writing code

Each gate = ONE question tool call containing ALL of the gate's questions.
HALT after every gate until the user answers.
```

---

## 2. Using the Host Agent `question` Tool

When operating inside an agent runtime equipped with the `question` tool (OpenCode / Claude Code / Antigravity interactive harnesses):

### Gate 1 Tool Call Specification (Data Requirements)

```json
{
  "questions": [
    {
      "header": "Data Fields",
      "question": "Which data fields do you want to extract from the target?",
      "multiple": true,
      "options": [
        { "label": "All available fields (Recommended)", "description": "Extract every detected field." },
        { "label": "Core identity fields", "description": "Title, ID/URL, primary classification." },
        { "label": "Identity + metrics", "description": "Add counts: views, plays, rating." },
        { "label": "Identity + media", "description": "Add thumbnail/image URLs." },
        { "label": "Let me specify", "description": "List exact fields in your reply." }
      ]
    },
    {
      "header": "Coverage",
      "question": "How much data should the scraper collect?",
      "multiple": false,
      "options": [
        { "label": "Single page / first batch", "description": "One request, fastest." },
        { "label": "First N pages", "description": "Limited pagination count." },
        { "label": "All pages (auto-stop)", "description": "Full traversal with end detection." },
        { "label": "Infinite scroll", "description": "Continuous with stall detection." }
      ]
    },
    {
      "header": "Filters",
      "question": "Do you need specific filters or categories?",
      "multiple": true,
      "options": [
        { "label": "No filter, everything", "description": "Collect results as-is." },
        { "label": "Category filter", "description": "e.g. songs/albums/videos tabs." },
        { "label": "Sort order", "description": "newest/cheapest/rating." },
        { "label": "Search query driven", "description": "Scraper accepts --query argument." }
      ]
    }
  ]
}
```

### Gate 2 Tool Call Specification (Technical Stack)

```json
{
  "questions": [
    {
      "header": "Language",
      "question": "Recon: [TARGET_TYPE]. I recommend [RECOMMENDED_LANGUAGE] ([LIBRARIES]) because [TECHNICAL_REASON]. Which language?",
      "multiple": false,
      "options": [
        { "label": "Python (Recommended)", "description": "httpx, parsel, pydantic - fast, robust execution." },
        { "label": "Node.js (JavaScript)", "description": "got-scraping, cheerio, playwright - JS-native." }
      ]
    },
    {
      "header": "Output Format",
      "question": "In what format should the scraped data be saved?",
      "multiple": false,
      "options": [
        { "label": "JSON (Recommended)", "description": "Structured array file." },
        { "label": "JSONL (JSON Lines)", "description": "Streaming-friendly, one record per line." },
        { "label": "CSV / Excel", "description": "Spreadsheet flat table." },
        { "label": "SQLite database", "description": "Queryable local DB with dedup." },
        { "label": "stdout only", "description": "Terminal output, no file." }
      ]
    },
    {
      "header": "Stealth Level",
      "question": "Anti-bot detection level needed?",
      "multiple": false,
      "options": [
        { "label": "Standard headers", "description": "Realistic UA + client hints." },
        { "label": "TLS impersonation", "description": "curl_cffi / got-scraping for WAF targets." },
        { "label": "TLS + auto-proxy rotation", "description": "Adds 60-source proxy health-checked pool." },
        { "label": "Full stealth browser", "description": "Playwright stealth flags + route aborting." }
      ]
    },
    {
      "header": "Request Rate",
      "question": "How aggressive should request pacing be?",
      "multiple": false,
      "options": [
        { "label": "Safe 2-3s + jitter (Recommended)", "description": "Human-like pacing." },
        { "label": "Normal 1s", "description": "Balanced." },
        { "label": "Fast 0.3s", "description": "High throughput, proxy rotation advised." }
      ]
    }
  ]
}
```

### Gate 3 Tool Call Specification (Runtime Experience)

```json
{
  "questions": [
    {
      "header": "Interactive Menu",
      "question": "Should the scraper have an interactive menu when run in the terminal?",
      "multiple": false,
      "options": [
        { "label": "Yes, full interactive menu (Recommended)", "description": "Numbered menu: search, filters, details, export." },
        { "label": "CLI arguments only", "description": "No prompts; --url/--query/--format flags." },
        { "label": "Both (menu if no args)", "description": "Menu without flags, CLI mode with flags." }
      ]
    },
    {
      "header": "Menu Features",
      "question": "Which features should the interactive menu include?",
      "multiple": true,
      "options": [
        { "label": "Search / re-search loop", "description": "New queries without restarting." },
        { "label": "Filter / category switching", "description": "Change filters between searches." },
        { "label": "Item detail view", "description": "Pick a result number for full detail." },
        { "label": "Export results", "description": "Save current results from menu." },
        { "label": "Continuous crawl mode", "description": "Multi-page collection from menu." }
      ]
    },
    {
      "header": "Logging",
      "question": "How verbose should runtime logging be?",
      "multiple": false,
      "options": [
        { "label": "Normal progress (Recommended)", "description": "Page progress + final summary." },
        { "label": "Debug verbose", "description": "URLs, payloads, response keys, diagnostics." },
        { "label": "Quiet (results only)", "description": "Errors only." }
      ]
    }
  ]
}
```

---

## 3. Terminal Fallback Prompt (Agents Without a Question Tool)

If the host lacks a native `question` tool, print one consolidated gate prompt to stdout and **halt until user input arrives**:

```text
=== SCRAPECRAFT REQUIREMENTS GATE 1/3: DATA ===
Target: https://example.com/catalog

Q1) Which fields?  [1] All detected  [2] Core identity  [3] Identity+metrics  [4] Identity+media  [5] Specify
Q2) Coverage?      [1] Single page   [2] First N pages   [3] All pages      [4] Infinite scroll
Q3) Filters?       [1] None          [2] Category        [3] Sort order     [4] Search driven

Answer like: "1,2,4" or free text.
```

Repeat the same consolidated format for Gates 2 and 3.

---

## 4. Skip Logic & Defaults

| Situation | Protocol |
|---|---|
| User pre-answered a question in the original request | Mark it answered; do not re-ask |
| Q8 = "CLI arguments only" | Drop Q9 silently (it becomes irrelevant) |
| User says "you decide" / "whatever works" | Apply defaults: all fields, full pagination, no filter, recommended language, JSON, standard stealth (escalate if WAF), safe rate, CLI-only, normal logging - then state applied defaults in one sentence |
| Recon reveals WAF after Gate 2 chose standard stealth | Present ONE extra stealth-escalation question (allowed exception) |
| Gate answer is ambiguous | ONE short follow-up question on that specific item only |

---

## 5. Violation Protocol

If the AI writes code before all three gates are resolved:
- The output violates ScrapeCraft core operational discipline.
- The Core Developer must halt, purge the draft from buffer, and return to the first unanswered gate.
- Gates 1-3 unanswered respectively guarantee: wrong data shape, wrong stack/format, wrong deliverable shape (user wanted a menu, got a bare CLI).
