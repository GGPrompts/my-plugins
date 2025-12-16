---
description: Query OpenAI Codex for root cause analysis (read-only, no edits)
---

# Codex Root Cause Investigation

Build a focused debug prompt for Codex, then run it in read-only mode.

## Model Selection

**Default:** `gpt-5.1-codex-max` (deep reasoning, optimized for code debugging)
**Fallback:** `gpt-5.1` (broad world knowledge, for conceptual/architecture questions)

**Available models:**
- `gpt-5.1-codex-max` - Flagship, deep+fast reasoning (default for code)
- `gpt-5.1-codex` - Codex-optimized, balanced
- `gpt-5.1-codex-mini` - Faster/cheaper, less capable
- `gpt-5.1` - General reasoning, broad knowledge

**Heuristics:**
- Code, logs, errors, stack traces, file paths, diffs → `gpt-5.1-codex-max`
- Purely conceptual, architecture, UX design (no code) → `gpt-5.1`

**Override:** User can append `--model=max`, `--model=codex`, `--model=mini`, or `--model=general`

## Command Format

```bash
codex exec -m gpt-5.1-codex-max -c model_reasoning_effort="high" --sandbox read-only "PROMPT"
```

**Model mapping for overrides:**
- `--model=max` → `gpt-5.1-codex-max`
- `--model=codex` → `gpt-5.1-codex`
- `--model=mini` → `gpt-5.1-codex-mini`
- `--model=general` → `gpt-5.1`

- `--sandbox read-only` - **CRITICAL**: Codex can only analyze, not edit files
- `model_reasoning_effort="high"` - Maximum reasoning for complex debugging
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

1. Parse user query for `--model=gpt5` or `--model=codex` override
2. Apply heuristics to select model if no override
3. Build focused prompt from conversation context
4. Execute: `codex exec -m {{model}} -c model_reasoning_effort="high" --sandbox read-only "prompt"`
5. Wait synchronously (timeout: 600000ms)

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

- Check codex CLI: `which codex`
- Verify auth: `codex login`
- Increase timeout if needed: `timeout: 900000` (15 min)

---

**Remember:** Codex analyzes, you implement. Always use `--sandbox read-only`.
