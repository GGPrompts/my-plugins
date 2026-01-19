# Conductor Architecture Options

## The Problem

Orchestrating parallel Claude workers with quality checkpoints (code review, visual QA, tests) requires balancing:

1. **Context efficiency** - Loading complex workflows eats into context budget
2. **Reliability** - Agents not spawning, wrong tool access, cached plugins
3. **Simplicity** - Plugin system complexity makes debugging hard
4. **Token cost** - Fresh context on every spawn is expensive

## Current State

- **Workers**: Spawn via TabzChrome, work in worktrees, close beads issues
- **Conductor**: Monitors workers, merges when done
- **Missing**: Reliable checkpoint pipeline between "worker done" and "merge"

## Architecture Options

### Option 1: Monolithic Conductor (Current Pain Point)

```
Conductor Claude
├── Loads: all checkpoint skills, commands, formulas
├── Runs: everything inline or via Task tool
└── Problem: Context bloat, things get missed
```

**Pros:**
- Single session maintains full context of wave
- Can make nuanced decisions with full history

**Cons:**
- Context fills up fast with checkpoint knowledge
- Task tool agent spawning is unreliable
- Plugin caching issues make iteration painful
- Hard to debug what's loaded vs not

**Token cost:** High upfront, but amortized if session stays alive

---

### Option 2: Lean Conductor + Subagent Checkpoints

```
Conductor (minimal)
├── Knows: when to delegate, what checkpoints exist
├── Spawns: Task(subagent_type="checkpoint-name", ...)
└── Parses: results, decides next step

Checkpoint Subagents (loaded on-demand)
├── codex-reviewer
├── visual-qa
├── test-runner
└── etc.
```

**Pros:**
- Conductor stays lean (~1-2k tokens)
- Checkpoint context loaded only when needed
- Clean separation of concerns

**Cons:**
- Task tool reliability issues (tool access, spawn failures)
- Plugin system complexity remains
- Subagent results need to flow back cleanly

**Token cost:** Medium - subagents load their context when spawned

---

### Option 3: Bash Orchestrator + Claude Workers

```
Bash Script (orchestrator)
├── Monitors: beads issues, terminal states
├── Spawns: claude --agent <name> --print -p "..."
├── Parses: stdout/exit codes
└── Decides: next step, merge, or reopen

Claude Instances (stateless workers)
├── codex-reviewer agent
├── visual-qa agent
├── test-runner agent
└── Each runs, outputs result, exits
```

**Pros:**
- No plugin/caching issues - `--agent` reads .md fresh
- Predictable behavior - bash controls flow
- Easy to debug - each step is a CLI invocation
- `--print` gives parseable output

**Cons:**
- Each spawn pays full startup cost (~10-20k tokens for CLAUDE.md, etc.)
- Loses context between steps
- More complex bash scripting
- No nuanced decision-making with conversation history

**Token cost:** High per-step, but each step is isolated and predictable

---

### Option 4: Conductor Handoffs via /exit

```
Conductor: does work → /exit with status
    ↓
Bash: sees exit → spawns next Claude with prompt
    ↓
Next Claude: does checkpoint → /exit with status
    ↓
Bash: parses → spawns next OR merges OR reopens
```

**Pros:**
- Each Claude gets fresh, full context
- No context bloat from accumulated history
- Bash script is the "memory" between steps
- Simple mental model

**Cons:**
- High token cost per transition
- State must be serialized to disk/beads between steps
- No conversational continuity

**Token cost:** Highest - full startup for every step

---

### Option 5: TabzChrome Terminal Orchestration

```
Conductor Claude (long-lived)
├── Spawns: terminals via TabzChrome API
├── Monitors: terminal status via API
├── Reads: results from output/files
└── Stays: in control of overall flow

Checkpoint Terminals (isolated)
├── Each: claude --agent <name> -p "..."
├── Runs: in isolated tmux session
├── Outputs: to file or beads issue
└── Exits: conductor detects completion
```

