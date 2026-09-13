# Document & PDF Table Extraction

Enterprise data is frequently published within PDF documents (financial statements, government reports, product spec sheets, research papers). ScrapeCraft provides structured PDF extraction pipelines for converting tabular PDF data into clean JSON/CSV datasets.

---

## Library Selection

| Library | Role | Install |
|---|---|---|
| `pdfplumber` | High-precision table & text layout extraction | `pip install pdfplumber` |
| `pypdf` | Fast metadata, text parsing, and stream reading | `pip install pypdf` |
| `fitz` (`PyMuPDF`) | Ultra-fast rendering & image/text extraction | `pip install pymupdf` |

---

## Strategy 1: Table Extraction with `pdfplumber`

```python
#!/usr/bin/env python3
import json
import sys
import pdfplumber


def extract_pdf_tables(pdf_path: str) -> list[dict]:
    all_table_records = []

    with pdfplumber.open(pdf_path) as pdf:
        for page_idx, page in enumerate(pdf.pages, start=1):
            tables = page.extract_tables({
                "vertical_strategy": "lines",
                "horizontal_strategy": "lines",
                "snap_tolerance": 3,
            }) or page.extract_tables({
                "vertical_strategy": "text",
                "horizontal_strategy": "text",
            })

            for table in tables:
                if not table or len(table) < 2:
                    continue

                headers = [str(h).strip().replace("\n", " ") if h else f"col_{i}" for i, h in enumerate(table[0])]

                for row in table[1:]:
                    if not any(row):
                        continue
                    record = {
                        headers[i]: str(val).strip().replace("\n", " ") if val is not None else ""
                        for i, val in enumerate(row)
                        if i < len(headers)
                    }
                    record["_page"] = page_idx
                    all_table_records.append(record)

    return all_table_records


def main():
    pdf_file = sys.argv[1] if len(sys.argv) > 1 else "sample.pdf"
    data = extract_pdf_tables(pdf_file)
    print(json.dumps(data, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
```

---

## Strategy 2: Download & Extract Remote PDF Streams

```python
import tempfile
import httpx
import pdfplumber


def download_and_extract_pdf(pdf_url: str) -> list[dict]:
    with tempfile.NamedTemporaryFile(suffix=".pdf") as tmp:
        with httpx.stream("GET", pdf_url, follow_redirects=True, timeout=60) as resp:
            for chunk in resp.iter_bytes():
                tmp.write(chunk)
        tmp.flush()

        return extract_pdf_tables(tmp.name)
```
