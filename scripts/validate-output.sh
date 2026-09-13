#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="${1:?Usage: validate-output.sh <script-path> [output-file]}"
OUTPUT_FILE="${2:-}"

if [ ! -f "$SCRIPT_PATH" ]; then
    echo "FAIL: Script not found: $SCRIPT_PATH" >&2
    exit 1
fi

echo "=== ScrapeCraft Validation ===" >&2

FAIL_COUNT=0

SCRIPT_EXT="${SCRIPT_PATH##*.}"
FORBIDDEN_PATTERN="mock_data|sample_data|fake_|dummy_|test_data|example_data|TODO|FIXME|HACK|XXX|placeholder|your_|<INSERT>"

if grep -qEi "$FORBIDDEN_PATTERN" "$SCRIPT_PATH" 2>/dev/null; then
    echo "FAIL: Code contains forbidden patterns:" >&2
    grep -nEi "$FORBIDDEN_PATTERN" "$SCRIPT_PATH" >&2
    FAIL_COUNT=$((FAIL_COUNT + 1))
else
    echo "OK: No forbidden patterns" >&2
fi

if python3 -c "
import re, sys
with open('$SCRIPT_PATH') as f:
    content = f.read()
emoji_pattern = re.compile('[\U0001f600-\U0001f64f\U0001f300-\U0001f5ff\U0001f680-\U0001f6ff\U0001f1e0-\U0001f1ff\U00002702-\U000027b0\U0001f900-\U0001f9ff\U0001fa00-\U0001fa6f\U0001fa70-\U0001faff\U00002600-\U000026ff]')
if emoji_pattern.search(content):
    sys.exit(1)
" 2>/dev/null; then
    echo "OK: No emoji in code" >&2
else
    echo "FAIL: Code contains emoji characters" >&2
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

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
        echo "OK: Python syntax valid" >&2
    else
        echo "FAIL: Python syntax error" >&2
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
elif [ "$SCRIPT_EXT" = "js" ]; then
    if node --check "$SCRIPT_PATH" 2>/dev/null; then
        echo "OK: JavaScript syntax valid" >&2
    else
        echo "FAIL: JavaScript syntax error" >&2
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
fi

if [ -n "$OUTPUT_FILE" ] && [ -f "$OUTPUT_FILE" ]; then
    OUTPUT_SIZE=$(wc -c < "$OUTPUT_FILE")
    if [ "$OUTPUT_SIZE" -lt 3 ]; then
        echo "FAIL: Output is empty or trivial ($OUTPUT_SIZE bytes)" >&2
        FAIL_COUNT=$((FAIL_COUNT + 1))
    else
        echo "OK: Output is $OUTPUT_SIZE bytes" >&2
    fi

    if python3 -c "
import json, sys
try:
    with open('$OUTPUT_FILE') as f:
        data = json.load(f)
    if isinstance(data, list):
        print(f'OK: {len(data)} records in JSON array', file=sys.stderr)
        if len(data) == 0:
            print('WARNING: Zero records extracted', file=sys.stderr)
            sys.exit(1)
        empty_fields = 0
        total_fields = 0
        for record in data:
            if isinstance(record, dict):
                for key, value in record.items():
                    total_fields += 1
                    if not value or (isinstance(value, str) and not value.strip()):
                        empty_fields += 1
        if total_fields > 0:
            ratio = empty_fields / total_fields
            if ratio > 0.5:
                print(f'WARNING: {ratio:.0%} of fields are empty', file=sys.stderr)
                sys.exit(1)
            else:
                print(f'OK: {ratio:.0%} empty fields (acceptable)', file=sys.stderr)
    elif isinstance(data, dict):
        print(f'OK: JSON object with {len(data)} keys', file=sys.stderr)
    else:
        print('WARNING: Output is not a JSON array or object', file=sys.stderr)
except json.JSONDecodeError as e:
    print(f'FAIL: Invalid JSON: {e}', file=sys.stderr)
    sys.exit(1)
" 2>/dev/null; then
        echo "OK: JSON validation passed" >&2
    else
        echo "FAIL: JSON validation failed" >&2
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
else
    echo "SKIP: No output file to validate" >&2
fi

echo "===========================" >&2

if [ "$FAIL_COUNT" -gt 0 ]; then
    echo "RESULT: $FAIL_COUNT check(s) failed" >&2
    exit 1
else
    echo "RESULT: All checks passed" >&2
    exit 0
fi
