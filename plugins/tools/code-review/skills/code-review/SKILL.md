---
name: code-review
description: "Review code changes with parallel detection agents and smart fixing"
user-invocable: true
---

Review code changes using parallel Haiku detection agents, with Opus fixes when issues are found.

## Usage

```bash
/code-review                    # Review uncommitted changes
/code-review <issue-id>         # Review changes for specific beads issue
/code-review --quick            # Fast mode: lint + type check only
```

## Architecture

```
┌─────────────────────────────────────────────────────┐
│  DETECTION PHASE (5 parallel Haiku agents)          │
│                                                     │
│  1. claude-md-scan    - CLAUDE.md compliance        │
│  2. bug-scan          - Bug detection               │
│  3. security-scan     - Security vulnerabilities    │
│  4. silent-failure-scan - Error handling issues     │
│  5. git-context-scan  - Git history context         │
│                                                     │
│  → Aggregate findings, filter ≥80% confidence       │
└─────────────────────────────────────────────────────┘
                        │
                        ▼
              ┌─────────────────┐
              │ Issues found?   │
              └────────┬────────┘
                       │
           ┌───────────┴───────────┐
           │                       │
           ▼                       ▼
     ┌──────────┐           ┌──────────┐
     │   Yes    │           │    No    │
     └────┬─────┘           └────┬─────┘
          │                      │
          ▼                      ▼
  ┌───────────────┐        ┌──────────┐
  │ OPUS: fixer   │        │  Done!   │
  │ (apply fixes) │        │ (cheap)  │
  └───────────────┘        └──────────┘
```

## Process

### 1. Determine Scope

If `<issue-id>` provided:
```bash
bd show <issue-id>
git diff <base>..<head>
```

If no issue-id:
```bash
git diff HEAD
git status --short
```

### 2. Quick Mode Check (`--quick`)

For trivial changes, run fast checks only:

```bash
npx tsc --noEmit 2>&1 | grep -i error
npm run lint 2>&1 | grep -i error
grep -rn "api.key\|secret\|password" --include="*.ts" <changed-files>
```

If all pass, return immediately:
```json
{"passed": true, "mode": "quick", "summary": "Quick checks passed"}
```

### 3. Launch Detection Agents (Parallel)

Launch ALL 5 agents in parallel using Task tool:

```markdown
Task(subagent_type="code-review:claude-md-scan", model="haiku",
     prompt="Check CLAUDE.md compliance for: <files>")

Task(subagent_type="code-review:bug-scan", model="haiku",
     prompt="Scan for bugs in: <files>")

Task(subagent_type="code-review:security-scan", model="haiku",
     prompt="Security scan for: <files>")

Task(subagent_type="code-review:silent-failure-scan", model="haiku",
     prompt="Check error handling in: <files>")

Task(subagent_type="code-review:git-context-scan", model="haiku",
     prompt="Check git history context for: <files>")
```

**IMPORTANT:** Launch all 5 in a SINGLE message to run in parallel.

### 4. Aggregate Results

Collect JSON from all agents and merge:

1. **Combine findings** - Merge all `flagged` and `blockers` arrays
2. **Deduplicate** - Same file:line from multiple agents = keep highest confidence
3. **Filter** - Remove anything <80% confidence
4. **Sort** - By confidence descending

### 5. Decision Point

**If no issues ≥80% confidence:**
```
✅ Code Review PASSED

- Scanned by 5 agents
- No issues found
- Ready to proceed
```
STOP HERE - no Opus needed.

**If issues found ≥80% confidence:**
Continue to Step 6.

### 6. Launch Fixer Agent (Opus)

Only if issues were found:

```markdown
Task(subagent_type="code-review:fixer", model="opus",
     prompt="Fix these issues: <aggregated JSON>")
```

The fixer will:
- Auto-fix issues ≥90% confidence
- Add TODO comments for 80-89% confidence
- Skip issues requiring design decisions
- Verify fixes compile

### 7. Report Results

#### If blockers remain:
```
❌ Code Review FAILED

BLOCKERS (must fix):
- [SECURITY] Exposed API key in src/config.ts:12
- [CRITICAL] SQL injection in src/db/query.ts:45

Fix these issues and run /code-review again.
```

#### If all fixed:
```
✅ Code Review PASSED

Auto-fixed (3):
- Empty catch block in src/api/user.ts:67
- Missing await in src/utils/data.ts:23
- Unused import in src/components/Form.tsx:5

TODOs added (1):
- Possible race condition in src/state/store.ts:89

Ready to proceed.
```

#### If warnings only:
```
⚠️ Code Review PASSED with warnings

Skipped for manual review (2):
- Broad exception handling in src/api/auth.ts:34 (85% confidence)
- Possible logic error in src/utils/calc.ts:12 (82% confidence)

Review these when convenient.
```

## Cost Optimization

| Scenario | Agents Used | Cost |
|----------|-------------|------|
| Clean code | 5 Haiku | $ (cheap) |
| Issues found | 5 Haiku + 1 Opus | $$ (only when needed) |
| Quick mode | 0 agents | Free (just bash) |

## Confidence Scoring

All agents use consistent scoring:

| Score | Meaning | Action |
|-------|---------|--------|
| 0-79 | Uncertain / false positive | Skip |
| 80-89 | Verified issue | Flag + TODO comment |
| 90-94 | High confidence | Auto-fix if safe |
| 95-100 | Certain | Auto-fix |

## Integration with Beads

```bash
# After worker completes issue
bd show <issue-id>
/code-review <issue-id>

# If passed
bd update <issue-id> --status=reviewed

# If blockers
bd create --title="Fix review blockers for <issue-id>" --type=bug
```

## Notes

- Always launch detection agents in parallel (single message, 5 Task calls)
- Opus fixer only runs when issues are found (cost optimization)
- Use `--quick` for config/docs changes
- Detection agents return JSON - parse and aggregate
- Fixer agent makes minimal changes, preserves style
