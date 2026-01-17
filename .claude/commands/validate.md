---
description: Run quick validation on all plugins before commits
allowed-tools:
  - Bash
  - Read
---

# Validate Plugins

Run quick validation checks on all plugins in the marketplace.

## What to Do

1. Run the validation script:
   ```bash
   /home/marci/plugins/my-plugins/scripts/validate-all.sh
   ```

2. Review the output and report results to the user

3. If errors are found:
   - List the specific errors
   - Suggest fixes for each error
   - Offer to fix them if appropriate

4. If only warnings are found:
   - List the warnings
   - Explain they are non-blocking but should be reviewed

## Validation Checks

The script validates:
- JSON syntax (plugin.json, marketplace.json)
- Plugin manifests (required fields)
- Frontmatter in commands and agents
- Skills structure (SKILL.md requirements)
- Directory structure compliance
- Script executability

## Expected Output

A summary showing:
- Total plugins, skills, commands, agents
- Number of errors and warnings
- PASS/FAIL status
