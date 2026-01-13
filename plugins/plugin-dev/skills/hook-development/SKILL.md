---
name: hook-development
description: This skill should be used when the user asks to "create a hook", "add PreToolUse hook", "configure hooks.json", or mentions hook events, PostToolUse, SessionStart, Stop, or UserPromptSubmit.
---

# Hook Development

Hooks enable event-driven automation in Claude Code plugins for validation, policy enforcement, context loading, and workflow integration.

## Hook Types

**Prompt-Based (Recommended)**
- LLM-driven decisions with context awareness
- Supports: Stop, SubagentStop, UserPromptSubmit, PreToolUse

**Command**
- Execute bash for deterministic checks
- Use `${CLAUDE_PLUGIN_ROOT}` for portable paths

## Configuration

**Plugin format** (`hooks/hooks.json`):
```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "bash ${CLAUDE_PLUGIN_ROOT}/scripts/validate.sh",
        "timeout": 30
      }]
    }]
  }
}
```

**Settings format** (`.claude/settings.json`):
```json
{
  "PreToolUse": [{
    "matcher": "Write",
    "hooks": [{ "type": "command", "command": "..." }]
  }]
}
```

## Hook Events

| Event | Purpose |
|-------|---------|
| `PreToolUse` | Approve/deny/modify tool calls before execution |
| `PostToolUse` | React to tool results, provide feedback |
| `Stop` | Validate main agent completion |
| `SubagentStop` | Ensure subagent task completion |
| `UserPromptSubmit` | Add context or block prompts |
| `SessionStart` | Load context, set environment |
| `SessionEnd` | Cleanup, state preservation |
| `PreCompact` | Context preservation before compaction |
| `Notification` | Handle notifications |

## Matchers

- Exact: `"Write"`
- Multiple: `"Read|Write|Edit"`
- Wildcard: `"*"`
- Regex: `"mcp__.*__delete.*"`

## Output Structure

```json
{
  "continue": true,
  "suppressOutput": false,
  "systemMessage": "Context for Claude"
}
```

Exit codes: `0` (success), `2` (blocking error), other (non-blocking)

## Environment Variables

Available in command hooks:
- `$CLAUDE_PROJECT_DIR` - Project root
- `$CLAUDE_PLUGIN_ROOT` - Plugin directory
- `$CLAUDE_ENV_FILE` - Persist vars (SessionStart only)

## Security

- Validate all inputs
- Check for path traversal (`..` detection)
- Protect sensitive files (`.env`, credentials)
- Quote all bash variables: `"$variable"`
- Set appropriate timeouts (default 60s)

## Best Practices

**DO:**
- Use prompt-based hooks for complex logic
- Use `${CLAUDE_PLUGIN_ROOT}` consistently
- Return structured JSON output
- Test thoroughly before deployment

**DON'T:**
- Hardcode paths
- Trust unvalidated input
- Create long-running hooks
- Rely on execution ordering (hooks run in parallel)

## Example: PreToolUse Validation

```bash
#!/bin/bash
# ${CLAUDE_PLUGIN_ROOT}/scripts/validate-write.sh

FILE_PATH="$1"

# Block writes to sensitive files
if [[ "$FILE_PATH" == *".env"* ]]; then
  echo '{"continue": false, "systemMessage": "Cannot modify .env files"}'
  exit 2
fi

echo '{"continue": true}'
```

**Note:** Hooks load at session start only. Changes require Claude Code restart.
