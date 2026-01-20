---
name: create-plugin
description: 8-phase workflow for creating high-quality Claude Code plugins from concept to tested implementation
argument-hint: [plugin-description]
---

# Create Plugin Workflow

Systematic 8-phase approach for creating Claude Code plugins.

## Core Principles

- **Ask clarifying questions** rather than making assumptions
- **Load relevant skills** during appropriate phases
- **Follow established best practices** from plugin-dev skills
- **Use progressive disclosure** - lean skill design

## The 8 Phases

### Phase 1: Discovery

Clarify what problem the plugin solves:
- What specific tasks does it help with?
- Who are the target users?
- What existing solutions (if any) does it improve on?

**Ask the user** before proceeding.

### Phase 2: Component Planning

Determine which components are needed:
- [ ] Commands - User-invokable actions
- [ ] Skills - Knowledge and workflows
- [ ] Agents - Autonomous subprocesses
- [ ] Hooks - Event-driven automation
- [ ] MCP - External service integration
- [ ] Settings - User configuration

Load `plugin-structure` skill for guidance.

**Confirm component list** with user.

### Phase 3: Detailed Design

Resolve all ambiguities:
- Command names and arguments?
- Skill trigger phrases?
- Agent responsibilities?
- Hook events to handle?
- MCP servers needed?

**Get user confirmation** before implementation.

### Phase 4: Plugin Structure

Create directory structure and manifest:

```bash
mkdir -p plugin-name/.claude-plugin
mkdir -p plugin-name/{commands,skills,agents,hooks/scripts}
```

Create `plugin.json`:
```json
{
  "name": "plugin-name",
  "version": "1.0.0",
  "description": "..."
}
```

### Phase 5: Component Implementation

Build each component following best practices:

| Component | Skill to Load |
|-----------|---------------|
| Commands | `command-development` |
| Skills | `skill-development` |
| Agents | `agent-development` |
| Hooks | `hook-development` |
| MCP | `mcp-integration` |
| Settings | `plugin-settings` |

### Phase 6: Validation

Run validation checks:
- YAML frontmatter valid?
- Required fields present?
- Trigger descriptions specific?
- Writing style correct?
- All referenced files exist?

### Phase 7: Testing

Guide user through testing:
1. Install plugin locally
2. Restart Claude Code
3. Test each component
4. Verify expected behavior

**Get user confirmation** tests pass.

### Phase 8: Documentation

Finalize:
- README with installation instructions
- Example usage
- Configuration options
- Troubleshooting guide

## Quality Standards

Every component must:
- Follow proven patterns
- Use correct naming conventions
- Include strong trigger conditions
- Contain working examples
- Pass validation
- Test successfully

## Execute

If plugin description provided as `$ARGUMENTS`:

1. Start with Phase 1 questions based on: $ARGUMENTS
2. Progress through phases with user confirmation
3. Create complete, tested plugin

If no description provided, ask user to describe their plugin idea.
