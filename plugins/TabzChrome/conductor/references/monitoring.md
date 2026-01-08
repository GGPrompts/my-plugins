# Worker Monitoring Reference

Reference material for monitoring Claude workers via tmuxplexer.

## Tmuxplexer Status Indicators

| Indicator | Meaning | Action |
|-----------|---------|--------|
| 🟢 | Idle - ready for input | May need nudge if idle too long |
| 🟡 | Processing - actively working | Leave alone |
| 🔴 | Error or high context (75%+) | Investigate |
| ⚪ | Stale - no updates for 60s | May be stuck |
| ⏸️ | Awaiting Input | **Never nudge** - AskUserQuestion pending |

## Context Thresholds

| Context % | Color | Action |
|-----------|-------|--------|
| < 50% | Green | Healthy, can reuse for more tasks |
| 50-74% | Yellow | Warning, consider retiring after task |
| >= 75% | Red | Critical, retire after task |

## Parsing Tmuxplexer Output

Each AI session displays on 2 rows:

```
● 🤖 ctt-worker-abc123               🔧 Bash: npm test [33%]
    📁 ~/projects/myapp  main
```

**Row 1:** Status indicator, AI badge, session name, current tool, context %
**Row 2:** Working directory, git branch

### Extract Fields

```bash
# Session ID
session=$(echo "$line" | grep -oP 'ctt-[a-z0-9-]+' | head -1)

# Context %
context=$(echo "$line" | grep -oP '\[\d+%\]' | tr -d '[]%')

# Current tool
tool=$(echo "$line" | grep -oP '🔧 \K[^[]+' | xargs)
```

## State Files

Claude Code hooks write state to `/tmp/claude-code-state/`:

```bash
# Session status
cat /tmp/claude-code-state/*.json | jq -c '{session_id, status, current_tool}'

# Context usage
cat /tmp/claude-code-state/*-context.json | jq -c '{session_id, context_pct}'
```

### State File Fields

```json
{
  "session_id": "_3",
  "status": "tool_use",
  "current_tool": "Bash",
  "subagent_count": 0,
  "working_dir": "/home/matt/projects/TabzChrome",
  "context_pct": 45
}
```

## Idle Detection

### Check if idle at prompt

```bash
LAST_LINE=$(tmux capture-pane -t "$SESSION" -p | tail -1)
if echo "$LAST_LINE" | grep -qE '^\s*>\s*$'; then
  echo "IDLE_AT_PROMPT"
fi
```

### Check for uncommitted work

```bash
WORKDIR=$(tmux display-message -t "$SESSION" -p '#{pane_current_path}')
GIT_STATUS=$(git -C "$WORKDIR" status --short 2>/dev/null)
if [ -n "$GIT_STATUS" ]; then
  echo "UNCOMMITTED_CHANGES"
fi
```

### Track idle duration

```bash
IDLE_FILE="/tmp/claude-code-state/${SESSION}-idle.txt"
CURRENT_HASH=$(tmux capture-pane -t "$SESSION" -p | md5sum | cut -d' ' -f1)
PREV_HASH=$(head -1 "$IDLE_FILE" 2>/dev/null)

if [ "$CURRENT_HASH" = "$PREV_HASH" ]; then
  # No change - calculate idle time
  PREV_TIME=$(tail -1 "$IDLE_FILE")
  IDLE_SECONDS=$(($(date +%s) - PREV_TIME))
else
  # Activity detected - reset
  echo "$CURRENT_HASH" > "$IDLE_FILE"
  date +%s >> "$IDLE_FILE"
fi
```

## Completion Detection

### Check beads issue status (most reliable)

```bash
if bd show "$ISSUE_ID" 2>/dev/null | grep -q "Status: closed"; then
  echo "COMPLETED"
fi
```

### Check for commit in worktree

```bash
WORKTREE="${PROJECT_DIR}-worktrees/${ISSUE_ID}"
if git -C "$WORKTREE" log -1 --oneline | grep -qi "$ISSUE_ID"; then
  echo "COMMITTED"
fi
```

## Nudge Patterns

### Safe to nudge

- `idle` for 2+ minutes with uncommitted work
- `idle` for 5+ minutes at empty prompt

### Don't nudge

- `processing` or `tool_use` - actively working
- `awaiting_input` recently - may be at prompt, check pane first

### Nudge message

```bash
if tmux has-session -t "$SESSION" 2>/dev/null; then
  tmux send-keys -t "$SESSION" -l "You have uncommitted changes. Consider: git add . && git commit"
  sleep 0.3
  tmux send-keys -t "$SESSION" C-m
fi
```

## Notifications

```bash
# Browser notification
mcp-cli call tabz/tabz_notification_show '{"title": "Worker Done", "message": "Task completed", "type": "basic"}'

# TTS announcement
mcp-cli call tabz/tabz_speak '{"text": "Sprint complete"}'
```
