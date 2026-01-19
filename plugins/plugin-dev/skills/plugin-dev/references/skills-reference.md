# Skills Reference

Complete reference for creating Claude Code skills.

## Skill Architecture

**Critical insight**: Skills are NOT in the system prompt. They exist in a meta-tool called `Skill` within the tools array. Claude uses LLM reasoning (not keyword matching) to decide which skills to activate based on descriptions.

**Mental Model**: "Building a skill for an agent is like putting together an onboarding guide for a new hire."

## SKILL.md Frontmatter Fields

```yaml
---
name: skill-name              # REQUIRED: lowercase, hyphens, max 64 chars
description: |                # REQUIRED: max 1024 chars, triggers discovery
  [Primary capabilities]. [Secondary features].
  Use when [3-4 trigger scenarios].
  Trigger with "[phrase 1]", "[phrase 2]".
allowed-tools: Read, Glob, Grep  # Optional: restrict tools (scoped to skill)
model: sonnet                 # Optional: sonnet, opus, haiku, inherit
version: "1.0.0"              # Optional: semantic versioning
mode: false                   # Optional: true = appears in "Mode Commands" section
disable-model-invocation: false  # Optional: true = manual /skill-name only
context: fork                 # Optional: isolated sub-agent context
agent: explore                # Optional: agent type with context: fork
user-invocable: true          # Optional: show in slash menu (default: true)
hooks:                        # Optional: skill-scoped hooks
  PreToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/scripts/validate.sh"
          once: true
---
```

## Field Details

| Field | Required | Values | Description |
|-------|----------|--------|-------------|
| `name` | Yes | lowercase-hyphens | 3-64 chars, no `anthropic` or `claude` |
| `description` | Yes | string | Max 1024 chars, use third person voice |
| `allowed-tools` | No | tool names | Scoped permissions, revert after skill completes |
| `model` | No | haiku/sonnet/opus/inherit | Model override |
| `version` | No | semver | Track skill evolution |
| `mode` | No | true/false | Categorize as mode command |
| `disable-model-invocation` | No | true/false | Prevent auto-activation |
| `context` | No | fork | Isolated sub-agent context |
| `user-invocable` | No | true/false | Show in slash menu |
| `hooks` | No | object | Skill-scoped hooks |

## CRITICAL: Description Budget

**All skill descriptions combined have a 15,000-character context budget.**

If exceeded, Claude silently filters out skills causing unpredictable discovery failures.

**Scaling Formula:**
```
(Number of Skills) × (Avg Chars per Description) < 15,000 chars
```

| Skills | Avg Chars | Total | Status |
|--------|-----------|-------|--------|
| 20 | 400 | 8,000 | Safe |
| 30 | 400 | 12,000 | Caution |
| 40 | 400 | 16,000 | Exceeds budget |

**Best Practice**: Target 300-400 characters per description, not the 1024 max.

## Description Best Practices

Descriptions use **third person** voice (injected into system prompt):

```yaml
# GOOD - Clear triggers, third person
description: |
  Extract text and tables from PDF files, fill forms, merge documents.
  Use when working with PDF files or when user mentions PDFs, forms,
  or document extraction. Trigger with "process PDF", "fill form".

# GOOD - Action-oriented
description: |
  Generate commit messages by analyzing git diffs. Use when user asks
  for help writing commit messages or reviewing staged changes.
  Trigger with "write commit message", "analyze my changes".

# BAD - Vague
description: Helps with documents.

# BAD - First person
description: I can process your PDFs.

# BAD - Second person
description: You can use this for data.
```

## Three-Tier Progressive Disclosure

**"The amount of context bundled into a skill is effectively unbounded"** - Anthropic Engineering

| Tier | Content | When Loaded | Token Cost |
|------|---------|-------------|------------|
| 1 | Metadata (name + description) | Session start | ~100 chars (always) |
| 2 | Full SKILL.md body | Skill activates | ~2,000 tokens |
| 3 | References/scripts | On-demand | 0 until needed |

**Key Insight**: Only Tier 1 counts against the 15,000-char budget. You can bundle massive reference materials (10,000+ words) with zero context penalty until actually loaded.

### Directory Structure

```
skill-name/
├── SKILL.md              # Tier 2: Core instructions (<500 lines, <5000 words)
├── references/           # Tier 3: Docs loaded on-demand
│   ├── API_REFERENCE.md  # (loaded only if API questions)
│   ├── EXAMPLES.md       # (loaded only if user asks)
│   └── TROUBLESHOOTING.md
├── scripts/              # Tier 3: Executed, NOT loaded into context
│   ├── analyze.py
│   └── validate.py
└── assets/               # Referenced by path only
    └── template.md
```

### Token Costs

