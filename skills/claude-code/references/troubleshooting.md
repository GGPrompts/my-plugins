# Troubleshooting and Best Practices

## Common Issues

### MCP Server Connection Issues
```bash
# Test MCP server
npx @anthropic-ai/mcp-inspector

# Check MCP configuration
cat .mcp.json
```

### Performance Issues
- Reduce context window size
- Use appropriate model (Haiku for speed)
- Clear memory cache with `/clear`

### Permission Errors
- Check file permissions
- Review hook configurations
- Verify sandboxing settings

### Debug Mode
```bash
# Enable verbose logging
claude --verbose
```

---

## Best Practices

### Project Organization
- Keep `.claude/` directory in version control
- Document custom commands and skills
- Use project-specific settings in `.claude/settings.json`

### Security
- Never commit API keys
- Use environment variables for secrets
- Review hook scripts before execution
- Audit plugin sources

### Performance
- Choose appropriate model for task
- Use Haiku for simple/fast tasks
- Implement rate limiting in hooks

### Team Collaboration
- Standardize slash commands across projects
- Share useful skills via plugins
- Document custom configurations

---

## Configuration

### Settings Hierarchy
1. Global: `~/.claude/settings.json`
2. Project: `.claude/settings.json`
3. Environment variables
4. Command-line flags

### Key Settings
```json
{
  "model": "sonnet",
  "permissions": {
    "allow": ["Bash(npm:*)", "Read", "Write"],
    "deny": ["Bash(rm -rf /*)"]
  },
  "hooks": { ... }
}
```

---

## Advanced Features

### Extended Thinking
For complex problems, Claude uses extended thinking automatically with Opus.

### Memory
Claude remembers context across sessions:
- View with `/memory`
- Clear with `/clear`

### Checkpointing
Track and rewind changes during a session.

---

## Getting Help
- Documentation: https://docs.anthropic.com/claude-code
- GitHub Issues: https://github.com/anthropics/claude-code/issues
