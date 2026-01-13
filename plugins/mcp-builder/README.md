# MCP Builder Plugin

Build MCP servers to integrate external APIs with Claude.

## Overview

The MCP Builder plugin helps you create Model Context Protocol servers:
- **Python FastMCP** - Quick MCP servers with FastMCP framework
- **Node SDK** - TypeScript/JavaScript MCP servers
- **Best Practices** - Tool design, error handling, security
- **Evaluation** - Testing and validating MCP servers

## Installation

```bash
cp -r my-plugins/plugins/mcp-builder ~/.claude/plugins/
```

## Skills

| Skill | Purpose |
|-------|---------|
| `mcp-servers` | Complete guide for building MCP servers |

## Reference Topics

| Reference | Content |
|-----------|---------|
| `python_mcp_server.md` | FastMCP Python server patterns |
| `node_mcp_server.md` | Node.js SDK server patterns |
| `mcp_best_practices.md` | Tool design and security |
| `evaluation.md` | Testing MCP servers |

## Scripts

| Script | Purpose |
|--------|---------|
| `connections.py` | MCP connection utilities |
| `evaluation.py` | Server evaluation helpers |

## Quick Start

```bash
# Get MCP building guidance
/mcp-builder:mcp-servers

# Python FastMCP example:
from fastmcp import FastMCP

mcp = FastMCP("My Server")

@mcp.tool()
def my_tool(param: str) -> str:
    """Tool description."""
    return f"Result: {param}"
```

## MCP Server Structure

```
my-mcp-server/
├── server.py          # Main server file
├── tools/             # Tool implementations
├── resources/         # MCP resources
└── pyproject.toml     # Dependencies
```

## License

MIT License
