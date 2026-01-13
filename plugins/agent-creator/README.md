# Agent Creator Plugin

Create effective Claude Code agents with specialized prompts and tool configurations.

## Overview

The Agent Creator plugin helps you build spawnable subagents:
- **Agent patterns** - System prompts, tool restrictions, model selection
- **Opus prompting** - Best practices for Opus model agents
- **Tool catalog** - Complete reference for available tools
- **Templates** - Pre-built agent templates for common use cases

## Installation

```bash
cp -r my-plugins/plugins/agent-creator ~/.claude/plugins/
```

## Skills

| Skill | Purpose |
|-------|---------|
| `agent-design` | Complete guide for designing effective agents |

## Agents

| Agent | Purpose |
|-------|---------|
| `agent-creator` | Create new agents from requirements |

## Templates

Pre-built agent templates in `assets/templates/`:

| Template | Purpose |
|----------|---------|
| `code-reviewer.md` | Code review specialist |
| `frontend-specialist.md` | Frontend development expert |
| `prompt-engineer.md` | Prompt optimization specialist |
| `researcher.md` | Research and exploration agent |

## Scripts

| Script | Purpose |
|--------|---------|
| `init_agent.py` | Initialize a new agent file |

## Quick Start

```bash
# Use the agent to create a new agent
# Task tool with subagent_type: "agent-creator:agent-creator"

# Or manually create agents/<name>.md with frontmatter:
---
name: my-agent
description: What this agent does
tools:
  - Read
  - Glob
  - Grep
model: sonnet
---

# Agent instructions here...
```

## Agent Structure

```yaml
---
name: agent-name
description: Brief description
tools:              # Restrict available tools
  - Read
  - Write
  - Bash
model: haiku        # sonnet, opus, or haiku
---

# Agent Name

System prompt and instructions...
```

## License

MIT License
