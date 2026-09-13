# Domain: Real Estate & Property Scraping

Real estate portals (Zillow, Redfin, Realtor, Rumah123, Domain, Rightmove) feature map-bounded viewports, listing card grids, property specification matrices, and historical transaction tables.

---

## Core Data Schema

| Field | Type | Description |
|---|---|---|
| `listing_id` | `str` | MLS number or portal listing identifier |
| `title` | `str` | Listing headline |
| `property_type` | `str` | `Single Family`, `Condo`, `Apartment`, `Townhouse`, `Land` |
| `price` | `float` | Listing price parsed to numeric value |
| `currency` | `str` | ISO 3-letter currency code |
| `bedrooms` | `int | float` | Number of bedrooms |
| `bathrooms` | `float` | Number of full + half bathrooms |
| `square_feet` | `float | null` | Total living area in sq ft / sq meters |
| `lot_size` | `str | null` | Lot area description |
| `address` | `dict` | Structured address (`street`, `city`, `state`, `zipcode`, `country`) |
| `coordinates` | `dict | null` | Latitude & longitude coordinates (`{"lat": float, "lng": float}`) |
| `year_built` | `int | null` | Year the structure was constructed |
| `price_per_sqft` | `float | null` | Calculated unit price |
| `url` | `str` | Direct listing URL |

---

## Strategy 1: Map Viewport Bounding Box API Reverse Engineering

Portals load listings based on map coordinates. Intercepting this endpoint allows querying specific geographical bounding boxes:

```python
import httpx

API_ENDPOINT = "https://www.target-realestate.com/api/v2/listings/map"
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
    "Accept": "application/json",
    "Referer": "https://www.target-realestate.com/homes-for-sale",
}


def fetch_properties_in_bounds(
    north: float, south: float, east: float, west: float, page: int = 1
) -> list[dict]:
    params = {
        "north": north,
        "south": south,
        "east": east,
        "west": west,
        "page": page,
        "limit": 50,
        "status": "for_sale",
    }

    response = httpx.get(API_ENDPOINT, headers=HEADERS, params=params, timeout=30)
    if response.status_code != 200:
        return []

    data = response.json()
    raw_listings = data.get("listings", [])
    results = []

    for item in raw_listings:
        results.append({
            "listing_id": str(item.get("id")),
            "title": item.get("title"),
            "property_type": item.get("propertyType"),
            "price": float(item.get("price", 0)) or None,
            "bedrooms": item.get("beds"),
            "bathrooms": item.get("baths"),
            "square_feet": item.get("sqft"),
            "coordinates": {
                "lat": item.get("latitude"),
                "lng": item.get("longitude"),
            },
            "url": f"https://www.target-realestate.com/property/{item.get('slug')}",
        })
    return results
```

---

## Strategy 2: SingleListing JSON-LD Schema

```python
import json
from parsel import Selector


def extract_real_estate_schema(html: str) -> dict:
    sel = Selector(text=html)
    scripts = sel.css('script[type="application/ld+json"]::text').getall()

    for raw in scripts:
        try:
            data = json.loads(raw)
            if data.get("@type") in ["SingleFamilyResidence", "Apartment", "RealEstateListing", "Place"]:
                geo = data.get("geo", {})
                return {
                    "title": data.get("name"),
                    "price": float(data.get("offers", {}).get("price", 0)) or None,
                    "currency": data.get("offers", {}).get("priceCurrency", "USD"),
                    "bedrooms": data.get("numberOfRooms") or data.get("numberOfBedrooms"),
                    "bathrooms": data.get("numberOfBathroomsTotal"),
                    "square_feet": data.get("floorSize", {}).get("value"),
                    "coordinates": {
                        "lat": float(geo.get("latitude")) if geo.get("latitude") else None,
                        "lng": float(geo.get("longitude")) if geo.get("longitude") else None,
                    },
                }
        except json.JSONDecodeError:
            continue
    return {}
```
