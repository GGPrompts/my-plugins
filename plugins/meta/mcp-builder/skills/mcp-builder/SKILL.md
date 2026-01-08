---
name: mcp-builder
description: Guide for creating high-quality MCP (Model Context Protocol) servers that enable LLMs to interact with external services through well-designed tools. Use when building MCP servers to integrate external APIs or services, whether in Python (FastMCP) or Node/TypeScript (MCP SDK).
license: Complete terms in LICENSE.txt
---

# MCP Server Development Guide

Create high-quality MCP servers that enable LLMs to effectively interact with external services. Quality is measured by how well the server enables LLMs to accomplish real-world tasks.

## When to Use

- Building new MCP servers to integrate APIs or services
- Improving existing MCP server tool design
- Understanding agent-centric design principles
- Creating evaluations for MCP servers

## Quick Reference

| Topic | Reference |
|-------|-----------|
| Universal guidelines, naming, response formats | [references/mcp_best_practices.md](./references/mcp_best_practices.md) |
| Python/FastMCP implementation | [references/python_mcp_server.md](./references/python_mcp_server.md) |
| Node/TypeScript implementation | [references/node_mcp_server.md](./references/node_mcp_server.md) |
| Creating evaluation questions | [references/evaluation.md](./references/evaluation.md) |

## Agent-Centric Design Principles

### Build for Workflows, Not API Endpoints

- Don't simply wrap API endpoints - build workflow tools
- Consolidate related operations (e.g., `schedule_event` checks availability AND creates event)
- Focus on tools that complete tasks, not individual API calls

### Optimize for Limited Context

- Return high-signal information, not exhaustive data dumps
- Provide "concise" vs "detailed" response format options
- Default to human-readable identifiers (names over IDs)
- Treat agent context budget as scarce resource

### Design Actionable Error Messages

- Guide agents toward correct usage patterns
- Suggest next steps: "Try using filter='active_only' to reduce results"
- Make errors educational, not just diagnostic

### Use Evaluation-Driven Development

- Create realistic evaluation scenarios early
- Let agent feedback drive tool improvements
- Prototype quickly and iterate based on agent performance

## Development Workflow

### Phase 1: Research and Planning

1. **Study MCP Protocol**: Fetch `https://modelcontextprotocol.io/llms-full.txt`
2. **Load best practices**: Read [references/mcp_best_practices.md](./references/mcp_best_practices.md)
3. **Study target API**: Read ALL available documentation
4. **Create implementation plan**: Tool selection, shared utilities, I/O design, error handling

### Phase 2: Implementation

1. **Set up project** - Python: single `.py` or modules; TypeScript: proper project structure
2. **Implement infrastructure** - API helpers, error handling, response formatting, pagination
3. **Implement tools** - Input schemas (Pydantic/Zod), docstrings, tool logic, annotations

Load language-specific guide:
- Python: [references/python_mcp_server.md](./references/python_mcp_server.md)
- TypeScript: [references/node_mcp_server.md](./references/node_mcp_server.md)

### Phase 3: Review and Refine

1. **Code quality review** - DRY, composability, consistency, error handling, type safety
2. **Test and build** - Use evaluation harness or tmux (servers are long-running processes)
3. **Quality checklist** - See language-specific guide

### Phase 4: Create Evaluations

Create 10 complex, realistic questions to test MCP server effectiveness.

Load [references/evaluation.md](./references/evaluation.md) for complete guidelines.

**Question requirements:**
- Independent, read-only, complex, realistic
- Verifiable with single clear answer
- Stable (won't change over time)

## External Resources

- **MCP Protocol**: `https://modelcontextprotocol.io/llms-full.txt`
- **Python SDK**: `https://raw.githubusercontent.com/modelcontextprotocol/python-sdk/main/README.md`
- **TypeScript SDK**: `https://raw.githubusercontent.com/modelcontextprotocol/typescript-sdk/main/README.md`
