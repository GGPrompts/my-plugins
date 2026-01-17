#!/usr/bin/env bash
# lookahead-enhancer.sh - Parallel prompt preparation that runs alongside wave execution
#
# Usage: lookahead-enhancer.sh [OPTIONS]
#
# Options:
#   --max-ahead N    Maximum issues to prepare ahead (default: 8)
#   --batch N        Process N issues per cycle (default: 4)
#   --once           Run once and exit (don't loop)
#   --status         Show enhancer status and exit
#
# This script is designed to run in a parallel terminal (Haiku model) during
# bd-swarm execution. It stays 1-2 waves ahead by preparing prompts for ready
# issues before workers need them.
#
# Flow:
# 1. Get ready issues that don't have prepared.prompt
# 2. Mark with enhancing: true to prevent race conditions
# 3. Match skills, find files, craft prompt
# 4. Store prepared.prompt in notes
# 5. Clear enhancing flag
# 6. Loop until no more unprepared issues or max-ahead reached

set -e

# ============================================================================
# Configuration
# ============================================================================

MAX_AHEAD=${MAX_AHEAD:-8}      # Max issues to prepare ahead
BATCH_SIZE=${BATCH_SIZE:-4}    # Issues per cycle
LOOP_DELAY=${LOOP_DELAY:-10}   # Seconds between cycles
ONCE_MODE=false

# Find conductor root for script access
CONDUCTOR_ROOT="${CLAUDE_PLUGIN_ROOT:-./plugins/conductor}"
if [ ! -d "$CONDUCTOR_ROOT" ]; then
  CONDUCTOR_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
MATCH_SCRIPT="$CONDUCTOR_ROOT/scripts/match-skills.sh"

# ============================================================================
# Argument parsing
# ============================================================================

while [[ $# -gt 0 ]]; do
  case $1 in
    --max-ahead)
      MAX_AHEAD="$2"
      shift 2
      ;;
    --batch)
      BATCH_SIZE="$2"
      shift 2
      ;;
    --once)
      ONCE_MODE=true
      shift
      ;;
    --status)
      # Show status and exit
      echo "=== Lookahead Enhancer Status ==="
      ENHANCING=$(bd list --status=open --json 2>/dev/null | jq -r '.[] | select(.notes | test("enhancing: true")) | .id' | wc -l)
      PREPARED=$(bd ready --json 2>/dev/null | jq -r '.[] | select(.notes | test("prepared\\.prompt:")) | .id' | wc -l)
      UNPREPARED=$(bd ready --json 2>/dev/null | jq -r '.[] | select(.notes | test("prepared\\.prompt:") | not) | .id' | wc -l)
      echo "Currently enhancing: $ENHANCING"
      echo "Already prepared: $PREPARED"
      echo "Awaiting preparation: $UNPREPARED"
      exit 0
      ;;
    --help|-h)
      echo "Usage: lookahead-enhancer.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --max-ahead N    Maximum issues to prepare ahead (default: 8)"
      echo "  --batch N        Process N issues per cycle (default: 4)"
      echo "  --once           Run once and exit (don't loop)"
      echo "  --status         Show enhancer status and exit"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# ============================================================================
# Helper Functions
# ============================================================================

log() {
  echo "[$(date +%H:%M:%S)] $*"
}

# Check if an issue has prepared.prompt in notes
has_prepared_prompt() {
  local ISSUE_ID="$1"
  local NOTES=$(bd show "$ISSUE_ID" --json 2>/dev/null | jq -r '.[0].notes // ""')
  echo "$NOTES" | grep -q "prepared\.prompt:"
}

# Check if an issue is currently being enhanced
is_enhancing() {
  local ISSUE_ID="$1"
  local NOTES=$(bd show "$ISSUE_ID" --json 2>/dev/null | jq -r '.[0].notes // ""')
  echo "$NOTES" | grep -q "enhancing: true"
}

# Mark issue as being enhanced (prevents race conditions)
mark_enhancing() {
  local ISSUE_ID="$1"
  local NOTES=$(bd show "$ISSUE_ID" --json 2>/dev/null | jq -r '.[0].notes // ""')

  # Skip if already has enhancing flag or prepared prompt
  if echo "$NOTES" | grep -qE "(enhancing: true|prepared\.prompt:)"; then
    return 1
  fi

  # Add enhancing flag
  local NEW_NOTES="enhancing: true
$NOTES"
  bd update "$ISSUE_ID" --notes "$NEW_NOTES" 2>/dev/null
}

# Clear enhancing flag
clear_enhancing() {
  local ISSUE_ID="$1"
  local NOTES=$(bd show "$ISSUE_ID" --json 2>/dev/null | jq -r '.[0].notes // ""')

  # Remove enhancing flag
  local NEW_NOTES=$(echo "$NOTES" | grep -v "^enhancing:")
  bd update "$ISSUE_ID" --notes "$NEW_NOTES" 2>/dev/null
}

