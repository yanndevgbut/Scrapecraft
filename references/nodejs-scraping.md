# Node.js Scraping Playbook

## Library Selection

| Library | Use Case | Install |
|---|---|---|
| `playwright` | JS-rendered pages, browser automation | `npm install playwright` |
| `puppeteer` | Browser automation (Chrome-focused) | `npm install puppeteer` |
| `cheerio` | Fast HTML parsing (jQuery-like) | `npm install cheerio` |
| `axios` | HTTP client | `npm install axios` |
| `got` | Advanced HTTP client (retries, streams) | `npm install got` |
| `node-fetch` | Lightweight HTTP fetch | `npm install node-fetch` |
| `cheerio` + `axios` | Default combo for static pages | `npm install cheerio axios` |

## Code Templates

### Template 1: Static Page (axios + cheerio)

```javascript
#!/usr/bin/env node
const axios = require("axios");
const cheerio = require("cheerio");

const HEADERS = {
  "User-Agent":
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
  Accept:
    "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
  "Accept-Language": "en-US,en;q=0.9",
};

async function scrape(url) {
  const response = await axios.get(url, {
    headers: HEADERS,
    timeout: 30000,
    maxRedirects: 5,
  });

  if (response.status !== 200) {
    console.error(`HTTP ${response.status}: ${url}`);
    process.exit(1);
  }

  const $ = cheerio.load(response.data);
  const items = $("CONTAINER_SELECTOR");

  if (items.length === 0) {
    console.error("No items found. Selector may be incorrect.");
    process.exit(1);
  }

  const results = [];
  items.each((_, el) => {
    results.push({
      field_1: $(el).find("FIELD_1_SELECTOR").text().trim(),
      field_2: $(el).find("FIELD_2_SELECTOR").text().trim(),
    });
  });

  return results;
}

async function main() {
  const url = "TARGET_URL";
  const data = await scrape(url);
  console.log(JSON.stringify(data, null, 2));
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
```

### Template 2: JS-Rendered Page (Playwright)

```javascript
#!/usr/bin/env node
const { chromium } = require("playwright");

async function scrape(url) {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    userAgent:
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
    viewport: { width: 1920, height: 1080 },
  });
  const page = await context.newPage();
  await page.goto(url, { waitUntil: "networkidle", timeout: 30000 });

  const items = await page.$$("CONTAINER_SELECTOR");

  if (items.length === 0) {
    console.error("No items found. Selector may be incorrect.");
    await browser.close();
    process.exit(1);
  }

  const results = [];
  for (const item of items) {
    const field1El = await item.$("FIELD_1_SELECTOR");
    const field2El = await item.$("FIELD_2_SELECTOR");
    results.push({
      field_1: field1El ? (await field1El.innerText()).trim() : "",
      field_2: field2El ? (await field2El.innerText()).trim() : "",
    });
  }

  await browser.close();
  return results;
}

async function main() {
  const url = "TARGET_URL";
  const data = await scrape(url);
  console.log(JSON.stringify(data, null, 2));
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
```

### Template 3: API Interception (Playwright)

```javascript
#!/usr/bin/env node
const { chromium } = require("playwright");

async function scrape(url) {
  const capturedData = [];

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  page.on("response", async (response) => {
    if (
      response.url().includes("API_ENDPOINT_PATTERN") &&
      response.status() === 200
    ) {
      try {
        const json = await response.json();
        capturedData.push(json);
      } catch (_) {}
    }
  });

  await page.goto(url, { waitUntil: "networkidle", timeout: 30000 });
  await browser.close();

  if (capturedData.length === 0) {
    console.error("No API responses captured.");
    process.exit(1);
  }

  return capturedData;
}

async function main() {
  const url = "TARGET_URL";
  const data = await scrape(url);
  console.log(JSON.stringify(data, null, 2));
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
```

### Template 4: Multi-Page Crawl (axios + cheerio)

```javascript
#!/usr/bin/env node
const axios = require("axios");
const cheerio = require("cheerio");

const HEADERS = {
  "User-Agent":
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
  Accept:
    "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
  "Accept-Language": "en-US,en;q=0.9",
};

const DELAY_MS = 1500;
const MAX_PAGES = 10;

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function fetchPage(url) {
  try {
    const response = await axios.get(url, {
      headers: HEADERS,
      timeout: 30000,
      maxRedirects: 5,
    });
    return response.data;
  } catch (err) {
    console.error(`Failed to fetch ${url}: ${err.message}`);
    return null;
  }
}

function parseListing(html) {
  const $ = cheerio.load(html);
  const results = [];
  $("CONTAINER_SELECTOR").each((_, el) => {
    results.push({
      field_1: $(el).find("FIELD_1_SELECTOR").text().trim(),
      field_2: $(el).find("FIELD_2_SELECTOR").text().trim(),
    });
  });
  return results;
}

function getNextPageUrl(html, currentUrl) {
  const $ = cheerio.load(html);
  const nextHref = $("NEXT_PAGE_SELECTOR").attr("href");
  if (!nextHref) return null;
  return new URL(nextHref, currentUrl).href;
}

async function main() {
  const startUrl = "TARGET_URL";
  const allResults = [];
  let currentUrl = startUrl;
  let pageNum = 1;

  while (currentUrl && pageNum <= MAX_PAGES) {
    console.error(`Scraping page ${pageNum}: ${currentUrl}`);
    const html = await fetchPage(currentUrl);
    if (!html) break;

    const results = parseListing(html);
    allResults.push(...results);

    currentUrl = getNextPageUrl(html, currentUrl);
    pageNum++;
    if (currentUrl) await sleep(DELAY_MS);
  }

  console.log(JSON.stringify(allResults, null, 2));
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
```

## Node.js Code Conventions

- Always use `#!/usr/bin/env node` shebang.
- Always define an `async function main()` with `.catch()` error handler.
- Use `require()` (CommonJS) for maximum compatibility across environments.
- Use `axios` over `node-fetch` for richer error handling and timeout support.
- Use `cheerio` for static HTML parsing (fast, jQuery-familiar API).
- Print results to stdout via `console.log`. Print diagnostics to stderr via `console.error`.
- Always set explicit `timeout` on every HTTP request.
- Always send a realistic `User-Agent` header.
- Use `process.exit(1)` for failures, never silent returns of empty arrays.
