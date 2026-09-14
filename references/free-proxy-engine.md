# Free Proxy Aggregator & Live Health-Check Engine

When scraping websites with geographic blocks, strict IP-based rate limiting (HTTP 429), or perimeter WAFs without a commercial proxy subscription, ScrapeCraft utilizes an automated **Multi-Source Proxy Aggregator & Live Health-Check Engine**.

This engine aggregates thousands of proxy endpoints across **60 public proxy repositories and APIs**, deduplicates them, and runs high-concurrency connection probes to return only verified, responsive, low-latency proxies before initiating target scrapes.

---

## 1. The 60 Managed Proxy Sources

The engine aggregates proxies across SOCKS5, HTTP, and HTTPS protocols:

### SOCKS5 Endpoints (Prioritized for WAF & TCP Resilience)
1. `https://api.proxyscrape.com/v2/?request=displayproxies&protocol=socks5&timeout=5000&country=all&ssl=all&anonymity=all`
2. `https://proxmint.com/api/free-proxies?protocol=socks5&format=txt`
3. `https://raw.githubusercontent.com/TheSpeedX/SOCKS-List/master/socks5.txt`
4. `https://raw.githubusercontent.com/monosans/proxy-list/main/proxies/socks5.txt`
5. `https://raw.githubusercontent.com/hookzof/socks5_list/master/proxy.txt`
6. `https://proxylist.geonode.com/api/proxy-list?protocols=socks5&limit=500&page=1&sort_by=lastChecked&sort_type=desc`
7. `https://raw.githubusercontent.com/VPSLabCloud/VPSLab-Free-Proxy-List/main/socks5_all.txt`
8. `https://raw.githubusercontent.com/wiki/gfpcom/free-proxy-list/lists/socks5.txt`
9. `https://raw.githubusercontent.com/proxifly/free-proxy-list/main/proxies/protocols/socks5/data.txt`
10. `https://raw.githubusercontent.com/roosterkid/openproxylist/main/SOCKS5_RAW.txt`
11. `https://raw.githubusercontent.com/MuRongPIG/Proxy-Master/main/socks5.txt`
12. `https://raw.githubusercontent.com/ErcinDedeoglu/proxies/main/proxies/socks5.txt`
13. `https://raw.githubusercontent.com/sunny9577/proxy-scraper/master/generated/socks5_proxies.txt`
14. `https://raw.githubusercontent.com/mertguvencli/http-proxy-list/main/socks5.txt`
15. `https://raw.githubusercontent.com/rdavydov/proxy-list/main/proxies/socks5.txt`
16. `https://raw.githubusercontent.com/zevtyardt/proxy-list/main/socks5.txt`
17. `https://raw.githubusercontent.com/Zaeem20/FREE_PROXIES_LIST/master/socks5.txt`
18. `https://raw.githubusercontent.com/prxchk/proxy-list/main/socks5.txt`
19. `https://raw.githubusercontent.com/officialputuid/KangProxy/KangProxy/socks5/socks5.txt`
20. `https://raw.githubusercontent.com/casals-ar/proxy-list/main/socks5.txt`
21. `https://raw.githubusercontent.com/ObcbO/getproxy/master/file/socks5.txt`
22. `https://raw.githubusercontent.com/yemixzy/proxy-list/main/proxies/socks5.txt`
23. `https://www.proxy-list.download/api/v1/get?type=socks5`
24. `https://api.openproxy.space/free-proxy-list/socks5.txt`
25. `https://raw.githubusercontent.com/ProxyBroker-Reloaded/proxy-list/master/socks5.txt`
26. `https://raw.githubusercontent.com/HyperBeats/proxy-list/main/socks5.txt`
27. `https://raw.githubusercontent.com/caliphdev/Proxy-List/master/socks5.txt`
28. `https://raw.githubusercontent.com/B4RC0D3-MD/proxy-list/main/SOCKS5.txt`
29. `https://raw.githubusercontent.com/Anonym0usWork1221/Free-Proxies/main/socks5.txt`
30. `https://raw.githubusercontent.com/jetkai/proxy-list/main/online-proxies/txt/proxies-socks5.txt`
31. `https://raw.githubusercontent.com/ShiftyTR/Proxy-List/master/socks5.txt`
32. `https://raw.githubusercontent.com/mmpx12/proxy-list/master/socks5.txt`
33. `https://raw.githubusercontent.com/vakhov/fresh-proxy-list/master/socks5.txt`
34. `https://raw.githubusercontent.com/im-razvan/proxy_list/main/socks5.txt`
35. `https://raw.githubusercontent.com/yucao/free-proxy-list/master/socks5.txt`

