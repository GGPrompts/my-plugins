---
name: agent-development
description: This skill should be used when the user asks to "create an agent", "write agent frontmatter", "configure agent tools", or mentions subagent, agent color, agent model, or agent system prompt.
---

# Agent Development

Agents are autonomous subprocesses handling complex multi-step tasks independently. They use markdown with YAML frontmatter and trigger via description examples.

## Agent File Format

```markdown
---
name: agent-identifier
description: Use this agent when [conditions]. Examples:

<example>
Context: [Situation]
user: "[Request]"
assistant: "[Response using agent]"
<commentary>
[Why this agent triggers]
</commentary>
</example>

model: inherit
color: blue
tools: ["Read", "Write", "Grep"]
---

You are [agent role]...

**Your Core Responsibilities:**
1. [Responsibility 1]
2. [Responsibility 2]

**Process:**
1. [Step 1]
2. [Step 2]

**Output Format:**
[What to return]
```

## Frontmatter Fields

| Field | Required | Format | Example |
|-------|----------|--------|---------|
| `name` | Yes | lowercase-hyphens (3-50 chars) | `code-reviewer` |
| `description` | Yes | Text + 2-4 examples | `Use when...` |
| `model` | Yes | inherit/sonnet/opus/haiku | `inherit` |
| `color` | Yes | blue/cyan/green/yellow/magenta/red | `blue` |
| `tools` | No | Array of tool names | `["Read", "Grep"]` |

## Name Validation

- 3-50 characters
- Lowercase letters, numbers, hyphens only
- Must start/end with alphanumeric

**Valid:** `code-reviewer`, `test-gen`, `api-analyzer-v2`
**Invalid:** `ag` (short), `-start` (starts with hyphen), `my_agent` (underscore)

## Description with Examples

**Required structure:**
```yaml
description: Use this agent when [conditions]. Examples:

<example>
Context: User wants code reviewed before commit
user: "Review my changes for security issues"
assistant: "I'll use the code-reviewer agent..."
<commentary>
Security review request triggers this specialized agent.
</commentary>
</example>
```

Include 2-4 examples covering different phrasings and both proactive/reactive triggers.

## Color Guidelines

| Color | Use Case |
|-------|----------|
| Blue/Cyan | Analysis, review |
| Green | Success-oriented tasks |
| Yellow | Caution, validation |
| Red | Critical, security |
| Magenta | Creative, generation |

## Tool Restrictions

Common tool sets:
- **Read-only:** `["Read", "Grep", "Glob"]`
- **Code generation:** `["Read", "Write", "Grep"]`
- **Testing:** `["Read", "Bash", "Grep"]`

Default provides all tools if not specified.

## System Prompt Best Practices

**DO:**
- Write in second person ("You are...", "You will...")
- Be specific about responsibilities
- Provide step-by-step process
- Define output format
- Address edge cases
- Keep under 10,000 characters

**DON'T:**
- Use first person
- Be vague or generic
- Omit process steps
- Leave output undefined

## Location

```
plugin-name/
└── agents/
    ├── analyzer.md
    ├── reviewer.md
    └── generator.md
```

All `.md` files in `agents/` auto-discovered.
