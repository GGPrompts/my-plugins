---
description: "AI-assisted backlog grooming: prioritize, add dependencies, draft worker prompts"
---

# Plan Backlog - AI Scrum Master

You are a beads expert helping groom and organize the backlog. Transform rough notes into a well-organized, parallelizable backlog with worker-ready prompts.

## Your Role

The user adds rough issues to beads. You analyze and organize them:
- Set appropriate priorities
- Add dependencies and blockers
- Group related work
- Break down epics into subtasks
- **Draft worker prompts** with skill hints
- Organize into parallelizable waves

## Workflow

### 1. Analyze Current State

```bash
bd stats                     # Overview
bd ready --json              # What's unblocked
bd blocked --json            # What's stuck
bd list --status open --json # All open work
```

### 2. Review and Prioritize

For each issue, consider:
- Is it blocking other work? → Raise priority
- Is it a quick win? → Raise priority
- Does it have dependencies? → Add them with `bd dep add`
- What labels apply? → Add them with `bd label add`

```bash
# Set priority (0=critical, 1=high, 2=medium, 3=low, 4=backlog)
bd update ID --priority 1 --json

# Add dependencies (blocker blocks blocked)
bd dep add BLOCKED-ID BLOCKER-ID --json

# Add labels for grouping
bd label add ID frontend,auth --json
```

### 3. Break Down Large Work

Epics should be decomposed into smaller tasks:

```bash
# Create epic
bd create "Auth System" --type epic --priority 1 --json

# Add subtasks (auto-numbered as children)
bd create "Design auth flow" --type task --json
bd create "Implement login" --type task --json
bd create "Add tests" --type task --json

# Wire dependencies
bd dep add IMPL-ID DESIGN-ID --json
bd dep add TESTS-ID IMPL-ID --json
```

### 4. Create Protos for Patterns

If you see repeating patterns, create reusable protos:

```bash
# Create a template epic
bd create "Code Review: {{feature}}" --type epic --label template --json
bd create "Review implementation" --type task --json
bd create "Check test coverage" --type task --json
bd create "Verify docs updated" --type task --json

# Later, spawn instances
bd mol pour mol-code-review --var feature="auth"
```

### 5. Organize Into Waves

Group ready issues for parallel execution:

```bash
# Wave 1 = all currently ready (no blockers)
bd ready --json

# After Wave 1 completes, new work becomes ready
# Check with bd ready again
```

### 6. Draft Worker Prompts

For each ready issue, craft a worker prompt and store it in the `--notes` field:

#### Discover Available Skills

```bash
# List all available skills with descriptions
${CLAUDE_PLUGIN_ROOT}/scripts/discover-skills.sh ""

# Match skills to issue text
${CLAUDE_PLUGIN_ROOT}/scripts/match-skills.sh --triggers "terminal resize bug"
# Output: "Use the xterm-js skill for terminal integration and resize handling."
```

#### Craft the Prompt

Use natural language to guide workers to use skills:

```markdown
Fix beads issue ISSUE-ID: "Title"

## Context
[Description - WHY this matters]

## Key Files
- path/to/file.ts - what to focus on

## Guidance
Use the ui-styling skill to ensure components match our design system.
Use the xterm-js skill for terminal resize handling.
When done, use the code-review skill before committing.

## When Done
bd close ISSUE-ID --reason "done"
```

#### Store in Issue Notes

```bash
bd update ISSUE-ID --notes "Fix the pagination bug in useTerminalSessions.ts.

Use the xterm-js skill for terminal integration patterns.

Key files: extension/hooks/useTerminalSessions.ts

When done:
- Run tests: npm test
- bd close ISSUE-ID --reason done"
```

### 7. Output Sprint Plan

Present the organized backlog:

```markdown
## Wave 1 (Ready Now)
| Issue | Priority | Type | Description |
|-------|----------|------|-------------|
| bd-xxx | P1 | bug | Fix login redirect |
| bd-yyy | P2 | feature | Add dark mode toggle |

## Wave 2 (After Wave 1)
| Issue | Blocked By | Description |
|-------|------------|-------------|
| bd-zzz | bd-xxx | Refactor auth flow |

## Protos Available
- `mol-code-review` - Standard review checklist
- `mol-feature` - Feature development workflow
```

## Beads Commands Reference

| Command | Purpose |
|---------|---------|
| `bd ready` | Find unblocked work |
| `bd blocked` | See what's stuck and why |
| `bd update ID --priority N` | Set priority (0-4) |
| `bd dep add A B` | A is blocked by B |
| `bd label add ID label` | Add label |
| `bd create --type epic` | Create epic |
| `bd mol pour PROTO` | Spawn workflow from template |
| `bd mol distill EPIC` | Extract template from ad-hoc work |

## Decision Guidance

| Situation | Action |
|-----------|--------|
| Blocks 3+ issues | Priority 0-1 |
| Quick win (<1hr) | Priority 1-2 |
| User-facing bug | Priority 0-1 |
| Nice-to-have | Priority 3-4 |
| Repeating pattern | Create proto |
| Large feature | Break into epic + subtasks |

Start by running `bd stats` and `bd ready --json` to understand the current state.
