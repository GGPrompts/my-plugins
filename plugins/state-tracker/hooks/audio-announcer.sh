#!/bin/bash
# Claude Code Audio Announcer
# Speaks status changes using Edge TTS
#
# Usage: audio-announcer.sh <event> [session_name]
# Events: stop, session-start, user-prompt, error

set -euo pipefail

EVENT="${1:-unknown}"
SESSION_NAME="${2:-Claude}"

# Audio cache directory
AUDIO_DIR="/tmp/claude-audio-cache"
mkdir -p "$AUDIO_DIR"

# Function to speak text (uses cached audio if available)
speak() {
    local text="$1"
    local cache_key=$(echo "$text" | md5sum | cut -d' ' -f1)
    local cache_file="$AUDIO_DIR/${cache_key}.mp3"

    # Generate if not cached
    if [[ ! -f "$cache_file" ]]; then
        edge-tts synthesize -t "$text" -o "${cache_file%.mp3}" 2>/dev/null || return 1
        # edge-tts adds .mp3 extension
        mv "${cache_file%.mp3}.mp3" "$cache_file" 2>/dev/null || true
    fi

    # Play in background (don't block the hook)
    if [[ -f "$cache_file" ]]; then
        mpv --no-video --really-quiet "$cache_file" &>/dev/null &
    fi
}

case "$EVENT" in
    stop)
        speak "$SESSION_NAME ready for input"
        ;;
    session-start)
        speak "$SESSION_NAME session started"
        ;;
    user-prompt)
        # Optional: could announce "Processing" but might be annoying
        # speak "$SESSION_NAME processing"
        ;;
    error)
        speak "$SESSION_NAME encountered an error"
        ;;
    summary)
        # For future: could trigger the brief summary here
        # gemini-media brief --since "5 min" --speak &
        ;;
    *)
        # Unknown event, don't speak
        ;;
esac

exit 0
