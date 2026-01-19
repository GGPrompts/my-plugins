---
name: spawning-terminals
description: "Spawn and manage terminal tabs via TabzChrome REST API. Use when spawning workers, creating terminals programmatically, setting up worktrees for parallel work, monitoring worker status, or sending prompts to Claude sessions."
---

# TabzChrome Terminal Management

Spawn terminals, manage workers, and orchestrate parallel Claude sessions via REST API.

## Prerequisites

```bash
# Check TabzChrome is running
curl -sf http://localhost:8129/api/health >/dev/null && echo "OK" || echo "TabzChrome not running"

# Get auth token
TOKEN=$(cat /tmp/tabz-auth-token)
```

## Spawn API

### Basic Spawn

```bash
TOKEN=$(cat /tmp/tabz-auth-token)
curl -X POST http://localhost:8129/api/spawn \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $TOKEN" \
  -d '{"name": "Worker", "workingDir": "~/projects"}'
```

### Spawn with Command

```bash
curl -X POST http://localhost:8129/api/spawn \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $TOKEN" \
  -d '{
    "name": "Build Worker",
    "workingDir": "~/projects/myapp",
    "command": "npm run build"
  }'
```

### Spawn Claude Worker

```bash
PLUGIN_DIRS="--plugin-dir $HOME/.claude/plugins/marketplaces --plugin-dir $HOME/plugins/my-plugins"

curl -X POST http://localhost:8129/api/spawn \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $TOKEN" \
  -d "{
    \"name\": \"ISSUE-ID\",
    \"workingDir\": \"/path/to/worktree\",
    \"command\": \"BEADS_NO_DAEMON=1 claude --dangerously-skip-permissions $PLUGIN_DIRS\"
  }"
```

### Spawn Parameters

| Param | Required | Default | Description |
|-------|----------|---------|-------------|
| `name` | No | "Claude Terminal" | Display name (use issue ID for workers) |
| `workingDir` | No | $HOME | Starting directory |
| `command` | No | - | Command to auto-execute after spawn |
| `profileId` | No | default | Terminal profile for appearance |

### Response

```json
{
  "success": true,
  "terminalId": "ctt-ISSUE-ID-abc123",
  "tmuxSession": "ctt-ISSUE-ID-abc123"
}
```

## Worker Management

### List All Workers

```bash
curl -s http://localhost:8129/api/agents | jq '.data[]'
```

### Find Worker by Name (Issue ID)

```bash
curl -s http://localhost:8129/api/agents | jq -r '.data[] | select(.name == "V4V-ct9")'
```

### Get Session ID

```bash
SESSION=$(curl -s http://localhost:8129/api/agents | jq -r '.data[] | select(.name == "V4V-ct9") | .id')
```

### Kill Worker

```bash
curl -s -X DELETE "http://localhost:8129/api/agents/$SESSION" \
  -H "X-Auth-Token: $TOKEN"
```

### Capture Terminal Output

```bash
curl -s "http://localhost:8129/api/tmux/sessions/$SESSION/capture" | jq -r '.data.content' | tail -50
```

### Detect Stale Workers

```bash
CUTOFF=$(date -d '5 minutes ago' -Iseconds)
curl -s http://localhost:8129/api/agents | jq -r \
  --arg cutoff "$CUTOFF" '.data[] | select(.lastActivity < $cutoff) | .name'
```

## Sending Prompts via tmux

```bash
SESSION="ctt-V4V-ct9-abc123"

# Wait for Claude to initialize (8+ seconds after spawn)
sleep 8

# Send prompt (literal mode preserves formatting)
PROMPT="Complete beads issue V4V-ct9. Run: bd show V4V-ct9 --json"
tmux send-keys -t "$SESSION" -l "$PROMPT"
sleep 0.5
tmux send-keys -t "$SESSION" Enter

# Verify delivery
tmux capture-pane -t "$SESSION" -p | tail -5
```

## Git Worktrees for Parallel Workers

Worktrees allow multiple workers on the same repo without conflicts.

