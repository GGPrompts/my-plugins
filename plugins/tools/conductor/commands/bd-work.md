---
description: "Pick the top ready beads issue and spawn a visible worker to complete it"
---

# Beads Work - Single Issue Worker

Spawn a visible worker to tackle one beads issue. Unlike bd-swarm, no worktree is created since there's only one worker.

## Workflow Steps

**Add these steps to your to-dos using TodoWrite, then mark each as completed:**

```
Steps:
- [ ] Step 1: Load prerequisites
- [ ] Step 2: Select issue
- [ ] Step 3: Get issue details
- [ ] Step 4: Craft prompt (engineering-prompts)
- [ ] Step 5: Set CONDUCTOR_SESSION
- [ ] Step 6: Spawn worker
- [ ] Step 7: Send prompt
- [ ] Step 8: Monitor completion
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

## Step 2: Select Issue

```bash
# If no ID provided, get top ready issue
bd ready

# Or use provided ID
ISSUE_ID="TabzChrome-xxx"  # Replace with actual ID
```

**Validation:**
- Issue ID obtained? → Proceed to Step 3
- No ready issues? → Announce "No issues ready" and stop

---

## Step 3: Get Issue Details

```bash
bd show "$ISSUE_ID"
```

**Validation:**
- Issue details retrieved? → Proceed to Step 4
- Issue not found? → Return to Step 2, verify issue ID

---

## Step 4: Craft Prompt

Invoke the engineering-prompts skill:

```
Skill(skill: "conductor:engineering-prompts")
```

This runs in **forked context** and:
1. Spawns parallel haiku Explore agents
2. Gathers file paths, patterns, dependencies
3. Returns a ready-to-use prompt

**Required prompt structure:**

```markdown
## Task: ISSUE-ID - Title
[Explicit, actionable description]

## Context
[Background and WHY]

## Key Files
- /path/to/file.ts:45-60 - [what's relevant]

## Approach
[Implementation guidance]

## When Done
Run `/conductor:worker-done ISSUE-ID`
```

**Validation:**
- Prompt crafted with all sections? → Proceed to Step 5
- Missing sections? → Complete the prompt structure above

---

## Step 5: Set CONDUCTOR_SESSION

```bash
CONDUCTOR_SESSION=$(tmux display-message -p '#{session_name}')
echo "Conductor session: $CONDUCTOR_SESSION"
```

**Validation:**
- Session name captured? → Proceed to Step 6
- Empty result? → Verify you're in a tmux session, retry

---

## Step 6: Spawn Worker

```bash
TOKEN=$(cat /tmp/tabz-auth-token)
PROJECT_DIR=$(pwd)

RESPONSE=$(curl -s -X POST http://localhost:8129/api/spawn \
  -H "Content-Type: application/json" \
  -H "X-Auth-Token: $TOKEN" \
  -d "{\"name\": \"$ISSUE_ID-worker\", \"workingDir\": \"$PROJECT_DIR\", \"command\": \"CONDUCTOR_SESSION=$CONDUCTOR_SESSION claude --dangerously-skip-permissions\"}")

SESSION=$(echo "$RESPONSE" | jq -r '.terminal.ptyInfo.tmuxSession')
echo "Spawned: $SESSION"

# Record session IDs for audit trail
bd update "$ISSUE_ID" --notes "conductor_session: $CONDUCTOR_SESSION
worker_session: $SESSION
started_at: $(date -Iseconds)"
```

**Validation:**
- Worker spawned (SESSION captured)? → Proceed to Step 7
- Spawn failed? → Check TabzChrome backend running, retry

---

## Step 7: Send Prompt

Wait for Claude to load (~8 seconds), then send:

```bash
sleep 8
tmux send-keys -t "$SESSION" -l "<crafted-prompt-from-step-4>"
sleep 0.3
tmux send-keys -t "$SESSION" C-m
```

**Validation:**
- Prompt sent? → Proceed to Step 8
- tmux error? → Verify SESSION name, retry

---

## Step 8: Monitor Completion

User watches worker progress in TabzChrome sidebar. Worker will:
1. Read issue details
2. Explore codebase as needed
3. Implement the fix/feature
4. Run `/conductor:worker-done <issue-id>`

**When worker completes:**

```bash
# Kill the worker session
tmux kill-session -t "$SESSION"
```

---

## Error Recovery

| Step | On Failure | Recovery |
|------|------------|----------|
| 2 | No ready issues | Check `bd ready`, verify beads database |
| 3 | Issue not found | Verify issue ID exists |
| 6 | Spawn failed | Check TabzChrome backend: `curl http://localhost:8129/api/health` |
| 7 | tmux error | Verify session exists: `tmux has-session -t "$SESSION"` |

---

## Comparison with bd-swarm

| Aspect | bd-work | bd-swarm |
|--------|---------|----------|
| Workers | 1 | Multiple |
| Worktree | No | Yes (per worker) |
| Conflict risk | None | Managed via isolation |
| Use case | Single issue focus | Batch parallel processing |
