---
description: "Enhance beads issue prompts with skill hints, key files, and structured context. Prepares issues for workers ahead of time."
---

# Prompt Enhancer

Analyze beads issues and craft skill-aware enhanced prompts. Stores prepared prompts in issue notes for workers to use directly.

## When to Use

- Run `skills/engineering-prompts/scripts/lookahead-enhancer.sh` in background during `bd-swarm` for automatic enhancement
- Or use this command to understand the enhancement process

## Process Overview

```
For each ready issue:
  1. Get issue details (title, description, labels)
  2. Match skills using match-skills.sh
  3. Find key files via quick grep
  4. Build structured prompt
  5. Store in issue notes as prepared.prompt
```

## Step 1: Get Issue Details

```bash
ISSUE_JSON=$(bd show "$ISSUE_ID" --json)
TITLE=$(echo "$ISSUE_JSON" | jq -r '.[0].title // ""')
DESC=$(echo "$ISSUE_JSON" | jq -r '.[0].description // ""')
LABELS=$(echo "$ISSUE_JSON" | jq -r '.[0].labels[]?' | tr '\n' ' ')
```

## Step 2: Match Skills

Use the central skill matching script (single source of truth):

```bash
MATCH_SCRIPT="${CLAUDE_PLUGIN_ROOT:-./plugins/conductor}/scripts/match-skills.sh"

# Returns keyword phrases that trigger skill-eval hook
SKILL_KEYWORDS=$($MATCH_SCRIPT --verify "$TITLE $DESC $LABELS" 2>/dev/null | tr '\n' ' ')
```

**Key mappings** (see `match-skills.sh` for complete list):
- terminal/xterm/pty → xterm-js skill
- ui/component/modal → ui-styling skill
- backend/api/server → backend-development skill
- browser/mcp/tabz → tabz-mcp skill
- plugin/skill/agent → plugin-development skill

## Step 3: Find Key Files (Quick)

Do a **fast** search (max 30 seconds):

```bash
KEY_FILES=""
for keyword in $(echo "$TITLE $DESC" | tr ' ' '\n' | grep -E '^[a-z]{4,}$' | head -5); do
  FOUND=$(find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.md" -o -name "*.json" \) \
    -not -path "*/node_modules/*" 2>/dev/null | xargs grep -l "$keyword" 2>/dev/null | head -3)
  [ -n "$FOUND" ] && KEY_FILES="$KEY_FILES $FOUND"
done
KEY_FILES=$(echo "$KEY_FILES" | tr ' ' '\n' | sort -u | head -10 | tr '\n' ',' | sed 's/,$//')
```

**Rules:**
- Max 10 files total
- Skip files >500 lines (just note path)
- Prefer source over tests
- If slow, skip - let worker explore

## Step 4: Build Enhanced Prompt

Structure the prompt for worker consumption. See [../skills/engineering-prompts/references/worker-prompt-guidelines.md](../skills/engineering-prompts/references/worker-prompt-guidelines.md) for detailed best practices.

### Prompt Quality Principles

1. **Be explicit** - "Fix X" not "Can you suggest fixes for X"
2. **Add context** - Explain WHY, not just WHAT
3. **Reference patterns** - Point to existing code for consistency
4. **Soften language** - No ALL CAPS, MUST, NEVER (causes overtriggering)
5. **Positive framing** - "Do Y" not "Don't do X"

### Prompt Template

```markdown
Fix beads issue ISSUE-ID: "Title"

## Context
[Description from bd show - the WHY and implementation hints]

## Relevant Skills
[Skill keywords that trigger skill-eval hook]

## Key Files
[Comma-separated list of relevant files]

## When Done
Run: /conductor:worker-done ISSUE-ID
```

## Step 5: Store in Notes

Persist the prepared data to issue notes:

```bash
NOTES="prepared.skills: $SKILL_KEYWORDS
prepared.files: $KEY_FILES
prepared.prompt: |
$(echo "$PREPARED_PROMPT" | sed 's/^/  /')"

bd update "$ISSUE_ID" --notes "$NOTES"
```

Workers read `prepared.prompt` directly from notes - no exploration needed.

## Output Format

Each enhanced issue has in its notes:

| Field | Purpose |
|-------|---------|
| `prepared.skills` | Keyword phrases for skill activation |
| `prepared.files` | Key files to read first |
| `prepared.prompt` | Full prompt ready for worker |

## Performance Guidelines

| Aspect | Target |
|--------|--------|
| Time per issue | < 60 seconds |
| File search depth | Max 5 keywords |
| Files per issue | Max 10 |
| Total enhancement | < 10 minutes for 20 issues |

If enhancement is slow, skip file search - workers can explore.

## Related

| Resource | Purpose |
|----------|---------|
| `skills/engineering-prompts/references/worker-prompt-guidelines.md` | Prompt quality principles |
| `references/anthropic-prompting-guide.md` | Full Claude 4.x prompting guide |
| `scripts/match-skills.sh` | Central skill matching (single source of truth) |
| `skills/engineering-prompts/scripts/lookahead-enhancer.sh` | Batch enhancement during swarm |
| `/conductor:bd-swarm` | Main workflow that uses prepared prompts |