### Create Worktree

```bash
ISSUE_ID="V4V-ct9"

# Create worktree with new branch
git worktree add ".worktrees/$ISSUE_ID" -b "feature/$ISSUE_ID"
```

### Initialize Dependencies

Worktrees share git but NOT node_modules. Initialize before spawning:

```bash
INIT_SCRIPT=$(find ~/plugins -name "init-worktree.sh" -path "*conductor*" 2>/dev/null | head -1)
$INIT_SCRIPT ".worktrees/$ISSUE_ID" 2>&1 | tail -5
```

### Full Spawn Workflow

```bash
ISSUE_ID="V4V-ct9"
WORKDIR=$(pwd)
TOKEN=$(cat /tmp/tabz-auth-token)
PLUGIN_DIRS="--plugin-dir $HOME/.claude/plugins/marketplaces --plugin-dir $HOME/plugins/my-plugins"

# 1. Create worktree
git worktree add ".worktrees/$ISSUE_ID" -b "feature/$ISSUE_ID"

# 2. Initialize dependencies SYNCHRONOUSLY
INIT_SCRIPT=$(find ~/plugins -name "init-worktree.sh" -path "*conductor*" 2>/dev/null | head -1)
$INIT_SCRIPT ".worktrees/$ISSUE_ID" 2>&1 | tail -5

# 3. Spawn terminal
curl -s -X POST http://localhost:8129/api/spawn \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $TOKEN" \
  -d "{
    \"name\": \"$ISSUE_ID\",
    \"workingDir\": \"$WORKDIR/.worktrees/$ISSUE_ID\",
    \"command\": \"BEADS_NO_DAEMON=1 claude --dangerously-skip-permissions $PLUGIN_DIRS\"
  }"

echo "Waiting for Claude to initialize..."
sleep 8

# 4. Get session ID
SESSION=$(curl -s http://localhost:8129/api/agents | jq -r --arg id "$ISSUE_ID" '.data[] | select(.name == $id) | .id')

# 5. Send prompt
PROMPT="Complete beads issue $ISSUE_ID. Use CLI (bd show, bd update, bd close) not MCP. Do NOT run bd sync. Run: bd show $ISSUE_ID --json"
tmux send-keys -t "$SESSION" -l "$PROMPT"
sleep 0.5
tmux send-keys -t "$SESSION" Enter
```

### Cleanup Worktree

```bash
ISSUE_ID="V4V-ct9"

# Get and kill session
SESSION=$(curl -s http://localhost:8129/api/agents | jq -r ".data[] | select(.name == \"$ISSUE_ID\") | .id")
curl -s -X DELETE "http://localhost:8129/api/agents/$SESSION" -H "X-Auth-Token: $TOKEN"

# Remove worktree and branch
git worktree remove ".worktrees/$ISSUE_ID" --force
git branch -d "feature/$ISSUE_ID"
```

## Naming Convention

**Use the issue ID as the terminal name.** This enables:
- Easy lookup via `/api/agents`
- Clear display in tmuxplexer dashboard
- Correlation: terminal name = issue ID = branch name = worktree name

## Worker Dashboard

Launch tmuxplexer watcher to monitor all Claude sessions:

```bash
curl -s -X POST http://localhost:8129/api/spawn \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $TOKEN" \
  -d '{
    "name": "Worker Dashboard",
    "workingDir": "/home/marci/projects/tmuxplexer",
    "command": "./tmuxplexer --watcher"
  }'
```

## Important Notes

1. **Name terminals with issue ID** for easy lookup
2. **Initialize deps SYNCHRONOUSLY** before spawning (not background)
3. **Use `BEADS_NO_DAEMON=1`** in worker command (worktrees share DB)
4. **Pass `--plugin-dir` flags** so workers have plugins
5. **Wait 8+ seconds** before sending prompt for Claude to initialize
6. **Workers use CLI (`bd`)** not MCP for beads operations
7. **Workers should NOT run `bd sync`** - conductor handles merge + push
