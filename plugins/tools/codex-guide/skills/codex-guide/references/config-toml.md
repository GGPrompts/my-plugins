# Complete config.toml Reference

All Codex configuration lives in `~/.codex/config.toml`.

## Authentication & Access

```toml
# Restrict login method
forced_login_method = "chatgpt"  # chatgpt | api

# Credential storage
cli_auth_credentials_store = "auto"  # file | keyring | auto

# Limit to specific workspace (UUID)
forced_chatgpt_workspace_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

## Model Settings

```toml
# Model selection
model = "gpt-5-codex"

# Provider (default: openai)
model_provider = "openai"  # or custom provider ID

# Context window size
model_context_window = 128000

# Auto-compact threshold
model_auto_compact_token_limit = 100000

# Reasoning effort (Responses API only)
model_reasoning_effort = "medium"  # minimal | low | medium | high | xhigh

# Verbosity (GPT-5 Responses API)
model_verbosity = "medium"  # low | medium | high
```

## Security & Sandbox

```toml
# Sandbox mode
sandbox_mode = "workspace-write"  # read-only | workspace-write | danger-full-access

# Approval policy
approval_policy = "on-failure"  # untrusted | on-failure | on-request | never

# Per-project trust levels
[projects."/home/user/my-project"]
trust_level = "trusted"  # trusted | untrusted

[projects."/home/user/another-project"]
trust_level = "untrusted"
```

## Shell Environment

```toml
[shell_environment_policy]
# Inherit environment variables
inherit = "all"  # all | core | none

# Explicitly set variables
[shell_environment_policy.set]
NODE_ENV = "development"
DEBUG = "true"

# Exclude patterns (glob)
exclude = ["AWS_*", "GITHUB_TOKEN"]
```

## Feature Flags

```toml
[features]
# Stable features
shell_tool = true
parallel = true
view_image_tool = true
warnings = true

# Beta features
unified_exec = true
shell_snapshot = true

# Experimental features
tui2 = true
remote_compaction = true
skills = true
```

## Tools Configuration

```toml
[tools]
# Enable image viewing
view_image = true

# Enable web search
web_search = true
```

## Notifications

```toml
# Command to receive JSON notification payloads
notify = "notify-send"
```

## Admin Enforcement (requirements.toml)

System admins can enforce policies via `/etc/codex/requirements.toml`:

```toml
# Restrict available approval policies
allowed_approval_policies = ["untrusted", "on-failure"]

# Restrict available sandbox modes
allowed_sandbox_modes = ["read-only", "workspace-write"]
```

## Full Example

```toml
# ~/.codex/config.toml

model = "gpt-5-codex"
model_reasoning_effort = "medium"
sandbox_mode = "workspace-write"
approval_policy = "on-failure"

[features]
parallel = true
skills = true

[shell_environment_policy]
inherit = "core"
exclude = ["AWS_*", "OPENAI_API_KEY"]

[projects."/home/user/trusted-repo"]
trust_level = "trusted"

[mcp_servers.context7]
command = "npx"
args = ["-y", "@upstash/context7-mcp"]
```
