#!/usr/bin/env python3
import argparse
import asyncio
import json
import re
import sys
import time
from urllib.parse import urlsplit
import httpx

ALL_PROXY_SOURCES = [
    # SOCKS5 Endpoints
    {"url": "https://api.proxyscrape.com/v2/?request=displayproxies&protocol=socks5&timeout=5000&country=all&ssl=all&anonymity=all", "type": "socks5"},
    {"url": "https://proxmint.com/api/free-proxies?protocol=socks5&format=txt", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/TheSpeedX/SOCKS-List/master/socks5.txt", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/monosans/proxy-list/main/proxies/socks5.txt", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/hookzof/socks5_list/master/proxy.txt", "type": "socks5"},
    {"url": "https://proxylist.geonode.com/api/proxy-list?protocols=socks5&limit=500&page=1&sort_by=lastChecked&sort_type=desc", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/VPSLabCloud/VPSLab-Free-Proxy-List/main/socks5_all.txt", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/wiki/gfpcom/free-proxy-list/lists/socks5.txt", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/proxifly/free-proxy-list/main/proxies/protocols/socks5/data.txt", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/roosterkid/openproxylist/main/SOCKS5_RAW.txt", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/MuRongPIG/Proxy-Master/main/socks5.txt", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/ErcinDedeoglu/proxies/main/proxies/socks5.txt", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/sunny9577/proxy-scraper/master/generated/socks5_proxies.txt", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/mertguvencli/http-proxy-list/main/socks5.txt", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/rdavydov/proxy-list/main/proxies/socks5.txt", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/zevtyardt/proxy-list/main/socks5.txt", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/Zaeem20/FREE_PROXIES_LIST/master/socks5.txt", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/prxchk/proxy-list/main/socks5.txt", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/officialputuid/KangProxy/KangProxy/socks5/socks5.txt", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/casals-ar/proxy-list/main/socks5.txt", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/ObcbO/getproxy/master/file/socks5.txt", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/yemixzy/proxy-list/main/proxies/socks5.txt", "type": "socks5"},
    {"url": "https://www.proxy-list.download/api/v1/get?type=socks5", "type": "socks5"},
    {"url": "https://api.openproxy.space/free-proxy-list/socks5.txt", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/ProxyBroker-Reloaded/proxy-list/master/socks5.txt", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/HyperBeats/proxy-list/main/socks5.txt", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/caliphdev/Proxy-List/master/socks5.txt", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/B4RC0D3-MD/proxy-list/main/SOCKS5.txt", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/Anonym0usWork1221/Free-Proxies/main/socks5.txt", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/jetkai/proxy-list/main/online-proxies/txt/proxies-socks5.txt", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/ShiftyTR/Proxy-List/master/socks5.txt", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/mmpx12/proxy-list/master/socks5.txt", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/vakhov/fresh-proxy-list/master/socks5.txt", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/im-razvan/proxy_list/main/socks5.txt", "type": "socks5"},
    {"url": "https://raw.githubusercontent.com/yucao/free-proxy-list/master/socks5.txt", "type": "socks5"},

    # HTTP & HTTPS Endpoints
    {"url": "https://raw.githubusercontent.com/TheSpeedX/SOCKS-List/master/http.txt", "type": "http"},
    {"url": "https://raw.githubusercontent.com/monosans/proxy-list/main/proxies/all.txt", "type": "http"},
    {"url": "https://raw.githubusercontent.com/VPSLabCloud/VPSLab-Free-Proxy-List/main/all_proxies.txt", "type": "http"},
    {"url": "https://raw.githubusercontent.com/wiki/gfpcom/free-proxy-list/lists/http.txt", "type": "http"},
    {"url": "https://raw.githubusercontent.com/roosterkid/openproxylist/main/HTTPS_RAW.txt", "type": "http"},
    {"url": "https://raw.githubusercontent.com/MuRongPIG/Proxy-Master/main/http.txt", "type": "http"},
    {"url": "https://raw.githubusercontent.com/hendrikbgr/Free-Proxy-Repo/master/proxy_list.txt", "type": "http"},
    {"url": "https://raw.githubusercontent.com/officialputuid/KangProxy/KangProxy/http/http.txt", "type": "http"},
    {"url": "https://www.proxy-list.download/api/v1/get?type=http", "type": "http"},
    {"url": "https://raw.githubusercontent.com/zevtyardt/proxy-list/main/all.txt", "type": "http"},
    {"url": "https://raw.githubusercontent.com/clarketm/proxy-list/master/proxy-list-raw.txt", "type": "http"},
    {"url": "https://raw.githubusercontent.com/jetkai/proxy-list/main/online-proxies/txt/proxies-http.txt", "type": "http"},
    {"url": "https://raw.githubusercontent.com/jetkai/proxy-list/main/online-proxies/txt/proxies-https.txt", "type": "http"},
    {"url": "https://raw.githubusercontent.com/almroot/proxylist/master/list.txt", "type": "http"},
    {"url": "https://raw.githubusercontent.com/ShiftyTR/Proxy-List/master/http.txt", "type": "http"},
    {"url": "https://raw.githubusercontent.com/ShiftyTR/Proxy-List/master/https.txt", "type": "http"},
    {"url": "https://raw.githubusercontent.com/saisuiu/Lionkings-Http-Proxys-Proxies/main/free.txt", "type": "http"},
    {"url": "https://raw.githubusercontent.com/mmpx12/proxy-list/master/http.txt", "type": "http"},
    {"url": "https://raw.githubusercontent.com/mmpx12/proxy-list/master/https.txt", "type": "http"},
    {"url": "https://raw.githubusercontent.com/vakhov/fresh-proxy-list/master/http.txt", "type": "http"},
    {"url": "https://raw.githubusercontent.com/vakhov/fresh-proxy-list/master/https.txt", "type": "http"},
    {"url": "https://raw.githubusercontent.com/im-razvan/proxy_list/main/http.txt", "type": "http"},
    {"url": "https://raw.githubusercontent.com/zevtyardt/proxy-list/main/http.txt", "type": "http"},
    {"url": "https://raw.githubusercontent.com/yucao/free-proxy-list/master/http.txt", "type": "http"},
    {"url": "https://raw.githubusercontent.com/andigwandi/free-proxy/main/proxy_list.txt", "type": "http"},
]

IP_PORT_REGEX = re.compile(r"\b((?:\d{1,3}\.){3}\d{1,3}):(\d{2,5})\b")


async def fetch_source_proxies(client: httpx.AsyncClient, source_info: dict) -> list[str]:
    url = source_info["url"]
    try:
        resp = await client.get(url, timeout=8.0, follow_redirects=True)
        if resp.status_code == 200:
            content = resp.text
            # Handle JSON list responses (e.g. Geonode)
            if url.startswith("https://proxylist.geonode.com"):
                try:
                    data = resp.json()
                    return [f"{item['ip']}:{item['port']}" for item in data.get("data", []) if "ip" in item and "port" in item]
                except Exception:
                    pass

            matches = IP_PORT_REGEX.findall(content)
            return [f"{ip}:{port}" for ip, port in matches]
    except Exception:
        pass
    return []


async def probe_proxy(
    semaphore: asyncio.Semaphore,
    proxy_str: str,
    protocol: str,
    test_target: str,
    timeout_sec: float,
) -> dict | None:
    async with semaphore:
        proxy_url = f"{protocol}://{proxy_str}" if not proxy_str.startswith(("http://", "https://", "socks5://", "socks4://")) else proxy_str
        proxies = {"http://": proxy_url, "https://": proxy_url}

        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
        }

        start = time.time()
        try:
            async with httpx.AsyncClient(proxies=proxies, timeout=timeout_sec, headers=headers) as client:
                res = await client.get(test_target)
                latency = round((time.time() - start) * 1000, 1)
                if res.status_code == 200:
                    return {
                        "proxy": proxy_url,
                        "ip_port": proxy_str,
                        "protocol": protocol,
                        "latency_ms": latency,
                        "status": "online",
                    }
        except Exception:
            pass
        return None


