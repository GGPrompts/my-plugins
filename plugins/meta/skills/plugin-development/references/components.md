# Plugin Components Reference

Plugins can provide five types of components: commands, agents, skills, hooks, and MCP servers.

## Commands

Slash commands that integrate with Claude Code's command system.

**Location**: `commands/` directory in plugin root

**File format**: Markdown files with YAML frontmatter

```markdown
---
description: Deploy to production environment
argument-hint: "[environment]"
model: sonnet
allowed-tools:
  - Bash
  - Read
hooks:
  PostToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/scripts/notify.sh"
---

# Deploy Command

Instructions for the deployment workflow...
```

**Frontmatter Fields**:

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `description` | Yes | string | Brief help text (<60 chars) |
| `argument-hint` | No | string | Document expected arguments |
| `model` | No | string | Override model for this command |
| `allowed-tools` | No | list | Restrict tools (supports YAML lists) |
| `context` | No | string | `fork` to run in forked sub-agent |
| `agent` | No | string | Agent type for execution |
| `hooks` | No | object | Command-scoped hooks |
| `disable-model-invocation` | No | bool | Prevent SlashCommand tool calls |

**Dynamic Arguments**:
- `$ARGUMENTS` - All arguments as string
- `$1`, `$2`, `$3` - Positional arguments
- `@$1` - Include file contents

**Features**:
- Commands appear in `/` autocomplete menu (anywhere in input)
- Can include arguments: `/plugin:deploy staging`
- Namespaced as `plugin-name:command-name` based on subdirectories
- Claude can invoke via SlashCommand tool

## Agents

Specialized subagents for specific tasks that Claude can invoke automatically.

**Location**: `agents/` directory in plugin root

**File format**: Markdown files with YAML frontmatter

```markdown
---
name: agent-name
description: "Use this agent when [triggers]. Invoke with phrases like '[examples]'."
model: sonnet
tools:
  - Read
  - Grep
  - Glob
  - Bash
skills:
  - skill-name
---

# Agent Name

System prompt defining agent behavior.

## Capabilities
- What this agent can do
- Specific expertise areas

## Guidelines
- How to approach tasks
- Quality standards to follow

## Output Format
- Expected output structure
```

**Frontmatter Fields**:

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `name` | Yes | string | Unique ID (lowercase, hyphens) |
| `description` | Yes | string | When/why to use, include trigger phrases |
| `tools` | No | list | Restrict to specific tools (omit for all) |
| `model` | No | string | `haiku`, `sonnet`, `opus`, or inherit |
| `permissionMode` | No | string | `default`, `acceptEdits`, `plan`, `bypassPermissions` |
| `skills` | No | list | Auto-load specific skills |
| `disallowedTools` | No | list | Explicitly block specific tools |
| `hooks` | No | object | Agent-scoped hooks (PreToolUse, PostToolUse, Stop) |

**Integration**:
- Claude invokes agents automatically based on description triggers
- Users invoke manually via `claude --agent name` or Task tool
- Agents can load skills for additional context
- Plugin agents work alongside built-in Claude agents

**Usage**:
```bash
# As main agent
claude --agent plugin-validator

# As subagent via Task tool
Task(subagent_type: "plugin-validator", prompt: "Validate my plugin")
```

## Skills

Agent Skills that extend Claude's capabilities. Skills and commands are now unified (v2.1.3).

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
user-invocable: true
model: sonnet
context: fork
allowed-tools:
  - Read
  - Write
  - Bash
hooks:
  PostToolUse:
    - matcher: "Write"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/scripts/validate.sh"
---

# PDF Processor

Instructions for PDF processing workflows...
```

**Frontmatter Fields**:

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `name` | Yes | string | Skill identifier (lowercase, hyphens) |
| `description` | Yes | string | Trigger phrases and usage context |
| `user-invocable` | No | bool | Show in slash command menu (default: true) |
| `model` | No | string | Override model for this skill |
| `context` | No | string | `fork` to run in forked sub-agent |
| `agent` | No | string | Agent type for execution |
| `allowed-tools` | No | list | Restrict tools (supports YAML lists) |
| `hooks` | No | object | Skill-scoped hooks |

**Integration**:
- Skills are automatically discovered when plugin is installed
- **Hot-reload**: Skills in `~/.claude/skills` or `.claude/skills` reload without restart
- Claude autonomously invokes skills based on matching task context
- Skills visible in `/` menu by default (opt-out with `user-invocable: false`)
- Skills show progress while executing (tool uses displayed)
- Skills can include supporting files alongside SKILL.md

## Hooks

Event handlers that respond to Claude Code events automatically.

**Location**: `hooks/hooks.json` in plugin root, inline in plugin.json, or in component frontmatter

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
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format-code.sh",
            "timeout": 30000
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Verify all tests pass before stopping.",
            "model": "haiku"
          }
        ]
      }
    ]
  }
}
```

**Available Events**:

| Event | When it fires | Special Fields |
|-------|---------------|----------------|
| `PreToolUse` | Before Claude uses any tool | Can modify `updatedInput`, return `ask` |
| `PostToolUse` | After Claude uses any tool | Access `tool_use_id` |
| `PermissionRequest` | Permission dialog shown | Can auto-approve/deny |
| `UserPromptSubmit` | User submits a prompt | `additionalContext` in output |
| `Notification` | Notifications sent | Supports `matcher` values |
| `Stop` | Claude attempts to stop | Prompt-based hooks supported |
| `SubagentStop` | Subagent attempts to stop | `agent_id`, `agent_transcript_path` |
| `SubagentStart` | Subagent starts | - |
| `SessionStart` | Session begins | `agent_type` if `--agent` used |
| `SessionEnd` | Session ends | `systemMessage` supported |
| `PreCompact` | Before history compacted | - |

**Hook Types**:
- `command`: Execute shell commands or scripts
- `prompt`: LLM-driven evaluation (can specify `model`)

**Hook Configuration**:

| Field | Type | Description |
|-------|------|-------------|
| `matcher` | string | Tool/event pattern (regex, `*` wildcard) |
| `timeout` | number | Timeout in ms (default: 10 minutes) |
| `once` | bool | Run only once per session |
| `model` | string | Model for prompt-based hooks |

**Environment Variables**:
- `${CLAUDE_PLUGIN_ROOT}` - Plugin directory path
- `$CLAUDE_PROJECT_DIR` - Project root

**Hook Output (JSON)**:
```json
{
  "continue": true,
  "suppressOutput": false,
  "systemMessage": "Context for Claude",
  "updatedInput": { }
}
```

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
