#!/bin/bash
# Claude Code State Tracker (Unified for Tmuxplexer + Terminal-Tabs)
# Writes Claude's current state to files that both projects can read

set -euo pipefail

# Portable helpers (Linux + macOS)
file_mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || echo 0; }
portable_md5() { printf '%s' "$1" | md5sum 2>/dev/null | cut -d' ' -f1 || printf '%s' "$1" | md5 2>/dev/null; }

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration
STATE_DIR="/tmp/claude-code-state"
DEBUG_DIR="$STATE_DIR/debug"
SUBAGENT_DIR="$STATE_DIR/subagents"
mkdir -p "$STATE_DIR" "$DEBUG_DIR" "$SUBAGENT_DIR"

# --- therminal binary resolution ---
# On WSL, only accept .exe binaries (Windows interop) to avoid silently
# targeting a Unix socket when a Linux-compiled `therminal` is on PATH.
# Override: THERMINAL_WINDOWS_BIN (first choice) or THERMINAL_BIN.
_THERMINAL_HOOK_WARNED=0
_THERMINAL_WARN_FILE="$STATE_DIR/.therminal-hook-warned"

# Fire-and-forget invocation of the therminal binary.
#
# tn-8lyq: therminal.exe release builds are compiled with
# `#![windows_subsystem = "windows"]`, so Windows never allocates a console
# for them at startup — we can invoke therminal.exe directly from WSL
# without flashing a conhost window. The earlier `cmd.exe /c start /B ""`
# wrapper is deliberately gone: cmd.exe itself is a CONSOLE subsystem
# binary, so wrapping through it re-introduced the exact flash we were
# trying to hide.
_invoke_therminal_async() {
    local bin="$1"; shift
    "$bin" "$@" </dev/null >/dev/null 2>&1 &
}

_resolve_therminal_bin() {
    # 1. Explicit override
    if [[ -n "${THERMINAL_WINDOWS_BIN:-}" ]]; then
        echo "$THERMINAL_WINDOWS_BIN"
        return
    fi
    if [[ -n "${THERMINAL_BIN:-}" ]]; then
        echo "$THERMINAL_BIN"
        return
    fi
    # 2. WSL: only accept .exe binaries
    if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
        local bin
        bin=$(command -v therminal.exe 2>/dev/null || true)
        if [[ -n "$bin" ]]; then
            echo "$bin"
            return
        fi
        # 2b. Probe Windows Desktop (common install location for therminal)
        local win_user
        win_user=$(wslvar USERPROFILE 2>/dev/null || cmd.exe /C "echo %USERPROFILE%" 2>/dev/null | tr -d '\r' || true)
        if [[ -n "$win_user" ]]; then
            # Convert Windows path to WSL mount: C:\Users\X → /mnt/c/Users/X
            local wsl_desktop
            wsl_desktop=$(wslpath "$win_user" 2>/dev/null || echo "/mnt/c/Users/$(basename "$win_user")")/Desktop
            if [[ -x "$wsl_desktop/therminal.exe" ]]; then
                echo "$wsl_desktop/therminal.exe"
                return
            fi
        fi
        # No .exe found — emit one-time warning
        if [[ ! -f "$_THERMINAL_WARN_FILE" ]]; then
            echo "[therminal hook] WARNING: WSL detected but therminal.exe not found on PATH or Desktop." >&2
            echo "[therminal hook] Set THERMINAL_WINDOWS_BIN to the Windows therminal.exe path." >&2
            touch "$_THERMINAL_WARN_FILE" 2>/dev/null || true
        fi
        return
    fi
    # 3. Non-WSL: standard lookup
    local bin
    bin=$(command -v therminal.exe 2>/dev/null || command -v therminal 2>/dev/null || true)
    if [[ -n "$bin" ]]; then
        echo "$bin"
        return
    fi
    # Not found — emit one-time warning
    if [[ ! -f "$_THERMINAL_WARN_FILE" ]]; then
        echo "[therminal hook] WARNING: therminal binary not found on PATH." >&2
        echo "[therminal hook] Install therminal or set THERMINAL_BIN." >&2
        touch "$_THERMINAL_WARN_FILE" 2>/dev/null || true
    fi
}