**Pros:**
- Conductor keeps wave context
- Checkpoints run in isolation (fresh context)
- TabzChrome API gives lifecycle control
- Can parallelize checkpoints if independent

**Cons:**
- Each checkpoint still pays startup cost
- Need to pass state via files/beads
- More moving parts (TabzChrome dependency)

**Token cost:** Medium-high - conductor amortized, checkpoints pay startup

---

### Option 6: Checkpoint-as-Codex-Only

```
Conductor Claude
├── After worker done: calls codex/review MCP tool
├── Codex: fast, cheap, returns structured JSON
├── Conductor: parses, decides if more checks needed
└── Only spawns: heavy checkpoints (visual QA) when codex says to
```

**Pros:**
- Codex is fast and cheap (~10x cheaper than Claude)
- Single MCP call, no spawn overhead
- Conductor stays lean - just MCP calls
- Codex can recommend which heavy checks are needed

**Cons:**
- Codex less capable than Claude for nuanced review
- Still need solution for visual QA (requires browser)
- Limited to what Codex MCP can do

**Token cost:** Low for codex, only pay Claude cost when needed

---

### Option 7: Skill with Stop Hook (Gate Pattern)

```
Worker uses: /worker-done skill
    ↓
Worker says: "Task complete"
    ↓
Stop hook fires: runs checkpoint-pipeline.sh
    ↓
Script: calls codex/review, checks results
    ↓
Pass: exit 0 (allow stop) → worker exits, issue closes
Fail: {"decision": "block", "reason": "Fix these: ..."} → worker continues
```

**The skill:**

```yaml
---
name: worker-done
description: "Complete a beads task. Always use this when finishing work."
hooks:
  Stop:
    - hooks:
        - type: command
          command: "./scripts/checkpoint-pipeline.sh"
---

# Worker Done

Use this skill when you've completed your assigned task.

The stop hook will:
1. Run codex review on your changes
2. If issues found → you'll be asked to fix them
3. If passed → issue closes, you can stop
```

**The checkpoint script:**

```bash
#!/bin/bash
# checkpoint-pipeline.sh

INPUT=$(cat)  # Hook passes JSON to stdin
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

# CRITICAL: Prevent infinite loops
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0  # Already ran once, allow stop
fi

# Run codex review
RESULT=$(mcp-cli call codex/review '{"uncommitted": true}' 2>/dev/null)
PASSED=$(echo "$RESULT" | jq -r '.passed // true')

if [ "$PASSED" = "true" ]; then
  # Optional: run visual QA if UI changes detected
  if git diff --name-only | grep -qE '\.(tsx|jsx|css)$'; then
    # Could spawn visual-qa here or skip for speed
    :
  fi
  exit 0  # Allow stop
else
  ISSUES=$(echo "$RESULT" | jq -c '.issues // []')
  cat <<EOF
{"decision": "block", "reason": "Codex review found issues. Please fix:\n$ISSUES\n\nAfter fixing, try completing again."}
EOF
  exit 0
fi
```

**Pros:**
- Workers don't need to know about checkpoints - just use the skill
- Hook runs automatically on stop attempt
- Clean gate pattern: pass → exit, fail → continue working
- No plugin caching issues - hook script runs fresh
- Conductor doesn't need checkpoint knowledge - it's in the worker skill
- Low token overhead - just the skill instructions + script

**Cons:**
- Workers must remember to use `/worker-done` (enforce via PRIME.md)
- Complex checkpoints (visual QA) still need terminal spawn or subagent
- Script needs access to MCP CLI
- `stop_hook_active` check is critical to prevent infinite loops

**Token cost:** Very low - skill is minimal, script runs outside Claude context

**Key insight:** The Stop hook is a **gate**. The worker can't actually stop until the gate opens. This inverts the control - instead of conductor pulling status, the worker pushes through a checkpoint.

**Handling visual QA:**

