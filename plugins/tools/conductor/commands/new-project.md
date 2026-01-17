---
description: "Multi-phase workflow for brainstorming, scaffolding, and setting up new projects with skill-aware configuration"
---

# New Project - Interactive Project Scaffolding

A comprehensive workflow for starting new projects with interactive brainstorming, tech stack research, scaffolding, and Claude Code configuration.

## Overview

| Phase | Purpose | Interaction |
|-------|---------|-------------|
| 1. Brainstorm | Gather requirements | AskUserQuestion |
| 2. Tech Stack | Research & select | docs-seeker + AskUserQuestion |
| 3. Initialize | Scaffold project | Execution |
| 4. Setup | Configure Claude Code | skill-picker + beads |

---

## Quick Start: TabzTemplates Starters

For common project types, use pre-configured starters from `~/projects/TabzTemplates`:

| Starter | Use Case | Command |
|---------|----------|---------|
| `threejs-landing` | 3D landing page with R3F + scroll animations | See below |
| `saas-landing` | SaaS marketing page with dashboards | See below |

**Using a starter:**
```bash
# 1. Copy starter templates to new project
PROJECT_NAME="my-project"
STARTER="threejs-landing"  # or "saas-landing"
mkdir -p ~/projects/$PROJECT_NAME/.beads
cp ~/projects/TabzTemplates/starters/$STARTER/templates/* ~/projects/$PROJECT_NAME/
cp ~/projects/TabzTemplates/starters/$STARTER/templates/PRIME.md.tmpl ~/projects/$PROJECT_NAME/.beads/PRIME.md

# 2. Initialize beads and git
cd ~/projects/$PROJECT_NAME
bd init
git init && git add . && git commit -m "chore: initialize from $STARTER starter"

# 3. Replace template variables ({{business_name}}, etc.)
# Then run /conductor:bd-swarm-auto to execute the pre-planned backlog
```

Starters include pre-configured:
- CLAUDE.md with project-specific guidelines
- PRIME.md with beads workflow context
- issues.jsonl with wave-organized backlog
- Skill references for the tech stack

**Skip to Phase 4** if using a starter - scaffolding is handled by the backlog issues.

---

## Phase 1: Brainstorm (Interactive)

### 1.1 Project Vision

Use AskUserQuestion to gather core requirements:

```
Question 1: "What type of project are you building?"
Header: "Project Type"
Options:
- Web Application (Frontend + Backend)
- CLI Tool
- API/Backend Service
- Browser Extension
- Library/Package
```

```
Question 2: "What's the primary goal of this project?"
Header: "Goal"
Options:
- Learning/Experimentation
- Personal Tool
- Production Application
- Open Source Project
```

### 1.2 Feature Priorities

Use multi-select to understand priorities:

```
Question: "Which features are most important? (select all that apply)"
Header: "Priorities"
MultiSelect: true
Options:
- Fast Development Speed (simple setup, hot reload)
- Type Safety (TypeScript, strict typing)
- Performance (optimized builds, minimal bundle)
- Testing (built-in test framework)
```

### 1.3 Scale & Constraints

```
Question: "Expected scale and constraints?"
Header: "Scale"
Options:
- Small (personal use, <100 users)
- Medium (team/startup, 100-10k users)
- Large (enterprise, 10k+ users)
- Uncertain (start small, grow later)
```

### 1.4 Capture Requirements

Document gathered requirements:

```markdown
## Project Requirements Summary

**Type:** <selected type>
**Goal:** <selected goal>
**Priorities:** <selected priorities>
**Scale:** <selected scale>

**Additional Notes:**
<any user-provided context>
```

---

## Phase 2: Tech Stack Selection (Research)

### 2.1 Map Requirements to Stack Options

| Project Type | Recommended Stacks |
|--------------|-------------------|
| Web App (Full-stack) | Next.js, Remix, SvelteKit, Nuxt |
| Web App (SPA) | Vite + React, Vite + Vue, Vite + Svelte |
| CLI Tool | Node.js + Commander, Bun, Go + Cobra |
| API Service | Fastify, Hono, Express, Go + Chi |
| Browser Extension | Vite + CRXJS, Plasmo, WXT |
| Library | tsup, unbuild, Rollup |

