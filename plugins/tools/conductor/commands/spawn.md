---
description: "Spawn Claude workers in isolated worktrees via TabzChrome"
---

# Spawn Workers

Spawn Claude terminals in isolated git worktrees to work on beads issues in parallel.

## Quick Start

```bash
# Get ready issues
bd ready --json

# Create worktrees for each issue (using beads built-in)
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

## Worker Workflow

Workers use standard beads commands - no special conductor instructions needed:

```bash
# Worker does this automatically:
bd ready --json              # Find work
bd update ID --status in_progress --json  # Claim it
# ... do the work ...
bd close ID --reason "Done" --json  # Complete
bd sync                      # End of session
```

## Monitoring

```bash
# Check worker status
${CLAUDE_PLUGIN_ROOT}/scripts/monitor-workers.sh --summary
```

## Cleanup

```bash
# Remove worktree when done
bd worktree remove .worktrees/ISSUE-ID

# Kill terminal session
tmux kill-session -t SESSION_NAME
```

## Notes

- Always create worktrees BEFORE spawning (workers need isolated directories)
- Workers are just Claude + beads - they know what to do
- Use `bd worktree create` (not raw `git worktree`) for proper beads redirect setup
