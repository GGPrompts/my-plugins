# Plugin Marketplaces

Marketplaces allow bundling and distributing multiple plugins from a single repository.

## Standalone Plugin vs Marketplace

| Aspect | Standalone (`plugin.json`) | Marketplace (`marketplace.json`) |
|--------|---------------------------|----------------------------------|
| **Use case** | Single focused plugin | Collection of related plugins |
| **Manifest** | `.claude-plugin/plugin.json` | `.claude-plugin/marketplace.json` |
| **Installation** | Install entire plugin | Install individual plugins or bundles |
| **Distribution** | Share repo directly | Centralized catalog |
| **Updates** | Per-plugin versioning | Marketplace-wide + per-plugin versions |

**Important:** Use ONE approach, not both. Having both `plugin.json` and `marketplace.json` may cause conflicts.

## Marketplace Structure

```
my-marketplace/
├── .claude-plugin/
│   └── marketplace.json      # ONLY this file here
└── plugins/
    ├── tool-a/
    │   ├── commands/
    │   ├── agents/
    │   └── skills/
    ├── tool-b/
    │   ├── commands/
    │   └── hooks/
    └── full-bundle/          # Optional: bundle pointing to root
```

## marketplace.json Schema

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "my-marketplace",
  "version": "1.0.0",
  "description": "Collection of plugins for X workflow",
  "owner": {
    "name": "Author Name",
    "email": "author@example.com"
  },
  "plugins": [
    {
      "name": "tool-a",
      "description": "What tool-a does",
      "version": "1.0.0",
      "source": "./plugins/tool-a",
      "category": "development"
    },
    {
      "name": "tool-b",
      "description": "What tool-b does",
      "source": "./plugins/tool-b",
      "category": "productivity"
    },
    {
      "name": "full-bundle",
      "description": "All tools in one install",
      "source": "./",
      "category": "bundle"
    }
  ]
}
```

## Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Marketplace identifier (kebab-case) |
| `plugins` | array | List of available plugins |
| `plugins[].name` | string | Plugin identifier |
| `plugins[].description` | string | Brief plugin description |
| `plugins[].source` | string | Relative path to plugin directory |

## Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| `$schema` | string | Schema URL for validation |
| `version` | string | Marketplace version |
| `description` | string | Marketplace description |
| `owner` | object | `{name, email, url}` |
| `plugins[].version` | string | Individual plugin version |
| `plugins[].category` | string | Category for organization |
| `plugins[].author` | object | Plugin-specific author |
| `plugins[].tags` | array | Discovery keywords |
| `plugins[].skills` | array | **Explicit skill paths** (recommended) |
| `plugins[].strict` | boolean | Enable strict validation |

## Skills Array (Recommended)

Anthropic's official marketplace explicitly lists skills for each plugin:

```json
{
  "plugins": [
    {
      "name": "document-skills",
      "description": "Document processing suite",
      "source": "./",
      "skills": [
        "./skills/xlsx",
        "./skills/docx",
        "./skills/pptx",
        "./skills/pdf"
      ]
    }
  ]
}
```

**Why use explicit skills array?**
- Ensures skills are discovered correctly
- Avoids relying on auto-discovery which may miss nested paths
- Documents exactly which skills a plugin provides

## Categories

Categories are **metadata only** - they do NOT create visual groupings in the `/plugin` UI. Plugins are displayed in a flat list regardless of category.

```json
{
  "plugins": [
    {"name": "linter", "category": "development"},
    {"name": "reviewer", "category": "productivity"}
  ]
}
```

Categories serve as:
- Semantic organization for documentation
- Potential future filtering (not currently implemented)
- Grouping plugins by purpose in README

## Installation

Users install from marketplaces via `/plugin`:

```bash
# Add marketplace from GitHub
/plugin add https://github.com/user/my-marketplace

# Add specific branch or tag (v2.0.28+)
/plugin add https://github.com/user/my-marketplace#develop
/plugin add https://github.com/user/my-marketplace#v1.0.0

# Install individual plugin
/plugin install tool-a@my-marketplace

# Install bundle
/plugin install full-bundle@my-marketplace
```

## Auto-Update Configuration

Marketplaces can be configured to auto-update or stay pinned (v2.0.70+):

```bash
# Toggle auto-update for a marketplace
/plugins  # Then select marketplace and toggle auto-update
```

## Team Configuration

Share marketplace recommendations with your team via `settings.json` (v2.0.12+):

```json
{
  "extraKnownMarketplaces": [
    "https://github.com/company/internal-plugins",
    "https://github.com/company/tools#stable"
  ]
}
```

These marketplaces appear in `/plugins discover` for team members.

## Command Prefixing

Commands from marketplace plugins are **namespaced by plugin name**, but the prefix is optional:

```bash
# Direct (if no naming conflicts)
/deploy

# Prefixed (if disambiguation needed)
/tool-a:deploy
```

Prefixes are only required when multiple installed plugins have commands with the same name.

## Bundle Plugin Pattern

To offer "install everything" option, create a bundle plugin pointing to root:

```json
{
  "plugins": [
    {"name": "tool-a", "source": "./plugins/tool-a"},
    {"name": "tool-b", "source": "./plugins/tool-b"},
    {
      "name": "complete-toolkit",
      "description": "All tools in one install",
      "source": "./",
      "category": "bundle"
    }
  ]
}
```

The bundle with `"source": "./"` loads all components from the repository root.

## Flat Structure Alternative

For simpler setups, you can have components at root with sub-plugins in directories:

```
my-marketplace/
├── .claude-plugin/
│   └── marketplace.json
├── commands/              # Loaded by bundle plugin
├── agents/                # Loaded by bundle plugin
├── skills/                # Loaded by bundle plugin
└── plugins/
    └── specialized-tool/  # Individual installable plugin
```

## Important: Symlinks Don't Work for Remote Plugins

When plugins are loaded from remote GitHub repositories, **symlinks do not resolve correctly**. The symlink targets point to relative paths that don't exist in the plugin cache.

**Don't do this:**
```
plugins/my-tool/commands/cmd.md -> ../../commands/cmd.md  # BROKEN
```

**Do this instead:**
```
plugins/my-tool/commands/cmd.md  # Actual file copy
```

For remote marketplaces, use actual file copies in the `plugins/` directory, not symlinks.

---

## Comparison with Official Anthropic Marketplace

The official Anthropic marketplace at `github.com/anthropics/claude-code` uses:

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "claude-code-plugins",
  "version": "1.0.0",
  "owner": {"name": "Anthropic", "email": "support@anthropic.com"},
  "plugins": [
    {"name": "plugin-dev", "source": "./plugins/plugin-dev", "category": "development"},
    {"name": "code-review", "source": "./plugins/code-review", "category": "productivity"}
  ]
}
```

Key patterns:
- Only `marketplace.json` in `.claude-plugin/` (no `plugin.json`)
- Each plugin in `plugins/` subdirectory
- Each plugin directory has its own `commands/`, `agents/`, `skills/`