For heavier checkpoints that need browser access, the script could:

```bash
# Option A: Spawn subagent via claude CLI
if [ "$NEEDS_VISUAL" = "true" ]; then
  VISUAL_RESULT=$(claude --agent visual-qa --print -p "Check localhost:3000")
  if [ "$(echo "$VISUAL_RESULT" | jq -r '.passed')" != "true" ]; then
    echo '{"decision": "block", "reason": "Visual QA failed: '"$VISUAL_RESULT"'"}'
    exit 0
  fi
fi

# Option B: Just flag it for conductor to handle post-merge
if [ "$NEEDS_VISUAL" = "true" ]; then
  bd update "$ISSUE_ID" --labels "+needs-visual-qa"
fi
```

---

## Hybrid Approach (Recommended)

Combine Option 6 (Codex gatekeeper) with Option 5 (TabzChrome for heavy checkpoints):

```
Worker closes issue
    ↓
Conductor: mcp-cli call codex/review '{...}'  (cheap, fast)
    ↓
Codex returns: {passed: true/false, needs_visual: bool, needs_tests: bool, issues: [...]}
    ↓
If needs_visual: spawn terminal "claude --agent visual-qa ..."
If needs_tests: spawn terminal "claude --agent test-runner ..."
    ↓
Conductor: waits for terminals, parses results
    ↓
All pass: merge
Any fail: reopen issue with findings
```

**Why this works:**
- Codex handles 80% of reviews (cheap)
- Heavy checkpoints only when needed
- Conductor stays lean (just MCP calls + terminal spawning)
- Each heavy checkpoint gets fresh context

---

## Decision Factors

| Factor | Monolithic | Subagents | Bash+Workers | Handoffs | TabzChrome | Codex+TabzChrome | Stop Hook |
|--------|-----------|-----------|--------------|----------|------------|------------------|-----------|
| Context efficiency | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Reliability | ❌ | ⚠️ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Simplicity | ⚠️ | ⚠️ | ✅ | ✅ | ⚠️ | ⚠️ | ✅ |
| Token cost | ⚠️ | ⚠️ | ❌ | ❌ | ⚠️ | ✅ | ✅ |
| Debugging | ❌ | ❌ | ✅ | ✅ | ⚠️ | ⚠️ | ✅ |
| Nuanced decisions | ✅ | ⚠️ | ❌ | ❌ | ⚠️ | ⚠️ | ⚠️ |
| No conductor needed | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |

---

## Implementation Checklist

### For any approach, you need:

**Checkpoint Agents** (as .md files):
- [ ] `codex-reviewer.md` - Calls codex/review, returns structured result
- [ ] `visual-qa.md` - Uses tabz MCP to check browser, returns pass/fail
- [ ] `test-runner.md` - Runs project tests, returns pass/fail

**Conductor Knowledge** (minimal):
- [ ] When to run each checkpoint (labels? file types? codex recommendation?)
- [ ] How to parse checkpoint results
- [ ] What to do on pass vs fail

**State Passing**:
- [ ] How checkpoints know what to check (worktree path, issue ID, diff)
- [ ] How results flow back to conductor (stdout, files, beads notes)

**Lifecycle Management**:
- [ ] How to detect checkpoint completion
- [ ] How to handle checkpoint failures/timeouts
- [ ] How to retry or escalate

---

## Questions to Answer

1. **How often do checkpoints fail?** If rarely, optimize for happy path (Codex only). If often, need robust retry/escalate.

2. **How important is review quality?** Codex is good but not great. Claude is better but expensive.

3. **How many checkpoints per issue?** If usually 1-2, sequential is fine. If 5+, need parallelization.

4. **How much does startup cost matter?** If running 50 workers/day, startup costs add up. If 5 workers/day, doesn't matter.

5. **What's the debugging story?** When something goes wrong, how do you figure out what happened?

---

## Next Steps

