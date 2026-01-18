---
description: "Spawn Claude workers in isolated worktrees via TabzChrome"
---

# Spawn Workers

Spawn Claude terminals in isolated git worktrees to work on beads issues in parallel.

## Prerequisites

### Start Beads Daemon

The daemon auto-syncs issues across workers. Start it before spawning:

```bash
# Check if daemon is running
bd daemon status

# Start if not running
bd daemon start

# Verify it's healthy
bd daemon status --all
```

The daemon ensures workers see the latest issue state without manual `bd sync`.

## Quick Start

```bash
# Ensure daemon is running
bd daemon status || bd daemon start

# Get ready issues
bd ready --json

# Create worktree for issue
bd worktree create .worktrees/ISSUE-ID --branch feature/ISSUE-ID

# Spawn terminal via TabzChrome
TOKEN=$(cat /tmp/tabz-auth-token)
curl -s -X POST http://localhost:8129/api/spawn \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $TOKEN" \
  -d '{
    "name": "Claude: ISSUE-ID",
    "workingDir": "/path/to/.worktrees/ISSUE-ID",
    "command": "claude --dangerously-skip-permissions"
  }'
```

## Prompts in Beads Issues

Store worker prompts in the issue `notes` field:

```bash
# Add prompt when planning
bd update ISSUE-ID --notes "Fix the pagination bug in useTerminalSessions.ts around line 200.

Key files: extension/hooks/useTerminalSessions.ts

When done:
- Run tests: npm test
- Close: bd close ISSUE-ID --reason done"

# Worker reads prompt
PROMPT=$(bd show ISSUE-ID --json | jq -r '.[0].notes')
```

### Prompt Guidelines

Keep prompts simple - workers are vanilla Claude:
- **Be explicit** - "Fix X on line Y" not "Can you look at X"
- **Include key files** - Worker reads these first
- **Use skill triggers** - Natural language hints for skills
- **End with completion** - `bd close ISSUE-ID --reason done`

#### Skill Trigger Examples

Use natural language to activate skills:

| Domain | Trigger Phrase |
|--------|----------------|
| Terminal | "Use the xterm-js skill for terminal resize handling" |
| UI/React | "Use the ui-styling skill to match our design system" |
| Backend | "Use the backend-development skill for API patterns" |
| Plugin dev | "Use the plugin-dev skill for manifest validation" |
| Code review | "Use the code-review skill before committing" |
| Browser | "Use the automating-browser skill to check for console errors" |

Example prompt with skill hints:
```
Fix the terminal resize bug in Terminal.tsx.

Use the xterm-js skill for terminal integration patterns.
Key files: extension/components/Terminal.tsx

When done:
- Use the code-review skill before committing
- bd close ISSUE-ID --reason done
```

Avoid:
- Step-by-step pipelines (let Claude work naturally)
- ALL CAPS or aggressive language
- Skill loading instructions (skills activate on keywords)

## Sending Prompts via tmux

**CRITICAL: Always use sleep before C-m to prevent premature submission:**

```bash
SESSION="ctt-default-abc123"  # From spawn response

# Send prompt with proper timing
tmux send-keys -t "$SESSION" -l "$(bd show ISSUE-ID --json | jq -r '.[0].notes')"
sleep 0.3  # CRITICAL: prevents prompt corruption
tmux send-keys -t "$SESSION" C-m
```

### Common tmux Issues

| Problem | Cause | Fix |
|---------|-------|-----|
| Prompt doesn't submit | Missing delay | Add `sleep 0.3` before `C-m` |
| Partial prompt sent | Special characters | Use `-l` flag for literal text |
| Worker sits idle | Prompt not received | Check session name matches |

## Monitoring Workers

```bash
# Summary of all workers
${CLAUDE_PLUGIN_ROOT}/scripts/monitor-workers.sh --summary

# Detailed status (session|status|context%)
${CLAUDE_PLUGIN_ROOT}/scripts/monitor-workers.sh --status

# Check if issue is closed
${CLAUDE_PLUGIN_ROOT}/scripts/monitor-workers.sh --check-issue ISSUE-ID
```

### Status States

| Status | Meaning | Action |
|--------|---------|--------|
| `tool_use` | Worker executing | Wait |
| `processing` | Worker thinking | Wait |
| `awaiting_input` | Worker idle at prompt | May need nudge |
| `asking_user` | Waiting for user answer | Answer or nudge |
| `stale` | No activity | Check/restart |

### Nudging Idle Workers

```bash
# If worker finished but didn't close issue
tmux send-keys -t "$SESSION" -l "Close the issue: bd close ISSUE-ID --reason done"
sleep 0.3
tmux send-keys -t "$SESSION" C-m
```

## Browser Debugging (via tabz MCP)

Use tabz MCP tools to check browser state during QA:

```bash
# Check for console errors
MCPSearch: select:mcp__tabz__tabz_get_console_logs
mcp__tabz__tabz_get_console_logs with level="error"

# Capture network issues
MCPSearch: select:mcp__tabz__tabz_enable_network_capture
MCPSearch: select:mcp__tabz__tabz_get_network_requests
mcp__tabz__tabz_enable_network_capture
# ... trigger action ...
mcp__tabz__tabz_get_network_requests with filter="error" or statusFilter="error"

# Screenshot for visual QA
MCPSearch: select:mcp__tabz__tabz_screenshot
mcp__tabz__tabz_screenshot
```

## Worker Workflow

Workers use standard beads - no special instructions needed:

```bash
# Worker does this automatically:
bd ready --json                           # Find work
bd update ID --status in_progress --json  # Claim it
# ... do the work ...
bd close ID --reason "Done" --json        # Complete
bd sync                                   # End of session
```

## Cleanup

```bash
# Remove worktree when done
bd worktree remove .worktrees/ISSUE-ID

# Kill terminal session
tmux kill-session -t SESSION_NAME
```

## Notes

- Always create worktrees BEFORE spawning
- Use `bd worktree create` (not raw `git worktree`) for beads redirect
- Workers are vanilla Claude - they use beads naturally
- Store prompts in `--notes` field for easy retrieval
