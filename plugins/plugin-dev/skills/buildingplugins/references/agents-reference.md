# Agents Reference

Complete reference for creating Claude Code sub-agents.

## Agent Markdown Format

```yaml
---
name: code-reviewer              # REQUIRED: lowercase, hyphens, 3-50 chars
description: |                   # REQUIRED: triggers Claude's selection
  Expert code reviewer. Use for code review tasks,
  finding bugs, and suggesting improvements.

  <example>
  Context: User wants security review
  user: "Review my auth code for vulnerabilities"
  assistant: "I'll use the code-reviewer agent..."
  </example>
tools: [Read, Grep, Glob, Bash]  # Optional: allowed tools (whitelist)
disallowedTools: [Write, Edit]   # Optional: denied tools (blacklist)
model: sonnet                    # Optional: sonnet, opus, haiku, inherit
permissionMode: default          # Optional: permission handling
skills: [skill-name]             # Optional: auto-load skills
color: blue                      # Optional: visual identification
hooks:                           # Optional: agent-scoped hooks
  PreToolUse: [...]
---

# Code Reviewer

You are an expert code reviewer with deep knowledge of...

## Your Responsibilities
- Review code for bugs and issues
- Suggest improvements
- Check for security vulnerabilities

## Guidelines
- Be specific in feedback
- Provide code examples
- Explain the "why" behind suggestions
```

## Frontmatter Fields

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `name` | Yes | string | Unique ID, lowercase-hyphens, 3-50 chars |
| `description` | Yes | string | When/why to invoke, include examples |
| `tools` | No | array | Whitelist of allowed tools |
| `disallowedTools` | No | array | Blacklist of denied tools |
| `model` | No | string | haiku, sonnet, opus, inherit |
| `permissionMode` | No | string | Permission handling mode |
| `skills` | No | array | Skills to auto-load |
| `color` | No | string | Visual identification |
| `hooks` | No | object | Agent-scoped hooks |

## Permission Modes

| Mode | Behavior |
|------|----------|
| `default` | Standard permission prompts |
| `acceptEdits` | Auto-accept file edits |
| `dontAsk` | Auto-deny (use allowed tools only) |
| `bypassPermissions` | Skip all permission checks |
| `plan` | Read-only exploration mode |

## Tool Configuration

```yaml
# Whitelist approach - only these tools allowed
tools: [Read, Grep, Glob]

# Blacklist approach - all except these
disallowedTools: [Write, Edit, Bash]

# Combined (whitelist takes precedence)
tools: [Read, Grep, Glob, Bash]
disallowedTools: [Write]  # Ignored when tools specified
```

## Color Guidelines

| Color | Use Case |
|-------|----------|
| `blue` | Analysis, general purpose |
| `cyan` | Review, exploration |
| `green` | Success-oriented, building |
| `yellow` | Caution, validation |
| `red` | Critical, security |
| `magenta` | Creative, generation |

## Built-In Agents

| Agent | Purpose | Model | Tools |
|-------|---------|-------|-------|
| `Explore` | Fast codebase discovery | Haiku | Read-only |
| `Plan` | Research during planning | Sonnet | Read-only |
| `General-purpose` | Complex multi-step tasks | Sonnet | All |
| `Bash` | Terminal commands | Sonnet | Bash |

## Configuration Locations

Priority order (highest to lowest):
1. `--agents` CLI flag (session only)
2. `.claude/agents/` (project)
3. `~/.claude/agents/` (user)
4. Plugin `agents/` directory

## Description with Examples

Include 2-4 examples for better discovery:

```yaml
description: |
  Use this agent for security audits and vulnerability scanning.

  <example>
  Context: User wants code reviewed for security
  user: "Check this auth code for vulnerabilities"
  assistant: "I'll use the security-auditor agent to analyze..."
  <commentary>
  Security-specific request triggers specialized agent.
  </commentary>
  </example>

  <example>
  Context: User mentions OWASP or CVE
  user: "Does this have any OWASP top 10 issues?"
  assistant: "I'll use the security-auditor agent..."
  </example>
```

## CLI-Based Agents

```bash
claude --agents '{
  "security-auditor": {
    "description": "Security expert for vulnerability scanning",
    "prompt": "You are a security expert...",
    "tools": ["Read", "Grep", "Glob", "Bash"],
    "model": "opus"
  }
}'
```

## Agent-Scoped Hooks

```yaml
---
name: safe-deployer
description: Deployment agent with safety checks
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/scripts/validate-deploy.sh"
  Stop:
    - hooks:
        - type: prompt
          prompt: "Verify deployment checklist complete"
---
```

## System Prompt Best Practices

1. **Define Expert Persona**: "You are a senior backend engineer..."
2. **Clear Responsibilities**: Numbered list of tasks
3. **Specific Guidelines**: How to approach work
4. **Include Examples**: Expected behavior
5. **Define Boundaries**: What's out of scope
6. **Keep under 10,000 characters**

## Invoking Agents

```markdown
<!-- Claude selects based on description -->
I'll use the code-reviewer agent to analyze this.

<!-- Programmatically via Task tool -->
Task tool with subagent_type: "code-reviewer"
```

## Testing

```bash
# Test agent file
claude --agents ./my-agent.md

# Test in plugin
claude --plugin-dir ./my-plugin
# Then invoke agent via Task tool
```

## Validation Checklist

- [ ] Name is lowercase with hyphens, 3-50 chars
- [ ] Description clearly states when to use
- [ ] Includes 2-4 example blocks
- [ ] Tools are minimal but sufficient
- [ ] Model matches complexity needs
- [ ] System prompt uses second person ("You are...")
- [ ] Tested as both main agent and subagent
