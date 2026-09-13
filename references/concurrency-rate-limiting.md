# Concurrency, Async & Rate Limiting

High-throughput scrapers require balanced concurrency architectures that maximize throughput without overloading the target server or triggering rate limits (HTTP 429).

---

## 1. Asyncio Semaphore Pattern (Python)

Control the exact number of parallel tasks executing simultaneously:

```python
#!/usr/bin/env python3
import asyncio
import json
import random
import sys
import httpx

MAX_CONCURRENT_TASKS = 10
HEADERS = {"User-Agent": "Mozilla/5.0"}


async def fetch_item(client: httpx.AsyncClient, semaphore: asyncio.Semaphore, item_id: int) -> dict:
    async with semaphore:
        url = f"https://api.target-site.com/items/{item_id}"
        # Randomized jitter delay
        await asyncio.sleep(random.uniform(0.1, 0.4))

        try:
            response = await client.get(url, timeout=25)
            if response.status_code == 200:
                return response.json()
            elif response.status_code == 429:
                # Rate limit encountered: sleep and retry once
                await asyncio.sleep(3.0)
                retry_res = await client.get(url, timeout=25)
                return retry_res.json() if retry_res.status_code == 200 else {}
        except Exception as e:
            print(f"Error fetching {item_id}: {e}", file=sys.stderr)
        return {}


async def main():
    semaphore = asyncio.Semaphore(MAX_CONCURRENT_TASKS)
    item_ids = list(range(1, 101))

    limits = httpx.Limits(max_keepalive_connections=20, max_connections=MAX_CONCURRENT_TASKS)
    async with httpx.AsyncClient(headers=HEADERS, limits=limits) as client:
        tasks = [fetch_item(client, semaphore, i) for i in item_ids]
        results = await asyncio.gather(*tasks)

    valid_records = [r for r in results if r]
    print(json.dumps(valid_records, indent=2))


if __name__ == "__main__":
    asyncio.run(main())
```

---

## 2. Token Bucket Rate Limiter (Python)

Ensure requests never exceed a strict rate (e.g. 5 requests per second):

```python
import time


class TokenBucketRateLimiter:
    def __init__(self, rate: float, capacity: float):
        self.rate = rate  # Tokens added per second
        self.capacity = capacity
        self.tokens = capacity
        self.last_update = time.time()

    def acquire(self):
        while True:
            now = time.time()
            elapsed = now - self.last_update
            self.last_update = now
            self.tokens = min(self.capacity, self.tokens + elapsed * self.rate)

            if self.tokens >= 1.0:
                self.tokens -= 1.0
                return
            time.sleep(0.05)
```
