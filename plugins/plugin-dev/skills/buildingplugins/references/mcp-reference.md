# MCP Reference

Complete reference for Model Context Protocol (MCP) server configuration.

## Server Types

### Stdio Server (Local Process)

```json
{
  "mcpServers": {
    "my-server": {
      "type": "stdio",
      "command": "node",
      "args": ["./server.js", "--port", "3000"],
      "env": {
        "API_KEY": "${API_KEY}",
        "DEBUG": "true"
      },
      "cwd": "${CLAUDE_PLUGIN_ROOT}/servers"
    }
  }
}
```

### HTTP Server (Remote)

```json
{
  "mcpServers": {
    "remote-server": {
      "type": "http",
      "url": "https://api.example.com/mcp",
      "headers": {
        "Authorization": "Bearer ${API_TOKEN}"
      }
    }
  }
}
```

### SSE Server (Deprecated)

```json
{
  "mcpServers": {
    "sse-server": {
      "type": "sse",
      "url": "https://api.example.com/sse"
    }
  }
}
```

**Note:** SSE is deprecated. Use HTTP instead.

## Configuration Locations

| Location | File | Priority |
|----------|------|----------|
| Managed | `managed-mcp.json` | 1 (highest) |
| Project | `.mcp.json` | 2 |
| User | `~/.claude/mcp.json` | 3 |
| Plugin | `.mcp.json` | 4 |

## Environment Variable Substitution

```json
{
  "mcpServers": {
    "server": {
      "command": "${CLAUDE_PLUGIN_ROOT}/bin/server",
      "env": {
        "DB_URL": "${DATABASE_URL}",
        "PORT": "${PORT:-3000}",
        "DEBUG": "${DEBUG:-false}"
      }
    }
  }
}
```

**Available variables:**
- `${VARIABLE}` - Direct substitution
- `${VARIABLE:-default}` - With default value
- `${CLAUDE_PLUGIN_ROOT}` - Plugin installation directory
- `${CLAUDE_PROJECT_DIR}` - Current project directory

## Plugin MCP Configuration

### Separate File (`.mcp.json` at plugin root)

```json
{
  "mcpServers": {
    "plugin-server": {
      "type": "stdio",
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/main.js",
      "args": [
        "--config",
        "${CLAUDE_PLUGIN_ROOT}/config.json"
      ],
      "env": {
        "DATA_DIR": "${CLAUDE_PROJECT_DIR}/.data"
      }
    }
  }
}
```

### Inline in plugin.json

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "mcpServers": {
    "inline-server": {
      "type": "stdio",
      "command": "python",
      "args": ["${CLAUDE_PLUGIN_ROOT}/server.py"]
    }
  }
}
```

## MCP CLI Usage

```bash
# List MCP servers
mcp-cli servers

# List tools from all servers
mcp-cli tools

# List tools from specific server
mcp-cli tools my-server

# Get tool schema (REQUIRED before calling)
mcp-cli info my-server/tool-name

# Call a tool
mcp-cli call my-server/tool-name '{"param": "value"}'

# Read a resource
mcp-cli read my-server/resource-name

# Search tools
mcp-cli grep "search pattern"
```

## Server Development

### Basic MCP Server (Node.js)

```javascript
import { Server } from '@modelcontextprotocol/sdk/server';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio';

const server = new Server({
  name: 'my-server',
  version: '1.0.0'
});

server.setRequestHandler('tools/list', async () => ({
  tools: [{
    name: 'my-tool',
    description: 'What this tool does',
    inputSchema: {
      type: 'object',
      properties: {
        param: { type: 'string', description: 'Parameter description' }
      },
      required: ['param']
    }
  }]
}));

server.setRequestHandler('tools/call', async (request) => {
  const { name, arguments: args } = request.params;
  // Handle tool call
  return { content: [{ type: 'text', text: 'Result' }] };
});

const transport = new StdioServerTransport();
await server.connect(transport);
```

### Basic MCP Server (Python with FastMCP)

```python
from fastmcp import FastMCP

mcp = FastMCP("my-server")

@mcp.tool()
def my_tool(param: str) -> str:
    """What this tool does.

    Args:
        param: Parameter description
    """
    return f"Result: {param}"

if __name__ == "__main__":
    mcp.run()
```

## Best Practices

1. **Minimal Permissions** - Only grant necessary access
2. **Secure Secrets** - Use environment variables, never hardcode
3. **Fast Responses** - MCP servers should respond quickly
4. **Error Handling** - Return clear error messages
5. **Documentation** - Document required environment variables
6. **Testing** - Test locally before distribution
7. **Portability** - Use `${CLAUDE_PLUGIN_ROOT}` for paths

## Troubleshooting

```bash
# Check if server is running
mcp-cli servers

# Test server connection
mcp-cli tools my-server

# Debug server startup
DEBUG=* mcp-cli tools my-server

# Check server logs
# Stderr from stdio servers goes to Claude's log
```

| Issue | Solution |
|-------|----------|
| Server not appearing | Check config path and JSON syntax |
| Connection failures | Verify command exists and is executable |
| Environment variables empty | Check variable names and shell export |
| Tools not found | Use `mcp-cli tools server-name` to debug |
