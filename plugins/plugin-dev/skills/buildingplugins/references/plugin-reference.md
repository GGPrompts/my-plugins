# Plugin Reference

Complete technical reference for Claude Code plugin development.

## plugin.json Schema

```json
{
  "name": "plugin-name",           // REQUIRED: lowercase, hyphens, 3-64 chars
  "version": "1.2.0",              // REQUIRED: semantic versioning
  "description": "Brief description",
  "author": {
    "name": "Author Name",
    "email": "author@example.com",
    "url": "https://github.com/author"
  },
  "homepage": "https://docs.example.com",
  "repository": "https://github.com/author/plugin",
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"],
  "commands": "./commands/",       // Directory or array of paths
  "agents": "./agents/",
  "skills": "./skills/",
  "hooks": "./hooks/hooks.json",   // Or inline hooks object
  "mcpServers": "./.mcp.json",     // Or inline mcpServers object
  "lspServers": "./.lsp.json",     // LSP server configuration
  "outputStyles": "./styles/",     // Custom output styles
  "strict": true                   // Require plugin.json in source
}
```

## Plugin Location Patterns

### Standalone Plugin
```
my-plugin/
├── .claude-plugin/
│   └── plugin.json          # Manifest in .claude-plugin/
├── commands/
├── skills/
└── agents/
```

### Marketplace Plugin
```
my-marketplace/
├── .claude-plugin/
│   └── marketplace.json     # Marketplace manifest
└── plugins/
    └── my-plugin/
        ├── plugin.json      # Manifest at plugin root (NOT in .claude-plugin/)
        ├── commands/
        └── skills/
```

## Installation Scopes

| Scope | Location | Use Case |
|-------|----------|----------|
| `user` | `~/.claude/settings.json` | Personal, all projects |
| `project` | `.claude/settings.json` | Team, version controlled |
| `local` | `.claude/settings.local.json` | Personal, gitignored |
| `managed` | `managed-settings.json` | Organization-wide, read-only |

## Installation Commands

```bash
# From local directory
/plugin install ./my-plugin

# From GitHub
/plugin install github:owner/repo

# From marketplace
/plugin marketplace add https://github.com/owner/marketplace
/plugin install marketplace:marketplace-name/plugin-name

# With specific scope
/plugin install ./my-plugin --scope user

# List installed plugins
/plugin list

# Remove plugin
/plugin remove plugin-name
```

## Plugin Namespacing

- Commands: `/plugin-name:command-name`
- Skills: Auto-namespaced to plugin
- Agents: Available as `plugin-name:agent-name`

## Environment Variables

Available in plugin configurations:

| Variable | Description |
|----------|-------------|
| `${CLAUDE_PLUGIN_ROOT}` | Plugin installation directory |
| `${CLAUDE_PROJECT_DIR}` | Current project directory |
| `${VARIABLE}` | Environment variable |
| `${VARIABLE:-default}` | Environment variable with default |

## Auto-Discovery

Claude Code automatically discovers:
1. `plugin.json` (at plugin root for marketplace, or `.claude-plugin/plugin.json` for standalone)
2. `commands/*.md` files
3. `agents/*.md` files
4. `skills/*/SKILL.md` files
5. `hooks/hooks.json` configuration
6. `.mcp.json` MCP servers

**Note:** Explicit arrays for `skills`, `agents`, `commands` in plugin.json are optional. Use only for custom paths.

## Validation

```bash
# Validate plugin structure
claude plugin validate ./my-plugin

# Test without installing
claude --plugin-dir ./my-plugin
```

## Publishing Checklist

1. Unique, descriptive plugin name
2. Semantic version number
3. Comprehensive README.md
4. All paths relative to plugin root using `${CLAUDE_PLUGIN_ROOT}`
5. No hardcoded secrets
6. Tested on clean environment
7. License file included
