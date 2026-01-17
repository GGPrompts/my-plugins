# Scripts Directory

Validation and audit scripts for the my-plugins marketplace.

## Quick Start

```bash
# Quick validation before commits
./scripts/validate-all.sh

# Full audit suite with detailed logs
./scripts/audit-full.sh

# Individual audits
./scripts/audit-manifests.sh
./scripts/audit-directories.sh
./scripts/audit-skills.sh
./scripts/audit-commands.sh
./scripts/audit-agents.sh
./scripts/audit-marketplace.sh
```

## Scripts Overview

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `validate-all.sh` | Quick validation | Before every commit |
| `audit-full.sh` | Complete audit suite | Weekly or before releases |
| `audit-manifests.sh` | Validate plugin.json files | After editing manifests |
| `audit-directories.sh` | Check directory structure | After adding plugins |
| `audit-skills.sh` | Validate SKILL.md files | After editing skills |
| `audit-commands.sh` | Validate commands/*.md | After editing commands |
| `audit-agents.sh` | Validate agents/*.md | After editing agents |
| `audit-marketplace.sh` | Validate marketplace.json | After adding plugins |

## Using with Claude

The `.claude/commands/` directory contains slash commands to run these scripts:

```
/validate    - Quick validation
/audit       - Full audit suite
```

## What Gets Validated

### Plugin Manifests (`audit-manifests.sh`)
- JSON syntax validity
- Required fields: `name`, `description`
- Name format (kebab-case)
- Version format (semver)
- Description length (10-400 chars)
- Unknown fields detection

### Directory Structure (`audit-directories.sh`)
- `.claude-plugin/plugin.json` location
- No plugin.json in wrong locations
- Component directories (commands/, agents/, skills/, hooks/)
- No nested skills structures
- Script executability

### Skills (`audit-skills.sh`)
- SKILL.md frontmatter presence
- Required fields: `name`, `description`
- Description quality (length, action verbs)
- Content length (< 5000 words)
- References directory usage
- Unlinked references detection

### Commands (`audit-commands.sh`)
- Frontmatter presence
- Required field: `description`
- Content quality checks
- Heading presence

### Agents (`audit-agents.sh`)
- Frontmatter presence
- Required field: `description`
- Name format validation
- Model field validation
- Color field validation
- Content quality checks

### Marketplace (`audit-marketplace.sh`)
- JSON syntax validity
- Required fields: `name`, `plugins`
- Plugin entry validation
- Source path existence
- Orphaned plugin detection
- Duplicate entry detection

## Output

### Exit Codes
- `0` - All checks passed
- `1` - Errors found (blocking)

### Log Files
Full audit creates logs in `scripts/audit-logs/`:
- `audit-report-TIMESTAMP.md` - Summary report
- `AUDIT-TIMESTAMP.log` - Individual audit logs

Old logs are automatically cleaned (keeps last 10).

## Best Practices

1. **Before commits**: Run `./scripts/validate-all.sh`
2. **Before releases**: Run `./scripts/audit-full.sh`
3. **After adding plugins**: Run `./scripts/audit-marketplace.sh`
4. **Fix errors before warnings**: Errors are blocking, warnings are advisory

## Dependencies

- `bash` 4.0+
- `jq` for JSON processing
- Standard Unix tools (`find`, `grep`, `awk`)

## Adding New Scripts

Follow the naming convention:
- `audit-*.sh` - Validation/audit scripts
- `validate-*.sh` - Quick validation scripts
- `fix-*.sh` - Auto-fix scripts

Make scripts executable:
```bash
chmod +x scripts/new-script.sh
```
