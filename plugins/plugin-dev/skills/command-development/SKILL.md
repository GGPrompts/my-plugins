---
name: command-development
description: This skill should be used when the user asks to "create a command", "add a slash command", "write command frontmatter", or mentions allowed-tools, argument-hint, $ARGUMENTS, or command file format.
---

# Command Development

Slash commands are Markdown files containing prompts that Claude executes during interactive sessions.

## Critical Principle

Commands are **instructions FOR Claude**, not messages to users. Command content becomes Claude's directive about what to do.

## Command Locations

| Location | Scope | Label |
|----------|-------|-------|
| `.claude/commands/` | Project (shared with team) | "project" |
| `~/.claude/commands/` | Personal (everywhere) | "user" |
| `plugin-name/commands/` | Plugin (bundled) | plugin name |

## File Format

```markdown
---
description: Clear, actionable description
allowed-tools: Read, Write, Edit, Bash(git:*)
model: sonnet
argument-hint: [file] [priority]
---

Command instruction content here.
```

## Frontmatter Fields

| Field | Purpose | Example |
|-------|---------|---------|
| `description` | Brief description for `/help` | "Review code for security issues" |
| `allowed-tools` | Restrict tool access | `Read, Write, Bash(git:*)` |
| `model` | Force specific model | `haiku`, `sonnet`, `opus` |
| `argument-hint` | Document expected args | `[file] [priority]` |
| `disable-model-invocation` | Prevent programmatic use | `true` |

## Dynamic Arguments

- `$ARGUMENTS` - All arguments as single string
- `$1`, `$2`, `$3` - Positional arguments
- `@$1` - First argument as file path (contents included)
- `@src/file.js` - Static file reference
- `@${CLAUDE_PLUGIN_ROOT}/config.json` - Plugin resource

**Example:**
```markdown
Review @$1 for security issues with priority $2
```

Usage: `/command file.js high`

## Bash Execution

Execute bash inline for dynamic context:

```markdown
Current branch: `git branch --show-current`
Recent commits:
`git log --oneline -5`

Now review the changes...
```

## Organization

**Flat (5-15 commands):**
```
.claude/commands/
├── build.md
├── test.md
└── deploy.md
```

**Namespaced (15+ commands):**
```
.claude/commands/
├── ci/
│   ├── build.md
│   └── test.md
└── git/
    └── commit.md
```

## Best Practices

1. Single responsibility per command
2. Clear, self-explanatory descriptions
3. Explicit tool dependencies via `allowed-tools`
4. Always provide `argument-hint`
5. Consistent verb-noun naming (`review-pr`, `fix-issue`)
6. Limit bash scope: `Bash(git:*)` over `Bash(*)`
7. Handle missing files gracefully

## Plugin Commands

Use `${CLAUDE_PLUGIN_ROOT}` for portable paths:

```markdown
!`node ${CLAUDE_PLUGIN_ROOT}/scripts/analyze.js $1`
@${CLAUDE_PLUGIN_ROOT}/config/settings.json
```

Plugin commands auto-discovered from `commands/` directory.
