---
description: "Spawn multiple Claude workers with skill-aware prompts to tackle beads issues in parallel"
---

# Beads Swarm - Parallel Issue Processing

Spawn multiple Claude workers to tackle beads issues in parallel.

## Workflow Steps

**Add these steps to your to-dos using TodoWrite, then mark each as completed:**

```
Steps:
- [ ] Step 1: Load prerequisites
- [ ] Step 2: Get ready issues
- [ ] Step 3: Create worktrees (BEFORE spawning)
- [ ] Step 4: Set CONDUCTOR_SESSION
- [ ] Step 5: Spawn workers
- [ ] Step 6: Craft and send prompts
- [ ] Step 7: Monitor workers
- [ ] Step 8: Run wave-done when complete
```

---

## Step 1: Load Prerequisites

```bash
/conductor:orchestration
```

Skip if already loaded or running as `--agent conductor:conductor`.

**Validation:**
- Orchestration loaded? → Proceed to Step 2
- Not loaded? → Run the command above, then proceed

---

## Step 2: Get Ready Issues

```bash
bd ready
```

Select issues to work on (interactive) or use all (auto mode).

**Validation:**
- Issues available? → Proceed to Step 3
- No ready issues? → Announce "Backlog complete!" and stop

---

## Step 3: Create Worktrees (MANDATORY - Before Spawning)

**Run for EACH issue before spawning any workers:**

```bash
for ISSUE in TabzChrome-abc TabzChrome-def; do
  ${CLAUDE_PLUGIN_ROOT}/scripts/setup-worktree.sh "$ISSUE" &
done
wait
echo "All worktrees ready"
```

The script creates worktree, installs dependencies, and runs initial build.

**Validation:**
- All worktrees show "READY: /path/..."? → Proceed to Step 3b
- Setup failed? → Check error output, fix issues, retry
- **DO NOT proceed without worktrees** - workers will conflict on files

---

## Step 3b: Start Lookahead Enhancer (OPTIONAL but recommended)

**While worktrees are being created, start the prompt enhancer in a background terminal:**

```bash
# In a separate terminal (or background)
${CLAUDE_PLUGIN_ROOT}/skills/engineering-prompts/scripts/lookahead-enhancer.sh &
```

This script (part of the `engineering-prompts` skill):
- Runs ahead of your workflow, preparing prompts for ready issues
- Stores `prepared.prompt` in issue notes for instant retrieval
- Matches skills and finds key files automatically
- Prevents duplicate work with `enhancing: true` flag

**Check status:**
```bash
${CLAUDE_PLUGIN_ROOT}/skills/engineering-prompts/scripts/lookahead-enhancer.sh --status
```

**Validation:**
- Enhancer running? → Proceed to Step 4
- Skipped? → You'll craft prompts manually in Step 6

---

## Step 4: Set CONDUCTOR_SESSION (REQUIRED)

**Workers use this to notify you when done. If not set, workers complete silently.**

```bash
CONDUCTOR_SESSION=$(tmux display-message -p '#{session_name}')
echo "Conductor session: $CONDUCTOR_SESSION"
```

**Validation:**
- Session name captured? → Proceed to Step 5
- Empty result? → Verify you're in tmux, retry

---

## Step 5: Spawn Workers

```bash
ISSUE_ID="TabzChrome-xxx"
WORKTREE_PATH="$(pwd)-worktrees/$ISSUE_ID"
TOKEN=$(cat /tmp/tabz-auth-token)

# BD_SOCKET isolates beads daemon per worker
RESPONSE=$(curl -s -X POST http://localhost:8129/api/spawn \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $TOKEN" \
  -d "{\"name\": \"worker-$ISSUE_ID\", \"workingDir\": \"$WORKTREE_PATH\", \"command\": \"BD_SOCKET=/tmp/bd-worker-$ISSUE_ID.sock CONDUCTOR_SESSION='$CONDUCTOR_SESSION' claude --dangerously-skip-permissions\"}")

SESSION_NAME=$(echo "$RESPONSE" | jq -r '.terminal.ptyInfo.tmuxSession // .terminal.id')
echo "Spawned: $SESSION_NAME"

# Record for audit trail
bd update "$ISSUE_ID" --notes "conductor_session: $CONDUCTOR_SESSION
worker_session: $SESSION_NAME
started_at: $(date -Iseconds)"
```

