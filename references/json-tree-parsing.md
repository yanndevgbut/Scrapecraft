# Deep JSON Tree Parsing

Internal APIs return deeply nested JSON payloads (YouTube Innertube responses reach 20+ levels deep) where **renderer shapes vary by context**. This playbook defines the resilient parsing patterns for such trees.

---

## Core Problems with Deep JSON APIs

| Problem | Manifestation |
|---|---|
| Shape polymorphism | Same entity appears as `musicResponsiveListItemRenderer`, `musicTwoRowItemRenderer`, or `musicCardShelfRenderer` depending on placement |
| Path instability | `contents.tabbedSearchResultsRenderer.tabs[0]...` restructures when A/B tests ship |
| Text as run arrays | Strings arrive as `[{text: "Hello"}, {text: " World"}]` instead of plain text |
| ID placement drift | `videoId` may live in navigationEndpoint, overlay buttons, or playlistItemData |
| Duplicates across shelves | Same item appears in "Top result" and category shelves |

---

## 1. Recursive Key Finder

The universal fallback: find every occurrence of a key anywhere in the tree.

```javascript
findAll(obj, key, results = []) {
  if (!obj || typeof obj !== "object") return results;
  if (obj[key] !== undefined) results.push(obj[key]);
  for (const val of Object.values(obj)) {
    if (val && typeof val === "object") {
      this.findAll(val, key, results);
    }
  }
  return results;
}
```

```python
def find_all(obj, key, results=None):
    if results is None:
        results = []
    if not isinstance(obj, dict):
        return results
    if key in obj:
        results.append(obj[key])
    for value in obj.values():
        if isinstance(value, dict):
            find_all(value, key, results)
        elif isinstance(value, list):
            for item in value:
                find_all(item, key, results)
    return results
```

---

## 2. Text Run Resolver

Handle every text encoding variant in one function:

```javascript
text(runs) {
  if (!runs) return "";
  if (typeof runs === "string") return runs;
  if (Array.isArray(runs)) return runs.map((r) => r?.text || "").join("");
  return runs.text || "";
}
```

```python
def resolve_text(runs) -> str:
    if not runs:
        return ""
    if isinstance(runs, str):
        return runs
    if isinstance(runs, list):
        return "".join(run.get("text", "") if isinstance(run, dict) else str(run) for run in runs)
    if isinstance(runs, dict):
        return runs.get("text", "")
    return ""
```

---

## 3. Multi-Shape Parser Strategy

Write one parser per renderer shape, then route by key:

```python
def parse_section(section: dict) -> list[dict]:
    results = []
    if "musicCardShelfRenderer" in section:
        item = parse_card(section["musicCardShelfRenderer"])
        if item:
            results.append(item)
    if "musicShelfRenderer" in section:
        shelf = section["musicShelfRenderer"]
        shelf_title = resolve_text(shelf.get("title", {}))
        for entry in shelf.get("contents", []):
            renderer = entry.get("musicResponsiveListItemRenderer")
            if renderer:
                parsed = parse_list_item(renderer)
                if parsed:
                    parsed["category"] = shelf_title
                    results.append(parsed)
    return results
```

Each parser extracts IDs from ALL known locations (overlay buttons, navigation runs, playlistItemData) before giving up:

```javascript
extractVideoId(renderer) {
  // Location 1: play button overlay
  const playBtn = renderer.overlay?.musicItemThumbnailOverlayRenderer?.content?.musicPlayButtonRenderer;
  if (playBtn?.playNavigationEndpoint?.watchEndpoint?.videoId) {
    return playBtn.playNavigationEndpoint.watchEndpoint.videoId;
  }
  // Location 2: title text runs navigation
  const runs = renderer.flexColumns?.[0]?.musicResponsiveListItemFlexColumnRenderer?.text?.runs || [];
  for (const run of runs) {
    if (run.navigationEndpoint?.watchEndpoint?.videoId) {
      return run.navigationEndpoint.watchEndpoint.videoId;
    }
  }
  // Location 3: playlist item data
  if (renderer.playlistItemData?.videoId) {
    return renderer.playlistItemData.videoId;
  }
  // Location 4: direct navigation endpoint
  if (renderer.navigationEndpoint?.watchEndpoint?.videoId) {
    return renderer.navigationEndpoint.watchEndpoint.videoId;
  }
  return null;
}
```

---

## 4. Per-Item Try/Catch (Batch Resilience)

One malformed item must never kill the whole batch:

```python
def parse_batch(renderers: list[dict]) -> list[dict]:
    results = []
    for renderer in renderers:
        try:
            parsed = parse_list_item(renderer)
            if parsed:
                results.append(parsed)
        except Exception as exc:
            print(f"Skipping malformed item: {exc}", file=sys.stderr)
            continue
    return results
```

Rules:
- Catch per item, log to stderr with enough context to debug.
- Continue the loop after a failed item.
- If MORE THAN HALF of items fail, the shape changed: escalate to structural re-inspection (see `references/error-correction.md`).

---

## 5. Deduplication Strategy

Multi-shelf responses duplicate items. Dedup by stable identifiers in priority order:

```python
def dedup_results(results: list[dict]) -> list[dict]:
    seen = set()
    unique = []
    for item in results:
        # Priority 1: unique content ID
        identity = item.get("videoId") or item.get("browseId")
        # Priority 2: composite of title + artist
        if not identity:
            title = item.get("title", "")
            artist = item.get("artist", "")
            if title:
                identity = f"{title}::{artist}"
        if not identity:
            continue
        if identity in seen:
            continue
        seen.add(identity)
        unique.append(item)
    return unique
```

---

## 6. Structured Fallback Chain

Always parse the **canonical path first**, then fall back to recursive search:

```javascript
async search(query, filter = "") {
  const data = await this.request("search", body);
  let results = [];

  // Canonical path: tabbed structure
  const sections = data?.contents?.tabbedSearchResultsRenderer?.tabs?.[0]
        ?.tabRenderer?.content?.sectionListRenderer?.contents || [];
  for (const section of sections) {
    results.push(...this.parseSection(section));
  }

  // Fallback: recursive discovery when canonical path yields <= 1 item
  if (results.length <= 1) {
    console.error("[*] Canonical path empty; running recursive fallback...");
    const allItems = this.findAll(data, "musicResponsiveListItemRenderer");
    results = [...results, ...this.parseBatch(allItems)];
    results = this.dedupResults(results);
  }

  return results;
}
```

Decision rule: canonical path returning 0-1 results while `json-explorer.py` shows items elsewhere in the tree = path drift. Fix by re-inspecting with `scripts/json-explorer.py`, then update the canonical path in the next correction iteration.
