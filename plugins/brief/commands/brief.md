---
description: Generate a spoken audio summary of recent Claude Code activity
---

# Session Brief - Audio Summary of Recent Conversation

Generate a spoken summary of recent Claude Code activity using Gemini 2.5 Flash. Perfect for catching up after a break or remembering what you were working on.

## Instructions

Use the AskUserQuestion tool to ask the user for their preferences:

**Question 1: Time Range**
- Header: "Time range"
- Options:
  - "5 minutes" - Quick recap of very recent activity
  - "10 minutes" - Short session summary
  - "30 minutes" - Extended session coverage
  - "1 hour" - Full session recap
- multiSelect: false

**Question 2: Output Mode**
- Header: "Output"
- Options:
  - "Speak aloud" - Generate summary and play audio via Edge TTS
  - "Text only" - Show summary without audio
- multiSelect: false

After getting answers, build and run the command:

| Time Selection | Command Flag |
|----------------|--------------|
| 5 minutes | `--since "5 min"` |
| 10 minutes | `--since "10 min"` |
| 30 minutes | `--since "30 min"` |
| 1 hour | `--since "1 hour"` |

| Output Selection | Command Flag |
|------------------|--------------|
| Speak aloud | `--speak` |
| Text only | (no flag) |

Example command: `gemini-media brief --since "10 min" --speak`

**IMPORTANT**: Run with `run_in_background: true` so audio doesn't block the chat:

```
Bash tool parameters:
- command: gemini-media brief --since "10 min" --speak
- run_in_background: true
```

After starting, tell the user "Summary generating - audio will play shortly!" and continue the conversation normally.
