---
description: "Autonomous worker loop - spawns workers, polls beads, respawns until backlog empty"
---

# Auto Mode - Autonomous Worker Loop

Spawns workers for ready issues, polls beads for updates, spawns new workers as issues become unblocked, cleans up completed work. Runs until backlog is empty.

## How It Works

1. Start beads daemon
2. Get ready issues → spawn workers (up to N parallel)
3. Wait 2 minutes (workers need time to start)
4. Poll every 30 seconds:
   - New issues unblocked? → Spawn workers
   - Issues closed? → Cleanup worktrees
   - All done? → Exit

## Usage

```bash
# Run auto mode (max 3 parallel workers)
/conductor:auto
```

**Max 3 workers** - more gets chaotic, especially since workers can spawn their own subagents.

## Implementation

```bash
#!/bin/bash
MAX_WORKERS=3  # Hard limit - workers spawn subagents, more than 3 gets chaotic
POLL_INTERVAL=30
INITIAL_WAIT=120

# Start daemon
bd daemon status || bd daemon start

# Track active workers: worktree_path -> issue_id
declare -A ACTIVE_WORKERS

spawn_worker() {
  local ISSUE_ID="$1"
  local WORKTREE=".worktrees/$ISSUE_ID"

  # Create worktree
  bd worktree create "$WORKTREE" --branch "feature/$ISSUE_ID"

  # Initialize dependencies (prevents workers from wasting time on npm install)
  ${CLAUDE_PLUGIN_ROOT}/scripts/init-worktree.sh "$WORKTREE" --quiet

  # Get prompt from notes
  local PROMPT=$(bd show "$ISSUE_ID" --json | jq -r '.[0].notes // "Work on issue '"$ISSUE_ID"'. When done: bd close '"$ISSUE_ID"' --reason done"')

  # Spawn terminal
  local TOKEN=$(cat /tmp/tabz-auth-token)
  local RESPONSE=$(curl -s -X POST http://localhost:8129/api/spawn \
    -H "Content-Type: application/json" \
    -H "X-Auth-Token: $TOKEN" \
    -d '{
      "name": "Claude: '"$ISSUE_ID"'",
      "workingDir": "'"$(pwd)/$WORKTREE"'",
      "command": "claude --dangerously-skip-permissions"
    }')

  local SESSION=$(echo "$RESPONSE" | jq -r '.sessionName')

  # Send prompt (literal mode preserves formatting)
  sleep 2
  tmux send-keys -t "$SESSION" -l "$PROMPT"
  sleep 0.5
  tmux send-keys -t "$SESSION" C-m

  # Track it
  ACTIVE_WORKERS["$WORKTREE"]="$ISSUE_ID"

  echo "Spawned worker for $ISSUE_ID in $SESSION"
}

cleanup_worker() {
  local WORKTREE="$1"
  local ISSUE_ID="${ACTIVE_WORKERS[$WORKTREE]}"

  # Merge changes
  git checkout main
  git merge "feature/$ISSUE_ID" --no-edit 2>/dev/null || true

  # Remove worktree
  bd worktree remove "$WORKTREE" 2>/dev/null || true
  git branch -d "feature/$ISSUE_ID" 2>/dev/null || true

  # Untrack
  unset ACTIVE_WORKERS["$WORKTREE"]

  echo "Cleaned up $ISSUE_ID"
}

# Initial spawn
echo "Getting ready issues..."
READY=$(bd ready --json | jq -r '.[].id' | head -n "$MAX_WORKERS")
for ISSUE_ID in $READY; do
  spawn_worker "$ISSUE_ID"
done

if [ ${#ACTIVE_WORKERS[@]} -eq 0 ]; then
  echo "No ready issues. Exiting."
  exit 0
fi

# Wait for workers to start
echo "Waiting ${INITIAL_WAIT}s for workers to initialize..."
sleep "$INITIAL_WAIT"

# Poll loop
while true; do
  echo "Polling... (${#ACTIVE_WORKERS[@]} active workers)"

  # Check for completed issues
  for WORKTREE in "${!ACTIVE_WORKERS[@]}"; do
    ISSUE_ID="${ACTIVE_WORKERS[$WORKTREE]}"
    STATUS=$(bd show "$ISSUE_ID" --json 2>/dev/null | jq -r '.[0].status // "unknown"')

    if [ "$STATUS" = "closed" ]; then
      echo "Issue $ISSUE_ID completed!"
      cleanup_worker "$WORKTREE"
    fi
  done

  # Check for new ready issues (if we have capacity)
  CURRENT_COUNT=${#ACTIVE_WORKERS[@]}
  if [ "$CURRENT_COUNT" -lt "$MAX_WORKERS" ]; then
    SLOTS=$((MAX_WORKERS - CURRENT_COUNT))

    # Get ready issues not already being worked
    NEW_READY=$(bd ready --json | jq -r '.[].id' | while read ID; do
      # Check if already active
      FOUND=0
      for ACTIVE_ID in "${ACTIVE_WORKERS[@]}"; do
        [ "$ACTIVE_ID" = "$ID" ] && FOUND=1
      done
      [ "$FOUND" -eq 0 ] && echo "$ID"
    done | head -n "$SLOTS")

    for ISSUE_ID in $NEW_READY; do
      spawn_worker "$ISSUE_ID"
    done
  fi

  # Exit if no active workers and no ready issues
  if [ ${#ACTIVE_WORKERS[@]} -eq 0 ]; then
    REMAINING=$(bd ready --json | jq -r '.[].id' | wc -l)
    if [ "$REMAINING" -eq 0 ]; then
      echo "All work complete!"
      bd sync
      exit 0
    fi
  fi

  sleep "$POLL_INTERVAL"
done
```

## What Workers Should Do

Workers follow the standard PRIME.md workflow:

1. `bd update ID --status in_progress`
2. Do the work
3. `bd close ID --reason "done"`
4. `bd sync`

That's it. The conductor sees the closed status via polling and handles cleanup.

## Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| MAX_WORKERS | 3 | Maximum parallel workers (hard limit) |
| POLL_INTERVAL | 30s | How often to check beads |
| INITIAL_WAIT | 120s | Wait after first spawn before polling |

**Why max 3?** Workers can spawn Explore agents, code-review subagents, etc. With 3 workers each potentially running subagents, you can easily have 6-9 Claude processes. More than 3 workers causes resource contention and merge conflicts.

## Notes

- Requires beads daemon running (auto-started)
- Workers must close issues for conductor to detect completion
- Merges happen on main branch after each worker completes
- Conflicts may need manual resolution
