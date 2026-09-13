# Storage & Database Export Pipelines

Production scrapers need to store data in persistent formats beyond flat JSON files, including SQLite, PostgreSQL, DuckDB, and Parquet.

---

## 1. SQLite Storage Pipeline (Python Built-In)

SQLite provides single-file relational storage without external server dependencies:

```python
import sqlite3


class SQLiteStoragePipeline:
    def __init__(self, db_path: str = "scraped_data.db"):
        self.conn = sqlite3.connect(db_path)
        self.cursor = self.conn.cursor()
        self.create_table()

    def create_table(self):
        self.cursor.execute("""
            CREATE TABLE IF NOT EXISTS products (
                sku TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                price REAL,
                currency TEXT,
                url TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        self.conn.commit()

    def insert_batch(self, records: list[dict]):
        self.cursor.executemany("""
            INSERT OR REPLACE INTO products (sku, title, price, currency, url)
            VALUES (:sku, :title, :price, :currency, :url)
        """, records)
        self.conn.commit()

    def close(self):
        self.conn.close()
```

---

## 2. DuckDB / Parquet Analytics Export

For high-performance analytical datasets:

```python
import duckdb


def export_records_to_parquet(records: list[dict], output_parquet_path: str):
    con = duckdb.connect()
    # Query Python dictionary list directly with SQL
    con.execute("CREATE TABLE data AS SELECT * FROM records")
    con.execute(f"COPY data TO '{output_parquet_path}' (FORMAT PARQUET, COMPRESSION ZSTD)")
    con.close()
```