1. **Prototype Codex-as-gatekeeper**: Just the MCP call, see if it catches real issues
2. **Create minimal checkpoint agents**: .md files that work with `--agent` flag
3. **Test TabzChrome spawning**: Verify terminal lifecycle works reliably
4. **Measure token costs**: Actual numbers for startup vs accumulated context
5. **Build incrementally**: Start with one checkpoint, add more as needed

---

## Summary: Which Option When?

| If you need... | Use |
|----------------|-----|
| Simplest possible setup | **Option 7 (Stop Hook)** - workers self-gate |
| Lowest token cost | **Option 7** or **Option 6 (Codex only)** |
| Most reliable | **Option 3 (Bash+Workers)** or **Option 7** |
| Nuanced multi-step decisions | **Option 1 (Monolithic)** or **Option 5 (TabzChrome)** |
| Heavy checkpoints (visual QA) | **Option 5** or **Hybrid** |
| No conductor at all | **Option 7** - checkpoints built into worker lifecycle |

### My Take (After 2 Weeks of Trying)

**Option 7 (Stop Hook)** is probably the sweet spot because:
- It inverts the control model - workers push through a gate instead of conductor pulling status
- Minimal context overhead - just the skill markdown + bash script
- No plugin caching issues - script runs fresh every time
- Codex review is cheap and catches most issues
- Heavy checkpoints can be deferred to post-merge or flagged for conductor

**The main risk** is workers forgetting to use the skill, but that's solvable with PRIME.md instructions.

**If Stop Hook doesn't work**, fall back to **Option 5 (TabzChrome)** where conductor stays lean and spawns checkpoint terminals as needed.

---

## Appendix A: Proven Patterns from claude-code-plugins-plus-skills

This section documents battle-tested patterns from a large, sophisticated plugin system (260+ plugins) that solves many of the same orchestration challenges.

### Pattern 1: Dual Output (Essential)

Every phase/checkpoint produces TWO outputs:

```json
{
  "status": "complete|failed",
  "report_path": "/absolute/path/to/report.md",  // Human-readable
  "phase_data": {                                 // Machine-readable
    "key_metric_1": value,
    "findings": ["...", "..."],
    "confidence": "high|medium|low"
  }
}
```

**Why this works:**
- Markdown reports are audit trails for humans
- JSON enables automation and validation
- Next phase receives structured data, not prose to parse
- Separation of concerns (narrative vs data)

### Pattern 2: Pass Summaries, Not Content

```
WRONG ❌: Include full Phase 1 report (4000 tokens)
RIGHT ✅: Include phase_data summary + path to full report (200 tokens)

Phase 2 receives:
{
  "phase1_summary": {
    "total_files": 42,
    "issues_found": 15,
    "categories": ["unused_fields", "deprecated_apis"]
  },
  "phase1_report_path": "/path/to/01-analysis.md"
}
```

Phase 2 can read full report from disk if needed, but doesn't load it into context by default.

### Pattern 3: Validation Gates Between Phases

After each phase, the orchestrator validates:

```python
def validate_phase_output(phase_num, output):
    # 1. Is it valid JSON?
    try:
        data = json.loads(output)
    except:
        raise ValidationError(f"Phase {phase_num} returned invalid JSON")

    # 2. Required keys present?
    for key in ["status", "report_path", "phase_data"]:
        if key not in data:
            raise ValidationError(f"Phase {phase_num} missing key: {key}")

    # 3. Status is success?
    if data["status"] != "complete":
        raise ValidationError(f"Phase {phase_num} failed: {data.get('error')}")

    # 4. Report file exists?
    if not os.path.exists(data["report_path"]):
        raise ValidationError(f"Phase {phase_num} report not found")
```

**Gate behavior:**
- If ANY validation fails, pipeline STOPS immediately
- No silent failures or graceful degradation
- Enables recovery: "Failed at Phase 4? Restart from Phase 4, not Phase 1"

### Pattern 4: Verification Phase (Ground Truth)

