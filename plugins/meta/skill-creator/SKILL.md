---
name: skill-creator
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
| Directory structure, SKILL.md format, bundled resources | [references/skill-anatomy.md](./references/skill-anatomy.md) |
| Step-by-step creation process (Steps 1-6) | [references/creation-process.md](./references/creation-process.md) |
| File size limits, script requirements, best practices | [references/requirements.md](./references/requirements.md) |

## Key Principles

### Progressive Disclosure

Skills use three-level loading:

1. **Metadata** (~100 words) - Always in context
2. **SKILL.md body** (<5k words) - When skill triggers
3. **Bundled resources** - Loaded as needed

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

## Creation Workflow

1. **Understand** - Gather concrete usage examples
2. **Plan** - Identify reusable scripts, references, assets
3. **Initialize** - Run `scripts/init_skill.py <name> --path <dir>`
4. **Edit** - Implement resources, update SKILL.md
5. **Package** - Run `scripts/package_skill.py <path>`
6. **Iterate** - Test, improve, repeat

See [references/creation-process.md](./references/creation-process.md) for detailed steps.

## External References

- [Agent Skills Documentation](https://docs.claude.com/en/docs/claude-code/skills.md)
- [Agent Skills Overview](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview.md)
- [Best Practices](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/best-practices.md)
