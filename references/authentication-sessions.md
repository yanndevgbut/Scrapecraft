# Authentication, Cookies & Session Persistence

When target websites require authentication (login credentials, API tokens, cookie jars, or OAuth sessions), scrapers must maintain persistent session states and manage cookie lifecycles without hardcoding secrets.

---

## 1. StorageState Persistence (Playwright)

Save and reload complete browser state (cookies, `localStorage`, `sessionStorage`):

### Step 1: Export Logged-In Session

```python
from playwright.sync_api import sync_playwright


def perform_login_and_save_session(login_url: str, username: str, password: str, session_file: str):
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context()
        page = context.new_page()

        page.goto(login_url, wait_until="networkidle")
        page.fill("input[name='username'], input[type='email']", username)
        page.fill("input[name='password'], input[type='password']", password)
        page.click("button[type='submit'], input[type='submit']")

        # Wait for navigation confirming successful auth
        page.wait_for_url("**/dashboard**", timeout=15000)

        # Save cookies and local storage to JSON
        context.storage_state(path=session_file)
        print(f"Session saved to {session_file}")
        browser.close()
```

### Step 2: Reuse Saved Session for Scraping

```python
def scrape_with_saved_session(target_url: str, session_file: str) -> str:
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        # Load authenticated context
        context = browser.new_context(storage_state=session_file)
        page = context.new_page()

        page.goto(target_url, wait_until="networkidle")
        content = page.content()
        browser.close()
        return content
```

---

## 2. HTTPX Cookie Jar & Session Management

```python
import httpx

# Reusable client holding session cookies
client = httpx.Client(
    headers={"User-Agent": "Mozilla/5.0"},
    timeout=30,
    follow_redirects=True,
)

# Login POST
login_payload = {"email": "user@example.com", "password": "SecretPassword"}
login_res = client.post("https://target.com/api/login", json=login_payload)

# Subsequent GET requests automatically include auth cookies
data_res = client.get("https://target.com/api/user/private-data")
```

---

## Security Best Practices for AI Scrapers

1. **Zero Hardcoded Passwords**: Always instruct users to pass credentials via environment variables (`os.environ["SCRAPER_USERNAME"]`) or CLI arguments.
2. **Sanitized Logs**: Never log `Authorization: Bearer <token>` or `Cookie` values to `stdout`/`stderr`.
3. **Session Expiry Handling**: Detect HTTP 401/403 responses and trigger automatic re-authentication routines.