### 2.2 Fetch Latest Documentation

Use docs-seeker skill to get current documentation:

```
Invoke Skill: docs-seeker
Args: "<primary framework> documentation llms.txt"
```

Example research queries:
- "Next.js 15 app router documentation"
- "Vite 6 configuration guide"
- "Bun CLI tool scaffolding"

### 2.3 Compare Tradeoffs

Present comparison to user:

```markdown
## Stack Comparison

| Option | Pros | Cons |
|--------|------|------|
| Next.js | Full-featured, great DX | Vercel-centric, complex |
| Vite + React | Fast, flexible | Manual routing/SSR setup |
| Remix | Web standards, simple | Smaller ecosystem |
```

### 2.4 Confirm Selection

```
Question: "Which tech stack would you like to use?"
Header: "Stack"
Options:
- <Option 1> (Recommended based on requirements)
- <Option 2>
- <Option 3>
- Other (I'll specify)
```

---

## Phase 3: Initialize (Execution)

### 3.1 Create Project Directory

```bash
# Ask for project name if not provided
PROJECT_NAME="${1:-my-project}"
PROJECT_DIR="$HOME/projects/$PROJECT_NAME"

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"
```

### 3.2 Scaffold Based on Stack

**Next.js:**
```bash
npx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"
```

**Vite + React:**
```bash
npm create vite@latest . -- --template react-ts
npm install
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

**CLI Tool (Node.js):**
```bash
npm init -y
npm install commander chalk
npm install -D typescript @types/node tsup
npx tsc --init
```

**Browser Extension (WXT):**
```bash
npx wxt@latest init . --template react
npm install
```

### 3.3 Create Environment Setup Script

Create `.claude/init.sh`:

```bash
#!/bin/bash
# Project initialization script for Claude Code

# Install dependencies if needed
if [ -f "package.json" ] && [ ! -d "node_modules" ]; then
  echo "Installing dependencies..."
  npm install
fi

# Environment checks
if [ -f ".env.example" ] && [ ! -f ".env" ]; then
  echo "Creating .env from .env.example..."
  cp .env.example .env
fi

# Start dev server in background (optional)
# npm run dev &

echo "Environment ready!"
```

```bash
chmod +x .claude/init.sh
```

### 3.4 Initialize Git

```bash
git init
git add .
git commit -m "chore: initial project scaffold"
```

---

## Phase 4: Setup (Configuration)

### 4.1 Find and Install Relevant Skills

Based on the selected stack, search for and install relevant skills from skillsmp.com:

**Stack-to-skill mappings:**

| Stack Component | Search Query | Example Skills |
|-----------------|--------------|----------------|
| Next.js | "nextjs app router production" | nextjs, react-patterns |
| React | "react hooks components" | shadcn-ui, react-query |
| Tailwind | "tailwindcss styling" | tailwindcss, ui-styling |
| TypeScript | "typescript strict patterns" | typescript-patterns |
| Testing | "vitest react testing" | testing-library |
| CLI | "nodejs cli commander" | cli-builder |

**Automatic skill installation:**

```bash
# Spawn skill-picker to search and install
Task tool:
  subagent_type: "conductor:skill-picker"
  prompt: |
    Search skillsmp.com for skills matching this project's stack:
    - Framework: <selected framework>
    - Styling: <selected styling>
    - Testing: <selected testing if any>

    For each relevant skill found:
    1. Preview the SKILL.md to verify quality
    2. If good (>100 stars, matches needs), install to .claude/skills/
    3. Skip skills that overlap with already-installed ones

    Install at least:
    - 1 framework skill (e.g., nextjs, react)
    - 1 UI skill (e.g., shadcn-ui, tailwindcss)

    Report what was installed.