### HTTP & HTTPS Endpoints
36. `https://raw.githubusercontent.com/TheSpeedX/SOCKS-List/master/http.txt`
37. `https://raw.githubusercontent.com/monosans/proxy-list/main/proxies/all.txt`
38. `https://raw.githubusercontent.com/VPSLabCloud/VPSLab-Free-Proxy-List/main/all_proxies.txt`
39. `https://raw.githubusercontent.com/wiki/gfpcom/free-proxy-list/lists/http.txt`
40. `https://raw.githubusercontent.com/roosterkid/openproxylist/main/HTTPS_RAW.txt`
41. `https://raw.githubusercontent.com/MuRongPIG/Proxy-Master/main/http.txt`
42. `https://raw.githubusercontent.com/hendrikbgr/Free-Proxy-Repo/master/proxy_list.txt`
43. `https://raw.githubusercontent.com/officialputuid/KangProxy/KangProxy/http/http.txt`
44. `https://www.proxy-list.download/api/v1/get?type=http`
45. `https://raw.githubusercontent.com/zevtyardt/proxy-list/main/all.txt`
46. `https://raw.githubusercontent.com/clarketm/proxy-list/master/proxy-list-raw.txt`
47. `https://raw.githubusercontent.com/jetkai/proxy-list/main/online-proxies/txt/proxies-http.txt`
48. `https://raw.githubusercontent.com/jetkai/proxy-list/main/online-proxies/txt/proxies-https.txt`
49. `https://raw.githubusercontent.com/almroot/proxylist/master/list.txt`
50. `https://raw.githubusercontent.com/ShiftyTR/Proxy-List/master/http.txt`
51. `https://raw.githubusercontent.com/ShiftyTR/Proxy-List/master/https.txt`
52. `https://raw.githubusercontent.com/saisuiu/Lionkings-Http-Proxys-Proxies/main/free.txt`
53. `https://raw.githubusercontent.com/mmpx12/proxy-list/master/http.txt`
54. `https://raw.githubusercontent.com/mmpx12/proxy-list/master/https.txt`
55. `https://raw.githubusercontent.com/vakhov/fresh-proxy-list/master/http.txt`
56. `https://raw.githubusercontent.com/vakhov/fresh-proxy-list/master/https.txt`
57. `https://raw.githubusercontent.com/im-razvan/proxy_list/main/http.txt`
58. `https://raw.githubusercontent.com/zevtyardt/proxy-list/main/http.txt`
59. `https://raw.githubusercontent.com/yucao/free-proxy-list/master/http.txt`
60. `https://raw.githubusercontent.com/andigwandi/free-proxy/main/proxy_list.txt`

---

## 2. Live Health-Check Verification Protocol

Public proxies have high churn rates. **ScrapeCraft never uses a proxy blindly.** Before using any proxy in a scraper, it runs concurrent async probes:

```
[ Aggregator: Fetch from 60 Sources ]
                 │
                 ▼
[ Deduplication & Format Normalizer: IP:Port -> URI ]
                 │
                 ▼
[ High-Speed Async Prober: 50-100 Concurrent Health Checks ]
                 │
                 ├─► Probe Target: https://cloudflare.com/cdn-cgi/trace or Target URL
                 ├─► Timeout Constraint: 2.5 seconds per probe
                 │
                 ▼
[ Filter: Status 200 OK + Latency < 2500ms ]
                 │
                 ▼
[ Working Verified Pool: Injected into Scraper / Rotating Gateway ]
```

