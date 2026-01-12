---
name: plugin-development
description: Create and manage Claude Code plugins including commands, agents, skills, hooks, and MCP servers. This skill should be used when building new plugins, debugging plugin issues, understanding plugin structure, or working with plugin marketplaces.
user-invocable: true
---

# Plugin Development

This skill provides guidance for creating, structuring, and debugging Claude Code plugins.

## When to Use

This skill should be used when:
- Creating a new Claude Code plugin from scratch
- Adding components (commands, agents, skills, hooks, MCP servers) to an existing plugin
- Debugging plugin loading or configuration issues
- Understanding plugin directory structure and manifest format
- Preparing plugins for distribution via marketplaces
- Setting up a marketplace to bundle multiple plugins

## Two Plugin Patterns

Claude Code supports two patterns:

| Pattern | Manifest Location | Use Case |
|---------|-------------------|----------|
| **Standalone** | `.claude-plugin/plugin.json` | Entire repo IS one plugin |
| **Marketplace** | `plugin.json` at plugin root | Multiple plugins in one repo |

**Choose ONE approach** - having both may cause conflicts.

## Marketplace Plugin (Most Common)

When your repo contains **multiple plugins** via a marketplace:

```
my-marketplace/
├── .claude-plugin/
│   └── marketplace.json      # Lists all plugins
└── plugins/
    ├── tool-a/
    │   ├── plugin.json       # AT PLUGIN ROOT (not .claude-plugin/)
    │   ├── commands/
    │   ├── agents/
    │   └── skills/
    │       └── my-skill/
    │           └── SKILL.md
    └── tool-b/
        ├── plugin.json
        └── skills/
```

**Key:** `.claude-plugin/` is ONLY at marketplace root, NOT inside each plugin.

## Standalone Plugin

Only use when your **entire repo IS the plugin** (no marketplace wrapper):

```
my-plugin/                    # Repo root = plugin root
├── .claude-plugin/
│   └── plugin.json          # Standalone uses .claude-plugin/
├── commands/
├── agents/
├── skills/
├── hooks/
└── .mcp.json
```

## Creating a Plugin

### Step 1: Create Directory Structure

For marketplace plugins:
```
plugins/my-plugin/
├── plugin.json           # AT ROOT (not in .claude-plugin/)
├── commands/             # Slash commands (.md files)
├── agents/               # Subagents (.md files)
├── skills/               # Agent skills (dirs with SKILL.md)
│   └── skill-name/
│       └── SKILL.md      # ONE level deep - no nesting!
├── hooks/
│   └── hooks.json        # Hook configurations
├── .mcp.json             # MCP server definitions
└── scripts/              # Utility scripts for hooks
```

### Step 2: Create plugin.json

Minimal manifest:
```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "What this plugin does"
}
```

Full manifest - see `references/manifest-schema.md`.

### Step 3: Add Components

**Commands** - Create `commands/name.md`:
```markdown
---
description: Brief description for autocomplete
user-invocable: true
---

# Command Name

Instructions for the command...
```

**Agents** - Create `agents/name.md`:
```markdown
---
description: What this agent specializes in
user-invocable: true
capabilities: ["task1", "task2"]
---

# Agent Name

Agent instructions...
```

**Skills** - Create `skills/name/SKILL.md`:
```markdown
---
name: skill-name
description: What the skill does
user-invocable: true
---

# Skill Name

Skill instructions...
```

**Hooks** - Create `hooks/hooks.json` or inline in plugin.json:
```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/scripts/lint.sh"
      }]
    }]
  }
}
```

**MCP Servers** - Create `.mcp.json` or inline in plugin.json:
```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["@company/mcp-server"],
      "cwd": "${CLAUDE_PLUGIN_ROOT}"
    }
  }
}
```

## Critical Rules

1. **Marketplace plugins: `plugin.json` at plugin root** - NOT in `.claude-plugin/`
2. **Standalone plugins: `.claude-plugin/plugin.json`** - Only when entire repo = one plugin
3. **Skills must be ONE level deep** - `skills/name/SKILL.md` NOT `skills/parent/skills/child/SKILL.md`
4. **All paths are relative** - Must start with `./`
5. **Use `${CLAUDE_PLUGIN_ROOT}`** - For absolute paths in hooks/MCP configs
6. **Scripts must be executable** - Run `chmod +x script.sh`
7. **No `plugin.json` per skill** - Only one per plugin, not per skill directory

