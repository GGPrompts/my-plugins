---
description: "Spawn Claude workers in isolated worktrees via TabzChrome"
---

# Spawn Workers

Spawn Claude terminals in isolated git worktrees to work on beads issues in parallel.

## Prerequisites

### Check TabzChrome Health

```bash
curl -sf http://localhost:8129/api/health >/dev/null || echo "TabzChrome not running"
```

### Start Beads Daemon

```bash
bd daemon status || bd daemon start
```

## Quick Start

```bash
ISSUE_ID="V4V-ct9"
WORKDIR=$(pwd)

# 1. Create worktree
git worktree add ".worktrees/$ISSUE_ID" -b "feature/$ISSUE_ID"

# 2. Initialize dependencies (prevents worker from wasting time)
# For conductor plugin path, use absolute path or find it
INIT_SCRIPT="/home/marci/.claude/plugins/cache/my-plugins/conductor/*/scripts/init-worktree.sh"
$INIT_SCRIPT ".worktrees/$ISSUE_ID" --quiet 2>/dev/null || true

# 3. Spawn terminal - use issue ID as name for easy lookup
TOKEN=$(cat /tmp/tabz-auth-token)
RESP=$(curl -s -X POST http://localhost:8129/api/spawn \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $TOKEN" \
  -d "{
    \"name\": \"$ISSUE_ID\",
    \"workingDir\": \"$WORKDIR/.worktrees/$ISSUE_ID\",
    \"command\": \"BEADS_NO_DAEMON=1 claude --dangerously-skip-permissions\"
  }")

# 4. Get session name from response
SESSION=$(echo "$RESP" | jq -r '.terminal.sessionName')
echo "Spawned $ISSUE_ID in session $SESSION"

# 5. Send minimal prompt (issue notes have all context)
sleep 2
PROMPT="Complete beads issue $ISSUE_ID. Read bd show $ISSUE_ID for context."
tmux send-keys -t "$SESSION" -l "$PROMPT"
sleep 0.5
tmux send-keys -t "$SESSION" Enter
```

## Naming Convention

**Use the issue ID as the terminal name.** This enables:

- Easy lookup via `/api/agents`
- Clear display in tmuxplexer dashboard
- Correlation: terminal name = issue ID = branch name = worktree name

```bash
# Spawn with issue ID as name
curl -X POST http://localhost:8129/api/spawn \
  -d '{"name": "V4V-ct9", "workingDir": "...", "command": "..."}'

# Terminal ID becomes: ctt-V4V-ct9-abc123
# Display name: V4V-ct9
```

## TabzChrome API

### List All Workers

```bash
curl -s http://localhost:8129/api/agents | jq '.data[]'
```

### Find Worker by Issue ID

```bash
# By name (recommended)
curl -s http://localhost:8129/api/agents | jq -r '.data[] | select(.name == "V4V-ct9")'

# By workingDir
curl -s http://localhost:8129/api/agents | jq -r '.data[] | select(.workingDir | contains("V4V-ct9"))'
```

### Get Worker Session ID

```bash
SESSION=$(curl -s http://localhost:8129/api/agents | jq -r '.data[] | select(.name == "V4V-ct9") | .id')
```

### Kill Worker Terminal

```bash
curl -s -X DELETE "http://localhost:8129/api/agents/$SESSION" \
  -H "X-Auth-Token: $(cat /tmp/tabz-auth-token)"
```

### Capture Terminal Output (Debug)

```bash
curl -s "http://localhost:8129/api/tmux/sessions/$SESSION/capture" | jq -r '.data.content' | tail -50
```

### Detect Stale Workers

```bash
# Workers with no activity in 5+ minutes
CUTOFF=$(date -d '5 minutes ago' -Iseconds)
curl -s http://localhost:8129/api/agents | jq -r \
  --arg cutoff "$CUTOFF" '.data[] | select(.lastActivity < $cutoff) | .name'
```

## Worker Dashboard

Launch tmuxplexer in watcher mode to monitor all Claude sessions:

```bash
TOKEN=$(cat /tmp/tabz-auth-token)
curl -s -X POST http://localhost:8129/api/spawn \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $TOKEN" \
  -d '{
    "name": "Worker Dashboard",
    "workingDir": "/home/marci/projects/tmuxplexer",
    "command": "./tmuxplexer --watcher"
  }'
```