Before final recommendations, inject a **deterministic verification phase**:

```
Phase 1: LLM Analysis     → Phase 2: LLM Interpretation
                                    ↓
Phase 3: Script Verify    → Phase 4: Reconciliation
                                    ↓
                          Verified conclusions
```

**Reconciliation report:**
```markdown
## Confirmed (Script Verified)
- Fields where script matches LLM conclusion

## Revised (LLM Was Close But Inaccurate)
- Fields where actual data differs slightly from LLM estimate

## False Positives (LLM Hallucinated)
- Claims LLM made that script disproves

## Unexpected (Script Found Issues LLM Missed)
- Findings only the deterministic tool caught
```

This forces LLM to be precise knowing it will be checked.

### Pattern 5: Session Isolation

Each workflow run creates an isolated session:

```
reports/
├── project-name/
│   └── 2025-01-15_143022/         # Timestamp-based session
│       ├── 01-analysis.md
│       ├── 02-deep-dive.md
│       ├── 03-verification.md
│       └── 04-recommendations.md
```

**Benefits:**
- Multiple workflows can run in parallel without interference
- Each session is self-contained and auditable
- Historical comparison possible
- Cleanup is simple (delete old session dirs)

### Pattern 6: Beads as Source of Truth

After context compaction, beads (git-backed issues) is the ONLY reliable state:

```bash
# MANDATORY first action after context loss
bd ready

# Beads returns:
# - In-progress tasks (what was being worked on)
# - Blocked tasks (what's waiting)
# - Ready tasks (what can start)
# - Completed tasks (what's done)
```

**Critical rule:** Work is NOT complete until `git push` succeeds.

```bash
# End-of-session protocol
bd close <id> --reason "Completed X"
bd sync
git push
git status  # MUST show "up to date with origin"
```

### Pattern 7: Explicit Handoff Contracts

Each orchestrator/agent specifies:

```markdown
## Dispatches to:
- `codex-reviewer` - For code review
- `visual-qa` - For UI verification

## Called by:
- `conductor` - Main orchestrator
- `worker-done` - Completion flow

## Data Flow:
- Receives: { issue_id, worktree_path, diff_summary }
- Produces: { passed: bool, issues: [], report_path: string }
```

No implicit assumptions - everything is documented.

### Pattern 8: Context Budget Allocation

**Monolithic (bad):** 60k tokens, attention diluted
```
System prompt: 2k
Code files: 30k
Schema: 5k
Analysis: 3k
Intermediate reasoning: 10k
Previous notes: 8k
Final output: 2k
= Attention spread thin across everything
```

**Orchestrated (good):** Peak attention each phase
```
Phase 1: 8k tokens (fresh context, focused task)
Phase 2: 10k tokens (fresh + Phase 1 summary)
Phase 3: 6k tokens (fresh + Phase 2 summary)
Phase 4: 12k tokens (fresh + verification results)
= Each phase operates at peak attention
```

### Pattern 9: No `context: fork`

The plugin system does NOT use Claude Code's context forking for orchestration.

Instead:
- **File-based handoffs** with strict JSON contracts
- **Explicit orchestration** (SKILL.md calls phase agents sequentially)
- **Validation after each phase**

This is more predictable and debuggable than implicit forking.

### Pattern 10: Checkpointing for Recovery

```json
{
  "checkpoint": "phase_3_complete",
  "completed_phases": [1, 2, 3],
  "phase_outputs": {
    "phase_1": { "report_path": "...", "summary": {...} },
    "phase_2": { "report_path": "...", "summary": {...} },
    "phase_3": { "report_path": "...", "summary": {...} }
  },
  "timestamp": "2025-01-15T14:30:22Z"
}
```

On failure at Phase 5:
- Don't restart from Phase 1
- Load checkpoint, resume from Phase 4
- Saves time and tokens

---

### Applying These Patterns to Conductor

