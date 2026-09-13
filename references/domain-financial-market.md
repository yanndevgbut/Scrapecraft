# Domain: Financial & Market Data Scraping

Financial portals (Yahoo Finance, TradingView, MarketWatch, SEC EDGAR, CoinMarketCap, Binance) provide high-frequency ticker prices, historical OHLCV candlestick tables, balance sheets, and regulatory filings.

---

## Core Data Schema

| Field | Type | Description |
|---|---|---|
| `symbol` / `ticker` | `str` | Market symbol (e.g. `AAPL`, `BTCUSDT`) |
| `exchange` | `str` | Exchange identifier (`NASDAQ`, `NYSE`, `BINANCE`) |
| `timestamp` | `str` | ISO-8601 market timestamp |
| `price` | `float` | Current or closing price |
| `change` | `float` | Daily absolute price change |
| `change_percent`| `float` | Daily percentage change |
| `volume` | `float` | 24-hour traded volume |
| `market_cap` | `float | null` | Total market capitalization |
| `ohlcv` | `list[dict]` | Historical bars (`timestamp`, `open`, `high`, `low`, `close`, `volume`) |

---

## Strategy 1: Yahoo Finance Chart API Direct Extraction

Yahoo Finance provides public REST endpoints for real-time and historical OHLCV candles:

```python
#!/usr/bin/env python3
import json
import sys
from datetime import datetime, timezone
import httpx

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
}


def fetch_ohlcv(symbol: str, range_period: str = "1mo", interval: str = "1d") -> list[dict]:
    url = f"https://query1.finance.yahoo.com/v8/finance/chart/{symbol}?range={range_period}&interval={interval}"

    response = httpx.get(url, headers=HEADERS, timeout=30)
    if response.status_code != 200:
        print(f"HTTP {response.status_code}: {url}", file=sys.stderr)
        return []

    data = response.json()
    result = data.get("chart", {}).get("result", [{}])[0]
    timestamps = result.get("timestamp", [])
    quote = result.get("indicators", {}).get("quote", [{}])[0]

    opens = quote.get("open", [])
    highs = quote.get("high", [])
    lows = quote.get("low", [])
    closes = quote.get("close", [])
    volumes = quote.get("volume", [])

    bars = []
    for i, ts in enumerate(timestamps):
        if ts is None or closes[i] is None:
            continue
        iso_ts = datetime.fromtimestamp(ts, timezone.utc).isoformat()
        bars.append({
            "timestamp": iso_ts,
            "open": round(opens[i], 4) if opens[i] is not None else None,
            "high": round(highs[i], 4) if highs[i] is not None else None,
            "low": round(lows[i], 4) if lows[i] is not None else None,
            "close": round(closes[i], 4) if closes[i] is not None else None,
            "volume": int(volumes[i]) if volumes[i] is not None else None,
        })

    return bars
```

---

## Strategy 2: SEC EDGAR Filings & Company Facts API

The US SEC provides open JSON APIs for corporate financial statements:

```python
import httpx

# Note: SEC requires declaring a descriptive User-Agent with contact email
SEC_HEADERS = {
    "User-Agent": "DataScraper Research/1.0 (contact@research-example.org)",
    "Accept-Encoding": "gzip, deflate",
}


def fetch_sec_company_facts(cik_10_digits: str) -> dict:
    url = f"https://data.sec.gov/api/xbrl/companyfacts/CIK{cik_10_digits.zfill(10)}.json"
    response = httpx.get(url, headers=SEC_HEADERS, timeout=30)
    if response.status_code == 200:
        return response.json()
    return {}
```
