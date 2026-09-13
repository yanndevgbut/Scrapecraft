#!/usr/bin/env bash
set -euo pipefail

TIMEOUT_SECONDS="${1:-45}"
SCRIPT_PATH="${2:?Usage: sandbox-run.sh [timeout] <script-path>}"
SESSION_DIR=$(mktemp -d /tmp/scrapecraft_XXXXXX)

cleanup() {
    rm -rf "$SESSION_DIR"
}

if [ ! -f "$SCRIPT_PATH" ]; then
    echo "ERROR: Script not found: $SCRIPT_PATH" >&2
    exit 1
fi

cp "$SCRIPT_PATH" "$SESSION_DIR/"
SCRIPT_NAME=$(basename "$SCRIPT_PATH")
SCRIPT_EXT="${SCRIPT_NAME##*.}"

case "$SCRIPT_EXT" in
    py)
        RUNNER="python3"
        ;;
    js)
        RUNNER="node"
        ;;
    *)
        echo "ERROR: Unsupported file extension: .$SCRIPT_EXT (expected .py or .js)" >&2
        cleanup
        exit 1
        ;;
esac

echo "--- ScrapeCraft Sandbox ---" >&2
echo "Session:  $SESSION_DIR" >&2
echo "Script:   $SCRIPT_NAME" >&2
echo "Runner:   $RUNNER" >&2
echo "Timeout:  ${TIMEOUT_SECONDS}s" >&2
echo "--------------------------" >&2

OUTPUT_FILE="$SESSION_DIR/output.json"
STDERR_FILE="$SESSION_DIR/stderr.log"

EXIT_CODE=0
timeout "$TIMEOUT_SECONDS" "$RUNNER" "$SESSION_DIR/$SCRIPT_NAME" \
    > "$OUTPUT_FILE" \
    2> "$STDERR_FILE" \
    || EXIT_CODE=$?

if [ "$EXIT_CODE" -eq 124 ]; then
    echo "ERROR: Script timed out after ${TIMEOUT_SECONDS} seconds" >&2
    cat "$STDERR_FILE" >&2
    cleanup
    exit 124
fi

if [ "$EXIT_CODE" -ne 0 ]; then
    echo "ERROR: Script exited with code $EXIT_CODE" >&2
    cat "$STDERR_FILE" >&2
    cleanup
    exit "$EXIT_CODE"
fi

if [ -s "$STDERR_FILE" ]; then
    echo "--- stderr ---" >&2
    cat "$STDERR_FILE" >&2
    echo "--- end stderr ---" >&2
fi

if [ -s "$OUTPUT_FILE" ]; then
    cat "$OUTPUT_FILE"
else
    echo "WARNING: Script produced no output" >&2
fi

cleanup
exit 0
