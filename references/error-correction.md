# Error Correction Protocol

This document defines the linear self-correction procedure when scraping code fails.

## Core Principle: Linear Correction Only

```
Error occurs → Identify root cause → Apply ONE fix → Re-test → Move forward or escalate
```

**NEVER:**
- Apply multiple fixes simultaneously (masks the actual cause).
- Retry the same fix hoping for a different result.
- Wrap the failing code in try-except to hide the error.
- Restructure the entire script when a single selector is wrong.

## Iteration Budget

| Iteration | Purpose |
|---|---|
| 1 | Fix the specific error identified in stderr/traceback |
| 2 | If a different error occurs, fix that specific error |
| 3 | If still failing, this is a structural issue. STOP and report to user. |

After 3 iterations: **STOP.** Do not enter iteration 4. Report to the user what was tried and what the remaining issue is.

## Error Classification & Response

### Category A: Selector Errors (Most Common)

**Symptoms:**
- `No items found`
- `None has no attribute`
- `querySelectorAll returned empty`
- Zero records in output

**Response:**
1. Re-inspect the target DOM (fetch the page again).
2. Compare the expected selector with the actual DOM structure.
3. Identify what changed (class name, nesting level, dynamic content).
4. Write a new selector based on the fresh DOM snapshot.

```
Iteration 1: Fix the selector based on re-inspection.
Iteration 2: If still failing, the page may require JS rendering. Switch to Playwright.
Iteration 3: If Playwright also fails, report that the site structure may have anti-scraping measures.
```

### Category B: HTTP Errors

| Code | Meaning | Response |
|---|---|---|
| 403 | Forbidden / blocked | Try adding headers, then try stealth approach |
| 404 | URL not found | Verify URL with user |
| 429 | Rate limited | Add delays, reduce request frequency |
| 500+ | Server error | Retry once. If persistent, report to user |

```
Iteration 1: Add proper headers (User-Agent, Accept, Accept-Language).
Iteration 2: Switch to stealth approach (see references/anti-detection.md).
Iteration 3: Report that the site is blocking automated access.
```

### Category C: Runtime Errors

**Symptoms:**
- `ModuleNotFoundError` / `Cannot find module`
- `SyntaxError`
- `TypeError`
- `TimeoutError`

**Response:**

| Error | Fix |
|---|---|
| Module not found | Install the missing dependency |
| Syntax error | Fix the syntax (this should not happen if code is clean) |
| Type error | Check the data type assumption against actual DOM content |
| Timeout | Increase timeout or switch to a lighter approach |

```
Iteration 1: Fix the specific runtime error.
Iteration 2: If a different runtime error, fix that.
Iteration 3: Structural issue. Report to user.
```

### Category D: Data Quality Errors

**Symptoms:**
- Output is valid JSON but contains empty strings.
- Field values are HTML tags instead of text.
- Encoding issues (mojibake).

**Response:**
1. Check if `::text` (parsel) or `.innerText()` (Playwright) is used correctly.
2. Check if the data is inside an iframe or shadow DOM.
3. Check encoding: ensure `response.encoding` is correct.

## Error Report Format

When escalating to the user after 3 failed iterations, report:

```
SCRAPING FAILED after 3 correction attempts.

Target: <URL>
Approach: <language + library>

Attempt 1: <what was tried> → <result>
Attempt 2: <what was tried> → <result>
Attempt 3: <what was tried> → <result>

Root cause: <structural issue description>
Recommendation: <suggested next step for the user>
```

## Anti-Patterns (What NOT To Do)

| Anti-Pattern | Why It Is Wrong |
|---|---|
| `try: ... except: pass` | Hides the real error. Code appears to work but returns garbage. |
| Retrying the same selector 5 times | If it failed once, it will fail again. The DOM does not change on retry. |
| Adding `time.sleep(10)` hoping content loads | Use explicit waits (`wait_for_selector`) instead of arbitrary sleeps. |
| Switching from CSS to XPath for the same element | The issue is not the selector syntax. Re-inspect the DOM. |
| Rewriting the entire script | Overkill. Fix the ONE thing that broke. |
