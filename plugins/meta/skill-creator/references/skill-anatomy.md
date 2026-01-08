# Skill Anatomy

## Directory Structure

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter metadata (required)
│   │   ├── name: (required)
│   │   └── description: (required)
│   └── Markdown instructions (required)
└── Bundled Resources (optional)
    ├── scripts/          - Executable code (Python/Bash/etc.)
    ├── references/       - Documentation loaded into context as needed
    └── assets/           - Files used in output (templates, icons, fonts)
```

## SKILL.md Requirements

- **File name:** `SKILL.md` (uppercase)
- **File size:** Under 200 lines; split to `references/` if needed
- **Metadata:** `name` and `description` in YAML frontmatter determine activation
- **Style:** Use third-person ("This skill should be used when...")

## Bundled Resources

### Scripts (`scripts/`)

Executable code for tasks requiring deterministic reliability or repeatedly rewritten.

- **When to include**: Same code rewritten repeatedly, deterministic reliability needed
- **Example**: `scripts/rotate_pdf.py` for PDF rotation
- **Benefits**: Token efficient, deterministic, executed without loading into context
- **Note**: May still be read for patching or environment adjustments

### References (`references/`)

Documentation loaded as needed into context.

- **When to include**: Documentation Claude should reference while working
- **Examples**: `references/schema.md` for database schemas, `references/api_docs.md` for API specs
- **Use cases**: Database schemas, API docs, domain knowledge, company policies, workflow guides
- **Benefits**: Keeps SKILL.md lean, loaded only when needed
- **Best practice**: For large files (>10k words), include grep patterns in SKILL.md
- **Avoid duplication**: Info lives in SKILL.md OR references, not both

### Assets (`assets/`)

Files used in output, not loaded into context.

- **When to include**: Files used in final output
- **Examples**: `assets/logo.png`, `assets/slides.pptx`, `assets/frontend-template/`
- **Use cases**: Templates, images, icons, boilerplate, fonts, sample documents
- **Benefits**: Separates output resources from documentation

## Progressive Disclosure

Three-level loading system:

1. **Metadata** (~100 words) - Always in context
2. **SKILL.md body** (<5k words) - When skill triggers
3. **Bundled resources** (Unlimited) - As needed by Claude
