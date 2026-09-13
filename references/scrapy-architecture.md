# Scrapy Framework Architecture & Best Practices

Scrapy is the industry-standard framework for enterprise-scale distributed crawling, featuring built-in concurrency engines, item pipelines, middleware stacks, and automated request scheduling.

---

## Standalone Self-Contained Scrapy Spider (Single File)

You can run Scrapy spiders directly as single-file scripts via `CrawlerProcess`:

```python
#!/usr/bin/env python3
import json
import sys
import scrapy
from scrapy.crawler import CrawlerProcess


class CatalogSpider(scrapy.Spider):
    name = "catalog_spider"
    allowed_domains = ["target-catalog.com"]
    start_urls = ["https://target-catalog.com/products"]

    custom_settings = {
        "USER_AGENT": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
        "CONCURRENT_REQUESTS": 16,
        "DOWNLOAD_DELAY": 1.0,
        "AUTOTHROTTLE_ENABLED": True,
        "AUTOTHROTTLE_START_DELAY": 1.0,
        "AUTOTHROTTLE_MAX_DELAY": 10.0,
        "ROBOTSTXT_OBEY": False,
        "LOG_LEVEL": "INFO",
        "FEEDS": {
            "stdout:": {
                "format": "json",
                "encoding": "utf8",
                "indent": 2,
            }
        },
    }

    def parse(self, response):
        cards = response.css("div.product-card, article.item")
        for card in cards:
            yield {
                "title": card.css("h2.title::text").get("").strip(),
                "price": card.css("span.price::text").get("").strip(),
                "url": response.urljoin(card.css("a::attr(href)").get("")),
            }

        next_page = response.css("a[rel='next']::attr(href)").get()
        if next_page:
            yield response.follow(next_page, callback=self.parse)


def main():
    process = CrawlerProcess()
    process.crawl(CatalogSpider)
    process.start()


if __name__ == "__main__":
    main()
```

---

## Scrapy-Playwright Integration

For dynamic JS rendering within Scrapy pipelines:

```python
# settings.py configuration
DOWNLOAD_HANDLERS = {
    "http": "scrapy_playwright.handler.ScrapyPlaywrightDownloadHandler",
    "https": "scrapy_playwright.handler.ScrapyPlaywrightDownloadHandler",
}
TWISTED_REACTOR = "twisted.internet.asyncioreactor.AsyncioSelectorReactor"

# In Spider:
def start_requests(self):
    yield scrapy.Request(
        url="https://target-spa.com",
        meta={"playwright": True, "playwright_include_page": True},
        callback=self.parse_dynamic,
    )
```
