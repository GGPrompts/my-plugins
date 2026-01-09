# Plugin Directory Structure

## Two Distribution Models

Claude Code supports two plugin distribution approaches:

| Model | Manifest Location | Use Case |
|-------|-------------------|----------|
| **Standalone** | `.claude-plugin/plugin.json` | Single plugin = entire repo |
| **Marketplace** | `.claude-plugin/marketplace.json` | Collection of plugins in one repo |

**Choose ONE approach** - having both manifests may cause conflicts.

---

## Marketplace Plugin Layout (MOST COMMON)

When your repo contains **multiple plugins** via a marketplace, each plugin has `plugin.json` at its **root** (NOT in `.claude-plugin/`):

```
my-marketplace/
├── .claude-plugin/
│   └── marketplace.json      # Lists all plugins
└── plugins/
    ├── tool-a/
    │   ├── plugin.json       # AT ROOT (not .claude-plugin/)
    │   ├── commands/
    │   └── skills/
    └── tool-b/
        ├── plugin.json       # AT ROOT
        ├── agents/
        └── hooks/
```

**Key Point:** `.claude-plugin/` is ONLY at the marketplace root, NOT inside each plugin.

---

## Standalone Plugin Layout

Only use this when your **entire repo IS the plugin** (no marketplace wrapper):

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

---

## Quick Reference

| Setup | Manifest Location |
|-------|-------------------|
| Plugin inside marketplace | `plugins/my-tool/plugin.json` (at plugin root) |
| Standalone plugin (whole repo) | `.claude-plugin/plugin.json` |
| Marketplace manifest | `.claude-plugin/marketplace.json` |

## Critical Rules

1. **Marketplace plugins: `plugin.json` at plugin root** - NOT in `.claude-plugin/`
2. **Standalone plugins: `plugin.json` in `.claude-plugin/`** - Only when repo = plugin
3. **All paths in manifests are relative** - Must start with `./`
4. **Component directories are at plugin root** - `commands/`, `agents/`, `skills/`, `hooks/`

## File Locations Reference

| Component       | Location                     | Purpose                          |
|-----------------|------------------------------|----------------------------------|
| **Manifest**    | `plugin.json` (marketplace plugin) or `.claude-plugin/plugin.json` (standalone) | Plugin metadata |
| **Commands**    | `commands/`                  | Slash command markdown files     |
| **Agents**      | `agents/`                    | Subagent markdown files          |
| **Skills**      | `skills/`                    | Agent Skills with SKILL.md files |
| **Hooks**       | `hooks/hooks.json`           | Hook configuration               |
| **MCP servers** | `.mcp.json`                  | MCP server definitions           |

## Environment Variables

Use `${CLAUDE_PLUGIN_ROOT}` in hooks, MCP servers, and scripts for the absolute path to the plugin directory:

```json
{
  "hooks": {
    "PostToolUse": [{
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format.sh"
      }]
    }]
  }
}
```

---

## Marketplace Layout

For distributing multiple plugins from one repository:

```
my-marketplace/
├── .claude-plugin/
│   └── marketplace.json      # ONLY this file (no plugin.json)
└── plugins/
    ├── tool-a/
    │   ├── commands/
    │   ├── agents/
    │   └── skills/
    └── tool-b/
        ├── commands/
        └── hooks/
```

Each plugin in `plugins/` is independently installable. See `references/marketplace-schema.md` for full details.

## Command Prefixing

Commands from plugins are namespaced, but prefix is **optional unless conflicts exist**:

```bash
/deploy                  # Direct (no conflicts)
/tool-a:deploy           # Prefixed (disambiguation)
```