Repeat for each issue.

**Validation:**
- All workers spawned? → Proceed to Step 6
- Spawn failed? → Check TabzChrome backend: `curl http://localhost:8129/api/health`

---

## Step 6: Craft and Send Prompts

**6a. Check for pre-prepared prompts (if lookahead enhancer was running):**

```bash
# Check if prompt is already prepared
NOTES=$(bd show "$ISSUE_ID" --json | jq -r '.[0].notes // ""')
if echo "$NOTES" | grep -q "prepared.prompt:"; then
  # Extract prepared prompt from notes
  PROMPT=$(echo "$NOTES" | sed -n '/^prepared\.prompt:/,/^[a-z]*\./p' | tail -n +2 | sed 's/^  //')
  echo "Using pre-prepared prompt for $ISSUE_ID"
else
  echo "No prepared prompt - crafting manually"
fi
```

**6b. If no prepared prompt, craft manually using engineering-prompts skill:**

```
Skill(skill: "conductor:engineering-prompts")
```

This spawns parallel Explore agents (haiku) and synthesizes findings into detailed prompts.

**Required prompt structure:**

```markdown
## Task: ISSUE-ID - Title
[Explicit, actionable description]

## Context
[Background gathered via exploration]

## Key Files
- /path/to/file.ts:45-60 - [relevance]

## Approach
[Implementation guidance]

## When Done
Run `/conductor:worker-done ISSUE-ID`
```

**6c. Send prompts to workers:**

```bash
sleep 4
tmux send-keys -t "$SESSION_NAME" -l "$PROMPT"
sleep 0.3
tmux send-keys -t "$SESSION_NAME" C-m
```

**Validation:**
- All prompts include "When Done" section with worker-done? → Proceed to Step 7
- Missing? → Add `/conductor:worker-done ISSUE-ID` to each prompt

---

## Step 7: Monitor Workers

**Poll status every 2 minutes:**

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/monitor-workers.sh --summary
# Output: WORKERS:3 WORKING:2 IDLE:0 AWAITING:1 STALE:0
```

| Status | Action |
|--------|--------|
| `AskUserQuestion` | Don't nudge - waiting for user |
| `<other tool>` | Working, leave alone |
| `idle` / `awaiting_input` | Check if issue closed or stuck |
| Issue closed | Ready for cleanup |

**Validation:**
- All issues closed? → Proceed to Step 8
- Workers stuck? → Check pane content, nudge if needed
- Workers still working? → Continue monitoring

---

## Step 8: Run Wave-Done

When all issues are closed:

```bash
/conductor:wave-done TabzChrome-abc TabzChrome-def TabzChrome-ghi
```

This handles: merge branches → build verification → code review → cleanup → push.

**Validation:**
- Wave-done completed successfully? → Check `bd ready` for next wave
- Merge conflicts? → Resolve manually, re-run wave-done
- Build failed? → Fix errors, re-run wave-done

---

## Error Recovery

| Step | On Failure | Recovery |
|------|------------|----------|
| 3 | Worktree setup fails | Check disk space, git status |
| 5 | Spawn fails | Verify TabzChrome backend running |
| 6 | Prompt not sent | Verify tmux session exists |
| 7 | Worker stuck | Check pane content with `tmux capture-pane` |
| 8 | Merge conflict | Resolve manually, re-run wave-done |

---

## Mode Selection

| Mode | Command | Behavior |
|------|---------|----------|
| Interactive | `/conductor:bd-swarm` | Ask user for worker count |
| Auto | `/conductor:bd-swarm --auto` | Process entire backlog autonomously |

For auto mode details, see `references/bd-swarm/auto-mode.md`.

---

## Reference Files

| File | Content |
|------|---------|
| `references/bd-swarm/interactive-mode.md` | Full interactive workflow |
| `references/bd-swarm/auto-mode.md` | Auto mode wave loop |
| `references/bd-swarm/monitoring.md` | Worker status monitoring |
| `references/bd-swarm/completion-pipeline.md` | Cleanup steps |

---

## Key Rules

- **Worktrees BEFORE spawn** - Workers need isolated directories
- **CONDUCTOR_SESSION BEFORE spawn** - Workers need notification target
- **BD_SOCKET per worker** - Isolates beads daemon (prevents conflicts)
- **Visual review at conductor level** - Workers skip it to avoid browser tab conflicts
