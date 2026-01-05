---
description: Query OpenAI Codex for root cause analysis (read-only, no edits)
---

# Codex Root Cause Investigation

Build a focused debug prompt for Codex, then run it in read-only mode.

## Model Selection

**Default:** `gpt-5.2-codex` (latest frontier agentic coding model)
**Fallback:** `gpt-5.1-codex-mini` (cheaper, stretch limits when approaching rate limits)

**Available models:**
- `gpt-5.2-codex` - Latest frontier, best for complex debugging (default)
- `gpt-5.1-codex-max` - Deep+fast reasoning, flagship
- `gpt-5.1-codex-mini` - Faster/cheaper, use to stretch limits
- `gpt-5.2` - General reasoning, broad knowledge (non-codex optimized)

**Heuristics:**
- Code, logs, errors, stack traces, file paths, diffs → `gpt-5.2-codex`
- Approaching rate limits, simple queries → `gpt-5.1-codex-mini`
- Purely conceptual, architecture, UX design (no code) → `gpt-5.2`

**Override:** User can append `--model=latest`, `--model=max`, `--model=mini`, or `--model=general`

## Command Format

```bash
# Standard (human-readable output)
codex exec -m gpt-5.2-codex --config model_reasoning_effort="high" --sandbox read-only "PROMPT"

# Automation (structured JSON output for parsing)
codex exec --json -m gpt-5.2-codex --config model_reasoning_effort="high" --sandbox read-only "PROMPT"
```

**Model mapping for overrides:**
- `--model=latest` → `gpt-5.2-codex` (default)
- `--model=max` → `gpt-5.1-codex-max`
- `--model=mini` → `gpt-5.1-codex-mini`
- `--model=general` → `gpt-5.2`

**Reasoning effort levels:** `minimal | low | medium | high | xhigh`
- Default: `high` for complex debugging
- Use `xhigh` for extremely difficult problems (slower, more tokens)

**Notes:**
- `--sandbox read-only` - Codex can only analyze, not edit files (default for exec, but explicit is safer)
- Use Bash tool with `timeout: 600000` (10 min) - run synchronously, not in background

## Prompt Template

```
# Bug Investigation Request

## Issue
[Brief bug description]

## Context
- **Files:** path/to/file.ext:line
- **What's happening:** [observed behavior]
- **Expected:** [what should happen]
- **Tried:** [previous attempts]

## Code Snippet
[Small, relevant excerpt if helpful]

## Question
What is the root cause? Include:
1. Root cause analysis
2. Why prior attempts failed (if applicable)
3. Suggested fix approach
```

## Execution

1. Parse user query for `--model=` override
2. Apply heuristics to select model if no override
3. Build focused prompt from conversation context
4. Execute: `codex exec -m {{model}} --config model_reasoning_effort="high" --sandbox read-only "prompt"`
5. Wait synchronously (timeout: 600000ms)
6. If rate limited, retry with `gpt-5.1-codex-mini`

## Rate Limit Fallback

If you hit rate limits with `gpt-5.2-codex`:

```bash
# Fallback to mini model (explicitly recommended by OpenAI to stretch limits)
codex exec -m gpt-5.1-codex-mini --config model_reasoning_effort="high" --sandbox read-only "PROMPT"
```

## Output Format

```
**Model:** {{model}}

## Codex Analysis
[Codex's response - skip session info, only show the analysis]

---

**Summary:** [2-3 sentence summary of findings]

**Next:** Would you like me to implement this fix?
```

## Troubleshooting

- Check codex CLI: `which codex` / `codex --version`
- Verify auth: `codex login`
- Increase timeout if needed: `timeout: 900000` (15 min)
- Rate limited? Switch to `--model=mini`

---

**Remember:** Codex analyzes, you implement. Always use `--sandbox read-only`.
