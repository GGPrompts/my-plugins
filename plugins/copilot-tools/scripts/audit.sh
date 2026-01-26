#!/bin/bash
# Read-only codebase audit using gpt5-mini
# Creates beads issues for findings - no files modified

set -e

AUDIT_PATH="${1:-.}"
AUDIT_PATH=$(realpath "$AUDIT_PATH")

echo "Auditing: $AUDIT_PATH"
echo "Model: gpt-5-mini (unlimited)"
echo "Output: beads issues"
echo ""

# Run the audit
copilot --model gpt-5-mini -p "
You are a codebase auditor. Scan this codebase and identify issues.

CONSTRAINTS:
- Read-only: You can only read files, not modify them
- Output findings as beads issues using the beads MCP tool
- Be concise and actionable

CHECKLIST:
1. README.md - exists and current?
2. CHANGELOG.md - has recent entries?
3. .env.example - matches code patterns?
4. TODO/FIXME/HACK comments
5. Docs match code structure?
6. Outdated versions in configs?
7. Dead/commented code blocks?
8. Hardcoded secrets?

For each finding, create a beads issue:
- title: Clear problem description
- priority: 1 (blocking), 2 (should fix), 3 (nice to have)
- description: File path, line numbers, suggested fix

End with summary: issues by priority, top 3 to address.

Workspace: $AUDIT_PATH
" -s --allow-tool 'read' --allow-tool 'glob' --allow-tool 'grep' --allow-tool 'beads*' --deny-tool 'write' --deny-tool 'shell'

echo ""
echo "Audit complete. Run 'bd list' to see findings."
