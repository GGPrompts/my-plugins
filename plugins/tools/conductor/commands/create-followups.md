---
description: "Analyze work and create follow-up beads issues if needed."
---

# Create Follow-ups

Analyze completed work and create follow-up beads issues for discovered work. This is a standalone atomic command.

## Usage

```
/conductor:create-followups
/conductor:create-followups <parent-issue-id>
```

## When to Use

Always run after completing a task to capture:
- Implementation work from research/spike tasks
- Edge cases discovered during feature work
- Root cause fixes beyond immediate bug fix
- Remaining cleanup from refactors

## Execute

### 1. Analyze Task Type

```bash
echo "=== Create Follow-ups ==="

# Check what was done
echo "Recent commit:"
git log -1 --oneline

echo ""
echo "Files changed:"
git diff HEAD~1 --name-only 2>/dev/null || git diff --cached --name-only
echo ""
```

### 2. Determine if Follow-ups Needed

| Task Type | Follow-up Action |
|-----------|------------------|
| Research/Spike | Create implementation issues from findings |
| Feature | Create issues for edge cases, TODOs, enhancements |
| Bug fix | Create issues if root cause reveals other problems |
| Refactor | Create issues for remaining cleanup |

### 3. Check for TODOs in Changes

```bash
# Find TODOs in changed files
echo "Checking for TODOs in changes..."
git diff HEAD~1 --name-only 2>/dev/null | xargs grep -n "TODO\|FIXME\|HACK" 2>/dev/null || echo "No TODOs found"
echo ""
```

### 4. Create Follow-up Issues with `discovered-from` Links

**IMPORTANT:** Always link new issues with `discovered-from` dependency to maintain context chain.

**For research tasks:**
```bash
# Example: Research completed, create implementation issues
NEW_ISSUE=$(bd create --title "Implement <finding from research>" \
  --type feature \
  --priority 2 \
  --description "Based on research in $PARENT_ISSUE. See docs/research/..." \
  --json | jq -r '.id')

# Link with discovered-from dependency
bd dep add "$NEW_ISSUE" discovered-from "$PARENT_ISSUE"
echo "Created: $NEW_ISSUE (discovered from $PARENT_ISSUE)"
```

**For discovered edge cases:**
```bash
NEW_ISSUE=$(bd create --title "Handle edge case: <description>" \
  --type bug \
  --priority 3 \
  --description "Discovered during $PARENT_ISSUE implementation" \
  --json | jq -r '.id')

bd dep add "$NEW_ISSUE" discovered-from "$PARENT_ISSUE"
```

**For TODOs:**
```bash
NEW_ISSUE=$(bd create --title "Address TODO: <description>" \
  --type chore \
  --priority 4 \
  --description "TODO found in <file>:<line> during $PARENT_ISSUE" \
  --json | jq -r '.id')

bd dep add "$NEW_ISSUE" discovered-from "$PARENT_ISSUE"
```

**Why `discovered-from`:** This creates a traceable chain showing where work originated. When reviewing the backlog later, you can see which issues spawned other issues.

### 5. Report Results

```bash
echo "=== Follow-up Summary ==="
echo ""
# List created issues or "none"
```

## Output Format

```json
{
  "created": ["TabzChrome-abc", "TabzChrome-def"],
  "skipped": false
}
```

Or if no follow-ups needed:

```json
{
  "created": [],
  "skipped": true,
  "reason": "no follow-up work identified"
}
```

## Guidelines

**DO create issues for:**
- Concrete implementation work from research
- Specific edge cases that need handling
- TODOs that should be tracked

**DON'T create issues for:**
- Vague "might be nice" ideas
- Duplicate existing issues
- Work that's out of scope for the project

## Ask User if Unsure

If unsure whether to create follow-ups:

```markdown
AskUserQuestion: "Should I create follow-up issues for: [list items]?"
```

## Composable With

- `/conductor:commit-changes` - Run after commit
- `/conductor:update-docs` - Run before or after
- `/conductor:close-issue` - Run before closing
- `/conductor:worker-done` - Full pipeline that includes this