---

## 3. Python Embeddable Proxy Fetcher & Validator

Include this module inside Python scrapers requiring automatic proxy rotation:

```python
import asyncio
import re
import sys
import time
import httpx

TEST_ENDPOINT = "https://cloudflare.com/cdn-cgi/trace"
DEFAULT_SOURCES = [
    "https://api.proxyscrape.com/v2/?request=displayproxies&protocol=socks5&timeout=5000&country=all&ssl=all&anonymity=all",
    "https://proxmint.com/api/free-proxies?protocol=socks5&format=txt",
    "https://raw.githubusercontent.com/TheSpeedX/SOCKS-List/master/socks5.txt",
    "https://raw.githubusercontent.com/monosans/proxy-list/main/proxies/socks5.txt",
    "https://raw.githubusercontent.com/hookzof/socks5_list/master/proxy.txt",
    "https://raw.githubusercontent.com/proxifly/free-proxy-list/main/proxies/protocols/socks5/data.txt",
    "https://raw.githubusercontent.com/TheSpeedX/SOCKS-List/master/http.txt",
    "https://raw.githubusercontent.com/monosans/proxy-list/main/proxies/all.txt",
]


async def fetch_proxy_list_from_url(client: httpx.AsyncClient, url: str) -> list[str]:
    try:
        resp = await client.get(url, timeout=10)
        if resp.status_code == 200:
            lines = resp.text.splitlines()
            proxies = []
            for line in lines:
                line = line.strip()
                match = re.search(r"(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):(\d{2,5})", line)
                if match:
                    proxies.append(f"{match.group(1)}:{match.group(2)}")
            return proxies
    except Exception:
        pass
    return []


async def check_proxy_health(proxy: str, protocol: str = "socks5", timeout: float = 2.5) -> dict | None:
    proxy_url = f"{protocol}://{proxy}" if not proxy.startswith(("http://", "https://", "socks5://", "socks4://")) else proxy
    proxies = {"http://": proxy_url, "https://": proxy_url}

    start = time.time()
    try:
        async with httpx.AsyncClient(proxies=proxies, timeout=timeout) as client:
            resp = await client.get(TEST_ENDPOINT)
            latency = round((time.time() - start) * 1000, 1)
            if resp.status_code == 200:
                return {"proxy": proxy_url, "latency_ms": latency}
    except Exception:
        pass
    return None


async def get_working_proxies(limit: int = 5, protocol: str = "socks5") -> list[str]:
    print(f"Aggregating and testing live {protocol} proxies...", file=sys.stderr)
    async with httpx.AsyncClient() as client:
        tasks = [fetch_proxy_list_from_url(client, s) for s in DEFAULT_SOURCES]
        source_results = await asyncio.gather(*tasks)

    # Flatten and deduplicate
    all_raw = list(set([p for sub in source_results for p in sub]))
    print(f"Found {len(all_raw)} unique proxy endpoints. Probing live health...", file=sys.stderr)

    # Batch test first 100 candidates
    candidates = all_raw[:100]
    check_tasks = [check_proxy_health(p, protocol=protocol) for p in candidates]
    results = await asyncio.gather(*check_tasks)

    working = [r["proxy"] for r in results if r is not None]
    print(f"Successfully verified {len(working)} active {protocol} proxies.", file=sys.stderr)
    return working[:limit]
```

---

## 4. Standalone CLI Utility

ScrapeCraft provides the standalone `scripts/proxy-checker.py` tool. You can run it directly from the terminal to test and extract working proxies:

```bash
# Verify and output 10 live SOCKS5 proxies:
python3 scripts/proxy-checker.py --protocol socks5 --limit 10

# Test proxies directly against target website:
python3 scripts/proxy-checker.py --target "https://example.com/catalog" --limit 5 --timeout 3.0
```