## Debugging

Run `claude --debug` to see:
- Which plugins are loading
- Errors in plugin manifests
- Command, agent, and hook registration
- MCP server initialization

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Plugin not loading | Invalid plugin.json | Validate JSON syntax |
| Skills not discovered | Nested skills (`skills/a/skills/b/`) | Flatten to `skills/b/SKILL.md` |
| Skills not showing | Missing from marketplace `skills` array | Add explicit skill paths to marketplace.json |
| Commands not appearing | Wrong directory structure | Ensure `commands/` at plugin root |
| Marketplace plugin.json wrong location | `plugins/X/.claude-plugin/plugin.json` | Move to `plugins/X/plugin.json` |
| Hooks not firing | Script not executable | Run `chmod +x script.sh` |
| MCP server fails | Missing CLAUDE_PLUGIN_ROOT | Use `${CLAUDE_PLUGIN_ROOT}` variable |
| Path errors | Absolute paths used | All paths must be relative with `./` |
| Plugins not appearing after update | Stale cache | Clear cache: `rm -rf ~/.claude/plugins/cache/<marketplace>` |

## CLI Commands

Claude Code provides CLI commands for plugin management outside the interactive menu.

### Plugin Management

```bash
# Install a plugin (user scope by default)
claude plugin install <plugin>@<marketplace>
claude plugin install plugin-development@my-plugins

# Install at project scope
claude plugin install <plugin>@<marketplace> --scope project

# Uninstall a plugin
claude plugin uninstall <plugin>@<marketplace>

# Enable/disable without uninstalling
claude plugin enable <plugin>@<marketplace>
claude plugin disable <plugin>@<marketplace>

# Update a plugin (restart required after)
claude plugin update <plugin>@<marketplace>

# Validate plugin/marketplace structure
claude plugin validate /path/to/plugin
```

### Marketplace Management

```bash
# List marketplaces
claude plugin marketplace list

# Add a marketplace (local directory)
claude plugin marketplace add /path/to/marketplace

# Add from GitHub
claude plugin marketplace add https://github.com/user/repo

# Remove a marketplace
claude plugin marketplace remove <marketplace-name>

# Update marketplace cache
claude plugin marketplace update <marketplace-name>
```

### Session-Only Loading

```bash
# Load plugins from directory for this session only (not installed)
claude --plugin-dir /path/to/plugins

# Multiple directories
claude --plugin-dir /path/one --plugin-dir /path/two
```

### Cache Management

Plugin data is cached at `~/.claude/plugins/`:
- `cache/` - Installed plugin files by marketplace
- `installed_plugins.json` - Installation records
- `known_marketplaces.json` - Registered marketplaces

**Clear cache to force refresh:**
```bash
# Clear specific marketplace cache
rm -rf ~/.claude/plugins/cache/<marketplace-name>

# Then reinstall or restart to repopulate
```

## Resources

- `references/plugin-structure.md` - Complete directory layout and file locations
- `references/manifest-schema.md` - Full plugin.json schema with all fields
- `references/marketplace-schema.md` - Marketplace bundles, categories, and installation
- `references/components.md` - Detailed specs for commands, agents, skills, hooks, MCP
- `references/hooks.md` - Complete hook events, configuration, and patterns

## Related Commands and Agents

| Resource | Purpose |
|----------|---------|
| `/meta:create-plugin` | Guided 8-phase plugin creation workflow |
| `/meta:verify-plugin` | Validate plugin structure and manifests |
| `plugin-validator` agent | Autonomous plugin validation |
| `skill-reviewer` agent | Review skill quality and best practices |
| `agent-creator` agent | AI-assisted agent generation |

## Standalone vs Marketplace

| Approach | Manifest | Use Case |
|----------|----------|----------|
| **Standalone** | `plugin.json` | Single focused plugin |
| **Marketplace** | `marketplace.json` | Bundle multiple plugins |

**Choose ONE** - having both may cause conflicts. Categories in marketplaces are metadata only (no visual grouping in UI).