| Pattern | Application |
|---------|-------------|
| Dual Output | Checkpoints return JSON + write markdown report |
| Pass Summaries | Conductor passes `{ issue_id, diff_stats }` not full diff |
| Validation Gates | Stop hook validates checkpoint JSON before allowing stop |
| Verification | Codex reviews claim "no bugs" → script runs tests to verify |
| Session Isolation | Each wave gets `waves/2025-01-15_143022/` directory |
| Beads as Truth | After context loss, `bd ready` recovers state |
| Explicit Contracts | Each checkpoint documents inputs/outputs |
| Context Budget | Workers stay lean, checkpoints get fresh context |
| No context: fork | Use `--agent` CLI or TabzChrome spawns instead |
| Checkpointing | Save wave state after each successful checkpoint |

---

## Appendix B: Multi-Model Routing

Different models excel at different tasks. A smart conductor routes checkpoints to the best model:

| Model | Strength | Cost | Use for |
|-------|----------|------|---------|
| **gpt5-mini** (Copilot) | Fast, decent quality | FREE (unlimited) | Quick lint, syntax, obvious issues |
| **Claude** | Code implementation | $$$ | Workers, code changes, merging |
| **Gemini 2.5 Pro** | Vision, 2M context | $$ | Visual QA, screenshots, conductor memory |
| **Codex/o1** | Deep reasoning, bugs | $$$$ (slow) | Complex debugging, architectural review |

### Tiered Checkpoint Pipeline

```
Worker completes
    ↓
Tier 1 - gpt5-mini (FREE): Quick scan
├── Syntax errors? → Block, worker fixes
├── Obvious bugs? → Block, worker fixes
└── Looks OK? → Continue to Tier 2
    ↓
Tier 2 - Codex (paid): Deep review
├── Logic errors? → Block, worker fixes
├── Security issues? → Block, worker fixes
└── Clean? → Continue to Tier 3 (if UI changes)
    ↓
Tier 3 - Gemini (paid): Visual QA
├── Screenshot diff
├── Layout broken? → Block
└── Looks good? → Allow merge
    ↓
Claude: Merge and cleanup
```

### Cost Optimization

- **90% of commits** caught by free gpt5-mini tier
- **9% of commits** need Codex deep review
- **1% of commits** need visual QA (only UI changes)

This keeps costs low while maintaining quality gates.

### GitHub Copilot CLI

```bash
# Use unlimited gpt5-mini for quick review
gh copilot suggest "review this diff for bugs: $(git diff)"

# Or via API if they expose it
gh copilot explain "$(git diff --cached)"
```

### Gemini for Vision

```bash
# Screenshot current page
mcp-cli call tabz/tabz_screenshot '{}'

# Send to Gemini for visual analysis
# (via API or gemini CLI when available)
```

### Model Routing Decision Tree

```
Is this a quick syntax/lint check?
  → gpt5-mini (free)

Is this a deep logic/security review?
  → Codex (best reasoning)

Does this involve UI/screenshots?
  → Gemini (best vision)

Does this need code written/changed?
  → Claude (best implementation)

Need to remember full wave context?
  → Gemini (2M context)
```

---

## Appendix B: Key Code References

### TabzChrome spawn API
```bash
curl -X POST http://localhost:8129/api/spawn \
  -H "X-Auth-Token: $(cat /tmp/tabz-auth-token)" \
  -d '{"name": "checkpoint", "command": "claude --agent codex-reviewer"}'
```

### Codex review MCP call
```bash
mcp-cli call codex/review '{"uncommitted": true, "prompt": "Check for bugs and security issues"}'
```

### Stop hook block response
```json
{"decision": "block", "reason": "Fix these issues before completing: ..."}
```

### Beads issue operations
```bash
bd show ISSUE-ID --json
bd update ISSUE-ID --labels "+needs-visual-qa"
bd close ISSUE-ID --reason "Completed, passed all checks"
bd reopen ISSUE-ID --reason "Codex found issues: ..."
```
