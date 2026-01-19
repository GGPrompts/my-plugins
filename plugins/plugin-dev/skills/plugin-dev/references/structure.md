# Plugin Structure

Claude Code plugins follow a standardized directory structure with automatic component discovery.

## Directory Structure

### Standard Plugin Pattern

Every plugin (standalone or in marketplace) uses the same structure:

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json          # Required: Plugin manifest
├── commands/                 # Slash commands (.md files)
├── agents/                   # Subagent definitions (.md files)
├── skills/                   # Agent skills (subdirectories)
│   └── skill-name/
│       ├── SKILL.md         # Required for each skill
│       └── references/      # Detailed docs (loaded on-demand)
├── hooks/
│   └── hooks.json           # Event handler configuration
├── .mcp.json                # MCP server definitions
└── scripts/                 # Helper scripts and utilities
```

### Marketplace Structure

A marketplace is a collection of plugins:

```
my-marketplace/
├── .claude-plugin/
│   └── marketplace.json     # Lists all plugins
└── plugins/
    ├── plugin-one/
    │   ├── .claude-plugin/
    │   │   └── plugin.json  # Each plugin has its own manifest
    │   └── skills/
    └── plugin-two/
        ├── .claude-plugin/
        │   └── plugin.json
        └── commands/
```

**Key points:**
- `marketplace.json` at marketplace root lists all plugins via `source` paths
- Each plugin has `.claude-plugin/plugin.json` (consistent, portable pattern)
- This structure allows plugins to be extracted and used standalone

**Critical rules:**
- Component directories (skills/, commands/, etc.) at plugin root, NOT inside `.claude-plugin/`
- References inside skills: `skills/<name>/references/` NOT at plugin root
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
1. `.claude-plugin/plugin.json` - Plugin manifest
2. `commands/*.md` files
3. `agents/*.md` files
4. `skills/*/SKILL.md` files
5. `hooks/hooks.json` configuration
6. `.mcp.json` MCP servers

Components available on next session; no restart required for file changes (but hooks require restart).

**Note:** Explicit arrays for `skills`, `agents`, `commands` in plugin.json are optional. Auto-discovery finds components in standard directories. Use explicit arrays only for custom paths.

## Common Patterns

**Minimal Plugin (command-only):**
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
    │   ├── SKILL.md
    │   └── references/
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
│   └── my-skill/
│       ├── SKILL.md
│       └── references/
├── hooks/
│   └── hooks.json
├── .mcp.json
└── scripts/
```

**Marketplace Structure:**
```
my-marketplace/
├── .claude-plugin/
│   └── marketplace.json
└── plugins/
    └── my-plugin/
        ├── .claude-plugin/
        │   └── plugin.json
        └── skills/
            └── my-skill/
                ├── SKILL.md
                └── references/
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Component not loading | Check directory/file names, YAML frontmatter syntax |
| Path resolution errors | Replace hardcoded paths with `${CLAUDE_PLUGIN_ROOT}` |
| Auto-discovery failing | Ensure directories at plugin root (not in `.claude-plugin/`) |
