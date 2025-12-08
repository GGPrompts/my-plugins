---
description: Query Gemini for real-time info, web research, or fast second opinions
---

# Gemini Quick Query

Use Gemini CLI for tasks where it excels over Claude/Codex.

## When to Use Gemini

| Use Case | Why Gemini |
|----------|------------|
| Real-time info | Google Search grounding - knows today's news/docs |
| Web research | Native URL fetching, summarizes pages |
| Quick checks | Flash 2.5 is very fast, free tier |
| Second opinion | Different perspective on architecture/approach |
| Large context | 1M tokens for massive files/logs |

## Command Format

```bash
# Quick query (non-interactive)
gemini "your question here"

# With specific model
gemini -m gemini-2.5-flash "quick question"
gemini -m gemini-2.5-pro "complex analysis"

# Fetch and analyze URL
gemini "summarize https://example.com/docs"

# Output as JSON (for parsing)
gemini "query" --output-format json
```

## Models

- `gemini-2.5-flash` - Fast, free tier, good for quick checks
- `gemini-2.5-pro` - Deeper reasoning, larger context

## Use Case Examples

### Real-time Information
```bash
gemini "what's new in Next.js 15.2 released this week?"
gemini "current best practices for React Server Components 2025"
```

### Web Research
```bash
gemini "fetch https://docs.example.com/api and explain the auth flow"
gemini "summarize the changes in this PR: https://github.com/org/repo/pull/123"
```

### Quick Second Opinion
```bash
gemini "is using zustand or jotai better for this use case: [brief description]"
gemini "review this approach: [paste snippet] - any red flags?"
```

### Large File Analysis
```bash
# Gemini has 1M token context - good for massive logs
cat huge-log.txt | gemini "find the root cause of the OOM errors"
```

## Execution

1. Determine if query benefits from Gemini's strengths (real-time info, web, speed)
2. Choose model: `gemini-2.5-flash` for speed, `gemini-2.5-pro` for depth
3. Run query with `timeout: 60000` (1 min for flash, increase for pro)
4. Present response with model used

## Output Format

```
**Model:** gemini-2.5-flash

[Gemini's response]

---
**Note:** [Any caveats about real-time data freshness if relevant]
```

## Comparison

| Feature | Gemini | Claude | Codex |
|---------|--------|--------|-------|
| Google Search grounding | Yes | No | No |
| Real-time web info | Yes | Limited | No |
| Speed (Flash) | Very fast | - | - |
| Free tier | Yes | No | No |
| Context window | 1M | 200k | 200k |

## For Multimodal (Audio/Video/Images)

Use the `ai-multimodal` skill instead - it uses Gemini API directly with full multimodal support:
- Audio transcription (up to 9.5 hours)
- Video analysis (up to 6 hours)
- Image understanding, OCR
- PDF processing

---

**Remember:** Gemini for real-time info and speed, Claude for deep coding, Codex for complex debugging.