async def run_proxy_discovery(
    protocol: str = "socks5",
    target: str = "https://cloudflare.com/cdn-cgi/trace",
    limit: int = 10,
    timeout_sec: float = 2.5,
    max_candidates: int = 250,
    concurrency: int = 50,
) -> list[dict]:
    print(f"Aggregating proxy endpoints for protocol: {protocol.upper()}...", file=sys.stderr)

    selected_sources = [
        s for s in ALL_PROXY_SOURCES
        if protocol == "all" or s["type"] == protocol or (protocol in ["http", "https"] and s["type"] == "http")
    ]

    async with httpx.AsyncClient() as client:
        fetch_tasks = [fetch_source_proxies(client, s) for s in selected_sources]
        results = await asyncio.gather(*fetch_tasks)

    all_proxies = []
    for r in results:
        all_proxies.extend(r)

    unique_proxies = list(dict.fromkeys(all_proxies))
    print(f"Aggregated {len(unique_proxies)} unique proxy endpoints from {len(selected_sources)} sources.", file=sys.stderr)

    if not unique_proxies:
        print("Error: No proxies retrieved from sources.", file=sys.stderr)
        return []

    candidates = unique_proxies[:max_candidates]
    print(f"Initiating concurrent live health checks on {len(candidates)} candidates (Timeout: {timeout_sec}s)...", file=sys.stderr)

    semaphore = asyncio.Semaphore(concurrency)
    probe_tasks = [
        probe_proxy(semaphore, p, protocol if protocol != "all" else "socks5", target, timeout_sec)
        for p in candidates
    ]

    probe_results = await asyncio.gather(*probe_tasks)
    working = [r for r in probe_results if r is not None]
    working.sort(key=lambda x: x["latency_ms"])

    print(f"Verification complete: {len(working)} verified live proxies found.", file=sys.stderr)
    return working[:limit]


def main():
    parser = argparse.ArgumentParser(description="ScrapeCraft High-Speed Proxy Aggregator & Live Health-Checker")
    parser.add_argument("--protocol", choices=["socks5", "http", "all"], default="socks5", help="Proxy protocol to aggregate (default: socks5)")
    parser.add_argument("--target", default="https://cloudflare.com/cdn-cgi/trace", help="Target test URL for connectivity check")
    parser.add_argument("--limit", type=int, default=10, help="Maximum verified proxies to output (default: 10)")
    parser.add_argument("--timeout", type=float, default=2.5, help="Probe timeout in seconds (default: 2.5)")
    parser.add_argument("--candidates", type=int, default=200, help="Max raw proxy candidates to probe (default: 200)")
    parser.add_argument("--concurrency", type=int, default=50, help="Concurrent probe tasks (default: 50)")
    parser.add_argument("--format", choices=["text", "json", "uris"], default="uris", help="Output format (uris | text | json)")
    args = parser.parse_args()

    results = asyncio.run(
        run_proxy_discovery(
            protocol=args.protocol,
            target=args.target,
            limit=args.limit,
            timeout_sec=args.timeout,
            max_candidates=args.candidates,
            concurrency=args.concurrency,
        )
    )

    if args.format == "json":
        print(json.dumps(results, indent=2))
    elif args.format == "text":
        for r in results:
            print(f"{r['proxy']} (Latency: {r['latency_ms']}ms)")
    else:
        for r in results:
            print(r["proxy"])


if __name__ == "__main__":
    main()
