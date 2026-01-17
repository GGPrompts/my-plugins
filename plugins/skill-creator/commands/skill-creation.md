---
description: Guide for creating effective skills. This skill should be used when users want to create a new skill (or update an existing skill) that extends Claude's capabilities with specialized knowledge, workflows, or tool integrations.
license: Complete terms in LICENSE.txt
---

# Skill Creator

Skills are modular packages that extend Claude's capabilities with specialized knowledge, workflows, and tools. They transform Claude from a general-purpose agent into a domain specialist.

## When to Use

- Creating a new skill from scratch
- Updating or improving an existing skill
- Understanding skill structure and best practices
- Packaging skills for distribution

## What Skills Provide

1. **Specialized workflows** - Multi-step procedures for specific domains
2. **Tool integrations** - Instructions for file formats or APIs
3. **Domain expertise** - Company-specific knowledge, schemas, business logic
4. **Bundled resources** - Scripts, references, and assets for complex tasks

## Quick Reference

| Topic | Reference |
|-------|-----------|
| Directory structure, SKILL.md format, bundled resources | [references/skill-anatomy.md](${CLAUDE_PLUGIN_ROOT}/references/skill-anatomy.md) |
| Step-by-step creation process (Steps 1-6) | [references/creation-process.md](${CLAUDE_PLUGIN_ROOT}/references/creation-process.md) |
| File size limits, script requirements, best practices | [references/requirements.md](${CLAUDE_PLUGIN_ROOT}/references/requirements.md) |
| Templates, examples, output formatting | [references/output-patterns.md](${CLAUDE_PLUGIN_ROOT}/references/output-patterns.md) |
| Sequential vs conditional workflows, degrees of freedom | [references/workflows.md](${CLAUDE_PLUGIN_ROOT}/references/workflows.md) |

## Key Principles

### Conciseness

**"The context window is a public good."** Only include information Claude doesn't already possess. Prefer concise examples over verbose explanations.

**What NOT to include:** README.md, installation guides, changelogs, or auxiliary documentation.

### Progressive Disclosure

Skills use three-level loading:

1. **Metadata** (~100 words) - Always in context
2. **SKILL.md body** (<5k words) - When skill triggers
3. **Bundled resources** - Loaded as needed

### Degrees of Freedom

Match instruction specificity to task fragility:

| Freedom | Format | Use When |
|---------|--------|----------|
| High | Text instructions | Flexible approaches OK |
| Medium | Pseudocode | Structure matters, some variation OK |
| Low | Specific scripts | Reliability critical |

See [references/workflows.md](${CLAUDE_PLUGIN_ROOT}/references/workflows.md) for examples.

### File Size Limit

SKILL.md should be **< 200 lines**. Move detailed content to `references/`.

### Writing Style

Use **imperative form**: "To accomplish X, do Y" not "You should do X".

## Skill Structure

```
skill-name/
├── SKILL.md              # Required: metadata + instructions
├── scripts/              # Optional: executable code
├── references/           # Optional: documentation loaded on-demand
└── assets/               # Optional: files used in output
```

## Skill Placement in Plugins

Skills live in a plugin's `skills/` directory - **ONE level deep only**:

```
my-plugin/
├── plugin.json
└── skills/
    ├── skill-a/          # ✅ Correct
    │   └── SKILL.md
    └── skill-b/          # ✅ Correct
        └── SKILL.md

# ❌ WRONG - nested skills won't be discovered:
└── skills/
    └── parent/
        └── skills/       # Nesting breaks discovery!
            └── child/
                └── SKILL.md
```

**Key rule:** Never nest skills inside skills. Each skill is a direct child of `skills/`.

## Creation Workflow

1. **Understand** - Gather concrete usage examples
2. **Plan** - Identify reusable scripts, references, assets
3. **Initialize** - Run `scripts/init_skill.py <name> --path <dir>`
4. **Edit** - Implement resources, update SKILL.md
5. **Package** - Run `scripts/package_skill.py <path>`
6. **Iterate** - Test, improve, repeat

See [references/creation-process.md](${CLAUDE_PLUGIN_ROOT}/references/creation-process.md) for detailed steps.

## External References

- [Agent Skills Documentation](https://docs.claude.com/en/docs/claude-code/skills.md)
- [Agent Skills Overview](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview.md)
- [Best Practices](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/best-practices.md)
