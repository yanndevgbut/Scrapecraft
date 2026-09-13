# HTTP/2 Multiplexing & TLS JA3/JA4 Impersonation

Modern anti-bot solutions (Cloudflare, Akamai, Imperva) inspect the cryptographic fingerprint of incoming TLS handshakes (JA3, JA4, and HTTP/2 settings frames). Standard Python `requests` or Node.js `https` libraries present signatures that are immediately flagged as automated tools.

---

## 1. TLS Impersonation with `curl_cffi` (Python)

`curl_cffi` binds against a custom `curl-impersonate` binary that replicates the exact TLS ClientHello, cipher suites, ALPN extensions, and HTTP/2 stream priorities of real Google Chrome / Safari / Edge browsers.

### Production Template

```python
#!/usr/bin/env python3
import json
import sys
from curl_cffi import requests as cffi_requests
from parsel import Selector

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
    "Accept-Encoding": "gzip, deflate, br, zstd",
    "Sec-Ch-Ua": '"Google Chrome";v="131", "Chromium";v="131", "Not_A Brand";v="24"',
    "Sec-Ch-Ua-Mobile": "?0",
    "Sec-Ch-Ua-Platform": '"Windows"',
    "Sec-Fetch-Dest": "document",
    "Sec-Fetch-Mode": "navigate",
    "Sec-Fetch-Site": "none",
    "Sec-Fetch-User": "?1",
    "Upgrade-Insecure-Requests": "1",
}


def fetch_protected_page(url: str) -> str:
    # impersonate='chrome131' matches the exact TLS JA4 hash of Chrome 131
    response = cffi_requests.get(
        url,
        headers=HEADERS,
        impersonate="chrome131",
        timeout=30,
        verify=True,
    )
    if response.status_code != 200:
        print(f"HTTP {response.status_code}: {url}", file=sys.stderr)
        return ""
    return response.text
```

---

## 2. High-Concurrency HTTP/2 Multiplexing with `httpx`

```python
import asyncio
import httpx

LIMITS = httpx.Limits(max_keepalive_connections=50, max_connections=100)


async def batch_fetch_urls(urls: list[str]) -> list[str]:
    # http2=True enables single TCP connection multiplexing
    async with httpx.AsyncClient(http2=True, limits=LIMITS, timeout=30) as client:
        tasks = [client.get(u) for u in urls]
        responses = await asyncio.gather(*tasks, return_exceptions=True)
        return [r.text for r in responses if isinstance(r, httpx.Response) and r.status_code == 200]
```