The dashboard shows:
- All Claude sessions with status (Processing, Awaiting Input, etc.)
- Context usage percentage
- Working directory and git branch
- Attached/detached state

## Prompts: Keep Them Minimal

The beads issue contains all context. Send a simple prompt:

```bash
PROMPT="Complete beads issue $ISSUE_ID. Read bd show $ISSUE_ID for context."
```

The worker will:
1. Run `bd show ISSUE-ID` to read full context
2. Load any skills mentioned in notes
3. Do the work
4. Close the issue with `bd close ISSUE-ID --reason "done"`

### Issue Notes Structure

Put everything the worker needs in the issue notes during planning:

```bash
bd update ISSUE-ID --notes "## Problem
Description of what needs to be fixed...

## Approach
Use the ui-styling skill for CSS audit.

## Key Files
- frontend/src/app/admin/page.tsx

## When done
bd close ISSUE-ID --reason \"summary\""
```

## Sending Prompts via tmux

```bash
SESSION="ctt-V4V-ct9-abc123"

# Send prompt (literal mode preserves formatting)
tmux send-keys -t "$SESSION" -l "$PROMPT"
sleep 0.5
tmux send-keys -t "$SESSION" Enter

# Verify delivery
tmux capture-pane -t "$SESSION" -p | tail -5
```

## Monitoring Workers

### Via TabzChrome API

```bash
# Get all workers with status
curl -s http://localhost:8129/api/agents | jq '.data[] | {name, state, lastActivity, workingDir}'
```

### Via tmuxplexer Dashboard

The `--watcher` mode shows real-time status:

| Status | Meaning |
|--------|---------|
| 🟡 Processing | Worker thinking |
| ⏸️ Awaiting Input | Idle at prompt |
| 🔧 Tool Use | Executing a tool |

### Nudging Idle Workers

```bash
# If worker finished but didn't close issue
tmux send-keys -t "$SESSION" -l "Close the issue: bd close ISSUE-ID --reason done"
sleep 0.5
tmux send-keys -t "$SESSION" Enter
```

## Cleanup

```bash
ISSUE_ID="V4V-ct9"

# Get session ID
SESSION=$(curl -s http://localhost:8129/api/agents | jq -r ".data[] | select(.name == \"$ISSUE_ID\") | .id")

# Kill terminal via API
curl -s -X DELETE "http://localhost:8129/api/agents/$SESSION" \
  -H "X-Auth-Token: $(cat /tmp/tabz-auth-token)"

# Remove worktree
git worktree remove ".worktrees/$ISSUE_ID" --force
git branch -d "feature/$ISSUE_ID"
```

## Worktree Initialization

Worktrees share git history but NOT node_modules, .venv, etc. Initialize before spawning:

```bash
# Auto-detect and install dependencies
INIT_SCRIPT=$(find ~/.claude/plugins -name "init-worktree.sh" -path "*conductor*" | head -1)
$INIT_SCRIPT ".worktrees/$ISSUE_ID" --quiet
```

### What It Does

| Detected File | Action |
|---------------|--------|
| `package.json` | `npm ci` (or pnpm/yarn/bun if lockfile exists) |
| `pyproject.toml` | `uv pip install -e .` (or pip if no uv) |
| `requirements.txt` | `uv pip install -r requirements.txt` |
| `Cargo.toml` | `cargo fetch` |
| `go.mod` | `go mod download` |

Also handles monorepos with `frontend/`, `backend/`, `packages/*` subdirectories.

### Parallel Initialization

```bash
# Create all worktrees
for ID in V4V-ct9 V4V-g2z V4V-3wh; do
  git worktree add ".worktrees/$ID" -b "feature/$ID"
done

# Initialize in parallel
for ID in V4V-ct9 V4V-g2z V4V-3wh; do
  $INIT_SCRIPT ".worktrees/$ID" --quiet &
done
wait

# Now spawn workers
```

## Notes

- **Name terminals with issue ID** for easy lookup via API
- Create worktrees BEFORE spawning
- Initialize dependencies BEFORE spawning to avoid worker delays
- Use `BEADS_NO_DAEMON=1` in worker command (worktrees share DB)
- Workers are vanilla Claude - they use beads naturally
