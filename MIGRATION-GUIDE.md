# Migration Guide - Consolidated Skills

This guide helps you update references to the old skill names.

## Quick Reference Table

| Old Skill Invocation | New Invocation | Specific Topic |
|---------------------|----------------|----------------|
| `/plugin-dev:buildingplugins` | `/plugin-dev:plugin-dev` | Main overview |
| `/plugin-dev:command-development` | `/plugin-dev:plugin-dev` | Then: @references/commands-reference.md |
| `/plugin-dev:skill-development` | `/plugin-dev:plugin-dev` | Then: @references/skills-reference.md |
| `/plugin-dev:agent-development` | `/plugin-dev:plugin-dev` | Then: @references/agents-reference.md |
| `/plugin-dev:hook-development` | `/plugin-dev:plugin-dev` | Then: @references/hooks-reference.md |
| `/plugin-dev:mcp-integration` | `/plugin-dev:plugin-dev` | Then: @references/mcp-reference.md |
| `/plugin-dev:marketplace-development` | `/plugin-dev:plugin-dev` | Then: @references/marketplace-reference.md |
| `/plugin-dev:plugin-structure` | `/plugin-dev:plugin-dev` | Then: @references/structure.md |
| `/plugin-dev:plugin-settings` | `/plugin-dev:plugin-dev` | Then: @references/settings.md |
| | | |
| `/debugging:systematic-debugging` | `/debugging:debugging` | Main framework |
| `/debugging:root-cause-tracing` | `/debugging:debugging` | Then: @references/root-cause.md |
| `/debugging:defense-in-depth` | `/debugging:debugging` | Then: @references/defense-in-depth.md |
| `/debugging:verification-before-completion` | `/debugging:debugging` | Then: @references/verification.md |
| | | |
| `/problem-solving:collision-zone-thinking` | `/problem-solving:problem-solving` | Then: @references/collision-zones.md |
| `/problem-solving:simplification-cascades` | `/problem-solving:problem-solving` | Then: @references/simplification.md |
| `/problem-solving:meta-pattern-recognition` | `/problem-solving:problem-solving` | Then: @references/meta-patterns.md |
| `/problem-solving:scale-game` | `/problem-solving:problem-solving` | Then: @references/scale-game.md |
| `/problem-solving:inversion-exercise` | `/problem-solving:problem-solving` | Then: @references/inversion.md |
| `/problem-solving:when-stuck` | `/problem-solving:problem-solving` | Then: @references/when-stuck.md |

## How Progressive Disclosure Works

### Old Way (Multiple Skills)
```
User: "How do I create a command?"
Assistant: /plugin-dev:command-development
[Loads entire command-development SKILL.md]
```

### New Way (Single Entry Point + References)
```
User: "How do I create a command?"
Assistant: /plugin-dev:plugin-dev
[Loads main overview, sees topic index]
[Reads @references/commands-reference.md for details]
[Only loads what's needed]
```

## Benefits of New Approach

1. **Faster Discovery** - One skill per domain, not 9
2. **Less Token Usage** - Main skill is brief (~200 tokens)
3. **On-Demand Details** - References load only when needed
4. **Worker-Friendly** - Clear entry points in skill list

## For Documentation/Script Authors

If you have documentation or scripts that reference old skill names:

### Search and Replace Patterns

```bash
# Find references to old skills
grep -r "plugin-dev:buildingplugins" .
grep -r "debugging:systematic-debugging" .
grep -r "problem-solving:collision-zone" .

# Replace with new unified names
# plugin-dev:* → plugin-dev:plugin-dev
# debugging:* → debugging:debugging  
# problem-solving:* → problem-solving:problem-solving
```

### Example Updates

**Before:**
```markdown
For plugin development, see /plugin-dev:buildingplugins
For command creation, see /plugin-dev:command-development
For debugging, use /debugging:systematic-debugging
```

**After:**
```markdown
For plugin development, see /plugin-dev:plugin-dev
For command creation, see /plugin-dev:plugin-dev (commands-reference.md)
For debugging, use /debugging:debugging
```

## Backward Compatibility Notes

- **Old skills removed** - Invocations like `/plugin-dev:buildingplugins` will fail
- **All content preserved** - Check references/ folder for specific topics
- **Same knowledge** - Nothing deleted, just reorganized

## Questions?

- Check `REFACTOR-SUMMARY.md` for detailed changelog
- See `references/` folders for specific topic documentation
- Test with `/audit` to verify structure compliance
