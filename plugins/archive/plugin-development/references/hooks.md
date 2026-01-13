# Hook Development Reference

Hooks are event-driven automation scripts that execute in response to Claude Code events.

## Hook Types

### Command Hooks
Execute shell commands for deterministic checks and file operations.

```json
{
  "type": "command",
  "command": "${CLAUDE_PLUGIN_ROOT}/scripts/lint.sh",
  "timeout": 30000
}
```

### Prompt Hooks (Recommended)
Use LLM-driven decision-making for context-aware validation.

```json
{
  "type": "prompt",
  "prompt": "Verify that all changes follow the project's coding standards.",
  "model": "haiku"
}
```

Prompt hooks are more flexible and handle edge cases better than bash scripting.

## Hook Configuration Locations

| Location | Scope | Use Case |
|----------|-------|----------|
| `hooks/hooks.json` | Plugin | Plugin-wide hooks |
| `plugin.json` (inline) | Plugin | Simple plugins |
| Agent frontmatter | Agent | Agent-scoped hooks |
| Skill frontmatter | Skill | Skill-scoped hooks |
| Command frontmatter | Command | Command-scoped hooks |
| `.claude/settings.json` | Project | Project-specific hooks |
| `~/.claude/settings.json` | User | User-wide hooks |

## All Hook Events

### Tool Events

#### PreToolUse
Fires before Claude uses any tool. Can approve, deny, or modify input.

```json
{
  "PreToolUse": [{
    "matcher": "Write|Edit",
    "hooks": [{
      "type": "command",
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/validate-path.sh"
    }]
  }]
}
```

**Special capabilities:**
- Return `updatedInput` to modify tool parameters
- Return `ask` to request user confirmation while still modifying input
- Block dangerous operations before they execute

#### PostToolUse
Fires after Claude uses any tool.

```json
{
  "PostToolUse": [{
    "matcher": "Bash",
    "hooks": [{
      "type": "command",
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/log-command.sh"
    }]
  }]
}
```

**Input includes:** `tool_use_id` for correlation

### Session Events

#### SessionStart
Fires at the beginning of a session. Good for environment setup.

```json
{
  "SessionStart": [{
    "hooks": [{
      "type": "command",
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/setup-env.sh"
    }]
  }]
}
```

**Input includes:** `agent_type` if `--agent` flag was used

#### SessionEnd
Fires at the end of a session. Good for cleanup and state preservation.

```json
{
  "SessionEnd": [{
    "hooks": [{
      "type": "command",
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/save-state.sh"
    }]
  }]
}
```

**Output supports:** `systemMessage` field

### Stop Events

#### Stop
Fires when Claude attempts to complete a task.

```json
{
  "Stop": [{
    "hooks": [{
      "type": "prompt",
      "prompt": "Verify all tests pass and code is committed before stopping.",
      "model": "haiku"
    }]
  }]
}
```

Prompt-based stop hooks can force Claude to continue if criteria aren't met.

#### SubagentStop
Fires when a subagent attempts to complete.

```json
{
  "SubagentStop": [{
    "hooks": [{
      "type": "command",
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/validate-subagent.sh"
    }]
  }]
}
```

**Input includes:** `agent_id`, `agent_transcript_path`

#### SubagentStart
Fires when a subagent starts execution.

```json
{
  "SubagentStart": [{
    "hooks": [{
      "type": "command",
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/log-subagent.sh"
    }]
  }]
}
```

### User Events

#### UserPromptSubmit
Fires when user submits a prompt. Good for context injection.

```json
{
  "UserPromptSubmit": [{
    "hooks": [{
      "type": "command",
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/inject-context.sh"
    }]
  }]
}
```

**Output supports:** `additionalContext` in advanced JSON output

#### PermissionRequest
Fires when a permission dialog is shown. Can auto-approve or deny.

```json
{
  "PermissionRequest": [{
    "matcher": "Bash(npm *)",
    "hooks": [{
      "type": "command",
      "command": "echo '{\"decision\": \"allow\"}'"
    }]
  }]
}
```

### Other Events

#### Notification
Fires when Claude Code sends notifications.

```json
{
  "Notification": [{
    "matcher": "completion",
    "hooks": [{
      "type": "command",
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/notify.sh"
    }]
  }]
}
```

Supports `matcher` values for filtering notification types.

#### PreCompact
Fires before conversation history is compacted.

```json
{
  "PreCompact": [{
    "hooks": [{
      "type": "command",
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/preserve-context.sh"
    }]
  }]
}
```

## Hook Configuration Options

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `matcher` | string | `*` | Tool/event pattern (regex supported) |
| `timeout` | number | 600000 | Timeout in ms (10 minutes default) |
| `once` | bool | false | Run only once per session |
| `model` | string | inherit | Model for prompt-based hooks |

## Matcher Patterns

| Pattern | Matches |
|---------|---------|
| `Write` | Exact tool name |
| `Write\|Edit` | Multiple tools (OR) |
| `*` | All tools/events |
| `mcp__.*__delete.*` | Regex pattern |
| `Bash(npm *)` | Bash commands starting with npm |
| `mcp__server__*` | All tools from an MCP server |

## Environment Variables

Available in command hooks:

| Variable | Description |
|----------|-------------|
| `${CLAUDE_PLUGIN_ROOT}` | Plugin directory (for portable paths) |
| `$CLAUDE_PROJECT_DIR` | Project root directory |
| `$CLAUDE_ENV_FILE` | Variable persistence in SessionStart |

## Hook Output Format

Command hooks should output JSON:

```json
{
  "continue": true,
  "suppressOutput": false,
  "systemMessage": "Context message for Claude",
  "updatedInput": {
    "file_path": "/new/path.txt"
  },
  "decision": "allow"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `continue` | bool | Whether to proceed with the operation |
| `suppressOutput` | bool | Hide hook output from display |
| `systemMessage` | string | Message injected into Claude's context |
| `updatedInput` | object | Modified tool input (PreToolUse only) |
| `decision` | string | `allow`, `deny`, or `ask` (PermissionRequest) |
| `additionalContext` | string | Extra context (UserPromptSubmit) |

## Hooks in Component Frontmatter

Agents, skills, and commands can define scoped hooks:

```yaml
---
name: my-skill
description: "..."
hooks:
  PostToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/scripts/format.sh"
  Stop:
    - hooks:
        - type: prompt
          prompt: "Verify changes are complete."
---
```

These hooks only run when the component is active.

## Best Practices

1. **Prefer prompt hooks** for complex logic over command hooks
2. **Use `${CLAUDE_PLUGIN_ROOT}`** for portable paths
3. **Always validate inputs** in command hooks
4. **Quote all bash variables** to prevent injection
5. **Use `once: true`** for one-time setup hooks
6. **Set appropriate timeouts** for long-running operations
7. **Return structured JSON** for predictable behavior
8. **Test hooks with `claude --debug`** to see execution

## Security Considerations

- Implement path traversal detection
- Block sensitive file access patterns
- Validate and sanitize all user input
- Use HTTPS for external URLs
- Never hardcode credentials in hooks

## Debugging

```bash
# Run Claude with debug logging
claude --debug

# Check hook execution in logs
tail -f ~/.claude/logs/debug.log | grep -i hook
```
