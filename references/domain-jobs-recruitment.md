# Domain: Jobs & Recruitment Scraping

Job boards and corporate career portals (LinkedIn, Indeed, Glassdoor, Lever, Greenhouse, Workday) require robust handling of salary ranges, remote/hybrid policies, skill tag arrays, and application deadline timestamps.

---

## Core Data Schema

| Field | Type | Description |
|---|---|---|
| `job_id` | `str` | Unique job listing ID |
| `title` | `str` | Standardized job title |
| `company` | `str` | Employer/organization name |
| `location` | `str` | City, State, Country |
| `workplace_type` | `str` | `Remote`, `Hybrid`, or `On-site` |
| `employment_type`| `str` | `Full-time`, `Part-time`, `Contract`, `Internship` |
| `salary` | `dict` | Salary object (`min: float`, `max: float`, `currency: str`, `interval: str`) |
| `description` | `str` | Clean body text of the job description |
| `skills` | `list[str]` | Extracted requirements and tech-stack tags |
| `posted_at` | `str` | ISO-8601 publication date |
| `apply_url` | `str` | Direct application URL |

---

## Strategy 1: JobPosting Schema.org Extraction

Job search engines (Google Jobs, Indeed, LinkedIn public postings) comply with Google's structured job posting specification:

```python
import json
from parsel import Selector


def extract_job_schema(html: str, fallback_url: str) -> dict:
    sel = Selector(text=html)
    scripts = sel.css('script[type="application/ld+json"]::text').getall()

    for raw in scripts:
        try:
            data = json.loads(raw)
            items = data if isinstance(data, list) else [data]
            for item in items:
                if item.get("@type") == "JobPosting":
                    base_salary = item.get("baseSalary", {}).get("value", {})
                    salary_obj = None
                    if base_salary:
                        salary_obj = {
                            "min": float(base_salary.get("minValue") or base_salary.get("value") or 0) or None,
                            "max": float(base_salary.get("maxValue") or 0) or None,
                            "currency": item.get("baseSalary", {}).get("currency", "USD"),
                            "interval": item.get("baseSalary", {}).get("value", {}).get("unitText", "YEAR"),
                        }

                    location_data = item.get("jobLocation", {})
                    address = location_data.get("address", {}) if isinstance(location_data, dict) else {}
                    loc_str = ", ".join(filter(None, [
                        address.get("addressLocality"),
                        address.get("addressRegion"),
                        address.get("addressCountry"),
                    ])) if address else "Not specified"

                    return {
                        "job_id": str(item.get("identifier", {}).get("value") or ""),
                        "title": item.get("title", "").strip(),
                        "company": item.get("hiringOrganization", {}).get("name", "").strip(),
                        "location": loc_str,
                        "workplace_type": "Remote" if item.get("jobLocationType") == "TELECOMMUTE" else "On-site",
                        "employment_type": item.get("employmentType", "FULL_TIME"),
                        "salary": salary_obj,
                        "description": item.get("description", "").strip(),
                        "posted_at": item.get("datePosted"),
                        "apply_url": item.get("directApply") or fallback_url,
                    }
        except json.JSONDecodeError:
            continue
    return {}
```

---

## Strategy 2: Greenhouse & Lever API Scraping

Greenhouse and Lever career pages load all open jobs via public JSON APIs:

```python
import httpx


def scrape_greenhouse_board(board_token: str) -> list[dict]:
    url = f"https://boards-api.greenhouse.io/v1/boards/{board_token}/jobs?content=true"
    response = httpx.get(url, timeout=30)
    if response.status_code != 200:
        return []

    jobs = response.json().get("jobs", [])
    results = []
    for j in jobs:
        results.append({
            "job_id": str(j.get("id")),
            "title": j.get("title"),
            "location": j.get("location", {}).get("name"),
            "posted_at": j.get("updated_at"),
            "description": j.get("content"),
            "apply_url": j.get("absolute_url"),
        })
    return results
```
