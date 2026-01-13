# Opus Agents Plugin

Opus-powered versions of built-in agents for complex implementation work.

## Overview

The Opus Agents plugin provides enhanced agents using the Opus model for tasks requiring deeper reasoning and more sophisticated code generation.

## Installation

```bash
cp -r my-plugins/plugins/opus-agents ~/.claude/plugins/
```

## Agents

| Agent | Purpose |
|-------|---------|
| `general-purpose` | Opus-powered general-purpose agent for complex multi-step tasks |

## Usage

```bash
# Spawn via Task tool
Task(
  subagent_type: "opus-agents:general-purpose",
  prompt: "Implement complex feature X..."
)
```

## When to Use

Use Opus agents for:
- Complex multi-file refactoring
- Architectural decisions requiring deep analysis
- Sophisticated code generation
- Tasks requiring nuanced understanding

Use standard Sonnet agents for:
- Quick searches and lookups
- Simple code modifications
- Routine tasks

## License

MIT License
