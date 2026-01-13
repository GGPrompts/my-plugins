# Plugin Development Plugin

Create and manage Claude Code plugins with proper structure and manifests.

## Overview

The Plugin Development plugin provides guidance on:
- **Plugin Structure** - Directory layout, plugin.json manifests
- **Components** - Skills, commands, agents, hooks
- **Marketplaces** - Multi-plugin repositories
- **Debugging** - Troubleshooting plugin issues
- **Templates** - Pre-built component templates

## Installation

```bash
cp -r my-plugins/plugins/plugin-development ~/.claude/plugins/
```

## Skills

| Skill | Purpose |
|-------|---------|
| `plugin-dev` | Complete plugin development guide |

## Agents

| Agent | Purpose |
|-------|---------|
| `plugin-validator` | Validate plugin structure and manifests |

## Reference Topics

| Reference | Content |
|-----------|---------|
| `plugin-structure.md` | Directory layout and organization |
| `manifest-schema.md` | plugin.json schema reference |
| `marketplace-schema.md` | marketplace.json for multi-plugin repos |
| `components.md` | Skills, commands, agents, hooks |
| `hooks.md` | Hook system and lifecycle |

## Templates

Pre-built templates in `assets/templates/`:

| Template | Purpose |
|----------|---------|
| `plugin.json.template` | Plugin manifest |
| `SKILL.md.template` | Skill file |
| `agent.md.template` | Agent file |
| `command.md.template` | Command file |
| `hooks.json.template` | Hooks configuration |
| `mcp.json.template` | MCP server configuration |

## Quick Start

```bash
# Get plugin development guidance
/plugin-development:plugin-dev

# Validate a plugin
# Task tool with subagent_type: "plugin-development:plugin-validator"
```

## Plugin Structure

```
my-plugin/
├── plugin.json        # Plugin manifest (required)
├── skills/            # Skills directory
│   └── my-skill/
│       └── SKILL.md
├── agents/            # Agents directory
│   └── my-agent.md
├── commands/          # Commands directory
│   └── my-command.md
└── hooks/             # Hooks directory
    └── hooks.json
```

## License

MIT License
