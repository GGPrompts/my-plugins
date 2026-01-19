# Hooks Reference

Complete reference for Claude Code hooks system.

## Hook Events

| Event | Fires | Can Block | Use Case |
|-------|-------|-----------|----------|
| `PreToolUse` | Before tool execution | Yes | Validate, modify, or block tool calls |
| `PostToolUse` | After tool completion | No | Log, notify, trigger follow-up |
| `PostToolUseFailure` | After tool fails | No | Error handling, retry logic |
| `PermissionRequest` | Permission dialog shown | Yes | Auto-approve/deny permissions |
| `UserPromptSubmit` | User submits prompt | Yes | Validate input, add context |
| `Notification` | Notifications sent | No | External notifications |
| `Stop` | Claude stops | Yes | Final validation, cleanup |
| `SubagentStop` | Subagent stops | Yes | Subagent validation |
| `SessionStart` | Session begins | No | Initialize state |
| `SessionEnd` | Session ends | No | Cleanup, logging |
| `PreCompact` | Before history compact | No | State preservation |

## Configuration Locations

| Location | File | Use Case |
|----------|------|----------|
| User | `~/.claude/settings.json` | Personal hooks |
| Project | `.claude/settings.json` | Team hooks |
| Local | `.claude/settings.local.json` | Gitignored hooks |
| Plugin | `hooks/hooks.json` | Plugin hooks |
| Component | SKILL.md/agent frontmatter | Scoped hooks |

## Hook Configuration Structure

### Plugin Format (`hooks/hooks.json`)

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/validate.sh",
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
            "prompt": "Review changes for security issues: $ARGUMENTS",
            "timeout": 60000
          }
        ]
      }
    ]
  }
}
```

### Settings Format (`.claude/settings.json`)

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          { "type": "command", "command": "./scripts/check.sh" }
        ]
      }
    ]
  }
}
```

## Matcher Patterns

```javascript
// Exact match
"matcher": "Write"

// Multiple tools (regex OR)
"matcher": "Write|Edit"

// All tools starting with
"matcher": "Bash.*"

// MCP tools
"matcher": "mcp__.*__delete.*"

// All tools (omit matcher)
// hooks apply to all events of that type
```

## Hook Types

### Command Hook

```json
{
  "type": "command",
  "command": "${CLAUDE_PLUGIN_ROOT}/scripts/validate.sh",
  "timeout": 30000
}
```

**Environment variables available:**
- `$CLAUDE_PROJECT_DIR` - Project directory
- `$CLAUDE_PLUGIN_ROOT` - Plugin directory
- `$CLAUDE_ENV_FILE` - Persist vars (SessionStart only)
- Tool input passed as JSON to stdin

**Exit codes:**
- `0` - Success, continue
- `2` - Error, feed message to Claude (blocking)
- Other - Non-blocking error

### Prompt Hook

```json
{
  "type": "prompt",
  "prompt": "Evaluate if this is safe: $ARGUMENTS",
  "timeout": 60000
}
```

`$ARGUMENTS` is replaced with tool input or event data.

## PreToolUse Response Format

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Input validated successfully",
    "updatedInput": {
      "file_path": "/sanitized/path.txt"
    }
  },
  "systemMessage": "Optional message for Claude"
}
```

**Permission decisions:**
- `allow` - Proceed with tool call
- `deny` - Block tool call
- `ask` - Show permission dialog

## Component-Scoped Hooks

In SKILL.md or agent frontmatter:

```yaml
---
name: my-skill
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/scripts/validate.sh"
          once: true  # Only run once per session
  Stop:
    - hooks:
        - type: prompt
          prompt: "Verify task completion: $ARGUMENTS"
---
```

**Scoped hooks:**
- Activate only when component is loaded
- Clean up when component completes
- Support `once: true` for single execution

## Example Scripts

### PreToolUse Validation

```bash
#!/bin/bash
# ${CLAUDE_PLUGIN_ROOT}/scripts/validate-write.sh

# Read JSON input from stdin
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.file_path')

# Block writes to sensitive files
if [[ "$FILE_PATH" == *".env"* ]]; then
  echo '{"continue": false, "systemMessage": "Cannot modify .env files"}'
  exit 2
fi

# Allow with message
echo '{"continue": true, "systemMessage": "Write validated"}'
exit 0
```

### SessionStart Context Loading

```bash
#!/bin/bash
# Load project context at session start

PROJECT_INFO=$(cat package.json 2>/dev/null | jq '{name, version, scripts}')

echo "{\"systemMessage\": \"Project: $PROJECT_INFO\"}"
exit 0
```

## Output Structure

Standard hook output:

```json
{
  "continue": true,
  "suppressOutput": false,
  "systemMessage": "Context for Claude"
}
```

## Security Considerations

- Hooks run with current user credentials
- Validate all inputs from stdin
- Check for path traversal (`..` detection)
- Protect sensitive files (`.env`, credentials)
- Quote all bash variables: `"$variable"`
- Set appropriate timeouts (default 60s)
- Test hooks in isolation before deployment

## Important Notes

- **Hooks load at session start only** - Changes require Claude Code restart
- **Hooks run in parallel** - Don't rely on execution ordering
- **Timeout default is 60 seconds** - Set explicit timeout for long operations
- **Use `${CLAUDE_PLUGIN_ROOT}`** - Never hardcode paths

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Hook not firing | Check matcher pattern, restart Claude |
| Hook blocking unexpectedly | Check exit codes (2 = blocking error) |
| Path resolution errors | Use `${CLAUDE_PLUGIN_ROOT}` |
| Timeout errors | Increase timeout or optimize script |
