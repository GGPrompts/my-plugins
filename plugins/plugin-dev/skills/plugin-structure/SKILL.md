---
name: plugin-structure
description: This skill should be used when the user asks to "create a plugin", "understand plugin structure", "configure plugin.json", "organize plugin directories", or mentions plugin manifest, auto-discovery, or CLAUDE_PLUGIN_ROOT.
---

# Plugin Structure

Claude Code plugins follow standardized directory structures with automatic component discovery.

## Directory Structure

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json          # Required: Plugin manifest
├── commands/                 # Slash commands (.md files)
├── agents/                   # Subagent definitions (.md files)
├── skills/                   # Agent skills (subdirectories)
│   └── skill-name/
│       └── SKILL.md         # Required for each skill
├── hooks/
│   └── hooks.json           # Event handler configuration
├── .mcp.json                # MCP server definitions
└── scripts/                 # Helper scripts and utilities
```

**Critical rules:**
- Manifest MUST reside in `.claude-plugin/` directory
- Component directories MUST be at plugin root, NOT nested inside `.claude-plugin/`
- Only create directories for components the plugin uses
- Use kebab-case for all directory and file names

## Plugin Manifest (plugin.json)

### Minimum Viable

```json
{
  "name": "plugin-name"
}
```

### Recommended

```json
{
  "name": "plugin-name",
  "version": "1.0.0",
  "description": "Brief explanation of plugin purpose",
  "author": {
    "name": "Author Name",
    "url": "https://example.com"
  },
  "license": "MIT",
  "keywords": ["testing", "automation"]
}
```

### Custom Component Paths

```json
{
  "name": "plugin-name",
  "commands": "./custom-commands",
  "agents": ["./agents", "./specialized-agents"],
  "hooks": "./config/hooks.json",
  "mcpServers": "./.mcp.json"
}
```

Custom paths supplement defaults (don't replace). All paths must be relative, starting with `./`.

## Portable Path References

Use `${CLAUDE_PLUGIN_ROOT}` for all intra-plugin paths:

```json
"command": "${CLAUDE_PLUGIN_ROOT}/scripts/tool.sh"
```

**Never use:** hardcoded absolute paths, home directory shortcuts, or relative paths from working directory.

## Auto-Discovery

Claude Code automatically loads:
1. `.claude-plugin/plugin.json` when plugin enables
2. `commands/*.md` files
3. `agents/*.md` files
4. `skills/*/SKILL.md` files
5. `hooks/hooks.json` configuration
6. `.mcp.json` MCP servers

Components available on next session; no restart required for file changes (but hooks require restart).

## Common Patterns

**Minimal Plugin:**
```
my-plugin/
├── .claude-plugin/
│   └── plugin.json
└── commands/
    └── hello.md
```

**Skill-Focused Plugin:**
```
my-plugin/
├── .claude-plugin/
│   └── plugin.json
└── skills/
    ├── skill-one/
    │   └── SKILL.md
    └── skill-two/
        └── SKILL.md
```

**Full-Featured Plugin:**
```
my-plugin/
├── .claude-plugin/
│   └── plugin.json
├── commands/
├── agents/
├── skills/
├── hooks/
│   ├── hooks.json
│   └── scripts/
├── .mcp.json
└── scripts/
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Component not loading | Check directory/file names, YAML frontmatter syntax |
| Path resolution errors | Replace hardcoded paths with `${CLAUDE_PLUGIN_ROOT}` |
| Auto-discovery failing | Ensure directories at plugin root (not in `.claude-plugin/`) |
