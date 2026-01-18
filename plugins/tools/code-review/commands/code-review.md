---
description: Review code changes for beads issues
---

Review code changes with automated quality checks and confidence-based filtering.

## Usage

```bash
/code-review                    # Review uncommitted changes
/code-review <issue-id>         # Review changes for specific beads issue
/code-review --thorough         # Deep review with parallel specialists
```

## Process

Follow these steps precisely:

### 1. Determine Scope

If `<issue-id>` provided:
- Get issue details: `bd view <issue-id>`
- Get commits for issue: `bd log <issue-id>` or check issue metadata for commit range
- Get diff: `git diff <base-sha>..<head-sha>`

If no issue-id:
- Review uncommitted changes: `git diff HEAD`
- Get list of changed files: `git status --short`

### 2. Find Relevant CLAUDE.md Files

```bash
# Get directories with changes
CHANGED_DIRS=$(git diff --name-only | xargs -I{} dirname {} | sort -u)

# Read root CLAUDE.md
cat CLAUDE.md 2>/dev/null

# Read CLAUDE.md in changed directories
for dir in $CHANGED_DIRS; do
  cat "$dir/CLAUDE.md" 2>/dev/null
done
```

### 3. Launch Review Agents

#### Standard Mode (default)

Spawn main reviewer agent:

```markdown
Task(
  subagent_type="code-review:reviewer",
  prompt="Review changes. Issue: <issue-id>. Changed files: <files>"
)
```

The reviewer will:
- Check CLAUDE.md compliance
- Scan for bugs (confidence ≥80)
- Auto-fix high-confidence issues (≥95)
- Assess test coverage needs
- Return structured JSON output

#### Thorough Mode (`--thorough`)

Launch 3 parallel specialized reviewers:

1. **Main Review** - `code-review:reviewer` (Opus)
   - CLAUDE.md compliance
   - Bug detection
   - Test coverage assessment

2. **Security Scan** - `code-review:security-scan` (Haiku)
   - OWASP Top 10 vulnerabilities
   - Exposed secrets (BLOCKER)
   - Injection vulnerabilities
   - Auth issues

3. **Silent Failures** - `code-review:silent-failure-scan` (Haiku)
   - Empty catch blocks
   - Swallowed errors
   - Missing error logging
   - Silent fallbacks

All agents return JSON. Merge results with confidence-based filtering.

### 4. Process Results

Collect output from all agents and:

1. **Merge findings** - Deduplicate issues across agents
2. **Filter by confidence** - Only report issues ≥80% confidence
3. **Check for blockers**:
   - Security vulnerabilities (exposed secrets, injection)
   - Critical bugs (data loss, crashes)
   - Required tests missing (`recommendation: "required"`)
4. **Auto-fixes applied** - List what was fixed automatically (≥95% confidence)

### 5. Report Results

#### If blockers found:

```
❌ Code Review FAILED

BLOCKERS (must fix before proceeding):
- [SECURITY] Exposed API key in src/config.ts:12
- [CRITICAL] Null pointer access in src/api.ts:45
- [TESTS] Missing tests for payment validation (required)

Fix these issues and run /code-review again.
```

#### If warnings only:

```
⚠️  Code Review PASSED with warnings

Auto-fixed (2):
- Removed unused import in src/utils.ts:5
- Fixed console.log in src/debug.ts:23

Important issues (3):
- Missing error handling in src/api.ts:34 (CLAUDE.md violation)
- Potential race condition in src/worker.ts:67
- Tests recommended for new API endpoint (medium priority)

Review complete. Address warnings when convenient.
```

#### If clean:

```
✅ Code Review PASSED

- Reviewed 5 files
- CLAUDE.md compliance verified
- No security issues
- No blockers

Tests: Not required (config changes only)

Ready to proceed.
```

### 6. Integration with Beads

For beads workflow integration:

```bash
# After worker completes issue
bd view <issue-id>              # Get issue details
/code-review <issue-id>         # Run review

# If passed, mark ready for merge
bd update <issue-id> --status reviewed

# If blockers, create follow-up issue
bd create "Fix code review blockers for #<issue-id>" --depends-on <issue-id>
```

## Output Format

All reviewer agents return JSON:

```json
{
  "passed": true,
  "mode": "thorough",
  "summary": "Reviewed 5 files. Auto-fixed 2 issues. No blockers.",
  "auto_fixed": [
    {
      "file": "src/utils.ts",
      "line": 45,
      "issue": "Unused import 'axios'",
      "confidence": 98,
      "fix": "Removed import"
    }
  ],
  "flagged": [
    {
      "severity": "important",
      "file": "src/auth/login.ts",
      "line": 23,
      "issue": "Missing error handling for API call",
      "confidence": 85,
      "rule": "CLAUDE.md: 'Always wrap API calls in try-catch'",
      "suggestion": "Add try-catch around fetch call"
    }
  ],
  "blockers": [],
  "needs_tests": true,
  "test_assessment": {
    "recommendation": "recommended",
    "rationale": "New API utility with validation logic",
    "suggested_tests": [
      {
        "type": "unit",
        "target": "validateApiResponse()",
        "cases": ["valid response", "error response", "null response"]
      }
    ],
    "priority": "medium"
  }
}
```

## Confidence Scoring

All agents use consistent confidence scoring:

| Score | Meaning | Action |
|-------|---------|--------|
| 0-25 | False positive / can't verify | Skip |
| 50-75 | Real but minor / uncertain | Skip |
| **80-94** | Verified issue | **Flag** |
| **95-100** | Certain bug or violation | **Auto-fix** |

## False Positives to Skip

Do NOT report:
- Pre-existing issues (not in the diff)
- Lines not modified in this change
- Linter/type errors (CI catches these)
- Intentional functionality changes
- Style preferences not in CLAUDE.md
- Hypothetical bugs without evidence
- Test-only code issues
- Silenced issues (with disable comments)

## Notes

- Make a todo list before starting review
- Use `Task` tool to spawn reviewer agents, not Bash
- Always cite sources (CLAUDE.md rules, file locations with line numbers)
- For beads issues, focus on the specific commits, not entire codebase
- Auto-fixes should be minimal and preserve formatting
- Test assessment is mandatory for all reviews
