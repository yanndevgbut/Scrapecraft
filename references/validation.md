# Validation Checklist

This document defines how to validate scraping code before delivering it to the user.

## Validation Pipeline

Run these checks in order. If any check fails, the code is NOT ready for delivery.

### Check 1: Exit Code

```bash
timeout 45 python3 scraper.py > /tmp/scrapecraft_output.json 2> /tmp/scrapecraft_stderr.log
EXIT_CODE=$?
```

| Exit Code | Meaning | Action |
|---|---|---|
| 0 | Success | Proceed to next check |
| 1 | Script error (explicit `sys.exit(1)`) | Read stderr, fix the root cause |
| 124 | Timeout (45 seconds exceeded) | Optimize: reduce wait times, check for infinite loops |
| 137 | OOM killed | Reduce data volume or fix memory leak |

### Check 2: Output Not Empty

```bash
OUTPUT_SIZE=$(wc -c < /tmp/scrapecraft_output.json)
if [ "$OUTPUT_SIZE" -lt 3 ]; then
    echo "FAIL: Output is empty or trivial"
fi
```

Minimum valid output is `[]` (2 bytes) for an empty array. But an empty array itself indicates a selector failure -- investigate why zero items were found.

### Check 3: Valid JSON

```bash
python3 -c "import json; json.load(open('/tmp/scrapecraft_output.json'))" 2>&1
```

If this fails, the output contains malformed JSON. Common causes:
- Print statements mixed with JSON output (diagnostic prints must go to stderr).
- Encoding issues (non-UTF-8 characters).
- Incomplete JSON due to timeout mid-write.

### Check 4: Data Quality

```python
import json
import sys

with open("/tmp/scrapecraft_output.json") as f:
    data = json.load(f)

if not isinstance(data, list):
    print("FAIL: Output is not a JSON array", file=sys.stderr)
    sys.exit(1)

if len(data) == 0:
    print("FAIL: Zero records extracted", file=sys.stderr)
    sys.exit(1)

empty_fields = 0
total_fields = 0
for record in data:
    for key, value in record.items():
        total_fields += 1
        if not value or (isinstance(value, str) and not value.strip()):
            empty_fields += 1

empty_ratio = empty_fields / total_fields if total_fields > 0 else 1
if empty_ratio > 0.5:
    print(f"FAIL: {empty_ratio:.0%} of fields are empty", file=sys.stderr)
    sys.exit(1)

print(f"OK: {len(data)} records, {empty_ratio:.0%} empty fields", file=sys.stderr)
```

### Check 5: No Forbidden Patterns in Code

Scan the generated code for forbidden patterns:

```bash
FORBIDDEN="mock_data|sample_data|fake_|dummy_|test_data|example_data|TODO|FIXME|HACK|XXX|placeholder|your_|<INSERT>"

if grep -qEi "$FORBIDDEN" scraper.py; then
    echo "FAIL: Code contains forbidden patterns"
    grep -nEi "$FORBIDDEN" scraper.py
fi
```

### Check 6: No Emoji in Code

```bash
if python3 -c "
import re, sys
with open('scraper.py') as f:
    content = f.read()
emoji_pattern = re.compile('[\U0001f600-\U0001f64f\U0001f300-\U0001f5ff\U0001f680-\U0001f6ff\U0001f1e0-\U0001f1ff\U00002702-\U000027b0\U0001f900-\U0001f9ff\U0001fa00-\U0001fa6f\U0001fa70-\U0001faff\U00002600-\U000026ff]')
if emoji_pattern.search(content):
    sys.exit(1)
"; then
    echo "OK: No emoji found"
else
    echo "FAIL: Code contains emoji characters"
fi
```

## Validation Result Matrix

| All Checks Pass | Action |
|---|---|
| Yes | Deliver the code to the user |
| No (fixable) | Enter error correction loop (max 3 iterations) |
| No (structural) | Report the issue to the user with explanation |

## Quick Validation Command

For fast validation during development iterations:

```bash
sh scripts/validate-output.sh /tmp/scrapecraft_<session>/scraper.py
```
