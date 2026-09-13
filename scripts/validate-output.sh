#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="${1:?Usage: validate-output.sh <script-path> [output-file]}"
OUTPUT_FILE="${2:-}"

if [ ! -f "$SCRIPT_PATH" ]; then
    echo "FAIL: Script not found: $SCRIPT_PATH" >&2
    exit 1
fi

echo "=== ScrapeCraft Pre-Delivery Validation ===" >&2

FAIL_COUNT=0
SCRIPT_EXT="${SCRIPT_PATH##*.}"
FORBIDDEN_PATTERN="mock_data|sample_data|fake_|dummy_|test_data|example_data|TODO|FIXME|HACK|XXX|placeholder|your_|<INSERT"

# Check 1: Forbidden Tokens
if grep -qEi "$FORBIDDEN_PATTERN" "$SCRIPT_PATH" 2>/dev/null; then
    echo "FAIL: Code contains forbidden placeholder/mock tokens:" >&2
    grep -nEi "$FORBIDDEN_PATTERN" "$SCRIPT_PATH" >&2
    FAIL_COUNT=$((FAIL_COUNT + 1))
else
    echo "OK: Zero forbidden tokens found" >&2
fi

# Check 2: Emoji Hygiene
if python3 -c "
import re, sys
with open('$SCRIPT_PATH') as f:
    content = f.read()
emoji_pattern = re.compile('[\U0001f600-\U0001f64f\U0001f300-\U0001f5ff\U0001f680-\U0001f6ff\U0001f1e0-\U0001f1ff\U00002702-\U000027b0\U0001f900-\U0001f9ff\U0001fa00-\U0001fa6f\U0001fa70-\U0001faff\U00002600-\U000026ff]')
if emoji_pattern.search(content):
    sys.exit(1)
" 2>/dev/null; then
    echo "OK: Zero emoji in code or comments" >&2
else
    echo "FAIL: Code contains emoji characters" >&2
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# Check 3: Language Syntax
if [ "$SCRIPT_EXT" = "py" ]; then
    if python3 -c "
import ast, sys
try:
    with open('$SCRIPT_PATH') as f:
        ast.parse(f.read())
except SyntaxError as e:
    print(f'Syntax error: {e}', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null; then
        echo "OK: Python AST syntax valid" >&2
    else
        echo "FAIL: Python syntax error" >&2
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
elif [ "$SCRIPT_EXT" = "js" ]; then
    if node --check "$SCRIPT_PATH" 2>/dev/null; then
        echo "OK: Node.js JavaScript syntax valid" >&2
    else
        echo "FAIL: Node.js syntax error" >&2
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
fi

# Check 4: Data Quality & Normalization
if [ -n "$OUTPUT_FILE" ] && [ -f "$OUTPUT_FILE" ]; then
    OUTPUT_SIZE=$(wc -c < "$OUTPUT_FILE")
    if [ "$OUTPUT_SIZE" -lt 3 ]; then
        echo "FAIL: Output payload is empty or trivial ($OUTPUT_SIZE bytes)" >&2
        FAIL_COUNT=$((FAIL_COUNT + 1))
    else
        echo "OK: Output payload size: $OUTPUT_SIZE bytes" >&2
    fi

    if python3 -c "
import json, sys

try:
    with open('$OUTPUT_FILE') as f:
        raw_text = f.read().strip()
    
    # Check JSON or JSONL
    if raw_text.startswith('['):
        data = json.loads(raw_text)
    elif raw_text.startswith('{'):
        try:
            data = json.loads(raw_text)
            if isinstance(data, dict):
                data = [data]
        except json.JSONDecodeError:
            data = [json.loads(line) for line in raw_text.splitlines() if line.strip()]
    else:
        data = [json.loads(line) for line in raw_text.splitlines() if line.strip()]

    if not isinstance(data, list) or len(data) == 0:
        print('FAIL: Zero records extracted from target', file=sys.stderr)
        sys.exit(1)

    print(f'OK: {len(data)} structured record(s) parsed', file=sys.stderr)

    empty_fields = 0
    total_fields = 0
    relative_urls = 0
    raw_entities = 0

    for r in data:
        if isinstance(r, dict):
            for k, v in r.items():
                total_fields += 1
                if v is None or (isinstance(v, str) and not v.strip()):
                    empty_fields += 1
                if isinstance(v, str):
                    if ('url' in k.lower() or 'link' in k.lower()) and v.startswith(('/', './', '../')):
                        relative_urls += 1
                    if any(e in v for e in ['&amp;', '&lt;', '&gt;', '&quot;', '&#39;']):
                        raw_entities += 1

    if relative_urls > 0:
        print(f'FAIL: Found {relative_urls} unresolved relative URL(s)', file=sys.stderr)
        sys.exit(1)

    if raw_entities > 0:
        print(f'FAIL: Found {raw_entities} unescaped HTML entity string(s)', file=sys.stderr)
        sys.exit(1)

    if total_fields > 0:
        ratio = empty_fields / total_fields
        if ratio > 0.5:
            print(f'WARNING: High empty field ratio ({ratio:.0%})', file=sys.stderr)
            sys.exit(1)
        else:
            print(f'OK: Data density optimal ({ratio:.0%} empty field ratio)', file=sys.stderr)

except Exception as e:
    print(f'FAIL: Data verification exception: {e}', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null; then
        echo "OK: Normalization & data quality audit passed" >&2
    else
        echo "FAIL: Data quality audit failed" >&2
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
else
    echo "SKIP: No output file passed for runtime data audit" >&2
fi

echo "===========================================" >&2

if [ "$FAIL_COUNT" -gt 0 ]; then
    echo "VALIDATION RESULT: $FAIL_COUNT check(s) failed." >&2
    exit 1
else
    echo "VALIDATION RESULT: ALL CHECKS PASSED. Ready for delivery." >&2
    exit 0
fi
