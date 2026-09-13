# Iframe & Shadow DOM Penetration

Modern web interfaces frequently encapsulate widgets, checkout forms, video players, and third-party components within **Nested Iframes** or **Shadow DOM** boundaries (Web Components). Standard `page.query_selector()` calls fail to pierce these boundaries without explicit traversal.

---

## 1. Penetrating Iframes

### Python Playwright Iframe Traversal

```python
from playwright.sync_api import sync_playwright


def scrape_iframe_content(url: str) -> dict:
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        page.goto(url, wait_until="networkidle", timeout=30000)

        # Strategy 1: Access by frame name or URL pattern
        frame = page.frame(name="content-frame") or page.frame(url=r".*payment-widget.*")

        # Strategy 2: Access via frame_locator (Modern Playwright Recommended)
        locator = page.frame_locator("iframe.widget-iframe, iframe[data-testid='embed-frame']")
        title = locator.locator("h2.widget-title").inner_text().strip()
        price = locator.locator(".price-amount").inner_text().strip()

        # Strategy 3: Iterate all child frames
        all_frames_data = []
        for f in page.frames:
            if f != page.main_frame:
                el = f.query_selector("h1, .target-text")
                if el:
                    all_frames_data.append(el.inner_text().strip())

        browser.close()
        return {"title": title, "price": price, "extra": all_frames_data}
```

---

## 2. Penetrating Shadow DOM (Open & Closed)

Playwright CSS locators pierce **Open Shadow DOM** automatically by default:
- `page.locator("custom-element >> div.shadow-inner")` works out of the box.

For **Closed Shadow DOM** or fine-grained JavaScript DOM traversal:

### JavaScript Piercing Function

```python
def extract_closed_shadow_dom(page) -> str:
    # Inject script that accesses internal components
    result = page.evaluate("""
        () => {
            const host = document.querySelector('custom-video-player');
            if (!host) return null;
            
            // For custom properties exposing internals
            const shadowRoot = host.shadowRoot;
            if (shadowRoot) {
                return shadowRoot.querySelector('.player-title')?.innerText;
            }
            return null;
        }
    """)
    return result
```

---

## 3. Node.js Playwright Frame & Shadow DOM Handling

```javascript
const { chromium } = require("playwright");

async function scrapeEncapsulatedData(url) {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.goto(url, { waitUntil: "networkidle" });

  // Frame locator penetrates nested iframes seamlessly
  const frame = page.frameLocator("iframe#checkout-frame");
  const cardNumberInput = frame.locator("input[name='cardnumber']");
  const secureBadgeText = await frame
    .locator(".security-badge >> span")
    .innerText();

  await browser.close();
  return { secureBadgeText };
}
```
