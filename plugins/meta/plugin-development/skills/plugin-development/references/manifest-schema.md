# Plugin Manifest Schema (plugin.json)

The `plugin.json` file in `.claude-plugin/` defines plugin metadata and configuration.

## Complete Schema

```json
{
  "name": "plugin-name",
  "version": "1.2.0",
  "description": "Brief plugin description",
  "author": {
    "name": "Author Name",
    "email": "author@example.com",
    "url": "https://github.com/author"
  },
  "homepage": "https://docs.example.com/plugin",
  "repository": "https://github.com/author/plugin",
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"],
  "commands": ["./custom/commands/special.md"],
  "agents": "./custom/agents/",
  "hooks": "./config/hooks.json",
  "mcpServers": "./mcp-config.json"
}
```

## Required Fields

| Field  | Type   | Description                               | Example              |
|--------|--------|-------------------------------------------|----------------------|
| `name` | string | Unique identifier (kebab-case, no spaces) | `"deployment-tools"` |

## Metadata Fields

| Field         | Type   | Description                         | Example                          |
|---------------|--------|-------------------------------------|----------------------------------|
| `version`     | string | Semantic version                    | `"2.1.0"`                        |
| `description` | string | Brief explanation of plugin purpose | `"Deployment automation tools"`  |
| `author`      | object | Author information                  | `{"name": "Dev", "email": "..."}` |
| `homepage`    | string | Documentation URL                   | `"https://docs.example.com"`     |
| `repository`  | string | Source code URL                     | `"https://github.com/user/repo"` |
| `license`     | string | License identifier                  | `"MIT"`, `"Apache-2.0"`          |
| `keywords`    | array  | Discovery tags                      | `["deployment", "ci-cd"]`        |

## Component Path Fields

| Field        | Type           | Description                          | Example                    |
|--------------|----------------|--------------------------------------|----------------------------|
| `commands`   | string\|array  | Additional command files/directories | `"./custom/cmd.md"`        |
| `agents`     | string\|array  | Additional agent files               | `"./custom/agents/"`       |
| `hooks`      | string\|object | Hook config path or inline config    | `"./hooks.json"`           |
| `mcpServers` | string\|object | MCP config path or inline config     | `"./custom-mcp-config.json"` |

## Path Behavior Rules

- Custom paths **supplement** default directories - they don't replace them
- If `commands/` exists, it loads in addition to custom command paths
- All paths must be relative to plugin root and start with `./`
- Multiple paths can be specified as arrays

## Inline Configuration

Hooks and MCP servers can be defined inline instead of separate files:

```json
{
  "name": "my-plugin",
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/scripts/lint.sh"
      }]
    }]
  },
  "mcpServers": {
    "my-server": {
      "command": "npx",
      "args": ["@company/mcp-server"],
      "cwd": "${CLAUDE_PLUGIN_ROOT}"
    }
  }
}
```
