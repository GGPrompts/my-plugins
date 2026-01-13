---
name: skill-development
description: This skill should be used when the user asks to "create a skill", "write SKILL.md", "add skill references", or mentions progressive disclosure, skill triggers, or bundled resources.
---

# Skill Development

Skills extend Claude's capabilities through modular packages with specialized workflows, tool integrations, and bundled resources.

## Required Structure

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter (name, description)
│   └── Markdown instructions
└── Bundled Resources (optional)
    ├── scripts/       # Executable code
    ├── references/    # Documentation loaded on-demand
    └── assets/        # Files used in output
```

## SKILL.md Format

```yaml
---
name: skill-name
description: This skill should be used when the user asks to "create X",
"configure Y", "analyze Z", or mentions specific-domain-terms.
---

# Skill Title

[Core instructions - keep under 2000 words]

## Additional Resources

- **`references/patterns.md`** - Detailed patterns
- **`scripts/validate.sh`** - Validation tool
```

## Progressive Disclosure

Three-level loading:

1. **Metadata** (~100 words) - Always in context
2. **SKILL.md body** (<5k words) - When skill triggers
3. **Bundled resources** - As needed

**Target:** 1,500-2,000 words in SKILL.md. Move details to `references/`.

## Description Best Practices

**Good (specific triggers):**
```yaml
description: This skill should be used when the user asks to "create a hook",
"add a PreToolUse hook", "validate tool use", or mentions hook events.
```

**Bad (vague):**
```yaml
description: Use this skill when working with hooks.
```

## Writing Style

Use **imperative/infinitive form**:

| Correct | Incorrect |
|---------|-----------|
| "Parse the frontmatter using sed." | "You should parse the frontmatter..." |
| "Validate values before use." | "You need to validate values..." |
| "Configure the server with auth." | "You can configure the server..." |

## Resource Categories

**scripts/**: Executable code for deterministic tasks
- Same code rewritten repeatedly
- Reliability is critical
- Execute without loading into context

**references/**: Documentation loaded as needed
- Schemas, APIs, policies
- Files >10k words with grep patterns in SKILL.md
- Information lives here OR in SKILL.md, not both

**assets/**: Files used in output
- Templates, images, fonts
- Not loaded into context

## Validation Checklist

- [ ] SKILL.md has `name` and `description` in frontmatter
- [ ] Description includes specific trigger phrases
- [ ] Body uses imperative form (not second person)
- [ ] Under 2000 words (detailed content in references/)
- [ ] All referenced files exist
- [ ] Examples are complete and working

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Weak triggers: "Provides guidance for X" | Strong triggers: "...when user asks to 'create X', 'configure Y'" |
| 8000-word SKILL.md | 1800-word SKILL.md + references/ |
| "You should..." | "To accomplish X, do Y" |
| No resource references | Clear "Additional Resources" section |
