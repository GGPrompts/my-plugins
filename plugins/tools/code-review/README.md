# Code Review Plugin

Automated code review for beads issues with confidence-based scoring and parallel specialized agents.

## Structure

```
code-review/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   └── code-review.md        # Main command - orchestrates review
└── agents/
    ├── reviewer.md            # Main reviewer (Opus) - comprehensive
    ├── security-scan.md       # Security specialist (Haiku) - OWASP, secrets
    └── silent-failure-scan.md # Error handling auditor (Haiku) - silent failures
```

## Usage

### Basic Review

```bash
/code-review                    # Review uncommitted changes
/code-review <issue-id>         # Review changes for specific beads issue
```

### Thorough Review

```bash
/code-review --thorough         # Parallel specialists (3 agents)
```

## How It Works

The `/code-review` command orchestrates specialized review agents:

1. **Find scope** - Gets changed files (uncommitted or by issue-id)
2. **Read CLAUDE.md** - Loads project conventions from relevant directories
3. **Launch reviewers** - Spawns agents based on mode:
   - **Standard**: Main reviewer only (Opus)
   - **Thorough**: Main + Security + Silent Failures (1 Opus + 2 Haiku)
4. **Collect results** - Merges findings with confidence filtering (≥80%)
5. **Report** - Shows blockers, auto-fixes, and warnings

## Confidence-Based Filtering

All agents score issues 0-100:

| Score | Meaning | Action |
|-------|---------|--------|
| 0-79 | False positive / uncertain | Skip |
| 80-94 | Verified issue | **Flag** for review |
| 95-100 | Certain bug/violation | **Auto-fix** |

## Review Categories

### Main Reviewer (`code-review:reviewer`)
- CLAUDE.md compliance
- Bug detection (null access, logic errors, race conditions)
- Code quality (duplication, complexity)
- Test coverage assessment
- Auto-fixes high-confidence issues

### Security Scanner (`code-review:security-scan`)
- Exposed secrets (API keys, passwords) - **BLOCKER**
- SQL/Command/XSS injection - **BLOCKER**
- Authentication/authorization issues
- Data exposure in logs/responses

### Silent Failure Hunter (`code-review:silent-failure-scan`)
- Empty catch blocks - **BLOCKER**
- Errors not logged
- Users not notified of failures
- Poor logging quality
- Silent fallbacks
- Mock data in production - **BLOCKER**

## Output

Structured JSON with:
- `passed`: true/false (blockers present?)
- `auto_fixed`: Issues fixed automatically (≥95% confidence)
- `flagged`: Issues to review (80-94% confidence)
- `blockers`: Critical issues that must be fixed
- `needs_tests`: Test coverage assessment
- `test_assessment`: Recommended tests with priority

## Integration with Beads

```bash
# After worker completes issue
bd view <issue-id>              
/code-review <issue-id>         

# If passed
bd update <issue-id> --status reviewed

# If blockers
bd create "Fix review blockers for #<issue-id>" --depends-on <issue-id>
```

## Comparison to Anthropic's Plugin

| Feature | Anthropic | This Plugin |
|---------|-----------|-------------|
| **Purpose** | GitHub PR review | Beads issue review |
| **Integration** | `gh` CLI for PRs | `bd` CLI for issues |
| **Agents** | 5 Sonnet + Haiku | 1 Opus + 2 Haiku |
| **Auto-fix** | No | Yes (≥95% confidence) |
| **Test assessment** | No | Yes (always) |
| **Confidence scoring** | 0-100 | 0-100 (same system) |
| **Output** | GitHub comment | JSON + terminal |

## Version History

### v2.0.0 (Current)
- Restructured to single command pattern (like Anthropic's)
- Added security-scan and silent-failure-scan specialist agents
- Removed fragmented skills (review, security, silent-failures, code-review)
- Added test coverage assessment
- Added auto-fix capability (≥95% confidence)
- Optimized for beads workflow integration

### v1.0.0 (Legacy)
- Multiple separate skills
- No orchestration
- Manual workflow
