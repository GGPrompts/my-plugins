---
description: Run full audit suite with detailed logs
allowed-tools:
  - Bash
  - Read
---

# Full Audit Suite

Run comprehensive audit of all plugins with detailed logging.

## What to Do

1. Run the full audit script:
   ```bash
   /home/marci/plugins/my-plugins/scripts/audit-full.sh
   ```

2. Review the summary output

3. If any audits fail, read the relevant log file:
   ```bash
   # Logs are in scripts/audit-logs/
   ls /home/marci/plugins/my-plugins/scripts/audit-logs/
   ```

4. Report findings to the user:
   - Overall pass/fail status for each audit
   - Key issues found
   - Recommendations for fixes

## Individual Audits

If user wants to run specific audits:

```bash
# Marketplace validation
/home/marci/plugins/my-plugins/scripts/audit-marketplace.sh

# Plugin manifests
/home/marci/plugins/my-plugins/scripts/audit-manifests.sh

# Directory structure
/home/marci/plugins/my-plugins/scripts/audit-directories.sh

# Skills
/home/marci/plugins/my-plugins/scripts/audit-skills.sh

# Commands
/home/marci/plugins/my-plugins/scripts/audit-commands.sh

# Agents
/home/marci/plugins/my-plugins/scripts/audit-agents.sh
```

## Audit Categories

| Audit | Checks |
|-------|--------|
| marketplace | marketplace.json validity, plugin references |
| manifests | plugin.json required fields, formatting |
| directories | .claude-plugin structure, component layout |
| skills | SKILL.md frontmatter, content quality |
| commands | command frontmatter, descriptions |
| agents | agent frontmatter, model/color validation |

## Log Files

Full audit creates logs in `scripts/audit-logs/`:
- `audit-report-TIMESTAMP.md` - Summary report
- `AUDIT-TIMESTAMP.log` - Individual audit logs
