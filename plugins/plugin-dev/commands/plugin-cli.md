---
description: Show Claude Code CLI commands for plugin and marketplace management
---

# Plugin CLI Reference

Claude Code provides CLI commands for plugin management outside the interactive `/plugin` menu.

## Plugin Management

```bash
# Install a plugin (user scope by default)
claude plugin install <plugin>@<marketplace>
claude plugin install plugin-dev@my-plugins

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

## Marketplace Management

```bash
# List marketplaces
claude plugin marketplace list

# Add a marketplace (local directory)
claude plugin marketplace add /path/to/marketplace

# Add from GitHub
claude plugin marketplace add https://github.com/user/repo

# Add specific branch or tag
claude plugin marketplace add https://github.com/user/repo#develop
claude plugin marketplace add https://github.com/user/repo#v1.0.0

# Remove a marketplace
claude plugin marketplace remove <marketplace-name>

# Update marketplace cache
claude plugin marketplace update <marketplace-name>
```

## Session-Only Loading

```bash
# Load plugins from directory for this session only (not installed)
claude --plugin-dir /path/to/plugins

# Multiple directories
claude --plugin-dir /path/one --plugin-dir /path/two
```

## Cache Management

Plugin data is cached at `~/.claude/plugins/`:

| Path | Purpose |
|------|---------|
| `cache/` | Installed plugin files by marketplace |
| `installed_plugins.json` | Installation records |
| `known_marketplaces.json` | Registered marketplaces |

### Clear Cache

```bash
# Clear specific marketplace cache
rm -rf ~/.claude/plugins/cache/<marketplace-name>

# Then reinstall or restart to repopulate
```

## Debug Mode

```bash
# See plugin loading details
claude --debug
```

Shows:
- Which plugins are loading
- Errors in plugin manifests
- Command, agent, and hook registration
- MCP server initialization

## Interactive Commands

Inside Claude Code, use `/plugin` for interactive management:

| Command | Purpose |
|---------|---------|
| `/plugin` | Open plugin management menu |
| `/plugins` | Alias for `/plugin` |
| `/plugins discover` | Browse available plugins from marketplaces |

## Scope Precedence

Plugins can be installed at two scopes:

| Scope | Location | Takes precedence |
|-------|----------|------------------|
| Project | `.claude/plugins/` | Yes (checked first) |
| User | `~/.claude/plugins/` | No (fallback) |

Project-scoped plugins override user-scoped ones with the same name.
