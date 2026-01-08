# Creating Codex Skills

Extend Codex with specialized knowledge, workflows, and tool integrations.

## Skill Locations

Skills load from these directories (in precedence order):

1. `.codex/skills/` - Current directory (project-level)
2. `.codex/skills/` - Parent directory (repo-level)
3. `$CODEX_HOME/skills/` - User level (~/.codex/skills/)
4. `/etc/codex/skills/` - System level

## Skill Structure

```
skill-name/
├── SKILL.md          # Required: instructions and metadata
├── scripts/          # Optional: executable code
│   ├── init.py
│   └── validate.py
├── references/       # Optional: detailed documentation
│   └── api-spec.md
├── assets/           # Optional: templates, configs
│   └── template.json
└── license.txt       # Optional: licensing info
```

## SKILL.md Format

### Required: Frontmatter

```yaml
---
name: skill-name
description: Detailed description of when to use this skill. Include specific contexts, keywords, and scenarios that should trigger activation.
metadata:
  short-description: Brief user-facing description (optional)
---
```

**Critical:** The `description` field determines when Codex triggers the skill. Be specific about:
- What functionality it provides
- What keywords/phrases should trigger it
- What contexts it applies to

### Body Content

The markdown body contains instructions for Codex:

```markdown
---
name: api-testing
description: Guide for API testing with Postman collections. Use when users mention API testing, Postman, Newman, or request validation.
---

# API Testing Guide

## Quick Start

Run existing collection:
```bash
newman run collection.json -e environment.json
```

## Creating Tests

[Detailed instructions...]

## Reference Files

For advanced patterns, see `references/advanced-testing.md`
```

## Design Principles

### 1. Concise by Default

Context windows are shared resources. Keep SKILL.md lean:
- Include only essential instructions
- Move detailed content to `references/`
- Load references only when needed

### 2. Progressive Disclosure

```
SKILL.md (always loaded when triggered)
├── Core concepts (~500-1500 words)
├── Quick reference
└── Pointers to references/

references/ (loaded on demand)
├── detailed-topic-1.md
├── detailed-topic-2.md
└── examples/
```

### 3. Appropriate Specificity

Match instruction detail to task fragility:
- **Fragile tasks** (specific syntax, exact commands): Be very specific
- **Flexible tasks** (general guidance): Allow model judgment

## Quick Start with $skill-creator

The easiest way to create a skill:

```
Codex> Use $skill-creator to create a skill for [your purpose]
```

This bootstraps the skill structure with appropriate files.

## Manual Creation

### Step 1: Create Directory

```bash
mkdir -p ~/.codex/skills/my-skill
```

### Step 2: Create SKILL.md

```bash
cat > ~/.codex/skills/my-skill/SKILL.md << 'EOF'
---
name: my-skill
description: Description of when to trigger this skill
---

# My Skill

Instructions for Codex...
EOF
```

### Step 3: Add Supporting Files (Optional)

```bash
# Scripts
mkdir ~/.codex/skills/my-skill/scripts
cat > ~/.codex/skills/my-skill/scripts/helper.py << 'EOF'
#!/usr/bin/env python3
# Helper script
EOF

# References
mkdir ~/.codex/skills/my-skill/references
cat > ~/.codex/skills/my-skill/references/details.md << 'EOF'
# Detailed Documentation
...
EOF
```

## Writing Effective Descriptions

The description is crucial for skill discovery:

**Good:**
```yaml
description: Guide for React Testing Library. Use when users ask about testing React components, writing component tests, querying DOM elements, user event simulation, or RTL best practices.
```

**Bad:**
```yaml
description: Testing guide
```

Include:
- Primary purpose
- Trigger keywords
- Specific scenarios
- Related tools/concepts

## Bundled Resources

### Scripts

Executable code in `scripts/`:

```python
# scripts/validate.py
#!/usr/bin/env python3
"""Validate skill structure."""
import sys
import yaml

def validate_skill(path):
    # Validation logic
    pass

if __name__ == "__main__":
    validate_skill(sys.argv[1])
```

Reference in SKILL.md:
```markdown
Validate with: `python scripts/validate.py`
```

### References

Detailed documentation loaded on demand:

```markdown
<!-- references/advanced.md -->
# Advanced Patterns

Detailed content that would bloat SKILL.md...
```

Reference in SKILL.md:
```markdown
For advanced patterns, see `references/advanced.md`
```

### Assets

Templates, configs, examples:

```json
// assets/config-template.json
{
  "setting": "value"
}
```

## Skill Validation

Before using a skill, validate:

1. **SKILL.md exists** in skill directory
2. **Frontmatter is valid YAML**
3. **Description is specific** enough for triggering
4. **References exist** if mentioned in SKILL.md
5. **Scripts are executable** if included

Use `$skill-creator`'s validation or create your own:

```bash
# Quick validation
codex "validate my skill at ~/.codex/skills/my-skill"
```

## Example: Complete Skill

```
docker-compose/
├── SKILL.md
├── scripts/
│   └── validate-compose.sh
├── references/
│   ├── networking.md
│   └── volumes.md
└── assets/
    └── compose-template.yaml
```

**SKILL.md:**
```yaml
---
name: docker-compose
description: Guide for Docker Compose multi-container applications. Use when users ask about docker-compose, container orchestration, service definitions, compose networking, or volume management.
---

# Docker Compose Guide

## Quick Reference

| Command | Purpose |
|---------|---------|
| `docker-compose up -d` | Start services |
| `docker-compose down` | Stop and remove |
| `docker-compose logs -f` | Follow logs |

## Service Definition

```yaml
services:
  web:
    image: nginx
    ports:
      - "80:80"
```

## Validation

Validate compose file: `bash scripts/validate-compose.sh`

## Detailed Topics

- Networking: `references/networking.md`
- Volumes: `references/volumes.md`
```

## Tips

1. **Start minimal** - Add complexity only when needed
2. **Test triggering** - Verify skill activates on expected phrases
3. **Iterate based on usage** - Refine based on real interactions
4. **Keep SKILL.md under 2000 words** - Move details to references
5. **Use code examples** - Concrete examples are more useful than explanations
