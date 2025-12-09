#!/bin/bash
# Claude Code Audio Announcer
# Speaks status changes using Edge TTS with configurable voices
#
# Usage: audio-announcer.sh <event> [session_name] [detail]
# Events: stop, session-start, user-prompt, pre-tool, post-tool, error
#
# Configuration: ~/.claude/audio-config.sh
# Environment variables override config file settings

set -euo pipefail

EVENT="${1:-unknown}"
SESSION_NAME="${2:-Claude}"
DETAIL="${3:-}"  # Optional detail (filename, command, pattern, etc.)

# ═══════════════════════════════════════════════════════════════
# LOAD CONFIGURATION
# ═══════════════════════════════════════════════════════════════
CONFIG_FILE="$HOME/.claude/audio-config.sh"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Apply config with env var overrides
VOICE="${CLAUDE_VOICE:-${DEFAULT_VOICE:-en-US-AndrewMultilingualNeural}}"
RATE="${CLAUDE_RATE:-${DEFAULT_RATE:-+0%}}"
PITCH="${CLAUDE_PITCH:-${DEFAULT_PITCH:-+0Hz}}"
VOLUME="${CLAUDE_VOLUME:-${DEFAULT_VOLUME:-+0%}}"
SPEED="${CLAUDE_SPEED:-${PLAYBACK_SPEED:-1.0}}"
DEBOUNCE_MS="${TOOL_DEBOUNCE_MS:-1000}"

# Feature toggles (default to true if not set)
ANNOUNCE_TOOLS="${ANNOUNCE_TOOLS:-true}"
ANNOUNCE_SESSION_START="${ANNOUNCE_SESSION_START:-true}"
ANNOUNCE_READY="${ANNOUNCE_READY:-true}"

# Audio directories
AUDIO_DIR="/tmp/claude-audio-cache"
CLIPS_DIR="${CUSTOM_CLIPS_DIR:-}"
mkdir -p "$AUDIO_DIR"

# ═══════════════════════════════════════════════════════════════
# DEBOUNCE CHECK (for tool announcements)
# ═══════════════════════════════════════════════════════════════
DEBOUNCE_FILE="/tmp/claude-audio-last-tool"

should_debounce() {
    [[ "$DEBOUNCE_MS" == "0" ]] && return 1  # Debounce disabled

    local now=$(date +%s%N | cut -c1-13)  # Current time in ms
    local last=$(cat "$DEBOUNCE_FILE" 2>/dev/null || echo "0")
    local diff=$((now - last))

    if (( diff < DEBOUNCE_MS )); then
        return 0  # Should debounce (skip this announcement)
    fi

    echo "$now" > "$DEBOUNCE_FILE"
    return 1  # Don't debounce (play this announcement)
}

# ═══════════════════════════════════════════════════════════════
# PLAY CUSTOM CLIP (if available)
# ═══════════════════════════════════════════════════════════════
play_clip() {
    local clip_name="$1"
    if [[ -n "$CLIPS_DIR" && -f "$CLIPS_DIR/${clip_name}.mp3" ]]; then
        mpv --no-video --really-quiet --speed="$SPEED" "$CLIPS_DIR/${clip_name}.mp3" &>/dev/null &
        return 0
    fi
    return 1  # No clip found
}

# ═══════════════════════════════════════════════════════════════
# SPEAK TEXT (TTS with caching)
# ═══════════════════════════════════════════════════════════════
speak() {
    local text="$1"
    # Include voice + rate in cache key
    local cache_key=$(echo "${VOICE}:${RATE}:${PITCH}:${text}" | md5sum | cut -d' ' -f1)
    local cache_file="$AUDIO_DIR/${cache_key}.mp3"

    # Generate if not cached
    if [[ ! -f "$cache_file" ]]; then
        edge-tts synthesize -v "$VOICE" -r "$RATE" -p "$PITCH" -l "$VOLUME" \
            -t "$text" -o "${cache_file%.mp3}" 2>/dev/null || return 1
        # edge-tts adds .mp3 extension
        mv "${cache_file%.mp3}.mp3" "$cache_file" 2>/dev/null || true
    fi

    # Play (with optional speed adjustment)
    if [[ -f "$cache_file" ]]; then
        mpv --no-video --really-quiet --speed="$SPEED" "$cache_file" &>/dev/null &
    fi
}

case "$EVENT" in
    stop)
        [[ "$ANNOUNCE_READY" != "true" ]] && exit 0
        play_clip "ready" || speak "$SESSION_NAME ready for input"
        ;;

    session-start)
        [[ "$ANNOUNCE_SESSION_START" != "true" ]] && exit 0
        play_clip "session-start" || speak "$SESSION_NAME session started"
        ;;

    user-prompt)
        # Optional: could announce "Processing" but might be annoying
        # speak "$SESSION_NAME processing"
        ;;

    pre-tool)
        [[ "$ANNOUNCE_TOOLS" != "true" ]] && exit 0
        should_debounce && exit 0  # Skip if too soon after last announcement

        # SESSION_NAME = tool name, DETAIL = relevant info (filename, pattern, etc.)
        TOOL_NAME="$SESSION_NAME"

        # Build announcement with detail if available
        if [[ -n "$DETAIL" ]]; then
            case "$TOOL_NAME" in
                Read) speak "Reading $DETAIL" ;;
                Write) speak "Writing $DETAIL" ;;
                Edit) speak "Editing $DETAIL" ;;
                Bash) speak "Running $DETAIL" ;;
                Glob) speak "Finding $DETAIL" ;;
                Grep) speak "Searching $DETAIL" ;;
                Task) speak "Agent: $DETAIL" ;;
                WebFetch) speak "Fetching $DETAIL" ;;
                WebSearch) speak "Searching $DETAIL" ;;
                *) speak "$TOOL_NAME $DETAIL" ;;
            esac
        else
            # Fallback without detail
            case "$TOOL_NAME" in
                Read) speak "Reading" ;;
                Write) speak "Writing" ;;
                Edit) speak "Editing" ;;
                Bash) speak "Running command" ;;
                Glob) speak "Searching files" ;;
                Grep) speak "Searching code" ;;
                Task) speak "Spawning agent" ;;
                WebFetch) speak "Fetching web" ;;
                WebSearch) speak "Searching web" ;;
                *) speak "Using $TOOL_NAME" ;;
            esac
        fi
        ;;

    post-tool)
        # Optional: announce tool completion
        # play_clip "done" || speak "Done"
        ;;

    build-pass)
        play_clip "build-pass" || speak "Build successful"
        ;;

    tests-pass)
        play_clip "tests-pass" || speak "Tests passing"
        ;;

    error)
        play_clip "error" || speak "$SESSION_NAME encountered an error"
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
