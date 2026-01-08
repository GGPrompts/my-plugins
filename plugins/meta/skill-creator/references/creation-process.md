# Skill Creation Process

Follow these steps in order, skipping only when clearly not applicable.

## Step 1: Understand with Concrete Examples

Skip only when usage patterns already clearly understood.

Gather concrete examples of how the skill will be used through:
- Direct user examples
- Generated examples validated with user feedback

**Example questions for an image-editor skill:**
- "What functionality should the skill support?"
- "Can you give examples of how it would be used?"
- "What would a user say to trigger this skill?"

Avoid overwhelming users - start with key questions, follow up as needed.

**Exit criteria:** Clear sense of functionality the skill should support.

## Step 2: Plan Reusable Contents

Analyze each example by:
1. Considering how to execute from scratch
2. Identifying helpful scripts, references, and assets for repeated workflows

**Example analyses:**

| Skill | Query | Analysis | Resource |
|-------|-------|----------|----------|
| pdf-editor | "Rotate this PDF" | Same code each time | `scripts/rotate_pdf.py` |
| frontend-builder | "Build a todo app" | Same boilerplate | `assets/hello-world/` |
| big-query | "How many users logged in?" | Re-discover schemas | `references/schema.md` |

**Exit criteria:** List of reusable resources to include.

## Step 3: Initialize the Skill

Skip if skill already exists (proceed to Step 4).

Run the init script:

```bash
scripts/init_skill.py <skill-name> --path <output-directory>
```

The script:
- Creates skill directory at specified path
- Generates SKILL.md template with frontmatter and TODOs
- Creates example `scripts/`, `references/`, `assets/` directories
- Adds example files to customize or delete

## Step 4: Edit the Skill

Remember: Creating for another Claude instance. Include information that's beneficial and non-obvious.

### 4.1 Start with Reusable Contents

Implement `scripts/`, `references/`, `assets/` files identified in Step 2.

Note: May require user input (e.g., brand assets, documentation).

Delete unneeded example files from initialization.

### 4.2 Update SKILL.md

**Writing style:** Imperative/infinitive form (verb-first). Use "To accomplish X, do Y" not "You should do X".

Answer these questions:
1. What is the skill's purpose? (few sentences)
2. When should it be used?
3. How should Claude use it? (reference all bundled resources)

## Step 5: Package the Skill

Package into distributable zip (validates automatically):

```bash
scripts/package_skill.py <path/to/skill-folder>
```

With output directory:

```bash
scripts/package_skill.py <path/to/skill-folder> ./dist
```

**Validation checks:**
- YAML frontmatter format and required fields
- Naming conventions and directory structure
- Description completeness and quality
- File organization and resource references

If validation fails, fix errors and re-run.

## Step 6: Iterate

After testing, users may request improvements.

**Iteration workflow:**
1. Use skill on real tasks
2. Notice struggles or inefficiencies
3. Identify updates to SKILL.md or bundled resources
4. Implement changes and test again
