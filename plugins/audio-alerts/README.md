# Audio Alerts for Claude Code

Spoken TTS announcements for Claude Code activity: session start, tool use, ready-for-input, and subagent tracking. Uses Microsoft Edge neural TTS (free, no API key) with per-session random voice assignment.

## What it does

- **Session start**: "Claude session started"
- **Tool use**: "Reading main.rs", "Editing config.toml", "Running git status", "Searching files", "Spawning agent", etc.
- **Ready**: "Claude ready for input" (when Claude stops and waits for you)
- **Subagent tracking**: Tracks active subagent count in state files

Tool announcements are debounced (1s default) and use a mutex so subagent floods don't overlap.

## Requirements

| Dependency | Purpose | Install |
|---|---|---|
| **edge-tts** | Microsoft Edge neural TTS | `pipx install edge-tts` |
| **mpv** | Audio playback | `apt install mpv` / `brew install mpv` |
| **jq** | JSON parsing | `apt install jq` / `brew install jq` |
| **python3** | Required by edge-tts | Usually preinstalled |

### Quick install

```bash
# Linux / WSL2
sudo apt install mpv jq
pipx install edge-tts

# macOS
brew install mpv jq
pipx install edge-tts
```

## Setup

1. Add the marketplace (one time):
   ```
   /plugin marketplace add GGPrompts/my-plugins
   ```

2. Install the plugin:
   ```
   /plugin install audio-alerts@my-plugins
   ```

3. Enable audio by adding to your `~/.claude/settings.json`:
   ```json
   {
     "env": {
       "CLAUDE_AUDIO": "1"
     }
   }
   ```

4. Restart Claude Code.

## Configuration

All configuration is via environment variables (set in `settings.json` env or `~/.claude/audio-config.sh`):

| Variable | Default | Description |
|---|---|---|
| `CLAUDE_AUDIO` | `0` | Set to `1` to enable audio announcements |
| `CLAUDE_VOICE` | random per-session | Edge TTS voice (e.g. `en-US-AriaNeural`) |
| `CLAUDE_RATE` | `+0%` | Speech rate (e.g. `+20%` for faster) |
| `CLAUDE_PITCH` | `+0Hz` | Voice pitch adjustment |
| `CLAUDE_VOLUME` | `+0%` | Volume adjustment |
| `CLAUDE_SPEED` | `1.0` | mpv playback speed multiplier |
| `ANNOUNCE_TOOLS` | `true` | Announce tool use |
| `ANNOUNCE_SESSION_START` | `true` | Announce session start |
| `ANNOUNCE_READY` | `true` | Announce ready for input |
| `TOOL_DEBOUNCE_MS` | `1000` | Min ms between tool announcements |

### Custom audio clips

Set `CUSTOM_CLIPS_DIR` to a directory containing `.mp3` files named after events:
- `ready.mp3` — plays instead of TTS for "ready for input"
- `session-start.mp3` — plays instead of TTS for session start
- `error.mp3`, `build-pass.mp3`, `tests-pass.mp3` — other events

### Per-session voices

Without `CLAUDE_VOICE` set, each session gets a random voice from a pool of 11 English neural voices (US, GB, AU accents). The voice is consistent within a session (hashed from session ID).

## Platform support

- **Linux**: works out of the box
- **WSL2**: works (mpv plays through PulseAudio/PipeWire to Windows)
- **macOS**: works (cross-platform shell helpers included)
- **Windows native**: not supported (bash scripts)

## State files

The state tracker writes JSON to `/tmp/claude-code-state/`:
- `{session_id}.json` — current Claude state (status, tool, subagent count)
- `subagents/{session_id}.count` — active subagent counter

These are useful for external dashboards, status bars, or other tools that want to observe Claude Code activity.
