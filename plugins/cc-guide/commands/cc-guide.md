---
description: Use when users ask about Claude Code features, setup, slash commands, MCP servers, agent skills, hooks, plugins, IDE integration, enterprise deployment, or troubleshooting Claude Code issues.
version: 1.0.0
---

# Claude Code Expert

Claude Code is Anthropic's agentic coding tool that lives in the terminal and helps turn ideas into code faster. It combines autonomous planning, execution, and validation with extensibility through skills, plugins, MCP servers, and hooks.

## When to Use This Skill

Use when users need help with:
- Understanding Claude Code features and capabilities
- Installation, setup, and authentication
- Using slash commands for development workflows
- Creating or managing Agent Skills
- Configuring MCP servers for external tool integration
- Setting up hooks and plugins
- Troubleshooting Claude Code issues
- Enterprise deployment (SSO, sandboxing, monitoring)
- IDE integration (VS Code, JetBrains)
- CI/CD integration (GitHub Actions, GitLab)
- Advanced features (extended thinking, caching, checkpointing)
- Cost tracking and optimization

**Activation examples:**
- "How do I use Claude Code?"
- "What slash commands are available?"
- "How to set up MCP servers?"
- "Create a new skill for X"
- "Fix Claude Code authentication issues"
- "Deploy Claude Code in enterprise environment"

## Core Architecture

**Subagents**: Specialized AI agents (planner, code-reviewer, tester, debugger, docs-manager, ui-ux-designer, database-admin, etc.)

**Agent Skills**: Modular capabilities with instructions, metadata, and resources that Claude uses automatically

**Slash Commands**: User-defined operations in `.claude/commands/` that expand to prompts

**Hooks**: Shell commands executing in response to events (pre/post-tool, user-prompt-submit)

**MCP Servers**: Model Context Protocol integrations connecting external tools and services

**Plugins**: Packaged collections of commands, skills, hooks, and MCP servers

## Quick Reference

Load these references when needed for detailed guidance:

### Getting Started
- **Installation & Setup**: `${CLAUDE_PLUGIN_ROOT}/references/getting-started.md`
  - Prerequisites, installation methods, authentication, first run

### Development Workflows
- **Slash Commands**: `${CLAUDE_PLUGIN_ROOT}/references/slash-commands.md`
  - Complete command catalog: /cook, /plan, /debug, /test, /fix:*, /docs:*, /git:*, /design:*, /content:*

- **Agent Skills**: `${CLAUDE_PLUGIN_ROOT}/references/agent-skills.md`
  - Creating skills, skill.json format, best practices, API usage

### Integration & Extension
- **MCP Integration**: `${CLAUDE_PLUGIN_ROOT}/references/mcp-integration.md`
  - Configuration, common servers, remote servers

- **Hooks & Plugins**: `${CLAUDE_PLUGIN_ROOT}/references/hooks-and-plugins.md`
  - Hook types, configuration, environment variables, plugin structure, installation

### Configuration & Settings
- **Configuration**: `${CLAUDE_PLUGIN_ROOT}/references/configuration.md`
  - Settings hierarchy, key settings, model configuration, output styles

### Enterprise & Production
- **Enterprise Features**: `${CLAUDE_PLUGIN_ROOT}/references/enterprise-features.md`
  - IAM, SSO, RBAC, sandboxing, audit logging, deployment options, monitoring

- **IDE Integration**: `${CLAUDE_PLUGIN_ROOT}/references/ide-integration.md`
  - VS Code extension, JetBrains plugin setup and features

- **CI/CD Integration**: `${CLAUDE_PLUGIN_ROOT}/references/cicd-integration.md`
  - GitHub Actions, GitLab CI/CD workflow examples

### Advanced Usage
- **Advanced Features**: `${CLAUDE_PLUGIN_ROOT}/references/advanced-features.md`
  - Extended thinking, prompt caching, checkpointing, memory management

- **Troubleshooting**: `${CLAUDE_PLUGIN_ROOT}/references/troubleshooting.md`
  - Common issues, authentication failures, MCP problems, performance, debug mode

- **API Reference**: `${CLAUDE_PLUGIN_ROOT}/references/api-reference.md`
  - Admin API, Messages API, Files API, Models API, Skills API

- **Best Practices**: `${CLAUDE_PLUGIN_ROOT}/references/best-practices.md`
  - Project organization, security, performance, team collaboration, cost management

## Common Workflows

### Feature Implementation
```bash
/cook implement user authentication with JWT
# Or plan first
/plan implement payment integration with Stripe
```

### Bug Fixing
```bash
/fix:fast the login button is not working
/debug the API returns 500 errors intermittently
/fix:types  # Fix TypeScript errors
```

### Code Review & Testing
```bash
claude "review my latest commit"
/test
/fix:test the user service tests are failing
```

### Documentation
```bash
/docs:init      # Create initial documentation
/docs:update    # Update existing docs
/docs:summarize # Summarize changes
```

### Git Operations
```bash
/git:cm                    # Stage and commit
/git:cp                    # Stage, commit, and push
/git:pr feature-branch main  # Create pull request
```

### Design & Content
```bash
/design:fast create landing page for SaaS product
/content:good write product description for new feature
```

## Instructions for Claude

When responding to Claude Code questions:

1. **Identify the topic** from the user's question
2. **Load relevant references** from the Quick Reference section above
3. **Provide specific guidance** using information from loaded references
4. **Include examples** when helpful
5. **Reference official docs** when appropriate (docs.claude.com/claude-code)

**Loading references:**
- Read reference files only when needed for the specific question
- Multiple references can be loaded for complex queries
- Use grep patterns if searching within references

**For setup/installation questions:** Load `${CLAUDE_PLUGIN_ROOT}/references/getting-started.md`

**For slash command questions:** Load `${CLAUDE_PLUGIN_ROOT}/references/slash-commands.md`

**For skill creation:** Load `${CLAUDE_PLUGIN_ROOT}/references/agent-skills.md`

**For MCP questions:** Load `${CLAUDE_PLUGIN_ROOT}/references/mcp-integration.md`

**For hooks/plugins:** Load `${CLAUDE_PLUGIN_ROOT}/references/hooks-and-plugins.md`

**For configuration:** Load `${CLAUDE_PLUGIN_ROOT}/references/configuration.md`

**For enterprise deployment:** Load `${CLAUDE_PLUGIN_ROOT}/references/enterprise-features.md`

**For IDE integration:** Load `${CLAUDE_PLUGIN_ROOT}/references/ide-integration.md`

**For CI/CD:** Load `${CLAUDE_PLUGIN_ROOT}/references/cicd-integration.md`

**For advanced features:** Load `${CLAUDE_PLUGIN_ROOT}/references/advanced-features.md`

**For troubleshooting:** Load `${CLAUDE_PLUGIN_ROOT}/references/troubleshooting.md`

**For API usage:** Load `${CLAUDE_PLUGIN_ROOT}/references/api-reference.md`

**For best practices:** Load `${CLAUDE_PLUGIN_ROOT}/references/best-practices.md`

**Documentation links:**
- Main docs: https://docs.claude.com/claude-code
- GitHub: https://github.com/anthropics/claude-code
- Support: support.claude.com

Provide accurate, actionable guidance based on the loaded references and official documentation.
