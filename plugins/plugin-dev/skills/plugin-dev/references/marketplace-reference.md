# Marketplace Reference

Complete reference for creating and distributing Claude Code plugin marketplaces.

## marketplace.json Schema

Located at `.claude-plugin/marketplace.json` in marketplace root:

```json
{
  "name": "my-marketplace",        // REQUIRED: unique identifier
  "owner": {
    "name": "Your Name",           // REQUIRED
    "email": "you@example.com",    // Optional
    "url": "https://github.com/you" // Optional
  },
  "metadata": {
    "description": "Marketplace description",
    "version": "1.0.0",
    "pluginRoot": "./plugins"      // Base path for relative sources
  },
  "plugins": [
    {
      "name": "plugin-name",       // REQUIRED
      "source": "./plugins/name",  // REQUIRED: path, GitHub, or Git URL
      "description": "Plugin description",
      "version": "1.0.0",
      "author": { "name": "Author" },
      "category": "development",
      "tags": ["tag1", "tag2"],
      "keywords": ["keyword1"],
      "strict": true               // Require plugin.json in source
    }
  ]
}
```

## Plugin Sources

### Relative Path (Git-based marketplaces)

```json
{
  "name": "local-plugin",
  "source": "./plugins/local-plugin"
}
```

### GitHub Repository

```json
{
  "name": "github-plugin",
  "source": {
    "source": "github",
    "repo": "owner/plugin-repo",
    "ref": "main"                  // Optional: branch, tag, commit
  }
}
```

### Git URL

```json
{
  "name": "git-plugin",
  "source": {
    "source": "url",
    "url": "https://gitlab.com/team/plugin.git",
    "ref": "v1.0.0"
  }
}
```

## Directory Structure

```
my-marketplace/
├── .claude-plugin/
│   └── marketplace.json   # Marketplace manifest
├── plugins/
│   ├── plugin-a/
│   │   ├── plugin.json    # Plugin manifest (at plugin root!)
│   │   ├── skills/
│   │   └── commands/
│   └── plugin-b/
│       ├── plugin.json
│       └── ...
└── README.md              # Documentation
```

**Critical:** In marketplace pattern, each plugin has `plugin.json` at its root (NOT in `.claude-plugin/` subdirectory).

## Marketplace Commands

```bash
# Add marketplace (local)
/plugin marketplace add ./my-marketplace

# Add marketplace (GitHub)
/plugin marketplace add https://github.com/owner/marketplace

# List marketplaces
/plugin marketplace list

# Remove marketplace
/plugin marketplace remove my-marketplace

# Refresh marketplace (fetch updates)
/plugin marketplace refresh my-marketplace

# Install from marketplace
/plugin install marketplace:my-marketplace/plugin-name
```

## Private Repository Authentication

Set environment variables for private repos:

```bash
# GitHub
export GITHUB_TOKEN=ghp_xxxxxxxxxxxx

# GitLab
export GITLAB_TOKEN=glpat-xxxxxxxxxxxx

# Bitbucket
export BITBUCKET_TOKEN=xxxxxxxxxxxx
```

## Reserved Marketplace Names

These names are blocked:
- `claude-code-marketplace`
- `claude-code-plugins`
- `claude-plugins-official`
- `anthropic-marketplace`
- `anthropic-plugins`
- `agent-skills`
- `life-sciences`

## Categories

Standard categories for organization:

| Category | Description |
|----------|-------------|
| `frontend` | UI, React, CSS, design |
| `backend` | APIs, servers, databases |
| `devops` | CI/CD, Docker, cloud |
| `tools` | Development utilities |
| `testing` | Test frameworks, mocking |
| `docs` | Documentation generation |
| `ai` | AI/ML integrations |
| `security` | Security scanning, auditing |

## Publishing Workflow

### Local Testing

```bash
# Add local marketplace
/plugin marketplace add ./my-marketplace

# Test plugin installation
/plugin install marketplace:my-marketplace/my-plugin

# Validate plugins
claude plugin validate ./my-marketplace/plugins/my-plugin
```

### GitHub Distribution

1. Create GitHub repository
2. Push marketplace.json and plugins/
3. Share: `/plugin marketplace add https://github.com/owner/marketplace`

### Version Management

- Bump `metadata.version` for marketplace changes
- Bump plugin `version` for plugin updates
- Users can refresh to get updates: `/plugin marketplace refresh name`

## Managed Marketplaces

Organizations can restrict marketplace access:

```json
// managed-settings.json
{
  "strictKnownMarketplaces": true,
  "knownMarketplaces": [
    "https://github.com/company/approved-marketplace"
  ]
}
```

When `strictKnownMarketplaces` is true, only listed marketplaces can be added.

## Best Practices

1. **Unique Names** - Avoid conflicts with official plugins
2. **Clear Descriptions** - Help users find plugins
3. **Semantic Versioning** - MAJOR.MINOR.PATCH
4. **Categories & Tags** - Organize plugins logically
5. **Keywords** - Enable search discovery
6. **Documentation** - Include README with setup instructions
7. **Testing** - Validate all plugins before publishing
8. **Private Repos** - Document required tokens

## Troubleshooting

```bash
# Check marketplace status
/plugin marketplace list

# Force refresh
/plugin marketplace refresh my-marketplace

# Check plugin validity
claude plugin validate ./plugins/my-plugin

# View installed plugins
/plugin list
```

| Issue | Solution |
|-------|----------|
| Marketplace not found | Check URL/path, ensure marketplace.json exists |
| Plugin install fails | Validate plugin.json at plugin root |
| Private repo access denied | Set appropriate token env var |
| Updates not appearing | Run marketplace refresh |
