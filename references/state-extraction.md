# Direct State Extraction Playbook

Modern web applications frequently embed complete, structured datasets directly inside the initial HTML payload to support Server-Side Rendering (SSR) and client hydration. Extracting from embedded state is **10x to 100x faster** than DOM selector traversal and immune to CSS class changes.

## Hierarchy of Embedded State Targets

Always check for embedded state in this order before attempting HTML selector parsing:

| Target | Framework / Format | Typical Location |
|---|---|---|
| 1. Next.js App / Pages | Next.js SSR State | `<script id="__NEXT_DATA__" type="application/json">` |
| 2. Nuxt.js / Vue | Nuxt 2/3 SSR State | `<script>window.__NUXT__=...</script>` or `<script id="__NUXT_DATA__">` |
| 3. Schema.org JSON-LD | Structured Metadata | `<script type="application/ld+json">` |
| 4. React / Redux / Custom | Hydration Blobs | `window.__INITIAL_STATE__`, `window.__PRELOADED_STATE__`, `window.__APOLLO_STATE__` |
| 5. Remix / React Router | Remix SSR State | `<script>window.__remixContext = ...</script>` |

---

## 1. Next.js (`__NEXT_DATA__`) Extraction

Next.js embeds page props, query parameters, and preloaded API data in `#__NEXT_DATA__`.

### Python Implementation

```python
#!/usr/bin/env python3
import json
import sys
import httpx
from parsel import Selector

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
}


def extract_next_data(html: str) -> dict:
    sel = Selector(text=html)
    raw_script = sel.css("script#__NEXT_DATA__::text").get()
    if not raw_script:
        return {}
    try:
        return json.loads(raw_script)
    except json.JSONDecodeError:
        return {}


def scrape(url: str):
    response = httpx.get(url, headers=HEADERS, timeout=30, follow_redirects=True)
    if response.status_code != 200:
        print(f"HTTP {response.status_code}: {url}", file=sys.stderr)
        sys.exit(1)

    data = extract_next_data(response.text)
    if not data:
        print("No __NEXT_DATA__ found in payload.", file=sys.stderr)
        sys.exit(1)

    page_props = data.get("props", {}).get("pageProps", {})
    return page_props


def main():
    url = "TARGET_URL"
    data = scrape(url)
    print(json.dumps(data, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
```

### Node.js Implementation

```javascript
#!/usr/bin/env node
const axios = require("axios");
const cheerio = require("cheerio");

const HEADERS = {
  "User-Agent":
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
};

async function extractNextData(html) {
  const $ = cheerio.load(html);
  const rawScript = $("script#__NEXT_DATA__").html();
  if (!rawScript) return null;
  try {
    return JSON.parse(rawScript);
  } catch (_) {
    return null;
  }
}

async function scrape(url) {
  const response = await axios.get(url, { headers: HEADERS, timeout: 30000 });
  const payload = await extractNextData(response.data);
  if (!payload) {
    console.error("No __NEXT_DATA__ found in payload.");
    process.exit(1);
  }
  return payload.props?.pageProps || payload;
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

---

## 2. Schema.org JSON-LD Extraction

E-commerce, news, recipe, and job listing websites almost universally embed standardized Schema.org JSON-LD objects.

### Python Implementation

```python
import json
from parsel import Selector


def extract_json_ld(html: str) -> list:
    sel = Selector(text=html)
    scripts = sel.css('script[type="application/ld+json"]::text').getall()
    objects = []
    for raw in scripts:
        try:
            parsed = json.loads(raw)
            if isinstance(parsed, list):
                objects.extend(parsed)
            elif isinstance(parsed, dict):
                if "@graph" in parsed:
                    objects.extend(parsed["@graph"])
                else:
                    objects.append(parsed)
        except json.JSONDecodeError:
            continue
    return objects


def find_schema_type(objects: list, schema_type: str) -> list:
    results = []
    for obj in objects:
        t = obj.get("@type")
        if t == schema_type or (isinstance(t, list) and schema_type in t):
            results.append(obj)
    return results
```

---

## 3. Inline JavaScript State Extraction

When data is assigned to global window variables:

```python
import json
import re


def extract_window_var(html: str, var_name: str) -> dict:
    patterns = [
        rf"window\.{re.escape(var_name)}\s*=\s*({{.*?}});\s*</script>",
        rf"window\.{re.escape(var_name)}\s*=\s*(\[.*?\]);\s*</script>",
        rf"window\['{re.escape(var_name)}'\]\s*=\s*({{.*?}});\s*</script>",
        rf"var\s+{re.escape(var_name)}\s*=\s*({{.*?}});\s*</script>",
    ]
    for pattern in patterns:
        match = re.search(pattern, html, re.DOTALL)
        if match:
            try:
                return json.loads(match.group(1))
            except json.JSONDecodeError:
                pass
    return {}
```

---

## Decision Flow: State vs DOM

```
Target Page Loaded
       │
       ├─► Check <script id="__NEXT_DATA__"> ──► [Found] ──► Parse JSON directly (Best)
       ├─► Check <script type="application/ld+json"> ──► [Found] ──► Extract Schema.org objects
       ├─► Check window.__INITIAL_STATE__ / Nuxt ──► [Found] ──► Regex JSON parse
       │
       └─► [None Found] ──► Fallback to Resilient DOM Selectors
```
