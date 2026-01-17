---
description: "Complete a wave of parallel workers: verify completion, merge branches, unified review, cleanup, push. Run after all workers finish."
---

# Wave Done - Wave Completion Orchestrator

Orchestrates the completion of a wave of parallel workers spawned by bd-swarm.

## Workflow Steps

**Add these steps to your to-dos using TodoWrite, then mark each as completed:**

```
Steps:
- [ ] Step 1: Verify all workers completed
- [ ] Step 2: Capture transcripts and kill sessions
- [ ] Step 3: Merge branches to main
- [ ] Step 4: Build verification
- [ ] Step 5: Unified code review
- [ ] Step 6: Cleanup worktrees and branches
- [ ] Step 7: Visual QA (if UI changes)
- [ ] Step 8: Sync and push
- [ ] Step 9: Summary and next wave check
```

---

## Usage

```bash
# Complete a wave with specific issues
/conductor:wave-done TabzChrome-abc TabzChrome-def TabzChrome-ghi

# Or use environment variable set by bd-swarm
/conductor:wave-done $WAVE_ISSUES
```

---

## Step 1: Verify All Workers Completed

```bash
echo "=== Step 1: Verify Worker Completion ==="

ISSUES="$@"
ALL_CLOSED=true

for ISSUE in $ISSUES; do
  STATUS=$(bd show "$ISSUE" --json 2>/dev/null | jq -r '.[0].status // "unknown"')
  if [ "$STATUS" != "closed" ]; then
    echo "BLOCKED: $ISSUE is $STATUS (not closed)"
    ALL_CLOSED=false
  else
    echo "OK: $ISSUE is closed"
  fi
done

if [ "$ALL_CLOSED" != "true" ]; then
  echo "ERROR: Not all issues are closed. Wait for workers to finish."
  exit 1
fi
```

**Validation:**
- All issues closed? → Proceed to Step 2
- Some not closed? → **STOP**, wait for workers, re-run Step 1

---

## Step 2: Capture Transcripts and Kill Sessions

**Capture transcripts BEFORE killing sessions.**

```bash
echo "=== Step 2: Capture Transcripts and Kill Sessions ==="

CAPTURE_SCRIPT="${CLAUDE_PLUGIN_ROOT:-./plugins/conductor}/scripts/capture-session.sh"

for ISSUE in $ISSUES; do
  # Try worker-ISSUE format
  if tmux has-session -t "worker-${ISSUE}" 2>/dev/null; then
    [ -x "$CAPTURE_SCRIPT" ] && "$CAPTURE_SCRIPT" "worker-${ISSUE}" "$ISSUE" 2>/dev/null
    tmux kill-session -t "worker-${ISSUE}" 2>/dev/null && echo "Killed: worker-${ISSUE}"
  fi

  # Try ctt-worker-* format (TabzChrome spawned)
  SHORT_ID="${ISSUE##*-}"
  tmux list-sessions -F '#{session_name}' 2>/dev/null | grep -E "ctt-worker.*${SHORT_ID}" | while read -r S; do
    [ -x "$CAPTURE_SCRIPT" ] && "$CAPTURE_SCRIPT" "$S" "$ISSUE" 2>/dev/null
    tmux kill-session -t "$S" 2>/dev/null && echo "Killed: $S"
  done || true
done

echo "Transcripts saved to .beads/transcripts/"
```

**Validation:**
- Sessions killed? → Proceed to Step 3
- Session not found? → Log warning, continue (may already be killed)

---

## Step 3: Merge Branches to Main

```bash
echo "=== Step 3: Merge Branches ==="

git checkout main

for ISSUE in $ISSUES; do
  BRANCH="feature/${ISSUE}"
  if git merge --no-edit "$BRANCH" 2>/dev/null; then
    echo "Merged: $BRANCH"
  else
    echo "CONFLICT: $BRANCH"
    git merge --abort 2>/dev/null || true
    echo "ERROR: Resolve conflicts manually, then re-run wave-done."
    exit 1
  fi
done
```

**Validation:**
- All branches merged? → Proceed to Step 4
- Merge conflict? → **STOP**, resolve manually, re-run from Step 3

---

## Step 4: Build Verification

Run `/conductor:verify-build`.

**Validation:**
- Build succeeded? → Proceed to Step 5
- Build failed? → **STOP**, fix errors, re-run from Step 4

---

## Step 5: Unified Code Review

Run `/conductor:code-review`.

This reviews all merged changes together, catching cross-worker interactions.

**Validation:**
- No blockers found? → Proceed to Step 6
- Blockers found? → **STOP**, fix issues, re-run from Step 5

---

## Step 6: Cleanup Worktrees and Branches

```bash
echo "=== Step 6: Cleanup ==="

PROJECT_DIR=$(pwd)
WORKTREE_DIR="${PROJECT_DIR}-worktrees"

for ISSUE in $ISSUES; do
  # Remove worktree
  if [ -d "${WORKTREE_DIR}/${ISSUE}" ]; then
    git worktree remove --force "${WORKTREE_DIR}/${ISSUE}" 2>/dev/null || true
    echo "Removed worktree: ${ISSUE}"
  fi

  # Delete feature branch
  git branch -d "feature/${ISSUE}" 2>/dev/null && echo "Deleted branch: feature/${ISSUE}" || true
done

rmdir "$WORKTREE_DIR" 2>/dev/null || true
```

**Validation:**
- Cleanup completed? → Proceed to Step 7
- Cleanup errors? → Log and continue (non-blocking)

---

## Step 7: Visual QA (Optional)

**Skip if wave was backend/config only.**

If UI changes were in the wave:

```markdown
Task(subagent_type="conductor:tabz-manager",
     prompt="Visual QA after wave merge. Screenshot key UI areas and check for errors.")
```

**Validation:**
- Visual QA passed (or skipped)? → Proceed to Step 8
- Visual issues found? → Fix, commit, re-run from Step 4

---

## Step 8: Sync and Push

```bash
echo "=== Step 8: Sync and Push ==="

bd sync
git push origin main

echo "Pushed to main"
```

**Validation:**
- Push succeeded? → Proceed to Step 9
- Push failed? → Check git errors, retry

---

## Step 9: Summary and Next Wave

Announce completion:
- Issues completed
- Branches merged
- Commits included

Check for next wave:

```bash
NEXT_COUNT=$(bd ready --json | jq 'length')
if [ "$NEXT_COUNT" -gt 0 ]; then
  echo "$NEXT_COUNT issues ready for next wave"
fi
```

---

## Error Recovery

| Step | On Failure | Recovery |
|------|------------|----------|
| 1 | Issues not closed | Wait for workers to finish |
| 2 | Session not found | Log warning, continue |
| 3 | Merge conflict | Resolve manually, re-run |
| 4 | Build failed | Fix errors, re-run |
| 5 | Review blockers | Fix issues, re-run |
| 6 | Cleanup failed | Log and continue |
| 7 | Visual issues | Fix, re-run from Step 4 |
| 8 | Push failed | Check git errors, retry |

---

## After Wave-Done

Use `/conductor:analyze-transcripts` to review worker performance and improve prompts.

For fully autonomous operation, use `/conductor:bd-swarm-auto` which loops waves automatically.
