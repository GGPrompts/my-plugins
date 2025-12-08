# Plugin Directory Structure

## Standard Plugin Layout

A complete plugin follows this structure:

```
my-plugin/
├── .claude-plugin/           # Metadata directory (REQUIRED)
│   └── plugin.json          # Plugin manifest (REQUIRED)
├── commands/                 # Slash commands (optional)
│   ├── deploy.md
│   └── status.md
├── agents/                   # Subagents (optional)
│   ├── reviewer.md
│   └── tester.md
├── skills/                   # Agent Skills (optional)
│   ├── code-reviewer/
│   │   └── SKILL.md
│   └── pdf-processor/
│       ├── SKILL.md
│       └── scripts/
├── hooks/                    # Hook configurations (optional)
│   └── hooks.json
├── .mcp.json                # MCP server definitions (optional)
├── scripts/                 # Utility scripts for hooks
│   ├── format-code.sh
│   └── validate.py
├── LICENSE
└── CHANGELOG.md
```

## Critical Rules

1. **`.claude-plugin/` contains ONLY `plugin.json`** - All other directories must be at plugin root
2. **All paths in plugin.json are relative** - Must start with `./`
3. **Component directories are at root level** - `commands/`, `agents/`, `skills/`, `hooks/` are siblings to `.claude-plugin/`

## File Locations Reference

| Component       | Default Location             | Purpose                          |
|-----------------|------------------------------|----------------------------------|
| **Manifest**    | `.claude-plugin/plugin.json` | Required metadata file           |
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
