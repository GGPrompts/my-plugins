---
name: plugin-development
description: Create and manage Claude Code plugins including commands, agents, skills, hooks, and MCP servers. This skill should be used when building new plugins, debugging plugin issues, understanding plugin structure, or working with plugin marketplaces.
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
---

# Command Name

Instructions for the command...
```

**Agents** - Create `agents/name.md`:
```markdown
---
description: What this agent specializes in
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
