---
name: audit
description: Run full audit suite on plugin structure with detailed logs
allowed-tools:
  - Bash
  - Read
---

# Full Plugin Audit Suite

Run comprehensive audit of plugins with detailed logging.

## Usage

Run from a plugin project root (directory containing `.claude-plugin/` or `plugins/`):

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/audit-full.sh [target-directory]
```

If no target specified, audits the current working directory.

## What Gets Checked

| Audit | Checks |
|-------|--------|
| marketplace | marketplace.json validity, plugin source references |
| manifests | plugin.json required fields, JSON formatting |
| directories | .claude-plugin structure, component layout |
| skills | SKILL.md frontmatter, content quality, references |
| commands | command frontmatter, descriptions |
| agents | agent frontmatter, model/tools validation |

## Individual Audits

Run specific audits if needed:

```bash
# Marketplace validation
${CLAUDE_PLUGIN_ROOT}/scripts/audit-marketplace.sh [target]

# Plugin manifests
${CLAUDE_PLUGIN_ROOT}/scripts/audit-manifests.sh [target]

# Directory structure
${CLAUDE_PLUGIN_ROOT}/scripts/audit-directories.sh [target]

# Skills
${CLAUDE_PLUGIN_ROOT}/scripts/audit-skills.sh [target]

# Commands
${CLAUDE_PLUGIN_ROOT}/scripts/audit-commands.sh [target]

# Agents
${CLAUDE_PLUGIN_ROOT}/scripts/audit-agents.sh [target]
```

## Output

- Console summary with pass/fail per audit
- Log files in `scripts/audit-logs/` (if directory exists)
- Detailed findings for any failures

## After Running

1. Review the summary output
2. If any audits fail, check the detailed log or re-run individual audit
3. Report findings: overall status, key issues, fix recommendations
