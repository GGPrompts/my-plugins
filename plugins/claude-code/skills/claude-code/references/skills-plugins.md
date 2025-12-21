# Creating Skills and Plugins

## Agent Skills

Skills are located in `.claude/skills/` with structure:

```
my-skill/
├── SKILL.md      # Main instructions
└── references/   # Detailed docs (optional)
```

### SKILL.md Structure

```markdown
---
name: my-skill
description: "Brief description of when to use this skill"
---

# Skill Name

## When to Use This Skill
Specific scenarios when Claude should activate this skill.

## Instructions
Step-by-step instructions for Claude to follow.
```

### Best Practices
1. **Clear activation criteria**: Define exactly when the skill should be used
2. **Concise instructions**: Focus on essential information
3. **Use references/**: Move detailed docs to references/ for progressive disclosure
4. **Third-person description**: "This skill should be used when..."

---

## Plugins System

Plugins are packaged collections of extensions:

```
my-plugin/
├── plugin.json          # Plugin metadata
├── commands/            # Slash commands
├── skills/              # Agent skills
├── hooks/               # Hook scripts
└── README.md
```

### plugin.json Example

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "Plugin description",
  "author": "Your Name",
  "commands": ["commands/*.md"],
  "skills": ["skills/*/"],
  "hooks": "hooks/hooks.json"
}
```

### Installing Plugins

```bash
# Install from GitHub
/install gh:username/repo

# List installed plugins
/plugins

# Uninstall plugin
/uninstall plugin-name
```
