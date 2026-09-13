# WebSocket & Streaming Data Scraping

Financial feeds, live sports scores, auction platforms, and real-time chat systems stream data continuously over WebSocket Secure (`wss://`) connections or Server-Sent Events (`SSE`).

---

## 1. Intercepting WebSocket Streams with Playwright

Playwright provides native WebSocket connection event listeners:

```python
#!/usr/bin/env python3
import json
import sys
import time
from playwright.sync_api import sync_playwright

captured_messages = []


def on_web_socket(ws):
    print(f"WebSocket Connected: {ws.url}", file=sys.stderr)

    def on_frame_received(payload):
        try:
            # Handle text/JSON frames
            if isinstance(payload, str):
                data = json.loads(payload)
                captured_messages.append(data)
        except Exception:
            pass

    ws.on("framereceived", on_frame_received)


def capture_stream(url: str, duration_seconds: int = 15):
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        page.on("websocket", on_web_socket)
        page.goto(url, wait_until="networkidle", timeout=30000)

        # Listen for stream messages for the specified duration
        time.sleep(duration_seconds)
        browser.close()

    return captured_messages


def main():
    target_url = "https://target-crypto-exchange.com/live"
    data = capture_stream(target_url, duration_seconds=10)
    print(json.dumps(data, indent=2))


if __name__ == "__main__":
    main()
```

---

## 2. Direct Python WebSocket Client (`websockets`)

When the WebSocket handshake parameters, subscription topics, and auth headers are known, query the socket directly:

```python
#!/usr/bin/env python3
import asyncio
import json
import sys
import websockets

SOCKET_URI = "wss://stream.target-site.com/ws"


async def listen_socket():
    async with websockets.connect(
        SOCKET_URI,
        extra_headers={"User-Agent": "Mozilla/5.0"},
        ping_interval=20,
    ) as ws:
        # Send subscription handshake payload
        subscribe_msg = {
            "action": "subscribe",
            "channels": ["live_quotes", "market_trades"],
        }
        await ws.send(json.dumps(subscribe_msg))
        print("Subscription message sent. Listening for events...", file=sys.stderr)

        message_count = 0
        while message_count < 50:
            msg = await ws.recv()
            data = json.loads(msg)
            print(json.dumps(data))
            message_count += 1


if __name__ == "__main__":
    asyncio.run(listen_socket())
```

---

## 3. Server-Sent Events (SSE) Scraping with `httpx`

```python
import json
import httpx


def stream_sse(url: str):
    headers = {"Accept": "text/event-stream"}
    with httpx.stream("GET", url, headers=headers, timeout=60) as response:
        for line in response.iter_lines():
            if line.startswith("data:"):
                raw_payload = line[5:].strip()
                try:
                    event_data = json.loads(raw_payload)
                    yield event_data
                except json.JSONDecodeError:
                    yield {"raw": raw_payload}
```
