# Sandbox and Approval Policies

Understanding Codex's security model for safe autonomous operation.

## Sandbox Modes

Control what file system operations Codex can perform.

### read-only
```toml
sandbox_mode = "read-only"
```
- Can read any file
- Cannot write, create, or delete files
- Cannot execute commands that modify the system
- **Use case:** Code review, exploration, learning codebases

### workspace-write
```toml
sandbox_mode = "workspace-write"
```
- Can read any file
- Can write within the current project directory
- Cannot modify files outside the workspace
- **Use case:** Normal development work (recommended default)

### danger-full-access
```toml
sandbox_mode = "danger-full-access"
```
- Full read/write access to entire system
- Can modify any file, run any command
- **Use case:** System administration, CI environments with external sandbox
- **Warning:** Only use in already-sandboxed environments

## Approval Policies

Control when Codex asks for permission to execute commands.

### untrusted
```toml
approval_policy = "untrusted"
```
- Only "trusted" commands run without approval (ls, cat, grep, etc.)
- Any untrusted command requires explicit user approval
- **Use case:** Maximum safety, learning Codex behavior

### on-failure
```toml
approval_policy = "on-failure"
```
- Commands run automatically in sandbox
- Only asks for approval if a command fails
- Failed commands can be retried with elevated permissions
- **Use case:** Balanced safety with productivity (recommended)

### on-request
```toml
approval_policy = "on-request"
```
- Model decides when to ask for approval
- Typically asks for destructive or uncertain operations
- **Use case:** Autonomous operation with model judgment

### never
```toml
approval_policy = "never"
```
- Never asks for approval
- All commands execute immediately
- Failures are returned to model without escalation
- **Use case:** CI/CD pipelines, fully sandboxed environments
- **Warning:** Combine with external sandboxing

## Combining Policies

| Sandbox | Approval | Safety | Autonomy |
|---------|----------|--------|----------|
| read-only | untrusted | Maximum | Minimal |
| workspace-write | on-failure | High | Moderate |
| workspace-write | on-request | Moderate | High |
| danger-full-access | never | Minimal | Maximum |

**Recommended for development:**
```toml
sandbox_mode = "workspace-write"
approval_policy = "on-failure"
```

**Recommended for CI:**
```toml
sandbox_mode = "workspace-write"  # or container provides sandbox
approval_policy = "never"
```

## Per-Project Trust

Override security for specific projects:

```toml
# Trust a specific project (less restrictive)
[projects."/home/user/my-trusted-repo"]
trust_level = "trusted"

# Explicitly untrust a project (more restrictive)
[projects."/home/user/untrusted-code"]
trust_level = "untrusted"
```

Trusted projects may have relaxed approval requirements for common operations.

## CLI Overrides

Override config for single sessions:

```bash
# Full autonomous mode
codex --full-auto "task"
# Equivalent to: -a on-request --sandbox workspace-write

# Specific sandbox
codex --sandbox read-only "review code"

# Specific approval
codex -a untrusted "explore codebase"

# Dangerous bypass (externally sandboxed only!)
codex --dangerously-bypass-approvals-and-sandbox "run all tests"
```

## Admin Enforcement

System admins can restrict user options via `/etc/codex/requirements.toml`:

```toml
# Users can only choose these approval policies
allowed_approval_policies = ["untrusted", "on-failure"]

# Users can only choose these sandbox modes
allowed_sandbox_modes = ["read-only", "workspace-write"]
```

This prevents users from using `danger-full-access` or `never` approval on managed systems.
