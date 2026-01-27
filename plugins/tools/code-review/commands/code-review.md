---
description: Review code changes with parallel detection and smart fixing
---

Review code changes using 5 parallel Haiku detection agents, with Opus fixes only when issues are found.

## Usage

```bash
/code-review                    # Review uncommitted changes
/code-review <issue-id>         # Review changes for specific beads issue
/code-review --quick            # Fast mode: lint + type check only
```

## Architecture

```
Detection (5 Haiku in parallel) → Aggregate → Fix if needed (1 Opus)
```

- **Clean code:** 5 cheap Haiku calls, done
- **Issues found:** 5 Haiku + 1 Opus to fix

## Process

### 1. Determine Scope

**With issue-id:**
```bash
bd show <issue-id>              # Get issue context
git log --oneline <issue-id>    # Find commits
git diff <base>..<head>         # Get diff
```

**Without issue-id:**
```bash
git diff HEAD                   # Uncommitted changes
git status --short              # Changed files
```

### 2. Quick Mode (`--quick`)

For trivial changes (docs, config), run fast checks only:

```bash
npx tsc --noEmit 2>&1 | grep -i error || true
npm run lint 2>&1 | grep -i error || true
grep -rn "api.key\|secret\|password" --include="*.ts" $(git diff --name-only HEAD)
```

If all pass: `✅ Quick checks passed` and STOP.

### 3. Launch 5 Detection Agents (PARALLEL)

**CRITICAL:** Launch ALL 5 in a SINGLE message for parallel execution.

```
Task(subagent_type="code-review:claude-md-scan", model="haiku", prompt="...")
Task(subagent_type="code-review:bug-scan", model="haiku", prompt="...")
Task(subagent_type="code-review:security-scan", model="haiku", prompt="...")
Task(subagent_type="code-review:silent-failure-scan", model="haiku", prompt="...")
Task(subagent_type="code-review:git-context-scan", model="haiku", prompt="...")
```

Each agent returns JSON with `flagged` and `blockers` arrays.

### 4. Aggregate & Filter

1. Merge all findings from 5 agents
2. Deduplicate (same file:line = keep highest confidence)
3. Filter out <80% confidence
4. Sort by confidence descending

### 5. Decision Point

**No issues ≥80%:**
```
✅ Code Review PASSED
- Scanned by 5 agents
- No issues found
```
STOP - no Opus needed.

**Issues found:**
Continue to fixer.

### 6. Launch Fixer (Opus)

Only if issues exist:

```
Task(subagent_type="code-review:fixer", model="opus",
     prompt="Fix these issues: <aggregated JSON>")
```

Fixer will:
- Auto-fix ≥90% confidence issues
- Add TODO comments for 80-89%
- Skip issues needing design decisions
- Verify fixes compile

### 7. Report

**Blockers remain:**
```
❌ Code Review FAILED

BLOCKERS:
- [SECURITY] Exposed API key in src/config.ts:12
```

**All fixed:**
```
✅ Code Review PASSED

Auto-fixed (2):
- Empty catch in src/api.ts:67
- Missing await in src/utils.ts:23
```

**Warnings only:**
```
⚠️ Code Review PASSED with warnings

Manual review needed (1):
- Broad catch in src/auth.ts:34 (85%)
```

## Detection Agents

| Agent | Focus | Model |
|-------|-------|-------|
| claude-md-scan | CLAUDE.md compliance | Haiku |
| bug-scan | Bug detection | Haiku |
| security-scan | Security vulnerabilities | Haiku |
| silent-failure-scan | Error handling | Haiku |
| git-context-scan | Git history context | Haiku |

## Fixer Agent

| Agent | Focus | Model |
|-------|-------|-------|
| fixer | Apply fixes for ≥90% confidence | Opus |

## Confidence Scoring

| Score | Action |
|-------|--------|
| 0-79 | Skip |
| 80-89 | Flag + TODO |
| 90-100 | Auto-fix |

## Notes

- Make a todo list before starting
- Use Task tool to spawn agents, not Bash
- Launch all 5 detection agents in ONE message (parallel)
- Opus only runs when issues found (cost optimization)
