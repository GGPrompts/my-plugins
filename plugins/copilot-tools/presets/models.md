# Model Presets

Quick reference for Copilot and Codex CLI model configurations.

## Copilot CLI Models

### Unlimited (gpt5-mini)
```bash
copilot --model gpt-5-mini -p "prompt" -s --yolo
```
Best for: Bulk work, maintenance, audits, simple tasks

### Balanced (gpt5)
```bash
copilot --model gpt-5 -p "prompt" -s --yolo
```
Best for: General purpose, good quality/cost balance

### Code-focused (gpt5.2-codex)
```bash
copilot --model gpt-5.2-codex -p "prompt" -s --yolo
```
Best for: Implementation, refactoring, code generation

### Deep Reasoning (claude-opus-4.5)
```bash
copilot --model claude-opus-4.5 -p "prompt" -s --yolo
```
Best for: Architecture, complex decisions, thorough analysis

### Alternative Perspective (gemini-3-pro)
```bash
copilot --model gemini-3-pro-preview -p "prompt" -s --yolo
```
Best for: Second opinion, Google ecosystem expertise

## Codex CLI Models

### Standard Codex
```bash
codex -m gpt5.2codex --full-auto "prompt"
```
Best for: Code tasks with good reasoning

### Max Thinking
```bash
codex -m gpt5.1codex-max --full-auto "prompt"
```
Best for: Complex debugging, hard problems that need extended thinking

## Common Flags

### Copilot
| Flag | Purpose |
|------|---------|
| `-p "prompt"` | Non-interactive mode |
| `-s` | Silent (output only, no stats) |
| `--yolo` | All permissions (alias for --allow-all) |
| `--allow-tool X` | Allow specific tool |
| `--deny-tool X` | Block specific tool |

### Codex
| Flag | Purpose |
|------|---------|
| `exec "prompt"` | Non-interactive mode |
| `--full-auto` | Auto-approve in sandbox |
| `-m MODEL` | Select model |
| `--search` | Enable web search |

## Example Combinations

### Safe Audit (read-only)
```bash
copilot --model gpt-5-mini -p "audit this codebase" -s \
  --allow-tool 'read' --allow-tool 'glob' --allow-tool 'grep' \
  --deny-tool 'write' --deny-tool 'shell'
```

### Full Implementation
```bash
copilot --model gpt-5.2-codex -p "implement feature X" -s --yolo
```

### Complex Debug
```bash
codex -m gpt5.1codex-max --full-auto "debug the race condition in worker.py"
```

### Multi-model Council
```bash
# Run in parallel
copilot --model claude-opus-4.5 -p "design question" -s --yolo &
copilot --model gpt-5.2-codex -p "design question" -s --yolo &
copilot --model gemini-3-pro-preview -p "design question" -s --yolo &
wait
```