# Get tmux pane ID if running in tmux
TMUX_PANE="${TMUX_PANE:-none}"

# Read stdin if available (contains hook data from Claude)
# Explicit timeout prevents hanging if Claude keeps stdin open
STDIN_DATA=$(timeout 1 cat 2>/dev/null || echo "")

# Get session identifier - UNIFIED STRATEGY for both projects
# Priority: 1. CLAUDE_SESSION_ID env var, 2. TMUX_PANE (for tmuxplexer), 3. Working directory hash (for terminal-tabs)
if [[ -n "${CLAUDE_SESSION_ID:-}" ]]; then
    SESSION_ID="$CLAUDE_SESSION_ID"
elif [[ "$TMUX_PANE" != "none" && -n "$TMUX_PANE" ]]; then
    SESSION_ID=$(echo "$TMUX_PANE" | sed 's/[^a-zA-Z0-9_-]/_/g')
elif [[ -n "$PWD" ]]; then
    SESSION_ID=$(portable_md5 "$PWD" | head -c 12)
else
    SESSION_ID="$$"
fi

STATE_FILE="$STATE_DIR/${SESSION_ID}.json"
SUBAGENT_COUNT_FILE="$SUBAGENT_DIR/${SESSION_ID}.count"

get_subagent_count() {
    cat "$SUBAGENT_COUNT_FILE" 2>/dev/null || echo "0"
}

_subagent_lock_dir() { echo "$SUBAGENT_COUNT_FILE.lock.d"; }

_subagent_lock_acquire() {
    local lock_dir; lock_dir=$(_subagent_lock_dir)
    local attempts=0
    while ! mkdir "$lock_dir" 2>/dev/null; do
        attempts=$((attempts + 1))
        [[ $attempts -ge 20 ]] && return 1
        sleep 0.05
    done
    return 0
}

_subagent_lock_release() { rmdir "$(_subagent_lock_dir)" 2>/dev/null || true; }

increment_subagent_count() {
    _subagent_lock_acquire || return 0
    local count=$(cat "$SUBAGENT_COUNT_FILE" 2>/dev/null || echo "0")
    echo $((count + 1)) > "$SUBAGENT_COUNT_FILE"
    _subagent_lock_release
}

decrement_subagent_count() {
    _subagent_lock_acquire || return 0
    local count=$(cat "$SUBAGENT_COUNT_FILE" 2>/dev/null || echo "0")
    local new_count=$((count - 1))
    [[ $new_count -lt 0 ]] && new_count=0
    echo "$new_count" > "$SUBAGENT_COUNT_FILE"
    _subagent_lock_release
}

# ── OSC 1341 marker emission (tn-nrur) ──────────────────────────────────
# Emit an inline OSC 1341 marker to stdout so therminal's PTY reader can
# update pane state instantly — no file polling delay. The marker carries
# key=value pairs separated by semicolons inside an OSC envelope:
#   ESC ] 1341 ; key=value [ ; key=value ]* ST
# Only emitted when TERM_PROGRAM=therminal (skip for non-therminal terminals).
emit_osc_marker() {
    [[ "${TERM_PROGRAM:-}" == "therminal" ]] || return 0
    local payload=""
    local sep=""
    for kv in "$@"; do
        payload="${payload}${sep}${kv}"
        sep=";"
    done
    # ESC ] 1341 ; <payload> ST  (ST = ESC \)
    printf '\033]1341;%s\033\\' "$payload" 2>/dev/null || true
}

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
HOOK_TYPE="${1:-unknown}"

# Carry forward existing session_title across hook calls (tn-ys0m).
# Each hook invocation is a fresh process, so read from the state file.
SESSION_TITLE=$(jq -r '.session_title // ""' "$STATE_FILE" 2>/dev/null || echo "")

