# CLAUDE.md - my-plugins

## Overview

A **Claude Code plugin marketplace** - a personal collection of plugins organized by domain for development workflows, browser automation, and specialized tools.

| | |
|--|--|
| **Type** | Plugin Marketplace (multiple plugins) |
| **Structure** | Domain-organized plugins with skills, commands, and agents |

---

## Plugin Structure (IMPORTANT)

This repo uses the **marketplace pattern** - one marketplace containing multiple plugins.

### Directory Layout

```
my-plugins/
├── .claude-plugin/
│   └── marketplace.json         # Lists all plugins
├── plugins/
│   ├── frontend/                # Category: frontend development
│   │   ├── ui-styling/          # Plugin: Tailwind + shadcn/ui
│   │   │   ├── .claude-plugin/
│   │   │   │   └── plugin.json  # Plugin manifest
│   │   │   └── skills/
│   │   │       └── ui-styling/
│   │   │           └── SKILL.md
│   │   └── frontend-design/     # Plugin: production UI
│   │       ├── .claude-plugin/
│   │       │   └── plugin.json
│   │       └── skills/
│   ├── backend/                 # Category: backend development
│   ├── visual/                  # Category: visual/media
│   ├── tools/                   # Category: dev tools
│   ├── terminal/                # Category: terminal utilities
│   ├── specialized/             # Category: domain-specific
│   ├── plugin-dev/              # Meta: plugin creation
│   ├── skill-creator/           # Meta: skill creation
│   ├── agent-creator/           # Meta: agent creation
│   ├── mcp-builder/             # Meta: MCP server building
│   ├── claude-code/             # Meta: Claude Code expertise
│   └── context-engineering/     # Meta: context optimization
└── CLAUDE.md
```

### Critical Rules

1. **Marketplace root has `.claude-plugin/marketplace.json`** - Lists all available plugins
2. **Each plugin has `.claude-plugin/plugin.json`** - Standard portable pattern
3. **Skills are `skills/<name>/SKILL.md`** - One level deep, NOT nested skills inside skills
4. **References are `skills/<name>/references/`** - At same level as SKILL.md
5. **Commands are `commands/<name>.md`** - Markdown files with YAML frontmatter
6. **Agents are `agents/<name>.md`** - Markdown files with YAML frontmatter
7. **Skills hot-reload** - Changes take effect immediately (hooks require restart)

### marketplace.json Format

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "my-plugins",
  "plugins": [
    {
      "name": "ui-styling",
      "description": "Tailwind CSS and shadcn/ui patterns",
      "source": "./plugins/frontend/ui-styling",
      "category": "frontend",
      "keywords": ["tailwind", "css", "shadcn"]
    }
  ]
}
```

### Common Mistakes

| Mistake | Correct |
|---------|---------|
| `plugins/X/plugin.json` (at root) | `plugins/X/.claude-plugin/plugin.json` |
| `skills/parent/skills/child/SKILL.md` | `skills/child/SKILL.md` (flatten) |
| References at plugin root | `skills/<name>/references/` inside skill |
| Individual `plugin.json` per skill | Only one `plugin.json` per plugin |

---

## Plugin Categories

| Category | Plugins | Purpose |
|----------|---------|---------|
| `frontend` | aesthetic, frontend-design, frontend-development, ui-styling, web-frameworks | React, TypeScript, Tailwind, shadcn/ui, Next.js |
| `backend` | backend-development, databases, better-auth, devops, docker-mcp | Node.js, Python, databases, auth, DevOps |
| `visual` | canvas-design, ai-multimodal, media-processing | Canvas, Gemini, FFmpeg, ImageMagick |
| `docs` | document-skills | PDF, Word, presentations, spreadsheets |
| `tools` | debugging, code-review, problem-solving, sequential-thinking, docs-seeker, repomix, validate-plan, codex | Dev tools, debugging, review |
| `terminal` | xterm-js, pmux, brief, wipe, restart, handoff | Terminal utilities, session management |
| `specialized` | bubbletea, shopify, git-commands, google-adk-python | Domain-specific tools |
| `meta` | plugin-dev, skill-creator, agent-creator, mcp-builder, claude-code, context-engineering | Plugin/skill/agent creation |

---

## Skill Invocation Formats

Skills use different invocation formats depending on their scope:

| Scope | Format | Example |
|-------|--------|---------|
| Plugin skills | `/plugin-name:skill-name` | `/ui-styling:ui-styling` |
| Standalone skills | `/skill-name` | `/restart` |

---

## Creating New Plugins

### Quick Start

1. Create plugin directory under appropriate category:
   ```bash
   mkdir -p plugins/frontend/my-plugin/.claude-plugin
   mkdir -p plugins/frontend/my-plugin/skills/my-skill/references
   ```

2. Create `.claude-plugin/plugin.json`:
   ```json
   {
     "$schema": "https://anthropic.com/claude-code/plugin.schema.json",
     "name": "my-plugin",
     "description": "What this plugin does",
     "version": "1.0.0"
   }
   ```

3. Create skill with `SKILL.md`:
   ```markdown
   ---
   name: my-skill
   description: What this skill does
   user-invocable: true
   ---

   # My Skill

   Instructions for Claude when this skill is activated...
   ```

4. Add to `marketplace.json`:
   ```json
   {
     "name": "my-plugin",
     "description": "What this plugin does",
     "source": "./plugins/frontend/my-plugin",
     "category": "frontend",
     "keywords": ["relevant", "keywords"]
   }
   ```

5. Restart Claude Code to load: `/restart`

### Plugin Components

| Component | Location | Purpose |
|-----------|----------|---------|
| Skills | `skills/<name>/SKILL.md` | Specialized knowledge/workflows |
| Commands | `commands/<name>.md` | User-invocable slash commands |
| Agents | `agents/<name>.md` | Spawnable subagents via Task tool |

### SKILL.md Frontmatter

```yaml
---
name: skill-name
description: Brief description (shown in menu)
user-invocable: true           # Show in slash command menu
model: sonnet                  # Optional: sonnet, opus, haiku
tools:                         # Optional: restrict available tools
  - Read
  - Glob
  - Grep
---
```

### Agent Frontmatter

```yaml
---
name: agent-name
description: Brief description
tools:                         # Tools available to this agent
  - Read
  - Write
  - Bash
model: haiku                   # Optional model override
---
```

---

## Installation

This marketplace is installed by symlinking or copying to Claude's plugin directory:

```bash
# Symlink approach (recommended for development)
ln -s ~/plugins/my-plugins ~/.claude/plugins/my-plugins

# Or copy
cp -r ~/plugins/my-plugins ~/.claude/plugins/
```

After installation, restart Claude Code to load plugins.

---

## Development Notes

- Use `/restart` to reload plugins after changes
- Skills hot-reload without restart (hooks require restart)
- Check `/plugin` to see loaded plugins
- Use `/plugin-dev:buildingplugins` for comprehensive plugin creation guidance
- Use `/skill-creator:skill-creation` for skill patterns
- Use `/agent-creator:agent-design` for agent patterns
