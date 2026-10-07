# Client Identity Spoofing Matrix

Internal APIs validate the calling client's declared identity. Sending the wrong `clientName`, stale `clientVersion`, or a fictional `User-Agent` produces empty responses, wrong payload shapes, or bot challenges. This playbook defines verified client identities per platform.

---

## Why Identity Matters

Internal API endpoints branch on the declared client:

- `clientName: "WEB"` vs `"WEB_REMIX"` vs `"ANDROID"` returns **different JSON structures** for the same endpoint.
- Version skew (declaring a clientVersion older than the live site) triggers degraded responses.
- `User-Agent` must correlate with the declared client (an ANDROID client claiming a Windows Chrome UA is an immediate red flag).

---

## YouTube / YouTube Music Client Identities

| Context | clientName | Client Version Pattern | UA Family | Notes |
|---|---|---|---|---|
| YouTube Web | `WEB` | `2.2025MMDD.XX.XX` | Desktop Chrome | Standard youtube.com |
| YouTube Music Web | `WEB_REMIX` | `1.2025MMDD.XX.XX` | Desktop Chrome | music.youtube.com |
| YouTube Embedded | `WEB_EMBEDDED_PLAYER` | `1.2025MMDD.XX.XX` | Desktop Chrome | For embed contexts |
| YouTube Android | `ANDROID` | `19.44.38` | Android UA (`com.google.android.youtube/19.44.38`) | Different response shapes |
| YT Music Android | `ANDROID_MUSIC` | `7.16.53` | Android UA | Mobile music app |
| YouTube iOS | `IOS` | `19.45.4` | iOS UA (`com.google.ios.youtube/19.45.4`) | iPhone device claims |
| TV | `TVHTML5` | `7.2025MMDD.XX.XX` | Smart TV UA | Living-room clients |

**Rule**: Always extract the CURRENT `clientVersion` from the live homepage during bootstrap (see `references/internal-api-bootstrap.md`). The table above defines the FORMAT, not fixed values.

---

## Locale & Region Parameters

| Parameter | Meaning | Example |
|---|---|---|
| `hl` | Interface language (ISO 639-1) | `id`, `en` |
| `gl` | Geo country (ISO 3166-1 alpha-2) | `ID`, `US` |

Declaring `hl`/`gl` shapes localized content (titles, availability, currency). Match them to the user's scraping goal.

---

## Other Platforms' Identity Anchors

| Platform | Identity Anchor | Where Harvested |
|---|---|---|
| TikTok | `X-Bogus` / `msToken` params + `UA-TT` headers | Homepage JS bundles |
| Shopee | `af-ac-enc-dat` anti-fraud headers + `csrftoken` | Homepage + cookie jar |
| Tokopedia | `x-tokopedia-token` + device fingerprint | Homepage JSON state |
| Spotify | `sp_t` cookie + `client-token` | Bootstrap JSON |
| Twitter/X | `x-csrf-token` header + `ct0` cookie | Homepage cookie jar |

---

## User-Agent Reality Rules

### Forbidden (Fictional Versions)

```text
Chrome/154.0.0.0        <- does not exist; Chrome 131 is current as of early 2026
Chrome/200.0.0.0
Firefox/200.0
```

Fictional versions break internal consistency: WAFs cross-check UA version against `sec-ch-ua` and TLS fingerprint.

### Correct (Real, Current, Consistent)

```text
Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36
```

With matching client hints:

```text
sec-ch-ua: "Chromium";v="131", "Google Chrome";v="131"
sec-ch-ua-platform: "Windows"
sec-ch-ua-mobile: ?0
```

### The Consistency Triangle

```
   User-Agent version
        /        \
  sec-ch-ua    TLS fingerprint (JA3/JA4)
        \        /
   Declared clientVersion (API context)
```

All three corners must agree. Verify with the 10-Point Pre-Flight Audit (`references/anti-blocking-checklist.md`).

---

## Android Client Full Example

When choosing the ANDROID client for different response shapes:

```javascript
const androidHeaders = {
  "User-Agent": "com.google.android.youtube/19.44.38 (Linux; U; Android 15) gzip",
  "X-YouTube-Client-Name": "3",
  "X-YouTube-Client-Version": "19.44.38",
  "Content-Type": "application/json",
};

const androidContext = {
  client: {
    clientName: "ANDROID",
    clientVersion: "19.44.38",
    androidSdkVersion: 35,
    osName: "Android",
    osVersion: "15",
    hl: "id",
    gl: "ID",
  },
};
```

---

## Identity Validation Checklist (Per Target)

1. Bootstrap extracted a CURRENT `clientVersion` from live HTML (not hardcoded).
2. `clientName` matches the platform surface being scraped.
3. `User-Agent` family matches the declared client (web=desktop Chrome, android=Android UA).
4. `sec-ch-ua` headers match the UA major version.
5. `hl`/`gl` locales declared deliberately, matching the user's target region.
6. Session tokens (visitor ID, CSRF) injected into BOTH headers and context payload.
