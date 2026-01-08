# MCP Server Configuration

Add external tools and services to Codex via Model Context Protocol (MCP).

## Adding Servers via CLI

### Basic Add
```bash
codex mcp add <server-name> -- <command> [args...]
```

### With Environment Variables
```bash
codex mcp add myserver --env API_KEY=xxx --env DEBUG=true -- node server.js
```

### Examples
```bash
# Context7 for documentation
codex mcp add context7 -- npx -y @upstash/context7-mcp

# Custom Node.js server
codex mcp add mytools -- node /path/to/server.js

# Python server
codex mcp add analyzer -- python -m my_mcp_server
```

## Managing Servers

```bash
# List configured servers
codex mcp list

# Remove a server
codex mcp remove <server-name>

# View in TUI
# Type /mcp while in Codex
```

## Configuration via config.toml

### STDIO Servers (Local Process)

```toml
[mcp_servers.context7]
command = "npx"
args = ["-y", "@upstash/context7-mcp"]

[mcp_servers.custom]
command = "node"
args = ["/path/to/server.js", "--port", "3000"]
cwd = "/working/directory"
env = { API_KEY = "xxx", DEBUG = "true" }
env_vars = ["HOME", "PATH"]  # Forward from shell
```

**STDIO Options:**
| Option | Type | Description |
|--------|------|-------------|
| `command` | string | Required. Startup command |
| `args` | array | Command arguments |
| `cwd` | string | Working directory |
| `env` | table | Environment variables |
| `env_vars` | array | Variables to forward from shell |

### HTTP Servers (Remote)

```toml
[mcp_servers.figma]
url = "https://mcp.figma.com/mcp"
bearer_token_env_var = "FIGMA_OAUTH_TOKEN"

[mcp_servers.custom_api]
url = "https://api.example.com/mcp"
http_headers = { "X-Custom-Header" = "value" }
env_http_headers = { "Authorization" = "API_TOKEN" }
```

**HTTP Options:**
| Option | Type | Description |
|--------|------|-------------|
| `url` | string | Required. Server URL |
| `bearer_token_env_var` | string | Env var for Bearer token |
| `http_headers` | table | Static headers |
| `env_http_headers` | table | Headers from env vars |

### Universal Options

```toml
[mcp_servers.myserver]
command = "node"
args = ["server.js"]

# Enable/disable
enabled = true

# Timeouts
startup_timeout_sec = 10  # Default: 10
tool_timeout_sec = 60     # Default: 60

# Tool filtering
enabled_tools = ["search", "fetch"]  # Allow-list
disabled_tools = ["delete", "admin"]  # Deny-list
```

## Tool Filtering

Control which tools from an MCP server are available:

```toml
[mcp_servers.powerful_server]
command = "node"
args = ["server.js"]

# Only allow safe read operations
enabled_tools = ["read", "search", "list"]

# Or block dangerous operations
disabled_tools = ["delete", "write", "admin"]
```

**Note:** `enabled_tools` and `disabled_tools` are mutually exclusive.

## Complete Example

```toml
# ~/.codex/config.toml

# Documentation lookup
[mcp_servers.context7]
command = "npx"
args = ["-y", "@upstash/context7-mcp"]
startup_timeout_sec = 15

# Database access (restricted)
[mcp_servers.postgres]
command = "npx"
args = ["-y", "@modelcontextprotocol/server-postgres"]
env = { DATABASE_URL = "${DATABASE_URL}" }
enabled_tools = ["query", "describe"]
disabled_tools = ["execute", "drop"]

# Design tool (HTTP)
[mcp_servers.figma]
url = "https://mcp.figma.com/mcp"
bearer_token_env_var = "FIGMA_OAUTH_TOKEN"
tool_timeout_sec = 120

# Disabled but kept in config
[mcp_servers.experimental]
command = "node"
args = ["experimental-server.js"]
enabled = false
```

## Troubleshooting

**Server not starting:**
- Check `startup_timeout_sec` (increase for slow servers)
- Verify command exists in PATH
- Check logs for error messages

**Tools not appearing:**
- Verify server is enabled (`enabled = true`)
- Check `enabled_tools`/`disabled_tools` filters
- Use `/mcp` in TUI to see registered tools

**Authentication failures:**
- Verify environment variables are set
- Check `bearer_token_env_var` points to correct var
- Ensure tokens haven't expired
