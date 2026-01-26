---
description: "Read-only codebase audit using gpt5-mini. Scans for stale docs, outdated deps, missing configs, and creates beads issues. No files modified - safe to run unattended."
---

# Audit Command

Run a read-only audit of a codebase using GitHub Copilot's gpt5-mini (unlimited usage).

## Usage

```
/audit [path]
```

- `path` - Optional. Directory to audit. Defaults to current working directory.

## What It Does

1. Scans the codebase (read-only)
2. Identifies issues like:
   - Stale documentation (README, CHANGELOG not updated recently)
   - Missing or incomplete configs (.env.example, etc.)
   - Outdated dependencies
   - TODO/FIXME comments that need attention
   - Inconsistencies between docs and code
3. Creates beads issues for each finding (prioritized P1-P3)
4. Returns a summary report

## Safety

- **Read-only**: Only uses Read, Glob, Grep tools
- **Beads output**: Findings go to issue tracker, not files
- **No approvals needed**: Safe to run unattended
- **Unlimited**: gpt5-mini has no usage limits

## Running the Audit

When this command is invoked, execute the following:

### Step 1: Set up the audit context

```bash
# Get the audit path (use argument or cwd)
AUDIT_PATH="${1:-.}"

# Ensure beads context is set
mcp-cli call beads/context '{"workspace_root": "'"$AUDIT_PATH"'"}'
```

### Step 2: Run the audit via Copilot

```bash
copilot --model gpt-5-mini -p "
You are a codebase auditor. Your job is to scan this codebase and identify issues.

IMPORTANT CONSTRAINTS:
- You can ONLY read files (Read, Glob, Grep)
- You can ONLY create beads issues for findings
- You CANNOT modify any files
- You CANNOT run any shell commands that modify state

AUDIT CHECKLIST:
1. Check if README.md exists and is up to date
2. Check if CHANGELOG.md exists and has recent entries
3. Check for .env.example and compare with actual .env patterns in code
4. Look for TODO, FIXME, HACK comments
5. Check if documentation matches actual code structure
6. Look for obviously outdated version numbers in configs
7. Check for dead/commented code blocks
8. Identify any hardcoded secrets or credentials

For each finding, create a beads issue with:
- Clear title describing the problem
- Priority: P1 (blocking), P2 (should fix), P3 (nice to have)
- Description with file path and line numbers
- Suggested fix

At the end, output a summary:
- Total issues found by priority
- Top 3 most important things to address

Workspace to audit: $AUDIT_PATH
" -s --allow-tool 'read' --allow-tool 'glob' --allow-tool 'grep' --deny-tool 'write' --deny-tool 'shell'
```

### Step 3: Show results

```bash
# List the issues created
bd list --json | jq -r '.[] | "\(.priority) \(.id): \(.title)"' | sort
```

## Example Output

```
P1 V4V-xxx: Missing CAREERONESTOP_API_KEY in .env.example
P2 V4V-xxx: CHANGELOG.md not updated since Jan 15
P2 V4V-xxx: README references deprecated /api/v0 endpoint
P3 V4V-xxx: 12 TODO comments need triage
P3 V4V-xxx: Dead code block in utils/legacy.py

Summary: 1 P1, 2 P2, 2 P3 issues created
Top priority: Add missing API key to .env.example
```
