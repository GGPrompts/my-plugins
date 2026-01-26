#!/bin/bash
# Fan out prompt to multiple models and compare responses

set -e

if [ -z "$1" ]; then
    echo "Usage: council.sh \"your prompt here\""
    exit 1
fi

PROMPT="$*"
TMPDIR=$(mktemp -d)
REPORT="council-$(date +%Y%m%d-%H%M%S).md"

echo "Council Query: $PROMPT"
echo "Running 3 models in parallel..."
echo ""

# Run all three in parallel
copilot --model claude-opus-4.5 -p "$PROMPT" -s --yolo > "$TMPDIR/opus.txt" 2>&1 &
PID_OPUS=$!

copilot --model gpt-5.2-codex -p "$PROMPT" -s --yolo > "$TMPDIR/codex.txt" 2>&1 &
PID_CODEX=$!

copilot --model gemini-3-pro-preview -p "$PROMPT" -s --yolo > "$TMPDIR/gemini.txt" 2>&1 &
PID_GEMINI=$!

# Wait with status
echo -n "Waiting for responses"
while kill -0 $PID_OPUS 2>/dev/null || kill -0 $PID_CODEX 2>/dev/null || kill -0 $PID_GEMINI 2>/dev/null; do
    echo -n "."
    sleep 2
done
echo " done!"
echo ""

# Build report
cat > "$REPORT" << EOF
# Council Report

**Date:** $(date +%Y-%m-%d\ %H:%M)
**Prompt:** $PROMPT

---

## Claude Opus 4.5

$(cat "$TMPDIR/opus.txt")

---

## GPT-5.2 Codex

$(cat "$TMPDIR/codex.txt")

---

## Gemini 3 Pro

$(cat "$TMPDIR/gemini.txt")

---

## Summary

Compare the responses above to identify:
- **Agreement**: Where all models align (high confidence)
- **Divergence**: Where they differ (needs investigation)
- **Synthesis**: Best ideas from each

EOF

echo "Report saved to: $REPORT"
echo ""
echo "=== Quick View ==="
echo ""
echo "--- Opus ---"
head -20 "$TMPDIR/opus.txt"
echo "..."
echo ""
echo "--- Codex ---"
head -20 "$TMPDIR/codex.txt"
echo "..."
echo ""
echo "--- Gemini ---"
head -20 "$TMPDIR/gemini.txt"
echo "..."

# Cleanup
rm -rf "$TMPDIR"
