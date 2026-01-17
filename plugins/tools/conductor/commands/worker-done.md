---
description: "Complete worker task: verify build, run tests, commit, and close issue. Code review happens at conductor level after merge."
---

# Worker Done - Task Completion Pipeline

Orchestrates the full task completion pipeline for workers.

## Workflow Steps

**Add these steps to your to-dos using TodoWrite, then mark each as completed:**

```
Steps:
- [ ] Step 0: Detect change types
- [ ] Step 1: Verify build (if code changes)
- [ ] Step 1a: Validate plugin (if plugin-only changes)
- [ ] Step 2: Run tests (if code changes)
- [ ] Step 3: Commit changes
- [ ] Step 4: Create follow-ups (non-blocking)
- [ ] Step 5: Update docs (non-blocking)
- [ ] Step 6: Close issue
- [ ] Step 7: Notify conductor (REQUIRED)
```

---

## Usage

```bash
/conductor:worker-done TabzChrome-abc

# Or if issue ID is in your task header:
/conductor:worker-done
```

---

## Step 0: Detect Change Types

```bash
echo "=== Step 0: Detecting Change Types ==="
CHANGED_FILES=$(git diff --cached --name-only; git diff --name-only)

if [ -z "$CHANGED_FILES" ]; then
  CHANGE_TYPE="none"
elif echo "$CHANGED_FILES" | grep -qvE '\.(md|markdown|json)$'; then
  CHANGE_TYPE="code"
else
  CHANGE_TYPE="plugin"
fi

echo "Change type: $CHANGE_TYPE"
```

**Decision tree:**
- `none` → Skip to Step 3
- `plugin` → Run Step 1a, skip Steps 1-2
- `code` → Run Steps 1-2

---

## Step 1: Verify Build (CHANGE_TYPE=code)

```bash
echo "=== Step 1: Build Verification ==="
```

Run `/conductor:verify-build`.

**Validation:**
- Build succeeded? → Proceed to Step 2
- Build failed? → **STOP**, fix errors, re-run from Step 1

---

## Step 1a: Plugin Validator (CHANGE_TYPE=plugin)

When only plugin files changed:

```markdown
Task(subagent_type="plugin-dev:plugin-validator",
     prompt="Validate plugin changes: $CHANGED_FILES")
```

**Validation:**
- Validation passed? → Skip to Step 3
- Validation failed? → **STOP**, fix issues, re-run from Step 1a

---

## Step 2: Run Tests (CHANGE_TYPE=code)

```bash
echo "=== Step 2: Test Verification ==="
```

Run `/conductor:run-tests`.

**Validation:**
- Tests passed (or no tests)? → Proceed to Step 3
- Tests failed? → **STOP**, fix tests, re-run from Step 2

---

## Step 3: Commit Changes

```bash
echo "=== Step 3: Commit ==="
```

Run `/conductor:commit-changes`.

**Validation:**
- Commit created? → Proceed to Step 4
- Commit failed? → Fix git errors, re-run from Step 3

---

## Step 4: Create Follow-ups (Non-blocking)

```bash
echo "=== Step 4: Follow-ups ==="
```

Run `/conductor:create-followups`. Log and continue regardless of result.

---

## Step 5: Update Docs (Non-blocking)

```bash
echo "=== Step 5: Documentation ==="
```

Run `/conductor:update-docs`. Log and continue regardless of result.

---

## Step 6: Close Issue

```bash
echo "=== Step 6: Close Issue ==="
```

Run `/conductor:close-issue <issue-id>`.

**Validation:**
- Issue closed? → Proceed to Step 7
- Close failed? → Check beads errors, retry

---

## Step 7: Notify Conductor (REQUIRED)

**DO NOT SKIP THIS STEP.** After closing the issue, notify the conductor:

```bash
echo "=== Step 7: Notify Conductor ==="

ISSUE_ID="$1"
SUMMARY=$(git log -1 --format='%s' 2>/dev/null || echo 'committed')
WORKER_SESSION=$(tmux display-message -p '#{session_name}' 2>/dev/null || echo 'unknown')

# Primary: tmux send-keys to conductor session
CONDUCTOR_SESSION="${CONDUCTOR_SESSION:-}"
if [ -n "$CONDUCTOR_SESSION" ]; then
  tmux send-keys -t "$CONDUCTOR_SESSION" -l "WORKER COMPLETE: $ISSUE_ID - $SUMMARY"
  sleep 0.3
  tmux send-keys -t "$CONDUCTOR_SESSION" C-m
  echo "Notified conductor via tmux: $CONDUCTOR_SESSION"
else
  echo "WARNING: CONDUCTOR_SESSION not set - conductor won't receive notification"
fi

# Secondary: API broadcast for browser UIs
TOKEN=$(cat /tmp/tabz-auth-token 2>/dev/null)
if [ -n "$TOKEN" ]; then
  curl -s -X POST http://localhost:8129/api/notify \
    -H "Content-Type: application/json" \
    -H "X-Auth-Token: $TOKEN" \
    -d "{\"type\": \"worker-complete\", \"issueId\": \"$ISSUE_ID\", \"summary\": \"$SUMMARY\", \"session\": \"$WORKER_SESSION\"}" >/dev/null
fi

echo "=== Worker Done ==="
```

---

## Error Recovery

| Step | On Failure | Recovery |
|------|------------|----------|
| 1 | Build failed | Fix errors, re-run pipeline |
| 1a | Plugin invalid | Fix issues, re-run pipeline |
| 2 | Tests failed | Fix tests, re-run pipeline |
| 3 | Commit failed | Fix git errors, retry |
| 4-5 | Non-blocking | Log and continue |
| 6 | Close failed | Check beads errors |
| 7 | Notify failed | Log warning (conductor will poll) |

---

## Re-running After Fixes

If the pipeline stopped:
1. Fix the issues
2. Run `/conductor:worker-done` again

The pipeline is idempotent - safe to re-run.

---

## Important Notes

- **Use `bd` CLI, not MCP** - Workers should use `bd show`, `bd close`, not `mcp-cli call beads/...`
- **Code review happens at conductor level** - Workers do NOT run code review
- **Workers do NOT kill their own session** - Conductor handles cleanup
