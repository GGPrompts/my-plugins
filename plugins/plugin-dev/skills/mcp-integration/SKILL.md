---
name: mcp-integration
description: This skill should be used when the user asks to "add MCP server", "configure .mcp.json", "integrate external API", or mentions Model Context Protocol, stdio server, SSE server, or MCP tools.
---

# MCP Integration

Model Context Protocol (MCP) enables Claude Code plugins to connect with external services and APIs through structured tool access.

## Configuration Methods

**Method 1: Dedicated .mcp.json (Recommended)**
```json
{
  "mcpServers": {
    "server-name": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/servers/server.js"],
      "env": {
        "API_KEY": "${API_KEY}"
      }
    }
  }
}
```

**Method 2: Inline in plugin.json**
```json
{
  "name": "my-plugin",
  "mcpServers": {
    "server-name": { ... }
  }
}
```

## Server Types

| Type | Use Case | Example |
|------|----------|---------|
| **stdio** | Local process | Custom tools, local APIs |
| **SSE** | Hosted servers with OAuth | Asana, GitHub, etc. |
| **HTTP** | REST API with tokens | Custom backends |
| **WebSocket** | Real-time bidirectional | Streaming data |

### stdio (Local Process)

```json
{
  "mcpServers": {
    "my-tools": {
      "command": "python",
      "args": ["${CLAUDE_PLUGIN_ROOT}/server.py"],
      "env": { "DEBUG": "true" }
    }
  }
}
```

### SSE (Server-Sent Events)

```json
{
  "mcpServers": {
    "github": {
      "type": "sse",
      "url": "https://mcp.github.com/sse"
    }
  }
}
```

### HTTP (REST)

```json
{
  "mcpServers": {
    "api": {
      "type": "http",
      "url": "https://api.example.com/mcp",
      "headers": {
        "Authorization": "Bearer ${API_TOKEN}"
      }
    }
  }
}
```

## Tool Naming

MCP tools follow this pattern:
```
mcp__plugin_<plugin-name>_<server-name>__<tool-name>
```

Pre-allow specific tools in command frontmatter:
```yaml
allowed-tools: mcp__plugin_my-plugin_server__specific-tool
```

## Security Best Practices

- Use HTTPS/WSS for connections
- Store tokens in environment variables (never hardcode)
- Pre-allow only necessary MCP tools
- Document required env vars in README
- Let OAuth handle auth flows for SSE

## Lifecycle

1. Plugin loads
2. MCP configuration parsed
3. Server process starts / connection established
4. Tools discovered and registered
5. Tools available with `mcp__plugin_` prefix

## Testing

```bash
# Verify server appears
/mcp

# Debug logs
claude --debug

# Test tool calls
# Use specific tool in conversation
```

## Environment Variables

Always use for portability:
- `${CLAUDE_PLUGIN_ROOT}` - Plugin directory
- `${API_KEY}`, `${TOKEN}` - Secrets from user environment
