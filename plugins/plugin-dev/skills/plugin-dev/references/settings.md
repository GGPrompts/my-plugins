# Plugin Settings

Plugins can store user-configurable settings in `.claude/plugin-name.local.md` files using YAML frontmatter for structured configuration.

## File Structure

```markdown
---
enabled: true
validation_level: strict
max_retries: 3
---

# Additional Context

Custom instructions or documentation here.
```

**Location:** `.claude/plugin-name.local.md` in project directory

## Reading Settings in Hooks

```bash
#!/bin/bash
SETTINGS_FILE=".claude/my-plugin.local.md"

# Quick-exit if no settings
if [[ ! -f "$SETTINGS_FILE" ]]; then
  exit 0
fi

# Extract YAML frontmatter
FRONTMATTER=$(sed -n '/^---$/,/^---$/p' "$SETTINGS_FILE" | sed '1d;$d')

# Parse specific field
ENABLED=$(echo "$FRONTMATTER" | grep "^enabled:" | sed 's/enabled: *//')

if [[ "$ENABLED" != "true" ]]; then
  exit 0
fi

# Continue with hook logic...
```

## Common Use Cases

**Hook Activation Control:**
```yaml
---
enabled: true
---
```

**Validation Levels:**
```yaml
---
validation_level: strict  # strict | standard | lenient
file_size_limit: 10000
---
```

**Agent State:**
```yaml
---
agent_name: worker-1
task_number: 42
coordinator_session: main
---

# Task Instructions
Complete the implementation of feature X...
```

## Reading the Body

```bash
# Extract everything after closing ---
BODY=$(awk '/^---$/{f=!f;next}f{exit}!f' "$SETTINGS_FILE")
```

## Best Practices

| Practice | Reason |
|----------|--------|
| Use `.local.md` suffix | Identifies as local config |
| Add to `.gitignore` | Prevent accidental commits |
| Provide defaults | Handle missing files gracefully |
| Validate values | Prevent errors from bad config |
| Document in README | Show example settings file |

## Gitignore Entry

Add to project `.gitignore`:
```
.claude/*.local.md
```

## Example: Conditional Hook

```bash
#!/bin/bash
# Only run if plugin is enabled

SETTINGS=".claude/my-plugin.local.md"

if [[ ! -f "$SETTINGS" ]]; then
  # No settings = use defaults (enabled)
  ENABLED="true"
else
  ENABLED=$(sed -n '/^---$/,/^---$/p' "$SETTINGS" | grep "^enabled:" | sed 's/enabled: *//')
fi

if [[ "$ENABLED" != "true" ]]; then
  echo '{"continue": true, "suppressOutput": true}'
  exit 0
fi

# Run actual validation...
```

**Note:** Users must restart Claude Code after editing settings files (hooks cannot hot-reload).
