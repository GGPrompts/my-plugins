# MCP Servers and Hooks

## MCP Server Configuration

MCP servers connect Claude Code to external tools. Configure in `.mcp.json`:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": { "GITHUB_TOKEN": "your_token" }
    }
  }
}
```

### Common MCP Servers
- **@modelcontextprotocol/server-filesystem**: File system access
- **@modelcontextprotocol/server-github**: GitHub integration
- **@modelcontextprotocol/server-postgres**: PostgreSQL database
- **@modelcontextprotocol/server-brave-search**: Web search
- **@modelcontextprotocol/server-puppeteer**: Browser automation

### Remote MCP Servers

```json
{
  "mcpServers": {
    "remote-service": {
      "url": "https://api.example.com/mcp",
      "headers": { "Authorization": "Bearer token" }
    }
  }
}
```

---

## Hooks System

Hooks execute shell commands in response to events.

### Hook Types
1. **PreToolUse**: Before tool calls
2. **PostToolUse**: After tool calls
3. **UserPromptSubmit**: When user submits prompts
4. **Stop**: When Claude finishes responding

### Configuration

Configure in `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": ["echo 'Running: $TOOL_INPUT'"]
    }],
    "PostToolUse": [{
      "matcher": "Write",
      "hooks": ["./scripts/format-code.sh"]
    }]
  }
}
```

### Environment Variables
- `$TOOL_NAME`: Tool being called
- `$TOOL_INPUT`: JSON of tool arguments
- `$TOOL_OUTPUT`: Result (PostToolUse only)
- `$USER_PROMPT`: Prompt text (UserPromptSubmit only)

### Use Cases
- Code formatting after file writes
- Security validation before bash
- Status tracking and monitoring
- Integration with external systems
