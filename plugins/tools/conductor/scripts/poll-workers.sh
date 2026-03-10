#!/bin/bash
# poll-workers.sh - Background worker status monitor
# Usage: poll-workers.sh [--interval 30] [--output /tmp/worker-status.json]
#
# Polls beads, TabzChrome, AND tmuxplexer dashboard for worker status.
# Run in background: ./poll-workers.sh &
#
# Output format:
# {
#   "timestamp": "2026-01-20T15:00:00Z",
#   "workers": [...],           # From TabzChrome API
#   "worker_status": [...],     # From tmuxplexer (session, status, context%)
#   "closed": [...],
#   "ready": [...],
#   "events": [{"type": "closed", "issue": "V4V-xxx", "at": "..."}],
#   "alerts": [...]             # High context, stale workers, etc.
# }

set -e

INTERVAL=${1:-30}
OUTPUT=${2:-/tmp/worker-status.json}
EVENTS_FILE="/tmp/worker-events.jsonl"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONITOR_SCRIPT="${SCRIPT_DIR}/monitor-workers.sh"

# Thresholds
CONTEXT_WARNING=60
CONTEXT_CRITICAL=75

log() {
  echo "[$(date +%H:%M:%S)] $*" >&2
}

# Ensure tmuxplexer monitor is running
ensure_monitor() {
  if [ -x "$MONITOR_SCRIPT" ]; then
    "$MONITOR_SCRIPT" --spawn 2>/dev/null || true
  fi
}

# Get worker status from tmuxplexer dashboard
# Returns JSON array: [{"session": "ctt-xxx", "status": "tool_use", "context": 45}, ...]
get_dashboard_status() {
  if [ ! -x "$MONITOR_SCRIPT" ]; then
    echo "[]"
    return
  fi

  local raw_status
  raw_status=$("$MONITOR_SCRIPT" --status 2>/dev/null) || {
    echo "[]"
    return
  }

  if [ -z "$raw_status" ]; then
    echo "[]"
    return
  fi

  # Convert pipe-delimited output to JSON
  echo "$raw_status" | while IFS='|' read -r session status context; do
    [ -n "$session" ] && echo "{\"session\":\"$session\",\"status\":\"$status\",\"context\":${context:-0}}"
  done | jq -s '.'
}

# Generate alerts based on worker status
generate_alerts() {
  local worker_status="$1"
  local alerts="[]"

  # Check for high context usage
  local high_context
  high_context=$(echo "$worker_status" | jq -c --argjson warn "$CONTEXT_WARNING" --argjson crit "$CONTEXT_CRITICAL" '
    [.[] | select(.context >= $warn) | {
      type: (if .context >= $crit then "critical" else "warning" end),
      session: .session,
      context: .context,
      message: (if .context >= $crit then "Context critical - consider /wipe" else "Context getting high" end)
    }]
  ')

  # Check for stale workers
  local stale
  stale=$(echo "$worker_status" | jq -c '
    [.[] | select(.status == "stale") | {
      type: "stale",
      session: .session,
      message: "Worker appears stale - no activity"
    }]
  ')

  # Check for workers asking user (needs attention)
  local asking
  asking=$(echo "$worker_status" | jq -c '
    [.[] | select(.status == "asking_user") | {
      type: "attention",
      session: .session,
      message: "Worker waiting for user input"
    }]
  ')

  # Combine all alerts
  echo "$high_context $stale $asking" | jq -s 'add | if . == null then [] else . end'
}

# Initialize
log "Starting poll-workers.sh (interval: ${INTERVAL}s, output: $OUTPUT)"
log "Monitor script: $MONITOR_SCRIPT"
PREV_CLOSED=""

# Spawn tmuxplexer monitor on startup
ensure_monitor

while true; do
  # Get current state from multiple sources
  WORKERS=$(curl -sf http://localhost:8129/api/agents 2>/dev/null | jq -c '.data // []' || echo '[]')
  IN_PROGRESS=$(bd list --status in_progress --json 2>/dev/null | jq -c '.' || echo '[]')
  CLOSED=$(bd list --status closed --json 2>/dev/null | jq -c '[.[-10:][].id]' || echo '[]')
  READY=$(bd ready --json 2>/dev/null | jq -c '[.[].id]' || echo '[]')

  # Get real-time status from tmuxplexer dashboard
  WORKER_STATUS=$(get_dashboard_status)

  # Generate alerts (high context, stale, etc.)
  ALERTS=$(generate_alerts "$WORKER_STATUS")

  # Detect newly closed issues (compare with previous)
  EVENTS="[]"
  if [ -n "$PREV_CLOSED" ]; then
    # Find IDs in CLOSED that weren't in PREV_CLOSED
    NEW_CLOSED=$(echo "$CLOSED" | jq -c --argjson prev "$PREV_CLOSED" '[.[] | select(. as $id | $prev | index($id) | not)]')

    if [ "$NEW_CLOSED" != "[]" ]; then
      # Generate events for each newly closed issue
      TIMESTAMP=$(date -Iseconds)
      EVENTS=$(echo "$NEW_CLOSED" | jq -c --arg ts "$TIMESTAMP" '[.[] | {type: "closed", issue: ., at: $ts}]')

      # Append to events file
      echo "$EVENTS" | jq -c '.[]' >> "$EVENTS_FILE"

      # Log
      log "Detected closed: $(echo "$NEW_CLOSED" | jq -r 'join(", ")')"
    fi
  fi
  PREV_CLOSED="$CLOSED"

  # Extract worker sessions that correspond to in-progress beads issues.
  # Avoid brittle regexes (beads IDs are often lowercase like bd-xxxx).
  IN_PROGRESS_IDS=$(echo "$IN_PROGRESS" | jq -c '[.[].id]' 2>/dev/null || echo '[]')
  WORKER_ISSUES=$(echo "$WORKERS" | jq -c --argjson ids "$IN_PROGRESS_IDS" \
    '[.[] | select(.name as $n | $ids | index($n)) | {id: .id, name: .name, state: .state}]' 2>/dev/null || echo '[]')

  # Build status JSON with dashboard data
  jq -n \
    --arg ts "$(date -Iseconds)" \
    --argjson workers "$WORKER_ISSUES" \
    --argjson worker_status "$WORKER_STATUS" \
    --argjson in_progress "$IN_PROGRESS" \
    --argjson closed "$CLOSED" \
    --argjson ready "$READY" \
    --argjson events "$EVENTS" \
    --argjson alerts "$ALERTS" \
    '{
      timestamp: $ts,
      workers: $workers,
      worker_status: $worker_status,
      in_progress: ($in_progress | map({id, title})),
      closed: $closed,
      ready: $ready,
      events: $events,
      alerts: $alerts
    }' > "$OUTPUT"

  # Log alerts if any
  if [ "$(echo "$ALERTS" | jq 'length')" -gt 0 ]; then
    log "ALERTS: $(echo "$ALERTS" | jq -c '.')"
  fi

  sleep "$INTERVAL"
done
