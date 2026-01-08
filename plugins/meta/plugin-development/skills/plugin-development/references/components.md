# Plugin Components Reference

Plugins can provide five types of components: commands, agents, skills, hooks, and MCP servers.

## Commands

Slash commands that integrate with Claude Code's command system.

**Location**: `commands/` directory in plugin root

**File format**: Markdown files with optional frontmatter

```markdown
---
description: Deploy to production environment
---

# Deploy Command

Instructions for the deployment workflow...
```

**Features**:
- Commands appear in `/` autocomplete menu
- Can include arguments: `/plugin:deploy staging`
- Namespaced as `plugin-name:command-name`

## Agents

Specialized subagents for specific tasks that Claude can invoke automatically.

**Location**: `agents/` directory in plugin root

**File format**: Markdown files with frontmatter

```markdown
---
description: What this agent specializes in
capabilities: ["task1", "task2", "task3"]
---

# Agent Name

Detailed description of the agent's role, expertise, and when Claude should invoke it.

## Capabilities
- Specific task the agent excels at
- Another specialized capability
- When to use this agent vs others

## Context and examples
Examples of when this agent should be used.
```

**Integration**:
- Agents appear in the `/agents` interface
- Claude can invoke agents automatically based on task context
- Users can invoke agents manually
- Plugin agents work alongside built-in Claude agents

## Skills

Agent Skills that extend Claude's capabilities. Model-invoked based on task context.

**Location**: `skills/` directory in plugin root

**File format**: Directories containing `SKILL.md` files with frontmatter

```
skills/
├── pdf-processor/
│   ├── SKILL.md
│   ├── references/ (optional)
│   └── scripts/ (optional)
└── code-reviewer/
    └── SKILL.md
```

**SKILL.md format**:
```markdown
---
name: pdf-processor
description: Process and manipulate PDF files including rotation, merging, and text extraction
---

# PDF Processor

Instructions for PDF processing workflows...
```

**Integration**:
- Skills are automatically discovered when plugin is installed
- Claude autonomously invokes skills based on matching task context
- Skills can include supporting files alongside SKILL.md

## Hooks

Event handlers that respond to Claude Code events automatically.

**Location**: `hooks/hooks.json` in plugin root, or inline in plugin.json

**Format**: JSON configuration with event matchers and actions

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format-code.sh"
          }
        ]
      }
    ]
  }
}
```

**Available Events**:

| Event              | When it fires                          |
|--------------------|----------------------------------------|
| `PreToolUse`       | Before Claude uses any tool            |
| `PostToolUse`      | After Claude uses any tool             |
| `PermissionRequest`| When a permission dialog is shown      |
| `UserPromptSubmit` | When user submits a prompt             |
| `Notification`     | When Claude Code sends notifications   |
| `Stop`             | When Claude attempts to stop           |
| `SubagentStop`     | When a subagent attempts to stop       |
| `SessionStart`     | At the beginning of sessions           |
| `SessionEnd`       | At the end of sessions                 |
| `PreCompact`       | Before conversation history compacted  |

**Hook Types**:
- `command`: Execute shell commands or scripts
- `validation`: Validate file contents or project state
- `notification`: Send alerts or status updates

## MCP Servers

Model Context Protocol servers connecting Claude Code with external tools and services.

**Location**: `.mcp.json` in plugin root, or inline in plugin.json

**Format**: Standard MCP server configuration

```json
{
  "mcpServers": {
    "plugin-database": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/db-server",
      "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"],
      "env": {
        "DB_PATH": "${CLAUDE_PLUGIN_ROOT}/data"
      }
    },
    "plugin-api-client": {
      "command": "npx",
      "args": ["@company/mcp-server", "--plugin-mode"],
      "cwd": "${CLAUDE_PLUGIN_ROOT}"
    }
  }
}
```

**Integration**:
- Plugin MCP servers start automatically when plugin is enabled
- Servers appear as standard MCP tools in Claude's toolkit
- Server capabilities integrate with Claude's existing tools
- Plugin servers configured independently of user MCP servers
