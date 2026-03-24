---
name: code-review
description: "Review code changes with parallel detection agents and smart fixing"
user-invocable: true
---

Language-agnostic code review with dynamic agent planning. Adapts to any language, framework, and project size.

## Usage

```bash
/code-review                          # Review uncommitted changes
/code-review --full                   # Review entire codebase
/code-review --files src/api tests/   # Review specific paths
/code-review <issue-id>              # Review changes for a beads issue
/code-review --quick                  # Fast mode: lint/build check only
```

## How It Works

```
DISCOVER → SCOPE → PLAN → SCAN (parallel) → AGGREGATE → FIX (if needed) → REPORT
```

### 1. Discover
Auto-detects languages, frameworks, linters, and build tools by scanning the project.

### 2. Scope
Determines what to review based on invocation mode:
- **No args**: uncommitted changes (`git diff HEAD`)
- **`--full`**: entire codebase (prioritizes recently changed files for large projects)
- **`--files`**: specific paths
- **`<issue-id>`**: changes for a beads issue (MCP `show` or `bd show`)

### 3. Plan
Dynamically decides how many scanner agents (2-8) and what each focuses on, based on:
- Project language(s) and frameworks
- Scope size (lines changed / files to review)
- Available linters and build tools
- Whether CLAUDE.md exists

### 4. Scan
Launches all planned agents **in parallel**:
- **scanner** agents (Haiku) — each with a focused prompt crafted from the language pattern library
- **claude-md-scan** (Haiku) — CLAUDE.md compliance, if applicable

### 5. Aggregate
Merges findings from all agents, deduplicates, filters by confidence (>= 80%).

### 6. Fix (conditional)
Only if issues found: launches **fixer** (Opus) with the project's build/lint commands for verification.
- Auto-fixes >= 90% confidence
- Adds TODO comments for 80-89%
- Verifies fixes with project's native tools

### 7. Report
Clear pass/fail report with categorized findings.

## Agents

| Agent | Purpose | Model |
|-------|---------|-------|
| scanner | Generic scanner, invoked N times with different focus prompts | Haiku |
| claude-md-scan | CLAUDE.md compliance check | Haiku |
| fixer | Apply fixes for high-confidence issues | Opus |

## Supported Languages

Works with any language. Built-in pattern libraries for:
- **Go** — error handling, nil deref, goroutine leaks, SQL injection
- **Python** — bare except, mutable defaults, eval(), import cycles
- **TypeScript/JavaScript** — empty catch, floating promises, XSS, type coercion
- **Rust** — unwrap(), unsafe blocks, deadlocks

For unlisted languages, the orchestrator infers patterns from the project structure and CLAUDE.md.

## Cost Optimization

| Scenario | Agents Used | Cost |
|----------|-------------|------|
| Clean code (small diff) | 2-3 Haiku | $ |
| Clean code (large/full) | 5-8 Haiku | $$ |
| Issues found | N Haiku + 1 Opus | $$$ (only when needed) |
| Quick mode | 0 agents | Free |

## Confidence Scoring

| Score | Action |
|-------|--------|
| 0-79 | Skip |
| 80-89 | Flag + TODO comment |
| 90-100 | Auto-fix |

## Integration with Beads

Prefer MCP tools when available, fall back to CLI:

```
# Get issue context (MCP preferred)
mcp__beads__show(issue_id="<issue-id>")
# CLI fallback: bd show <issue-id> --json

/code-review <issue-id>

# If passed (MCP preferred)
mcp__beads__update(issue_id="<issue-id>", status="reviewed")
# CLI fallback: bd update <issue-id> --status=reviewed
```

## Notes

- All scanner agents run in parallel (single message, multiple Task calls)
- Opus fixer only runs when issues are found
- Scanner prompts are crafted dynamically — no hardcoded language assumptions
- Use `--quick` for trivial changes (docs, config)
- Use `--full` for comprehensive codebase review
