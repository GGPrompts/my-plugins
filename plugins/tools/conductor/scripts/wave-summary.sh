#!/usr/bin/env bash
# Wave Summary Generator
# Usage: wave-summary.sh "ISSUE1 ISSUE2 ISSUE3" [--audio]
#
# Generates a comprehensive summary of a completed wave including:
# - Issues closed with titles
# - Files changed
# - Commits made
# - Next wave status

set -e

ISSUES="$1"
AUDIO_FLAG="$2"

if [ -z "$ISSUES" ]; then
  echo "Usage: wave-summary.sh \"ISSUE1 ISSUE2 ...\" [--audio]"
  exit 1
fi

# Count issues
ISSUE_COUNT=$(echo "$ISSUES" | wc -w | tr -d ' ')

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    WAVE COMPLETE                             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# List closed issues with titles
echo "📋 Issues Completed ($ISSUE_COUNT):"
echo "─────────────────────────────────"
for ISSUE in $ISSUES; do
  [[ "$ISSUE" =~ ^[a-zA-Z0-9_-]+$ ]] || continue
  TITLE=$(bd show "$ISSUE" --json 2>/dev/null | jq -r '.[0].title // "Unknown"' 2>/dev/null || echo "Unknown")
  STATUS=$(bd show "$ISSUE" --json 2>/dev/null | jq -r '.[0].status // "unknown"' 2>/dev/null || echo "unknown")
  if [ "$STATUS" = "closed" ]; then
    echo "  ✅ $ISSUE: $TITLE"
  else
    echo "  ⚠️  $ISSUE: $TITLE (status: $STATUS)"
  fi
done

echo ""

# Git stats since last push (approximate wave changes)
echo "📊 Wave Statistics:"
echo "─────────────────────────────────"

# Count commits from feature branches that were merged
COMMIT_COUNT=0
FILES_CHANGED=0
INSERTIONS=0
DELETIONS=0

for ISSUE in $ISSUES; do
  [[ "$ISSUE" =~ ^[a-zA-Z0-9_-]+$ ]] || continue
  BRANCH="feature/${ISSUE}"
  # Check if branch was merged (commit exists in main)
  if git branch -a --contains "$BRANCH" 2>/dev/null | grep -q "main"; then
    # Count commits from this branch
    COMMITS=$(git log main..."$BRANCH" --oneline 2>/dev/null | wc -l || echo 0)
    COMMIT_COUNT=$((COMMIT_COUNT + COMMITS))
  fi
done

# Get overall diff stats
DIFF_STATS=$(git diff --stat HEAD~$ISSUE_COUNT 2>/dev/null || echo "")
if [ -n "$DIFF_STATS" ]; then
  FILES_CHANGED=$(echo "$DIFF_STATS" | tail -1 | grep -oE '[0-9]+ files? changed' | grep -oE '[0-9]+' || echo "?")
  INSERTIONS=$(echo "$DIFF_STATS" | tail -1 | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || echo "0")
  DELETIONS=$(echo "$DIFF_STATS" | tail -1 | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+' || echo "0")
fi

echo "  Branches merged: $ISSUE_COUNT"
echo "  Files changed:   ${FILES_CHANGED:-?}"
echo "  Lines added:     +${INSERTIONS:-0}"
echo "  Lines removed:   -${DELETIONS:-0}"

echo ""

# Check for next wave
echo "🔮 Next Steps:"
echo "─────────────────────────────────"
NEXT_READY=$(bd ready --json 2>/dev/null | jq 'length' 2>/dev/null || echo "0")
BLOCKED_COUNT=$(bd blocked --json 2>/dev/null | jq 'length' 2>/dev/null || echo "0")

if [ "$NEXT_READY" -gt 0 ]; then
  echo "  📦 $NEXT_READY issues ready for next wave"
  echo "  Run: /conductor:bd-swarm or /conductor:bd-swarm-auto"
else
  if [ "$BLOCKED_COUNT" -gt 0 ]; then
    echo "  🔒 $BLOCKED_COUNT issues blocked (waiting on dependencies)"
    echo "  Run: bd blocked  # to see what's blocking"
  else
    echo "  🎉 Backlog complete! No more issues ready."
  fi
fi

echo ""
echo "─────────────────────────────────"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "Completed: $TIMESTAMP"
echo ""

# Audio notification if requested
if [ "$AUDIO_FLAG" = "--audio" ]; then
  if [ "$NEXT_READY" -gt 0 ]; then
    AUDIO_TEXT="Wave complete. $ISSUE_COUNT issues closed. $NEXT_READY more issues ready for next wave."
  else
    AUDIO_TEXT="Wave complete. $ISSUE_COUNT issues closed. Backlog is now empty."
  fi

  curl -s -X POST http://localhost:8129/api/audio/speak \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg text "$AUDIO_TEXT" '{text: $text, voice: "en-GB-SoniaNeural", rate: "+15%", priority: "high"}')" \
    > /dev/null 2>&1 &
fi
