# Copilot Tools Plugin

Multi-model orchestration using GitHub Copilot CLI and Codex CLI.

## Commands

### `/audit [path]`
Read-only codebase audit using gpt5-mini (unlimited). Creates beads issues for findings - no files modified.

```bash
/audit                    # Audit current project
/audit ~/projects/myapp   # Audit specific path
```

### `/council "prompt"`
Fan out the same prompt to multiple models (Opus, gpt5.2-codex, Gemini 3) and compare responses.

```bash
/council "Design an auth system for a veteran resource app"
/council "What's the best approach for real-time notifications?"
```

## Model Presets

Quick reference for Copilot CLI models:

| Preset | Model | Best For |
|--------|-------|----------|
| `mini` | gpt-5-mini | Unlimited grunt work, maintenance |
| `codex` | gpt-5.2-codex | Code-focused tasks |
| `codex-max` | gpt-5.1-codex-max | Complex debugging |
| `opus` | claude-opus-4.5 | Deep reasoning |
| `gemini` | gemini-3-pro-preview | Alternative perspective |

## Usage Examples

```bash
# Run maintenance audit (safe, read-only)
copilot --model gpt-5-mini -p "$(cat ~/.claude/plugins/copilot-tools/scripts/audit-prompt.md)" -s --yolo

# Complex debugging with max thinking
codex -m gpt5.2codex --full-auto "debug the race condition in worker.py"

# Get multiple perspectives on architecture
/council "Should we use WebSockets or SSE for real-time updates?"
```
