---
description: "Fully autonomous backlog completion. Runs waves until `bd ready` is empty. Self-resumable after /wipe. Use when you want hands-off parallel issue processing."
---

# BD Swarm Auto - Autonomous Backlog Completion

Fully autonomous mode that processes waves until the backlog is empty. No user input required.

## Workflow Steps

**Add these steps to your to-dos using TodoWrite, then mark each as completed:**

```
Steps:
- [ ] Step 1: Check ready issues
- [ ] Step 2: Create worktrees
- [ ] Step 3: Set CONDUCTOR_SESSION
- [ ] Step 4: Spawn workers (max 4)
- [ ] Step 5: Craft and send prompts
- [ ] Step 6: Monitor until all complete
- [ ] Step 7: Run wave-done
- [ ] Step 8: Check for next wave (loop to Step 1)
```

---

## Key Rules

- **NO USER INPUT** - Make reasonable defaults, never use AskUserQuestion
- **MAX 4 WORKERS** - Distribute issues across workers
- **MONITOR CONTEXT** - At 70%+, trigger `/wipe:wipe` with handoff
- **LOOP UNTIL EMPTY** - Keep running waves until backlog clear

---

## Step 1: Check Ready Issues

```bash
bd ready --json | jq -r '.[] | "\(.id): \(.title)"'
```

**Decision:**
- Issues available? → Proceed to Step 2
- No issues? → Announce "Backlog complete!" and **STOP**

---

## Step 2: Create Worktrees

```bash
PROJECT_DIR=$(pwd)
WORKTREE_DIR="${PROJECT_DIR}-worktrees"
mkdir -p "$WORKTREE_DIR"

for ISSUE_ID in $(bd ready --json | jq -r '.[].id'); do
  ${CLAUDE_PLUGIN_ROOT}/scripts/setup-worktree.sh "$ISSUE_ID" &
done
wait
```

**Validation:**
- All worktrees ready? → Proceed to Step 3
- Setup failed? → Fix issues, retry

---

## Step 3: Set CONDUCTOR_SESSION

```bash
CONDUCTOR_SESSION=$(tmux display-message -p '#{session_name}')
echo "Conductor session: $CONDUCTOR_SESSION"
```

**Validation:**
- Session captured? → Proceed to Step 4
- Empty? → Verify tmux, retry

---

## Step 4: Spawn Workers (Max 4)

```bash
TOKEN=$(cat /tmp/tabz-auth-token)
WORKTREE_DIR="$(pwd)-worktrees"

for ISSUE_ID in $(bd ready --json | jq -r '.[].id' | head -4); do
  WORKTREE="${WORKTREE_DIR}/${ISSUE_ID}"
  RESPONSE=$(curl -s -X POST http://localhost:8129/api/spawn \
    -H "Content-Type: application/json" \
    -H "X-Auth-Token: $TOKEN" \
    -d "{\"name\": \"worker-$ISSUE_ID\", \"workingDir\": \"$WORKTREE\", \"command\": \"BD_SOCKET=/tmp/bd-worker-$ISSUE_ID.sock CONDUCTOR_SESSION='$CONDUCTOR_SESSION' claude --dangerously-skip-permissions\"}")
  SESSION=$(echo "$RESPONSE" | jq -r '.terminal.ptyInfo.tmuxSession')
  echo "Spawned $ISSUE_ID -> $SESSION"
done
```

**Validation:**
- Workers spawned? → Proceed to Step 5
- Spawn failed? → Check TabzChrome backend, retry

---

## Step 5: Craft and Send Prompts

```
Skill(skill: "conductor:engineering-prompts")
```

Execute its workflow:
1. Spawn parallel Explore agents (haiku) per issue
2. Synthesize findings into detailed prompts
3. Each prompt must end with `/conductor:worker-done <issue-id>`

Send prompts to each worker via tmux send-keys.

**Validation:**
- All prompts sent with worker-done instruction? → Proceed to Step 6
- Missing worker-done? → Add it to each prompt

---

## Step 6: Monitor Until Complete

Poll every 2 minutes:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/monitor-workers.sh --summary
```

**Continue monitoring until:**
- All issues show status `closed` in beads
- Then proceed to Step 7

**Context check:**
- At 70%+ context → Prepare for `/wipe:wipe` with handoff
- Include wave state in handoff: issues, progress, next steps

---

## Step 7: Run Wave-Done

```bash
/conductor:wave-done $WAVE_ISSUES
```

This handles merge, review, cleanup, push.

**Validation:**
- Wave-done completed? → Proceed to Step 8
- Errors? → Fix, retry wave-done

---

## Step 8: Check for Next Wave

```bash
NEXT_COUNT=$(bd ready --json | jq 'length')
```

**Decision:**
- More issues ready? → **Loop to Step 1**
- Backlog empty? → Announce "All waves complete!" and **STOP**

---

## Error Recovery

| Step | On Failure | Recovery |
|------|------------|----------|
| 2 | Worktree setup fails | Check disk space, retry |
| 4 | Spawn fails | Check TabzChrome backend |
| 6 | Worker stuck | Check pane content, nudge |
| 7 | Wave-done fails | Fix issue, retry wave-done |

---

## Context Management

When context reaches 70%:

1. Capture current state:
   - Which issues are in progress
   - Which workers are running
   - What step in the wave

2. Run `/wipe:wipe` with handoff containing state

3. New session resumes from handoff

---

## Reference

For full details, see `references/bd-swarm/auto-mode.md`.
