# Model and Provider Configuration

Configure which models and providers Codex uses.

## Model Selection

```toml
# ~/.codex/config.toml

# Specify model by name
model = "gpt-5-codex"
```

Available models depend on your provider and access level.

## Provider Configuration

### Default (OpenAI)

```toml
model_provider = "openai"  # Default, can be omitted
model = "gpt-5-codex"
```

### Local Providers (OSS)

Use locally-running models via LM Studio or Ollama:

```toml
model_provider = "oss"
```

**Via CLI:**
```bash
# Auto-detect local provider
codex --oss "your prompt"

# Specify provider
codex --local-provider lmstudio "your prompt"
codex --local-provider ollama "your prompt"
```

**Requirements:**
- LM Studio or Ollama must be running
- Model must be loaded and serving
- Codex auto-detects the running server

## Model Parameters

### Reasoning Effort

Control how much the model "thinks" (Responses API only):

```toml
model_reasoning_effort = "medium"
```

| Level | Description | Use Case |
|-------|-------------|----------|
| `minimal` | Quick responses | Simple queries |
| `low` | Light reasoning | Routine tasks |
| `medium` | Balanced (default) | Most tasks |
| `high` | Deep reasoning | Complex problems |
| `xhigh` | Maximum effort | Hard problems |

### Verbosity

Control output detail (GPT-5 Responses API):

```toml
model_verbosity = "medium"
```

| Level | Description |
|-------|-------------|
| `low` | Concise responses |
| `medium` | Balanced detail |
| `high` | Verbose explanations |

### Context Window

Override detected context window size:

```toml
model_context_window = 128000
```

Useful when:
- Using custom/local models
- Codex can't auto-detect window size
- You want to limit context usage

### Auto-Compaction

Control when conversation history compacts:

```toml
model_auto_compact_token_limit = 100000
```

When context exceeds this limit, older messages are summarized to free space.

## CLI Overrides

Override config for single sessions:

```bash
# Use specific model
codex -m gpt-5-codex "task"

# Use local provider
codex --oss "task"

# Specify local provider type
codex --local-provider ollama "task"
```

## Custom Providers

Define custom providers in config:

```toml
[providers.my-provider]
api_base = "https://api.example.com/v1"
api_key_env = "MY_PROVIDER_API_KEY"
```

Then use:
```toml
model_provider = "my-provider"
model = "custom-model-name"
```

## Local LLM Setup

### LM Studio

1. Install LM Studio from https://lmstudio.ai
2. Download a model (e.g., CodeLlama, DeepSeek Coder)
3. Start local server (default: http://localhost:1234)
4. Run Codex with `--oss` or `--local-provider lmstudio`

### Ollama

1. Install Ollama from https://ollama.ai
2. Pull a model: `ollama pull codellama`
3. Ollama runs automatically
4. Run Codex with `--oss` or `--local-provider ollama`

### Config for Local Models

```toml
# ~/.codex/config.toml

model_provider = "oss"

# Adjust for local model capabilities
model_context_window = 32000
model_auto_compact_token_limit = 25000

# Lower reasoning for faster local inference
model_reasoning_effort = "low"
```

## Example Configurations

### Default OpenAI Setup
```toml
model = "gpt-5-codex"
model_reasoning_effort = "medium"
```

### High-Effort Complex Tasks
```toml
model = "gpt-5-codex"
model_reasoning_effort = "xhigh"
model_verbosity = "high"
```

### Local Development (Fast)
```toml
model_provider = "oss"
model_reasoning_effort = "minimal"
model_context_window = 32000
```

### Cost-Conscious Setup
```toml
model = "gpt-4o-mini"  # If available
model_reasoning_effort = "low"
model_auto_compact_token_limit = 50000
```
