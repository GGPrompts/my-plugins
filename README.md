# My GGPrompts Toolkit

This repository contains my curated Claude Code plugins, synced from [GGPrompts](https://ggprompts.com).

## Structure

This plugin follows the official Anthropic plugin format:

```
.claude-plugin/
  plugin.json       # Plugin manifest
commands/           # Slash commands
agents/             # Subagents
skills/             # Skills (each in its own directory)
hooks/              # Hook configurations
```

## Usage

Clone this repo and load it in Claude Code:

```bash
git clone https://github.com/YOUR_USERNAME/my-gg-plugins.git
cd my-gg-plugins
claude plugin load .
```

Or add it to your Claude Code settings to auto-load on startup.

## Managing Your Toolkit

Visit [ggprompts.com/claude-code/toolkit](https://ggprompts.com/claude-code/toolkit) to:
- Browse and add components to your toolkit
- Enable/disable specific plugins
- Sync changes to this repository

---

*Managed by [GGPrompts](https://ggprompts.com) - The control plane for your Claude Code setup*
