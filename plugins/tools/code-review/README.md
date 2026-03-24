# Code Review Plugin

Language-agnostic code review with dynamic agent planning. Adapts to any language, framework, and codebase size.

## Structure

```
code-review/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   └── code-review.md        # Orchestrator — dynamic 7-phase review
├── agents/
│   ├── scanner.md             # Generic scanner (Haiku) — invoked N times
│   ├── claude-md-scan.md      # CLAUDE.md compliance (Haiku)
│   └── fixer.md               # Precision fixer (Opus)
└── skills/
    └── code-review/
        └── SKILL.md           # User-facing skill entry point
```

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

1. **Discover** — auto-detects languages, frameworks, linters, build tools
2. **Scope** — determines what to review (diff, full codebase, specific paths, issue)
3. **Plan** — dynamically decides scanner count (2-8) and focus areas based on project context
4. **Scan** — launches all scanners in parallel with language-specific prompts
5. **Aggregate** — merges, deduplicates, filters findings (>= 80% confidence)
6. **Fix** — Opus fixer runs only if issues found, uses project's native build/lint tools
7. **Report** — clear pass/fail with categorized findings

## Key Design: Dynamic Agents

Instead of hardcoded language-specific agents, the plugin uses one generic **scanner** agent invoked multiple times with different prompts. The orchestrator crafts each prompt based on what it discovered about the project:

| Scope Size | Scanners |
|------------|----------|
| Small (<100 lines) | 2-3 |
| Medium (100-500 lines) | 3-5 |
| Large / full codebase | 5-8 |

## Supported Languages

Built-in pattern libraries for Go, Python, TypeScript/JavaScript, and Rust. For other languages, the orchestrator infers patterns from the project structure.

## Cost Optimization

| Scenario | Cost |
|----------|------|
| Clean code (small) | $ (2-3 Haiku) |
| Clean code (large) | $$ (5-8 Haiku) |
| Issues found | $$$ (N Haiku + 1 Opus) |
| Quick mode | Free (just lint/build) |

## Integration with Beads

Prefers MCP tools when available, falls back to `bd` CLI:

```
# MCP preferred
mcp__beads__show(issue_id="<issue-id>")
/code-review <issue-id>
mcp__beads__update(issue_id="<issue-id>", status="reviewed")

# CLI fallback
bd show <issue-id> --json
bd update <issue-id> --status=reviewed
```

## Version History

### v3.0.0 (Current)
- Language-agnostic — works for Go, Python, TypeScript, Rust, and more
- Dynamic agent planning — adapts scanner count and focus to project
- Full codebase review mode (`--full`)
- Single generic scanner agent replaces 5 hardcoded JS/TS agents
- Language pattern library for crafting scanner prompts
- Fixer uses project's native build/lint tools for verification

### v2.0.0
- 5 parallel Haiku detection agents (JS/TS-specific)
- Opus fixer for auto-fixes
- Beads integration

### v1.0.0
- Multiple separate skills, no orchestration
