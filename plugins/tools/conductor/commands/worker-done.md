---
description: "Clean up after a worker completes - merge, remove worktree, sync beads"
argument-hint: "WORKTREE_PATH"
---

# Worker Done

Clean up after a worker finishes their issue.

## Usage

```bash
/conductor:worker-done .worktrees/ISSUE-ID
```

## What This Does

1. **Merge changes** from worktree branch to main
2. **Remove worktree** via beads
3. **Sync beads** to persist state
4. **Kill tmux session** if still running

## Manual Steps

```bash
WORKTREE=".worktrees/ISSUE-ID"
BRANCH="feature/ISSUE-ID"
SESSION="ctt-default-abc123"

# 1. Check issue is closed
bd show ISSUE-ID --json | jq -r '.[0].status'  # Should be "closed"

# 2. Merge changes
git checkout main
git merge "$BRANCH" --no-edit

# 3. Remove worktree
bd worktree remove "$WORKTREE"

# 4. Delete branch
git branch -d "$BRANCH"

# 5. Kill session
tmux kill-session -t "$SESSION" 2>/dev/null || true

# 6. Sync beads
bd sync
```

## Batch Cleanup

After a wave of workers completes:

```bash
# Find all closed issues with worktrees
for dir in .worktrees/*/; do
  ISSUE=$(basename "$dir")
  STATUS=$(bd show "$ISSUE" --json 2>/dev/null | jq -r '.[0].status // "unknown"')
  if [ "$STATUS" = "closed" ]; then
    echo "Cleaning up $ISSUE..."
    git checkout main
    git merge "feature/$ISSUE" --no-edit 2>/dev/null || true
    bd worktree remove ".worktrees/$ISSUE" 2>/dev/null || true
    git branch -d "feature/$ISSUE" 2>/dev/null || true
  fi
done
bd sync
```

## Worker Retro (Optional)

Before cleanup, capture worker feedback on the closed issue:

```bash
bd update ISSUE-ID --notes "$(cat <<'EOF'
## Worker Retro
- What was unclear: [e.g., "Prompt didn't mention auth middleware dependency"]
- Missing context: [e.g., "Had to discover useTerminalSessions.ts - add to key files"]
- Discovered work: [e.g., "Found tech debt in X, created follow-up issue"]
- What would help: [e.g., "Link to relevant tests"]
EOF
)"
```

### Retro Questions

| Question | Why It Helps |
|----------|--------------|
| What was unclear in the prompt? | Improve prompt templates |
| What context did you wish you had? | Better key files lists |
| What did you have to search for? | Add to CLAUDE.md |
| Did you discover unrelated work? | Validate issue scoping |
| What would've made this 2x faster? | Process improvements |

### Mining Retros

Review past issues to find patterns:

```bash
# Get retros from closed issues
bd list --status closed --json | jq -r '.[] | select(.notes | contains("Retro")) | "\(.id): \(.notes)"'
```

Patterns → improve PRIME.md, CLAUDE.md, prompt templates.

## Notes

- Always verify issue is closed before cleanup
- Merge conflicts require manual resolution
- Use `bd sync` at the end to persist all changes
- Worker retros are optional but valuable for prompt improvement
