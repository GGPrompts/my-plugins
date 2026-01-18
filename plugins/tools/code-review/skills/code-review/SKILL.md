---
name: code-review
description: "Review code changes with automated quality checks and confidence-based filtering"
user-invocable: true
---

Review code changes for beads issues with automated quality checks, confidence-based filtering, and parallel specialized agents.

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
2. **Security Scan** - `code-review:security-scan` (Haiku)
3. **Silent Failures** - `code-review:silent-failure-scan` (Haiku)

### 4. Process Results

Collect output from all agents and:

1. **Merge findings** - Deduplicate issues across agents
2. **Filter by confidence** - Only report issues ≥80% confidence
3. **Check for blockers** (security vulnerabilities, critical bugs, required tests missing)
4. **Auto-fixes applied** - List what was fixed automatically (≥95% confidence)

### 5. Report Results

#### If blockers found:
```
❌ Code Review FAILED

BLOCKERS (must fix):
- [SECURITY] Exposed API key in src/config.ts:12
- [CRITICAL] Null pointer access in src/api.ts:45

Fix these issues and run /code-review again.
```

#### If warnings only:
```
⚠️  Code Review PASSED with warnings

Auto-fixed (2):
- Removed unused import in src/utils.ts:5

Important issues (3):
- Missing error handling in src/api.ts:34

Review complete.
```

#### If clean:
```
✅ Code Review PASSED

- Reviewed 5 files
- CLAUDE.md compliance verified
- No security issues
- No blockers

Ready to proceed.
```

## Confidence Scoring

| Score | Meaning | Action |
|-------|---------|--------|
| 0-79 | False positive / uncertain | Skip |
| 80-94 | Verified issue | **Flag** |
| 95-100 | Certain bug or violation | **Auto-fix** |
