# Node.js Scraping Playbook

## Library Selection Matrix

| Library | Role | Anti-Bot Stealth | HTTP/2 Support | Best Use Case | Install |
|---|---|---|---|---|---|
| **`got-scraping`** (Apify) | Specialized HTTP client | **High** (TLS & Header spoofing) | **Yes** (Native) | Static pages, API sniffing, anti-bot bypass | `npm install got-scraping cheerio` |
| **`cheerio`** | HTML/DOM parser | N/A | N/A | Parsing HTML with fast jQuery-like syntax | `npm install cheerio` |
| **`playwright`** | Headless browser | **High** (with route aborts) | Yes | Dynamic SPAs, client-rendered apps | `npm install playwright` |
| **`puppeteer-extra`** | Chrome CDP automation | **High** (with Stealth plugin) | Yes | Complex automation, CAPTCHA challenges | `npm install puppeteer-extra` |
| **`axios`** | General HTTP client | **Low** (Node.js TLS fingerprint) | No | Basic public REST APIs, zero-protection sites | `npm install axios` |

---

## Decision Tree: `got-scraping` vs `axios` vs `playwright`

```
Target Website Complexity
├── Dynamic JavaScript SPA (React/Vue/Angular empty root shell)
│   └── Use: Playwright (with asset route aborting for speed)
├── WAF Protected / Cloudflare / Custom Headers / Static Catalog
│   └── Use: got-scraping + cheerio (auto-generates browser TLS fingerprint & headers)
└── Unprotected Public REST API
    └── Use: got-scraping or axios
```

---

## Production Standard 1: `got-scraping` + `cheerio` (Recommended)

`got-scraping` automatically manages browser-like TLS handshakes, HTTP/2 multiplexing, and current User-Agent / client-hints generation:

```javascript
#!/usr/bin/env node
const { gotScraping } = require("got-scraping");
const cheerio = require("cheerio");
const { URL } = require("url");

function cleanText(text) {
  if (!text) return "";
  return String(text)
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/\s+/g, " ")
    .trim();
}

function parsePrice(priceStr) {
  if (!priceStr) return null;
  let cleaned = String(priceStr).replace(/[^\d.,]/g, "").trim();
  if (!cleaned) return null;
  if (cleaned.includes(",") && cleaned.includes(".")) {
    if (cleaned.lastIndexOf(",") > cleaned.lastIndexOf(".")) {
      cleaned = cleaned.replace(/\./g, "").replace(",", ".");
    } else {
      cleaned = cleaned.replace(/,/g, "");
    }
  } else if (cleaned.includes(",") && !cleaned.includes(".")) {
    cleaned = cleaned.replace(",", ".");
  }
  const num = parseFloat(cleaned);
  return isNaN(num) ? null : num;
}

function resolveUrl(relativeOrAbsolute, baseUrl) {
  if (!relativeOrAbsolute) return "";
  const trimmed = String(relativeOrAbsolute).trim();
  if (trimmed.startsWith("//")) return `https:${trimmed}`;
  try {
    return new URL(trimmed, baseUrl).href;
  } catch (_) {
    return trimmed;
  }
}

function extractItem($, element, baseUrl) {
  const el = $(element);

  const title = cleanText(
    el.find("[data-testid='title']").text() ||
      el.find("h2.title").text() ||
      el.find("h3").text() ||
      el.find("a").first().text()
  );

  const rawPrice =
    el.find("[data-testid='price']").text() ||
      el.find("span.price").text() ||
      el.find(".price-current").text();

  const relUrl =
    el.find("a[data-testid='link']").attr("href") ||
      el.find("a").first().attr("href") ||
      "";

  return {
    title,
    price: parsePrice(rawPrice),
    raw_price: cleanText(rawPrice),
    url: resolveUrl(relUrl, baseUrl),
  };
}

async function scrapePage(url, proxyUrl = null) {
  const options = {
    url,
    responseType: "text",
    headerGeneratorOptions: {
      browsers: [{ name: "chrome", minVersion: 125 }],
      devices: ["desktop"],
      locales: ["en-US"],
    },
    timeout: { request: 30000 },
  };

  if (proxyUrl) {
    options.proxyUrl = proxyUrl;
  }

  const response = await gotScraping(options);

  if (response.statusCode !== 200) {
    console.error(`HTTP ${response.statusCode}: ${url}`);
    return [];
  }

  const $ = cheerio.load(response.body);
  const cards = $("div.product-card, article.item, li.result-item");

  if (cards.length === 0) {
    console.error("Warning: Container selector matched zero elements.");
    return [];
  }

  const results = [];
  cards.each((_, el) => {
    results.push(extractItem($, el, url));
  });

  return results;
}

function exportData(records, format) {
  if (format === "jsonl") {
    for (const r of records) {
      process.stdout.write(JSON.stringify(r) + "\n");
    }
  } else {
    process.stdout.write(JSON.stringify(records, null, 2) + "\n");
  }
}

async function main() {
  const targetUrl = process.argv[2] || "TARGET_URL";
  const format = process.argv[3] || "json";
  const proxy = process.env.SCRAPER_PROXY || null;

  console.error(`Scraping target: ${targetUrl}`);
  const records = await scrapePage(targetUrl, proxy);
  exportData(records, format);
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
```

---

## Production Standard 2: Playwright for Dynamic SPAs

```javascript
#!/usr/bin/env node
const { chromium } = require("playwright");

async function scrapeDynamicSpa(url) {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    userAgent:
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
    viewport: { width: 1920, height: 1080 },
  });

  const page = await context.newPage();

  // Route aborting to conserve bandwidth and speed up scraping
  await page.route("**/*", (route) => {
    const type = route.request().resourceType();
    if (["image", "media", "font", "stylesheet"].includes(type)) {
      route.abort();
    } else {
      route.continue();
    }
  });

  await page.goto(url, { waitUntil: "networkidle", timeout: 35000 });

  const items = await page.$$("div.product-card, article.item");
  const results = [];

  for (const item of items) {
    const titleEl = await item.$("h2, .title");
    const priceEl = await item.$(".price, [data-testid='price']");
    results.push({
      title: titleEl ? (await titleEl.innerText()).trim() : "",
      price: priceEl ? (await priceEl.innerText()).trim() : "",
    });
  }

  await browser.close();
  return results;
}

async function main() {
  const url = process.argv[2] || "TARGET_URL";
  const data = await scrapeDynamicSpa(url);
  console.log(JSON.stringify(data, null, 2));
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
```

---

## Node.js Code Conventions

- Always use `#!/usr/bin/env node` shebang.
- Use `got-scraping` over raw `axios` when scraping HTML to avoid TLS fingerprint blocks.
- Pass all raw extracted strings through `cleanText()`, `parsePrice()`, and `resolveUrl()`.
- Route diagnostics to `console.error` (stderr) so `stdout` remains pure JSON/JSONL.