```

**Already-installed skills check:**
```bash
# Check what's already available from plugins/user skills
ls ~/.claude/skills/ 2>/dev/null
curl -s http://localhost:8129/api/plugins/skills | jq -r '.skills[].id'
```

Skip installing skills that duplicate what's already available globally.

### 4.2 Create Project CLAUDE.md

Generate a project-specific CLAUDE.md:

```markdown
# CLAUDE.md - <Project Name>

## Overview

<Brief description based on brainstorm>

## Tech Stack

- **Framework:** <selected framework>
- **Styling:** <styling solution>
- **Testing:** <test framework if any>

## Commands

\`\`\`bash
npm run dev      # Start development server
npm run build    # Build for production
npm test         # Run tests
\`\`\`

## Project Structure

\`\`\`
src/
├── components/   # UI components
├── lib/          # Utilities and helpers
└── app/          # Routes (if using app router)
\`\`\`

## Orchestration Instructions

### Completion Protocol

**Before marking work complete**, run the conductor pipeline:

\`\`\`bash
/conductor:verify-build      # Build and check for errors
/conductor:code-review       # Opus review with auto-fix
/conductor:commit-changes    # Stage + commit
/conductor:close-issue <id>  # Close beads issue
bd sync && git push          # Push everything
\`\`\`

Or use the full pipeline: `/conductor:worker-done <id>`

See `.beads/PRIME.md` for detailed workflow documentation.

## Key Files

| File | Purpose |
|------|---------|
| `src/app/page.tsx` | Home page |
| `tailwind.config.js` | Tailwind configuration |

## Development Notes

- <Any stack-specific notes>
- <Common pitfalls to avoid>
```

### 4.3 Create Initial Beads Backlog

Initialize beads, create PRIME.md, and add setup tasks:

```bash
# Initialize beads if not present
if [ ! -d ".beads" ]; then
  bd init
fi

# Create PRIME.md for worker context (bd prime uses this file)
cat > .beads/PRIME.md << 'EOF'
# Beads Workflow Context

> **Context Recovery**: Run `bd prime` after compaction, clear, or new session

# SESSION CLOSE PROTOCOL

**CRITICAL**: Before saying "done" or "complete", run the conductor completion pipeline:

## Standard Completion
```bash
/conductor:verify-build      # Build and check for errors
/conductor:code-review       # Opus review with auto-fix
/conductor:commit-changes    # Stage + commit
/conductor:close-issue <id>  # Close beads issue
bd sync && git push          # Push everything
```

Or use: `/conductor:worker-done <id>` for full pipeline.

## Essential Commands

- `bd ready` - Show issues ready to work
- `bd show <id>` - View issue details
- `bd update <id> --status=in_progress` - Claim work
- `bd close <id>` - Mark complete
- `bd sync` - Sync with git remote

**NEVER skip verification.** Work is not done until pushed.
EOF

# Create initial setup tasks
bd create --title="Set up CI/CD pipeline" --type=task --priority=2
bd create --title="Configure testing framework" --type=task --priority=2
bd create --title="Add authentication" --type=feature --priority=3
bd create --title="Create initial UI components" --type=feature --priority=2
bd create --title="Write README documentation" --type=task --priority=3

# Track beads files for cross-machine sync
git add .beads/issues.jsonl .beads/PRIME.md
git commit -m "chore: initialize beads with workflow context"
```

### 4.4 Report Summary

```markdown
## Project Created Successfully!

**Location:** `~/projects/<project-name>`
**Stack:** <selected stack>
**Skills Installed:** <list of installed skills>

### Next Steps

1. `cd ~/projects/<project-name>`
2. `npm run dev` - Start development
3. `bd ready` - See available tasks
4. Start building!

### Beads Backlog

| ID | Task | Priority |
|----|------|----------|
| ... | Set up CI/CD pipeline | P2 |
| ... | Configure testing framework | P2 |
| ... | Create initial UI components | P2 |
```

---

## Notes

- Each phase can be run independently if needed
- Skip phases with `--skip-brainstorm`, `--skip-research`, etc.
- For existing projects, jump to Phase 4 for Claude Code setup
- Use `ultrathink` prefix for complex architecture decisions
- If context gets high, use `/wipe` between phases

Execute this workflow now.
