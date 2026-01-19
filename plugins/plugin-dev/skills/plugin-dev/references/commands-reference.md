# Commands Reference

Complete reference for creating Claude Code slash commands.

## Command File Format

Commands are Markdown files in `commands/` with YAML frontmatter:

```yaml
---
description: What this command does. Include trigger phrases.
allowed-tools: Read, Write, Edit, Bash
argument-hint: "<required-arg> [optional-arg]"
---

# Command Title

Instructions for Claude when this command is invoked.

## Process

1. First step
2. Second step
3. Final step

## Output

What to produce or return.
```

## Frontmatter Fields

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `description` | Yes | string | Shown in command menu |
| `allowed-tools` | No | string/array | Restrict available tools |
| `argument-hint` | No | string | Usage hint shown in menu |
| `model` | No | string | haiku, sonnet, opus |

## Argument Patterns

```yaml
# No arguments
argument-hint: ""

# Required argument
argument-hint: "<file-path>"

# Optional argument
argument-hint: "[message]"

# Multiple arguments
argument-hint: "<source> <destination> [--force]"

# Complex with options
argument-hint: "<action> [target] [--dry-run] [--verbose]"
```

## Accessing Arguments

In the command body, arguments are available as `$ARGUMENTS`:

```markdown
---
description: Search for a pattern in the codebase
argument-hint: "<pattern> [path]"
---

Search the codebase for the pattern provided in: $ARGUMENTS

Use Grep to find all occurrences, then summarize findings.
```

## Command Locations

```
plugin-name/
└── commands/
    ├── build.md           # /plugin-name:build
    ├── test.md            # /plugin-name:test
    └── deploy.md          # /plugin-name:deploy
```

Commands are namespaced: `/plugin-name:command-name`

## Tool Restrictions

```yaml
# Read-only command
allowed-tools: Read, Glob, Grep

# Full access
allowed-tools: Read, Write, Edit, Bash, Glob, Grep

# Specific tools
allowed-tools: [Bash, Read]
```

## Examples

### Simple Command

```yaml
---
description: Run project tests
---

Run the test suite for this project:

1. Detect the test framework (jest, pytest, go test, etc.)
2. Execute the appropriate test command
3. Report results with any failures highlighted
```

### Command with Arguments

```yaml
---
description: Generate a component with the given name
argument-hint: "<component-name> [--typescript]"
---

Generate a new React component based on: $ARGUMENTS

## Process

1. Parse the component name from arguments
2. Check if --typescript flag is present
3. Create component file in appropriate directory
4. Add basic component structure
5. Create test file if test directory exists

## Output

Report the files created and their locations.
```

### Command with Tool Restrictions

```yaml
---
description: Analyze codebase structure without making changes
allowed-tools: Read, Glob, Grep
argument-hint: "[directory]"
---

Analyze the codebase structure. Do not modify any files.

## Analysis

1. Count files by type
2. Identify main entry points
3. Map directory structure
4. Find configuration files
5. Summarize architecture patterns

Provide a structured report of findings.
```

### Interactive Command

```yaml
---
description: Interactive git commit with message suggestions
allowed-tools: Bash, Read, Grep
---

Guide the user through creating a git commit:

1. Run `git status` to see changes
2. Run `git diff --staged` to see staged changes
3. Suggest a commit message based on the changes
4. Ask user to confirm or modify the message
5. Execute the commit with the approved message
```

## Best Practices

1. **Clear Description**: Include what the command does
2. **Argument Hints**: Show expected format
3. **Minimal Tools**: Only request tools needed
4. **Step-by-Step**: Break complex commands into steps
5. **Error Handling**: Mention how to handle failures
6. **Examples**: Show expected output format

## Validation Checklist

- [ ] Has `description` in frontmatter
- [ ] `argument-hint` matches expected usage
- [ ] `allowed-tools` is minimal but sufficient
- [ ] Instructions are clear and actionable
- [ ] File is in `commands/` directory
- [ ] Filename is kebab-case with `.md` extension
