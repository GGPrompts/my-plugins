---
description: Quick validation on plugins before commits
allowed-tools:
  - Bash
  - Read
---

# Quick Plugin Validation

Run quick validation checks on plugins - ideal before commits.

## Usage

Run from a plugin project root:

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/validate-all.sh [target-directory]
```

If no target specified, validates the current working directory.

## What Gets Validated

- JSON syntax (plugin.json, marketplace.json)
- Plugin manifests (required fields: name, description)
- Frontmatter in commands and agents
- Skills structure (SKILL.md requirements)
- Directory structure compliance
- Script executability

## Expected Output

```
============================================
     PLUGIN VALIDATION SUITE
============================================

✓ JSON syntax valid
✓ 42 plugin manifests valid
✓ 24 commands valid
✓ 11 agents valid
✓ 37 skills valid

SUMMARY: 0 errors, 2 warnings
STATUS: PASS
```

## After Running

1. Review the output
2. If errors found:
   - List the specific errors
   - Suggest fixes for each
   - Offer to fix if appropriate
3. If only warnings:
   - Note they're non-blocking
   - Recommend reviewing them
