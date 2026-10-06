#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_TMP=$(mktemp -d /tmp/scrapecraft_test_XXXXXX)

cleanup() {
    rm -rf "$TEST_TMP"
}
trap cleanup EXIT

echo "=================================================="
echo "      ScrapeCraft Automated Test Suite"
echo "=================================================="

TOTAL_TESTS=0
PASSED_TESTS=0

run_test() {
    local test_name="$1"
    local test_cmd="$2"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -n "Test $TOTAL_TESTS: $test_name ... "
    if eval "$test_cmd" >/dev/null 2>&1; then
        echo "[PASS]"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo "[FAIL]"
        echo "Command failed: $test_cmd" >&2
    fi
}

# 1. Shell scripts syntax validation
run_test "Syntax: install.sh" "bash -n '$SCRIPT_DIR/install.sh'"
run_test "Syntax: sandbox-run.sh" "bash -n '$SCRIPT_DIR/scripts/sandbox-run.sh'"
run_test "Syntax: validate-output.sh" "bash -n '$SCRIPT_DIR/scripts/validate-output.sh'"

# 2. Python AST syntax validation
run_test "Syntax: proxy-checker.py" "python3 -c \"import ast; ast.parse(open('$SCRIPT_DIR/scripts/proxy-checker.py').read())\""

# 3. Sandbox CLI argument forwarding test
cat << 'EOF' > "$TEST_TMP/arg_test.py"
import sys, json
arg_received = sys.argv[1] if len(sys.argv) > 1 else ""
print(json.dumps([{"status": "ok", "arg": arg_received}]))
EOF

run_test "Sandbox: Script execution & argument forwarding" \
    "bash '$SCRIPT_DIR/scripts/sandbox-run.sh' 5 '$TEST_TMP/arg_test.py' '--custom-flag' | grep -q 'custom-flag'"

# 4. Sandbox timeout enforcement test
cat << 'EOF' > "$TEST_TMP/sleep_test.py"
import time
time.sleep(10)
EOF

run_test "Sandbox: Timeout enforcement (exit code 124)" \
    "! bash '$SCRIPT_DIR/scripts/sandbox-run.sh' 1 '$TEST_TMP/sleep_test.py'"

# 5. Output validator: Valid JSON passes
cat << 'EOF' > "$TEST_TMP/valid_scraper.py"
import json
print(json.dumps([{"title": "Valid Item", "url": "https://example.com/item/1"}]))
EOF

cat << 'EOF' > "$TEST_TMP/valid_output.json"
[
  {
    "title": "Valid Item",
    "url": "https://example.com/item/1"
  }
]
EOF

run_test "Validator: Valid output accepted" \
    "bash '$SCRIPT_DIR/scripts/validate-output.sh' '$TEST_TMP/valid_scraper.py' '$TEST_TMP/valid_output.json'"

# 6. Output validator: Rejects forbidden tokens (mock_data)
cat << 'EOF' > "$TEST_TMP/bad_mock_scraper.py"
mock_data = [{"title": "fake"}]
EOF

run_test "Validator: Rejects forbidden mock_data token" \
    "! bash '$SCRIPT_DIR/scripts/validate-output.sh' '$TEST_TMP/bad_mock_scraper.py'"

# 7. Output validator: Rejects unresolved relative URLs
cat << 'EOF' > "$TEST_TMP/relative_url_output.json"
[
  {
    "title": "Item",
    "url": "/relative/path/1"
  }
]
EOF

run_test "Validator: Rejects unresolved relative URLs" \
    "! bash '$SCRIPT_DIR/scripts/validate-output.sh' '$TEST_TMP/valid_scraper.py' '$TEST_TMP/relative_url_output.json'"

# 8. Zero Emoji audit on entire repo
run_test "Repo Audit: Zero emoji across all repository files" \
    "python3 -c \"
import glob, re, sys
emoji_re = re.compile('[\U0001f600-\U0001f64f\U0001f300-\U0001f5ff\U0001f680-\U0001f6ff\U0001f1e0-\U0001f1ff\U00002702-\U000027b0\U0001f900-\U0001f9ff\U0001fa00-\U0001fa6f\U0001fa70-\U0001faff\U00002600-\U000026ff]')
for f in glob.glob('$SCRIPT_DIR/**/*', recursive=True):
    try:
        with open(f, 'r', encoding='utf-8') as fp:
            if emoji_re.search(fp.read()):
                sys.exit(1)
    except Exception:
        pass
\""

echo "=================================================="
echo "Summary: $PASSED_TESTS of $TOTAL_TESTS tests passed."
echo "=================================================="

if [ "$PASSED_TESTS" -eq "$TOTAL_TESTS" ]; then
    echo "Result: ALL TESTS PASSED SUCCESSFULLY."
    exit 0
else
    echo "Result: SOME TESTS FAILED."
    exit 1
fi
