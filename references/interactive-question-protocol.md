# Interactive Question Protocol & User Decision Gates

ScrapeCraft enforces a strict **Human-in-the-Loop Confirmation Gate** at critical milestones. The AI agent is **strictly prohibited from writing, scaffolding, or executing code immediately** without presenting its technical reconnaissance findings and asking the user for stack confirmation.

---

## 1. The Core Rule: Mandatory Language Selection Gate

Upon receiving a scraping objective:
1. **Never write code immediately.**
2. Silently inspect the target website (detect SSR hydration state, sniff background APIs, evaluate DOM complexity).
3. Formulate a technical recommendation (Python vs. Node.js).
4. **Present the Reconnaissance Dossier and actively prompt the user to choose the implementation language.**

---

## 2. Using Host Agent Interactive Tools

When operating inside an agent runtime equipped with the `question` tool (such as OpenCode / Antigravity / Claude Code interactive harnesses):

### Tool Call Specification: Language Selection Gate

```json
{
  "questions": [
    {
      "header": "Language Selection",
      "question": "Based on target inspection, [TARGET_TYPE] was detected. I recommend [RECOMMENDED_LANGUAGE] ([LIBRARIES]) because [TECHNICAL_REASON]. Which language would you like to use for this scraper?",
      "multiple": false,
      "options": [
        {
          "label": "Python (Recommended)",
          "description": "Uses httpx, parsel, and pydantic for fast, robust execution."
        },
        {
          "label": "Node.js (JavaScript)",
          "description": "Uses axios, cheerio, or playwright in a Node.js runtime environment."
        }
      ]
    }
  ]
}
```

---

## 3. Terminal Fallback Prompt (For Agents Without Native Question Tool)

If the host agent environment lacks a native `question` tool, print a concise, structured prompt to standard output and **halt execution until user input is received**:

```text
=== SCRAPECRAFT RECONNAISSANCE DOSSIER ===
Target URL:        https://example.com/catalog
Detected Stack:    Next.js SSR (__NEXT_DATA__ payload present)
Data Strategy:     Direct State Extraction (100x faster, zero DOM drift)
Recommended Stack: Python (httpx + json)

Before I generate the production code, please confirm your preferred language:
1. Python (Recommended - lightweight, fast SSR parsing)
2. Node.js / JavaScript (axios + cheerio)

Please respond with your choice (Python or Node.js) to proceed with code generation.
```

---

## 4. Secondary Interactive Gates

The agent may also prompt the user at these specific decision points:

| Decision Gate | Trigger Condition | Prompt Content |
|---|---|---|
| **Data Scope Confirmation** | Ambiguous target schema (e.g., user asks to "scrape everything") | Present list of detected fields (title, price, SKU, variants, reviews) and ask which fields to include. |
| **Stealth Escalation** | Cloudflare Turnstile / DataDome challenge detected | Inform user of anti-bot barrier; ask whether to use TLS impersonation (`curl_cffi`) or full Stealth Browser (`playwright`). |
| **Storage Destination** | Large crawl volume (>1,000 items) | Ask if user prefers flat JSON, streaming NDJSON/JSONL, CSV, or SQLite database. |

---

## 5. Violation Protocol

If the AI writes code before the user responds to the Language Selection Gate:
- The output violates ScrapeCraft core operational discipline.
- The Core Developer must halt, purge draft code from buffer, and return to the Language Selection Gate.
