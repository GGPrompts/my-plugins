# Plugin Debugging Guide

## Debug Mode

Run Claude Code with `--debug` flag to see detailed plugin loading information:

```bash
claude --debug
```

This shows:
- Which plugins are being loaded
- Errors in plugin manifests
- Command, agent, and hook registration
- MCP server initialization
- Skill discovery results

## Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Plugin not loading | Invalid plugin.json | Validate JSON syntax with `claude plugin validate` |
| Skills not discovered | Nested skills (`skills/a/skills/b/`) | Flatten to `skills/b/SKILL.md` |
| Skills not showing in menu | Missing from marketplace `skills` array | Add explicit skill paths to marketplace.json |
| Commands not appearing | Wrong directory structure | Ensure `commands/` at plugin root |
| Marketplace plugin.json wrong location | `plugins/X/.claude-plugin/plugin.json` | Move to `plugins/X/plugin.json` |
| Hooks not firing | Script not executable | Run `chmod +x script.sh` |
| MCP server fails to start | Missing CLAUDE_PLUGIN_ROOT | Use `${CLAUDE_PLUGIN_ROOT}` variable in paths |
| Path errors in hooks/MCP | Absolute paths used | All paths must be relative with `./` |
| Plugins not appearing after update | Stale cache | Clear cache: `rm -rf ~/.claude/plugins/cache/<marketplace>` |
| Standalone and marketplace conflict | Both manifests present | Remove one - use only `plugin.json` OR `marketplace.json` |
| Skills hot-reload not working | Wrong location | Skills must be in `~/.claude/skills` or `.claude/skills` |
| Agent not spawning | Missing or invalid frontmatter | Check YAML frontmatter in agent.md |
| Command prefixing confusion | Multiple plugins with same command | Use `plugin-name:command` format |

## Validation

Validate plugin structure before publishing:

```bash
# Validate a plugin directory
claude plugin validate /path/to/plugin

# Validate marketplace
claude plugin validate /path/to/marketplace
```

## Cache Locations

| Path | Purpose | Clear when |
|------|---------|------------|
| `~/.claude/plugins/cache/<marketplace>/` | Installed plugin files | Plugin updates not reflecting |
| `~/.claude/plugins/installed_plugins.json` | Installation records | Plugin state corrupted |
| `~/.claude/plugins/known_marketplaces.json` | Registered marketplaces | Marketplace list wrong |

## Quick Fixes

### Plugin Not Loading

1. Check JSON syntax: `cat plugin.json | jq .`
2. Verify manifest location:
   - Standalone: `.claude-plugin/plugin.json`
   - Marketplace plugin: `plugin.json` at plugin root
3. Run `claude --debug` to see errors

### Skills Not Found

1. Verify structure: `skills/<name>/SKILL.md`
2. Check for nesting: skills should be ONE level deep
3. Add explicit paths to marketplace.json `skills` array

### Hooks Not Executing

1. Check script permissions: `chmod +x scripts/*.sh`
2. Use `${CLAUDE_PLUGIN_ROOT}` for absolute paths
3. Verify hook event name matches (case-sensitive)

### MCP Server Fails

1. Test server independently: `npx @company/mcp-server`
2. Check `cwd` uses `${CLAUDE_PLUGIN_ROOT}`
3. Verify all dependencies installed

## Force Refresh

When changes don't appear:

```bash
# Clear marketplace cache
rm -rf ~/.claude/plugins/cache/<marketplace-name>

# Restart Claude Code
/restart
```

## Logging Hook Output

For debugging hooks, log to a file:

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write",
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/scripts/hook.sh 2>&1 | tee /tmp/hook.log"
      }]
    }]
  }
}
```

Then check `/tmp/hook.log` for output.