| Directory | Loaded Into Context? | Token Cost |
|-----------|---------------------|------------|
| `scripts/` | No (executed via Bash) | None (only output counts) |
| `references/` | Yes (via Read tool) | High (load on-demand) |
| `assets/` | No (path reference only) | None |

**Code Execution Economics**: Deterministic code execution is **200x cheaper** than token generation for algorithmic tasks.

## Scoped Tool Access

Tool permissions are **scoped to skill execution only** and **revert automatically**:

```yaml
# Read-only skill
allowed-tools: Read, Glob, Grep

# Scoped bash - restrict to specific commands
allowed-tools: "Bash(git:*),Bash(python:*),Read,Grep"

# NPM operations only
allowed-tools: "Bash(npm:*),Bash(npx:*),Read,Write"
```

**Security Principle**: Grant ONLY tools the skill actually requires.

**Note**: `allowed-tools` only supported in Claude Code, not claude.ai web.

## One-Level-Deep References

**AVOID deeply nested references**. Claude may only partially read nested files.

```
# BAD
SKILL.md → advanced.md → details.md → actual_info.md

# GOOD
SKILL.md → advanced.md
SKILL.md → reference.md
SKILL.md → examples.md
```

## Mutually Exclusive Contexts

Split reference files when contexts are NEVER used together:

```
my-skill/
├── SKILL.md
└── references/
    ├── FORECASTING.md       # Forecasting workflows
    ├── FINETUNING.md        # Fine-tuning (mutually exclusive)
    ├── ANOMALY_DETECTION.md # Anomaly detection (mutually exclusive)
    └── TROUBLESHOOTING.md   # Only on errors
```

**Context Savings**: Load only relevant file instead of all 4.

## Skill-Scoped Hooks

Hooks activate only while skill is loaded:

```yaml
---
name: safe-editor
hooks:
  PreToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/scripts/validate.sh"
          once: true  # Run only once per session
  Stop:
    - hooks:
        - type: prompt
          prompt: "Verify all edits follow style guide: $ARGUMENTS"
---
```

## Skill Validation Errors

| Error | Cause | Fix |
|-------|-------|-----|
| Empty command input | Missing command parameter | Pass valid skill name |
| Unknown skill | Not in skills directory | Check path/naming |
| Loading failure | Malformed YAML/encoding | Validate YAML, check UTF-8 |
| Model invocation disabled | `disable-model-invocation: true` | Use `/skill-name` manually |
| Skill type not supported | Experimental skill type | Use standard SKILL.md |

## When to Use `disable-model-invocation: true`

For skills that:
- Perform destructive operations
- Deploy to production
- Access sensitive credentials
- Should NEVER auto-activate

```yaml
---
name: deploy-production
description: Deploy to production. Dangerous - requires explicit invocation.
disable-model-invocation: true
allowed-tools: "Bash(deploy:*),Read,Glob"
---
```

## Writing Style

Use **imperative voice** in instructions:

| Correct | Incorrect |
|---------|-----------|
| "Analyze the data." | "You should analyze..." |
| "Validate inputs before use." | "You need to validate..." |
| "Parse the frontmatter." | "You can parse the frontmatter..." |

## Testing Skills

```bash
# Test skill in isolation
claude --skill-dir ./my-skill

# Invoke directly
/my-skill

# Validate YAML
python -c "import yaml; yaml.safe_load(open('SKILL.md').read().split('---')[1])"
```

## Production Checklist

**Naming & Description:**
- [ ] `name` matches folder name (lowercase + hyphens)
- [ ] `name` under 64 chars, no reserved words
- [ ] `description` under 1024 chars (target 300-400)
- [ ] `description` uses third person voice
- [ ] `description` includes what + when + trigger phrases

**Structure:**
- [ ] SKILL.md at root of skill folder
- [ ] Body under 500 lines / 5000 words
- [ ] Uses `${CLAUDE_PLUGIN_ROOT}` for paths
- [ ] `allowed-tools` minimal and necessary
- [ ] One-level-deep references only

**Content:**
- [ ] All required sections present
- [ ] Imperative voice throughout
- [ ] 2-3 concrete examples with input/output
- [ ] 4+ common errors documented
- [ ] All referenced files exist

**Testing:**
- [ ] Triggers correctly on intended phrases
- [ ] Does NOT trigger on unrelated requests
- [ ] Tested with Haiku, Sonnet, and Opus

## Anti-Patterns

| Anti-Pattern | Fix |
|--------------|-----|
| Hardcoded paths | Use `${CLAUDE_PLUGIN_ROOT}` or `{baseDir}` |
| 10,000+ word SKILL.md | Split to references/ |
| Vague "helps with X" description | Specific triggers + phrases |
| Unscoped `Bash` access | Scope to commands: `Bash(git:*)` |
| Exceeding description budget | Target 300-400 chars each |
| Deeply nested references | One-level-deep only |
