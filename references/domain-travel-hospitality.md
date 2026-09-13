# Domain: Travel & Hospitality Scraping

Travel aggregators and hospitality engines (Booking.com, Airbnb, Agoda, Expedia, Skyscanner, Google Flights) utilize date matrix selectors, occupancy parameters, live pricing updates, and geo-spatial room searches.

---

## Core Data Schema

| Field | Type | Description |
|---|---|---|
| `property_id` | `str` | Portal accommodation ID |
| `name` | `str` | Hotel or rental property name |
| `property_type` | `str` | `Hotel`, `Resort`, `Apartment`, `Villa`, `Hostel` |
| `star_rating` | `int | null` | Official star classification (1-5) |
| `review_score` | `float | null` | Guest review average score (e.g. 8.9 / 10.0) |
| `review_count` | `int | null` | Total verified guest reviews |
| `price_per_night`| `float` | Base night rate |
| `total_price` | `float | null` | Total rate inclusive of taxes & fees |
| `currency` | `str` | ISO 3-letter currency code |
| `address` | `str` | Full street address or area |
| `coordinates` | `dict | null` | `{"lat": float, "lng": float}` |
| `amenities` | `list[str]` | Amenity tags (e.g. Free WiFi, Pool, Breakfast) |
| `url` | `str` | Direct booking link |

---

## Strategy 1: Intercepting Search Result JSON Payloads

Hospitality sites query internal search endpoints as users adjust date ranges and guest counts. Intercept the JSON response with Playwright:

```python
import json
from playwright.sync_api import sync_playwright

hotel_listings = []


def on_response(response):
    if any(endpoint in response.url for endpoint in ["searchresults", "graphql", "properties/v2/list"]):
        if response.status == 200 and "application/json" in response.headers.get("content-type", ""):
            try:
                data = response.json()
                hotel_listings.append(data)
            except Exception:
                pass


def capture_travel_search(search_url: str):
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        page.on("response", on_response)
        page.goto(search_url, wait_until="networkidle", timeout=40000)
        browser.close()
    return hotel_listings
```

---

## Strategy 2: Hotel Schema.org Extraction

```python
import json
from parsel import Selector


def extract_hotel_schema(html: str) -> dict:
    sel = Selector(text=html)
    scripts = sel.css('script[type="application/ld+json"]::text').getall()

    for raw in scripts:
        try:
            data = json.loads(raw)
            if data.get("@type") in ["Hotel", "LodgingBusiness", "Resort"]:
                geo = data.get("geo", {})
                return {
                    "name": data.get("name"),
                    "star_rating": data.get("starRating", {}).get("ratingValue"),
                    "review_score": float(data.get("aggregateRating", {}).get("ratingValue", 0)) or None,
                    "review_count": int(data.get("aggregateRating", {}).get("reviewCount", 0)) or None,
                    "address": data.get("address", {}).get("streetAddress"),
                    "coordinates": {
                        "lat": float(geo.get("latitude")) if geo.get("latitude") else None,
                        "lng": float(geo.get("longitude")) if geo.get("longitude") else None,
                    },
                }
        except json.JSONDecodeError:
            continue
    return {}
```
