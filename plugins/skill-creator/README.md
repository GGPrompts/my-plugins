# Skill Creator Plugin

Create effective Claude Code skills with proper structure and patterns.

## Overview

The Skill Creator plugin helps you build skills that extend Claude's capabilities:
- **Skill anatomy** - SKILL.md structure, frontmatter, references
- **Creation process** - Step-by-step workflow for new skills
- **Quality patterns** - Best practices for trigger phrases, tool restrictions
- **Validation** - Scripts to verify skill structure

## Installation

```bash
cp -r my-plugins/plugins/skill-creator ~/.claude/plugins/
```

## Commands

| Command | Purpose |
|---------|---------|
| `/skill-creator:create` | Create a new skill interactively |

## Skills

| Skill | Purpose |
|-------|---------|
| `skill-creation` | Complete guide for creating effective skills |
| `skill-commands` | Quick reference for skill slash commands |

## Agents

| Agent | Purpose |
|-------|---------|
| `skill-reviewer` | Review skill quality and adherence to best practices |

## Scripts

| Script | Purpose |
|--------|---------|
| `init_skill.py` | Initialize a new skill directory structure |
| `package_skill.py` | Package skill for distribution |
| `quick_validate.py` | Validate skill structure and references |

## Hooks

The plugin includes a `skill-eval.sh` hook for runtime skill evaluation.

## Quick Start

```bash
# Create a new skill interactively
/skill-creator:create

# Or manually:
mkdir -p plugins/my-plugin/skills/my-skill/references
# Create SKILL.md with frontmatter
```

## Skill Structure

```
skills/
└── my-skill/
    ├── SKILL.md           # Main skill file with frontmatter
    ├── references/        # Supporting documentation
    │   └── patterns.md
    └── scripts/           # Optional helper scripts
        └── helper.py
```

## License

MIT License
