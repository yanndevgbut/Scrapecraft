# Validation Checklist

This document defines the automated validation pipeline every ScrapeCraft script must pass prior to delivery.

## 6-Stage Validation Pipeline

### Check 1: Process Exit Code
```bash
timeout 45 python3 scraper.py > output.json 2> stderr.log
EXIT_CODE=$?
```
- Must exit with code `0`. Non-zero indicates unhandled exceptions or connection drops.

### Check 2: Output Density & Volume
- Output must be non-empty and contain at least 1 extracted record.
- If record count is 0, the container selector or state key failed.

### Check 3: JSON / JSONL / CSV Schema Integrity
- Output must be valid, well-formed JSON array, line-delimited JSON, or standard CSV.
- No diagnostic text or trace logs intermixed in stdout.

### Check 4: Data Normalization Audit
```python
import json
import sys

data = json.load(open("output.json"))
if not isinstance(data, list) or len(data) == 0:
    sys.exit(1)

for record in data:
    # 1. URL absolute check
    for key, val in record.items():
        if "url" in key.lower() or "link" in key.lower():
            if isinstance(val, str) and val.startswith(("/", "./", "../")):
                print(f"FAIL: Unresolved relative URL in {key}: {val}", file=sys.stderr)
                sys.exit(1)

    # 2. Clean text check
    for key, val in record.items():
        if isinstance(val, str):
            if any(entity in val for entity in ["&amp;", "&lt;", "&gt;", "&quot;", "&#39;"]):
                print(f"FAIL: Unescaped HTML entity in {key}: {val}", file=sys.stderr)
                sys.exit(1)
```

### Check 5: Forbidden Token Audit
```bash
FORBIDDEN="mock_data|sample_data|fake_|dummy_|test_data|example_data|TODO|FIXME|HACK|XXX|placeholder|your_|<INSERT"
if grep -qEi "$FORBIDDEN" scraper.py; then
    echo "FAIL: Forbidden tokens found in code" >&2
    exit 1
fi
```

### Check 6: Emoji & Decorative Comments Audit
```bash
python3 -c "
import re, sys
with open('scraper.py') as f:
    text = f.read()
emoji_re = re.compile('[\U0001f600-\U0001f64f\U0001f300-\U0001f5ff\U0001f680-\U0001f6ff\U0001f1e0-\U0001f1ff\U00002702-\U000027b0\U0001f900-\U0001f9ff\U0001fa00-\U0001fa6f\U0001fa70-\U0001faff\U00002600-\U000026ff]')
if emoji_re.search(text):
    print('FAIL: Emoji detected in code', file=sys.stderr)
    sys.exit(1)
"
```

## Fast Validation Command

```bash
bash scripts/validate-output.sh /tmp/scrapecraft_<session>/scraper.py /tmp/scrapecraft_<session>/output.json
```
