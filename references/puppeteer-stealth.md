# Puppeteer Stealth & Node.js Evasion Playbook

When building Node.js scrapers against protected endpoints, `puppeteer-extra` combined with `puppeteer-extra-plugin-stealth` provides advanced evasion against bot-detection platforms.

---

## 1. Production Stealth Node.js Scraper

```javascript
#!/usr/bin/env node
const puppeteer = require("puppeteer-extra");
const StealthPlugin = require("puppeteer-extra-plugin-stealth");

puppeteer.use(StealthPlugin());

async function scrapeWithStealth(url) {
  const browser = await puppeteer.launch({
    headless: "new",
    args: [
      "--no-sandbox",
      "--disable-setuid-sandbox",
      "--disable-infobars",
      "--window-position=0,0",
      "--ignore-certifcate-errors",
      "--ignore-certifcate-errors-spki-list",
    ],
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 1920, height: 1080 });

  // Route blocking for performance
  await page.setRequestInterception(true);
  page.on("request", (req) => {
    if (["image", "stylesheet", "font"].includes(req.resourceType())) {
      req.abort();
    } else {
      req.continue();
    }
  });

  console.error(`Navigating to: ${url}`);
  await page.goto(url, { waitUntil: "networkidle2", timeout: 35000 });

  const data = await page.evaluate(() => {
    const cards = document.querySelectorAll(
      "div.product-card, article, [data-testid='item']"
    );
    return Array.from(cards).map((el) => ({
      title: el.querySelector("h2, .title")?.innerText.trim() || "",
      price: el.querySelector(".price, [data-testid='price']")?.innerText.trim() || "",
    }));
  });

  await browser.close();
  return data;
}

async function main() {
  const targetUrl = process.argv[2] || "TARGET_URL";
  const records = await scrapeWithStealth(targetUrl);
  console.log(JSON.stringify(records, null, 2));
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
```