if [[ "$HOOK_TYPE" == "pre-tool" ]] || [[ "$HOOK_TYPE" == "post-tool" ]]; then
    echo "$STDIN_DATA" > "$DEBUG_DIR/${HOOK_TYPE}-$(date +%s)-$$.json" 2>/dev/null || true
fi

case "$HOOK_TYPE" in
    session-start)
        STATUS="idle"
        CURRENT_TOOL=""
        DETAILS='{"event":"session_started"}'
        echo "0" > "$SUBAGENT_COUNT_FILE"
        (
            active_panes=$(tmux list-panes -a -F '#{pane_id}' 2>/dev/null | sed 's/[^a-zA-Z0-9_-]/_/g' || echo "")
            for file in "$STATE_DIR"/*.json; do
                [[ -f "$file" ]] || continue
                filename=$(basename "$file" .json)
                # Skip context files - handled separately below
                if [[ "$filename" == *-context ]]; then continue; fi
                if [[ "$active_panes" == *"$filename"* ]]; then continue; fi
                if [[ "$filename" =~ ^_[0-9]+$ ]]; then rm -f "$file"; continue; fi
                if [[ "$filename" =~ ^[a-f0-9]{12}$ ]]; then
                    file_age=$(($(date +%s) - $(file_mtime "$file")))
                    if [[ $file_age -gt 3600 ]]; then rm -f "$file"; fi
                fi
            done
            # Clean up context files older than 1 hour or orphaned (no parent state file)
            for file in "$STATE_DIR"/*-context.json; do
                [[ -f "$file" ]] || continue
                file_age=$(($(date +%s) - $(file_mtime "$file")))
                parent_file="${file/-context.json/.json}"
                if [[ ! -f "$parent_file" ]] || [[ $file_age -gt 3600 ]]; then
                    rm -f "$file"
                fi
            done
            find "$DEBUG_DIR" -name "*.json" -mmin +60 -delete 2>/dev/null || true
            # Clean stale subagent count files and orphaned lock dirs
            find "$SUBAGENT_DIR" -type f -mmin +240 -delete 2>/dev/null || true
            find "$SUBAGENT_DIR" -maxdepth 1 -name "*.lock.d" -type d -mmin +10 -exec rmdir {} \; 2>/dev/null || true
            # Clean stale cache-health and claude-sid files
            find "$STATE_DIR" -maxdepth 1 -name "*-cache-health.json" -mmin +240 -delete 2>/dev/null || true
            find "$STATE_DIR" -maxdepth 1 -name "*.claude-sid" -mmin +240 -delete 2>/dev/null || true
        ) &
        if [[ "${CLAUDE_AUDIO:-0}" == "1" ]]; then
            SESSION_NAME="${CLAUDE_SESSION_NAME:-Claude}"
            "$SCRIPT_DIR/audio-announcer.sh" session-start "$SESSION_NAME" &
        fi
        ;;
    user-prompt)
        STATUS="processing"
        CURRENT_TOOL=""
        PROMPT=$(echo "$STDIN_DATA" | jq -r '.prompt // "unknown"' 2>/dev/null || echo "unknown")
        DETAILS=$(jq -n --arg prompt "$PROMPT" '{event:"user_prompt_submitted",last_prompt:$prompt}')
        # Extract session title from the first user prompt (tn-ys0m).
        # Only set on first prompt — subsequent prompts ("yes", "looks good")
        # are usually not descriptive. Persist via state file.
        _EXISTING_TITLE=$(jq -r '.session_title // ""' "$STATE_FILE" 2>/dev/null || echo "")
        if [[ -z "$_EXISTING_TITLE" ]]; then
            # Try beads issue ID first (e.g. "tn-xxxx" or "bd-xxxx")
            _TITLE=$(echo "$PROMPT" | grep -oE '\b[a-z]{2,}-[a-z0-9]{2,}\b' | head -1 || true)
            # Try slash command (e.g. "/commit", "/review-pr 123")
            if [[ -z "$_TITLE" ]]; then
                _TITLE=$(echo "$PROMPT" | grep -oE '^/[a-z-]+(\s+\S+)?' | head -1 || true)
            fi
            # Fallback: first ~60 chars trimmed to word boundary
            if [[ -z "$_TITLE" ]]; then
                _TITLE=$(echo "$PROMPT" | head -c 60 | sed 's/[[:space:]][^[:space:]]*$//' | tr '\n' ' ' | sed 's/[[:space:]]*$//')
            fi
            SESSION_TITLE="$_TITLE"
        fi
        ;;
    pre-tool)
        STATUS="tool_use"
        CURRENT_TOOL=$(echo "$STDIN_DATA" | jq -r '.tool_name // .tool // .name // "unknown"' 2>/dev/null || echo "unknown")
        TOOL_ARGS_STR=$(echo "$STDIN_DATA" | jq -c '.tool_input // .input // .parameters // {}' 2>/dev/null || echo '{}')
        DETAILS=$(jq -n --arg tool "$CURRENT_TOOL" --arg args "$TOOL_ARGS_STR" '{event:"tool_starting",tool:$tool,args:($args|fromjson)}' 2>/dev/null || echo '{"event":"tool_starting"}')
        # NOTE: subagent counting is handled by subagent-start/subagent-stop hooks,
        # NOT here. PreToolUse fires even if the Task is denied or fails.
        if [[ "${CLAUDE_AUDIO:-0}" == "1" ]]; then
            TOOL_DETAIL=""
            case "$CURRENT_TOOL" in
                Read|Write|Edit) TOOL_DETAIL=$(echo "$STDIN_DATA" | jq -r '.tool_input.file_path // .input.file_path // ""' 2>/dev/null | xargs basename 2>/dev/null || echo "") ;;
                Bash) TOOL_DETAIL=$(echo "$STDIN_DATA" | jq -r '.tool_input.command // .input.command // ""' 2>/dev/null | head -c 30 || echo "") ;;
                Glob|Grep) TOOL_DETAIL=$(echo "$STDIN_DATA" | jq -r '.tool_input.pattern // .input.pattern // ""' 2>/dev/null || echo "") ;;
                Task) TOOL_DETAIL=$(echo "$STDIN_DATA" | jq -r '.tool_input.description // .input.description // ""' 2>/dev/null || echo "") ;;
                WebFetch|WebSearch) TOOL_DETAIL=$(echo "$STDIN_DATA" | jq -r '.tool_input.url // .tool_input.query // .input.url // .input.query // ""' 2>/dev/null || echo "") ;;
            esac
            "$SCRIPT_DIR/audio-announcer.sh" pre-tool "$CURRENT_TOOL" "$TOOL_DETAIL" &
        fi
        ;;
    post-tool)
        STATUS="processing"
        CURRENT_TOOL=$(echo "$STDIN_DATA" | jq -r '.tool_name // .tool // .name // "unknown"' 2>/dev/null || echo "unknown")
        TOOL_ARGS_STR=$(echo "$STDIN_DATA" | jq -c '.tool_input // .input // .parameters // {}' 2>/dev/null || echo '{}')
        DETAILS=$(jq -n --arg tool "$CURRENT_TOOL" --arg args "$TOOL_ARGS_STR" '{event:"tool_completed",tool:$tool,args:($args|fromjson)}' 2>/dev/null || echo '{"event":"tool_completed"}')
        ;;
    stop)
        STATUS="awaiting_input"
        CURRENT_TOOL=""
        DETAILS='{"event":"claude_stopped","waiting_for_user":true}'
        if [[ "${CLAUDE_AUDIO:-0}" == "1" ]]; then
            SESSION_NAME="${CLAUDE_SESSION_NAME:-Claude}"
            "$SCRIPT_DIR/audio-announcer.sh" stop "$SESSION_NAME" &
        fi
        ;;
    subagent-start)
        increment_subagent_count
        SUBAGENT_COUNT=$(get_subagent_count)
        STATUS="processing"
        CURRENT_TOOL=""
        AGENT_TYPE=$(echo "$STDIN_DATA" | jq -r '.agent_type // "unknown"' 2>/dev/null || echo "unknown")
        AGENT_ID=$(echo "$STDIN_DATA" | jq -r '.agent_id // ""' 2>/dev/null || echo "")
        DETAILS=$(jq -n --arg type "$AGENT_TYPE" --arg count "$SUBAGENT_COUNT" '{event:"subagent_started",agent_type:$type,active_subagents:($count|tonumber)}')
        # Push to therminal daemon for fast auto-tile (fire-and-forget).
        # Gated on TERM_PROGRAM=therminal so Claude Code sessions running in
        # other terminals (Windows Terminal, tmux, kitty, etc.) don't cause
        # therminal to spawn phantom subagent panes for agents that have no
        # PTY in therminal.
        if [[ "${TERM_PROGRAM:-}" == "therminal" ]]; then
            _tn=$(_resolve_therminal_bin)
            if [[ -n "$_tn" && -x "$_tn" ]]; then
                _invoke_therminal_async "$_tn" agent-event push \
                    --event subagent_start \
                    --session-id "${CLAUDE_SESSION_ID:-}" \
                    --parent-session-id "${CLAUDE_SESSION_ID:-}" \
                    --agent-id "$AGENT_ID" \
                    --agent-type "$AGENT_TYPE"
            fi
        fi
        ;;
    subagent-stop)
        decrement_subagent_count
        SUBAGENT_COUNT=$(get_subagent_count)
        CURRENT_TOOL=""
        AGENT_ID=$(echo "$STDIN_DATA" | jq -r '.agent_id // ""' 2>/dev/null || echo "")
        # FIX: When all subagents done, set to awaiting_input (not processing)
        # This prevents stale "processing" state when session ends after subagent work
        if [[ "$SUBAGENT_COUNT" -eq 0 ]]; then
            STATUS="awaiting_input"
            DETAILS='{"event":"subagent_stopped","remaining_subagents":0,"all_complete":true}'
        else
            STATUS="processing"
            DETAILS=$(jq -n --arg count "$SUBAGENT_COUNT" '{event:"subagent_stopped",remaining_subagents:($count|tonumber)}')
        fi
        # Gate matches subagent-start — see note above.
        if [[ "${TERM_PROGRAM:-}" == "therminal" ]]; then
            _tn=$(_resolve_therminal_bin)
            if [[ -n "$_tn" && -x "$_tn" ]]; then
                _invoke_therminal_async "$_tn" agent-event push \
                    --event subagent_stop \
                    --session-id "${CLAUDE_SESSION_ID:-}" \
                    --parent-session-id "${CLAUDE_SESSION_ID:-}" \
                    --agent-id "$AGENT_ID"
            fi
        fi
        ;;
    notification)
        NOTIF_TYPE=$(echo "$STDIN_DATA" | jq -r '.notification_type // "unknown"' 2>/dev/null || echo "unknown")
        case "$NOTIF_TYPE" in
            idle_prompt|awaiting-input)
                STATUS="awaiting_input"
                CURRENT_TOOL=""
                DETAILS='{"event":"awaiting_input_bell"}'
                ;;
            permission_prompt)
                if [[ -f "$STATE_FILE" ]]; then
                    STATUS=$(jq -r '.status // "idle"' "$STATE_FILE")
                    CURRENT_TOOL=$(jq -r '.current_tool // ""' "$STATE_FILE")
                else
                    STATUS="idle"
                    CURRENT_TOOL=""
                fi
                DETAILS='{"event":"permission_prompt"}'
                ;;
            *)
                if [[ -f "$STATE_FILE" ]]; then
                    STATUS=$(jq -r '.status // "idle"' "$STATE_FILE")
                    CURRENT_TOOL=$(jq -r '.current_tool // ""' "$STATE_FILE")
                else
                    STATUS="idle"
                    CURRENT_TOOL=""
                fi
                DETAILS=$(jq -n --arg type "$NOTIF_TYPE" '{event:"notification",type:$type}')
                ;;
        esac
        ;;
    *)
        if [[ -f "$STATE_FILE" ]]; then
            STATUS=$(jq -r '.status // "idle"' "$STATE_FILE")
            CURRENT_TOOL=$(jq -r '.current_tool // ""' "$STATE_FILE")
        else
            STATUS="idle"
            CURRENT_TOOL=""
        fi
        DETAILS=$(jq -n --arg hook "$HOOK_TYPE" '{event:"unknown_hook",hook:$hook}')
        ;;
esac

SUBAGENT_COUNT=$(get_subagent_count)

# Try to get context data from the context file written by the statusline script
# The statusline writes claude_session_id to our state file, which links to the context file
CONTEXT_PERCENT="null"
CONTEXT_WINDOW_SIZE="null"
TOTAL_INPUT_TOKENS="null"
TOTAL_OUTPUT_TOKENS="null"
CLAUDE_SESSION_ID=""

# Read claude_session_id from the linkage file written by statusline-script.sh
# (avoids jq parse of our own state file and eliminates a write-write race)
SID_FILE="$STATE_DIR/${SESSION_ID}.claude-sid"
CLAUDE_SESSION_ID=$(cat "$SID_FILE" 2>/dev/null || echo "")

# If we have claude_session_id, try to read context data
if [[ -n "$CLAUDE_SESSION_ID" ]]; then
    CONTEXT_FILE="$STATE_DIR/${CLAUDE_SESSION_ID}-context.json"
    # Require -s (non-empty): jq on an empty file exits 0 with empty stdout,
    # which then feeds "" into --argjson below and blows up the whole hook.
    if [[ -s "$CONTEXT_FILE" ]]; then
        # Check if context file is fresh (within 60 seconds)
        CONTEXT_AGE=$(($(date +%s) - $(file_mtime "$CONTEXT_FILE")))
        if [[ $CONTEXT_AGE -lt 60 ]]; then
            CONTEXT_PERCENT=$(jq -r '.context_pct // "null"' "$CONTEXT_FILE" 2>/dev/null || echo "null")
            CONTEXT_WINDOW_SIZE=$(jq -r '.context_window.context_window_size // "null"' "$CONTEXT_FILE" 2>/dev/null || echo "null")
            TOTAL_INPUT_TOKENS=$(jq -r '.context_window.total_input_tokens // "null"' "$CONTEXT_FILE" 2>/dev/null || echo "null")
            TOTAL_OUTPUT_TOKENS=$(jq -r '.context_window.total_output_tokens // "null"' "$CONTEXT_FILE" 2>/dev/null || echo "null")
            # Belt-and-suspenders: normalize any empty captures to the literal
            # JSON null so --argjson never sees "".
            [[ -z "$CONTEXT_PERCENT"      ]] && CONTEXT_PERCENT="null"
            [[ -z "$CONTEXT_WINDOW_SIZE"  ]] && CONTEXT_WINDOW_SIZE="null"
            [[ -z "$TOTAL_INPUT_TOKENS"   ]] && TOTAL_INPUT_TOKENS="null"
            [[ -z "$TOTAL_OUTPUT_TOKENS"  ]] && TOTAL_OUTPUT_TOKENS="null"
        fi
    fi
fi

# Determine PID to write. On WSL, Linux PIDs are invisible to the Windows-native
# daemon's OpenProcess() call, so pid_is_alive() always returns false — causing
# premature session pruning after RECENT_UPDATE_GRACE (120s) instead of allowing
# SESSION_MAX_AGE (5 min) to govern. Write pid=0 as a sentinel so session_is_dead()
# falls through to the timestamp-based path. (tn-1rn6)
if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
    _HOOK_PID=0
else
    _HOOK_PID=${PPID:-$$}
fi

# Build state JSON with jq (safe against special characters in values)
STATE_JSON=$(jq -n \
    --arg session_id "$SESSION_ID" \
    --arg claude_session_id "$CLAUDE_SESSION_ID" \
    --arg status "$STATUS" \
    --arg current_tool "$CURRENT_TOOL" \
    --argjson subagent_count "$SUBAGENT_COUNT" \
    --argjson context_percent "$CONTEXT_PERCENT" \
    --argjson context_window_size "$CONTEXT_WINDOW_SIZE" \
    --argjson input_tokens "$TOTAL_INPUT_TOKENS" \
    --argjson output_tokens "$TOTAL_OUTPUT_TOKENS" \
    --arg working_dir "$PWD" \
    --arg last_updated "$TIMESTAMP" \
    --arg tmux_pane "$TMUX_PANE" \
    --argjson pid "${_HOOK_PID}" \
    --arg hook_type "$HOOK_TYPE" \
    --arg session_title "$SESSION_TITLE" \
    --argjson details "$DETAILS" \
    '{
        session_id: $session_id,
        claude_session_id: (if $claude_session_id == "" then null else $claude_session_id end),
        status: $status,
        current_tool: $current_tool,
        subagent_count: $subagent_count,
        context_percent: $context_percent,
        context_window: {
            size: $context_window_size,
            input_tokens: $input_tokens,
            output_tokens: $output_tokens
        },
        working_dir: $working_dir,
        last_updated: $last_updated,
        tmux_pane: $tmux_pane,
        pid: $pid,
        hook_type: $hook_type,
        session_title: (if $session_title == "" then null else $session_title end),
        details: $details
    }'
)

echo "$STATE_JSON" > "$STATE_FILE"

if [[ "$SESSION_ID" =~ ^[a-f0-9]{12}$ ]] && [[ "$TMUX_PANE" != "none" && -n "$TMUX_PANE" ]]; then
    PANE_ID=$(echo "$TMUX_PANE" | sed 's/[^a-zA-Z0-9_-]/_/g')
    PANE_STATE_FILE="$STATE_DIR/${PANE_ID}.json"
    echo "$STATE_JSON" > "$PANE_STATE_FILE"
fi

# ── OSC 1341 inline markers (tn-nrur) ──────────────────────────────────
# Emit markers to stdout so therminal picks up state changes inline with
# the PTY stream. These are the primary signal; file polling is fallback.
# Build the marker args array based on what we know.
_marker_args=()
[[ -n "$STATUS" ]] && _marker_args+=("state=$STATUS")
[[ -n "$CLAUDE_SESSION_ID" ]] && _marker_args+=("session_id=$CLAUDE_SESSION_ID")
[[ -n "$PWD" ]] && _marker_args+=("cwd=$PWD")
[[ -n "$CURRENT_TOOL" ]] && _marker_args+=("tool=$CURRENT_TOOL")

# Environment detection (tn-ncmj): the shell self-identifies its runtime
# environment so the daemon knows the signal origin without crossing process
# boundaries.
if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
    _marker_args+=("environment=wsl:${WSL_DISTRO_NAME}")
elif [[ -f /.dockerenv ]]; then
    _host=$(hostname 2>/dev/null | tr -d '\000-\037\177')
    _marker_args+=("environment=docker:${_host:-unknown}")
elif [[ -n "${SSH_CONNECTION:-}" ]]; then
    _host=$(hostname 2>/dev/null | tr -d '\000-\037\177')
    _marker_args+=("environment=ssh:${_host:-unknown}")
else
    _marker_args+=("environment=local")
fi

# Emit state marker (only if we have at least one field).
if [[ ${#_marker_args[@]} -gt 0 ]]; then
    emit_osc_marker "${_marker_args[@]}"
fi

# Emit subagent lifecycle markers.
case "$HOOK_TYPE" in
    subagent-start)
        emit_osc_marker "subagent_start=$AGENT_ID" "session_id=${CLAUDE_SESSION_ID:-}"
        ;;
    subagent-stop)
        emit_osc_marker "subagent_stop=$AGENT_ID" "session_id=${CLAUDE_SESSION_ID:-}"
        ;;
esac

exit 0
