# Skill Requirements

## File Size Limits

- `SKILL.md`: **< 200 lines**; split to `references/` if needed
- Scripts/references: **< 200 lines** each; split into multiple files (progressive disclosure)

## Topic Organization

Combine related topics into single skills:
- `cloudflare`, `cloudflare-r2`, `cloudflare-workers`, `docker`, `gcloud` → `devops`

## Description Quality

Descriptions in SKILL.md metadata should be:
- Concise yet comprehensive
- Include use cases for references and scripts
- Enable automatic activation during Claude Code workflows

## Referenced Markdowns

- Sacrifice grammar for concision
- Can reference other markdown files or scripts

## Referenced Scripts

- **Prefer Node.js or Python** over bash (better Windows support)
- **Python scripts**: Include `requirements.txt`
- **Environment variables**: Respect `.env` file in order:
  1. `process.env`
  2. `.claude/skills/${SKILL}/.env`
  3. `.claude/skills/.env`
  4. `.claude/.env`
- Create `.env.example` showing required variables
- Always write tests for scripts

## Why These Requirements?

Better **context engineering**: Progressive disclosure means Claude Code loads only relevant files into context, instead of reading entire long SKILL.md files.