# Get unprepared ready issues (no prepared.prompt, not currently enhancing)
get_unprepared_issues() {
  bd ready --json 2>/dev/null | jq -r '
    .[] |
    select(.type != "epic") |
    select(.title | test("GATE"; "i") | not) |
    select((.notes // "") | test("prepared\\.prompt:") | not) |
    select((.notes // "") | test("enhancing: true") | not) |
    .id
  ' | head -n "$MAX_AHEAD"
}

# Count already prepared issues
count_prepared() {
  bd ready --json 2>/dev/null | jq '[.[] | select((.notes // "") | test("prepared\\.prompt:"))] | length'
}

# ============================================================================
# Main Enhancement Function
# ============================================================================

enhance_issue() {
  local ISSUE_ID="$1"

  # Try to mark as enhancing (atomic check-and-set via notes)
  if ! mark_enhancing "$ISSUE_ID"; then
    log "Skipping $ISSUE_ID (already enhancing or prepared)"
    return 0
  fi

  log "Enhancing: $ISSUE_ID"

  # Get issue details
  local ISSUE_JSON=$(bd show "$ISSUE_ID" --json 2>/dev/null)
  local TITLE=$(echo "$ISSUE_JSON" | jq -r '.[0].title // ""')
  local DESC=$(echo "$ISSUE_JSON" | jq -r '.[0].description // ""')
  local LABELS=$(echo "$ISSUE_JSON" | jq -r '.[0].labels[]?' 2>/dev/null | tr '\n' ' ')
  local CURRENT_NOTES=$(echo "$ISSUE_JSON" | jq -r '.[0].notes // ""' | grep -v "^enhancing:")

  # Match skills (verified against available)
  local SKILLS=""
  if [ -f "$MATCH_SCRIPT" ]; then
    SKILLS=$("$MATCH_SCRIPT" --verify "$TITLE $DESC $LABELS" 2>/dev/null | tr '\n' ' ')
  fi

  # Extract skill names for storage
  local SKILL_NAMES=$(echo "$SKILLS" | grep -oE '/[a-z-]+:[a-z-]+' | sed 's|^/||' | tr '\n' ',' | sed 's/,$//')

  # Find key files (quick search - max 10 seconds)
  local KEY_FILES=""
  for keyword in $(echo "$TITLE $DESC" | tr ' ' '\n' | grep -E '^[a-z]{4,}$' | head -3); do
    local FOUND=$(timeout 3 find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.md" \) 2>/dev/null | xargs grep -l "$keyword" 2>/dev/null | head -2)
    [ -n "$FOUND" ] && KEY_FILES="$KEY_FILES $FOUND"
  done
  KEY_FILES=$(echo "$KEY_FILES" | tr ' ' '\n' | sort -u | head -5 | tr '\n' ',' | sed 's/,$//')

  # Build skill load instructions
  local SKILL_LOADS=""
  for skill in $(echo "$SKILL_NAMES" | tr ',' ' '); do
    [ -n "$skill" ] && SKILL_LOADS="$SKILL_LOADS
- /$skill"
  done
  [ -z "$SKILL_LOADS" ] && SKILL_LOADS="
- No specific skills matched (general development)"

  # Build key files section
  local FILES_SECTION="Explore based on issue description."
  if [ -n "$KEY_FILES" ]; then
    FILES_SECTION=$(echo "$KEY_FILES" | tr ',' '\n' | sed 's/^/- /')
  fi

  # Craft prepared prompt (keywords for skill-eval hook activation)
  local SKILL_KEYWORDS=""
  if [ -n "$SKILL_LOADS" ]; then
    SKILL_KEYWORDS="
This task involves: $SKILL_LOADS"
  fi

  local PREPARED_PROMPT="## Task: $ISSUE_ID - $TITLE

## Context
$DESC$SKILL_KEYWORDS

## Key Files
$FILES_SECTION

## Approach
Implement the changes described above. Reference existing code patterns for consistency.

## When Done
Run /conductor:worker-done $ISSUE_ID"

  # Store prepared data in notes (YAML-like format)
  local NEW_NOTES="prepared.skills: $SKILL_NAMES
prepared.files: $KEY_FILES
prepared.prompt: |
$(echo "$PREPARED_PROMPT" | sed 's/^/  /')
$CURRENT_NOTES"

  # Update issue (removes enhancing flag, adds prepared data)
  bd update "$ISSUE_ID" --notes "$NEW_NOTES" 2>/dev/null

  log "Prepared: $ISSUE_ID (skills: ${SKILL_NAMES:-none})"
}

# ============================================================================
# Main Loop
# ============================================================================

main() {
  log "Lookahead Enhancer started (max-ahead: $MAX_AHEAD, batch: $BATCH_SIZE)"

  while true; do
    # Check how many are already prepared
    local PREPARED_COUNT=$(count_prepared)

    if [ "$PREPARED_COUNT" -ge "$MAX_AHEAD" ]; then
      log "Max ahead reached ($PREPARED_COUNT prepared), waiting..."
      if [ "$ONCE_MODE" = true ]; then
        exit 0
      fi
      sleep "$LOOP_DELAY"
      continue
    fi

    # Get unprepared issues
    local UNPREPARED=$(get_unprepared_issues)

    if [ -z "$UNPREPARED" ]; then
      log "No unprepared issues found"
      if [ "$ONCE_MODE" = true ]; then
        exit 0
      fi
      sleep "$LOOP_DELAY"
      continue
    fi

    # Process batch
    local PROCESSED=0
    for ISSUE_ID in $UNPREPARED; do
      if [ "$PROCESSED" -ge "$BATCH_SIZE" ]; then
        break
      fi

      enhance_issue "$ISSUE_ID"
      PROCESSED=$((PROCESSED + 1))
    done

    log "Cycle complete: prepared $PROCESSED issues"

    if [ "$ONCE_MODE" = true ]; then
      exit 0
    fi

    # Brief pause before next cycle
    sleep "$LOOP_DELAY"
  done
}

# ============================================================================
# Entry Point
# ============================================================================

main "$@"
