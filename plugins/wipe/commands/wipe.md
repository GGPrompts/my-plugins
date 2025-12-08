---
description: Generate handoff, clear context, and auto-continue in fresh session
---

Generate a concise handoff summary, then automatically clear context and resume with the handoff in a fresh session.

## Step 1: Generate Handoff Summary

Use this format (skip sections that don't apply):

```
## What we're working on
- [Primary task/topic]

## Current state
- [Where we left off]
- [Any pending questions or decisions]

## Key decisions made
- [Important choices/conclusions]

## Recent changes
- [Files modified, commands run]

## Important context
- [Facts, preferences, constraints, technical details]

## Next steps
- [Immediate next action]
```

## Step 2: Save and Schedule

After generating the summary, execute this bash script. Replace `HANDOFF_CONTENT` with the actual handoff you generated (properly escaped):

```bash
# Save handoff to temp file
HANDOFF_FILE="/tmp/claude-handoff-$$.txt"
cat > "$HANDOFF_FILE" << 'HANDOFF_EOF'
Here's the context from my previous session:

[INSERT YOUR GENERATED HANDOFF SUMMARY HERE]

---
Please acknowledge you've received this context, then let me know what you'd suggest we do next.
HANDOFF_EOF

# Also copy to clipboard as backup
if command -v clip.exe &> /dev/null; then
    cat "$HANDOFF_FILE" | clip.exe
    echo "Backup copied to clipboard (WSL)"
elif command -v xclip &> /dev/null; then
    cat "$HANDOFF_FILE" | xclip -selection clipboard -i &>/dev/null &
    sleep 0.2
    echo "Backup copied to clipboard (xclip)"
elif command -v wl-copy &> /dev/null; then
    cat "$HANDOFF_FILE" | wl-copy
    echo "Backup copied to clipboard (Wayland)"
fi

# Detect tmux session info (capture everything upfront)
if [ -n "$TMUX" ]; then
    TMUX_SOCKET=$(echo "$TMUX" | cut -d',' -f1)
    TARGET_PANE=$(tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}')

    echo "Target: $TARGET_PANE"

    # Schedule: clear scrollback, clear context, then send handoff
    (
        sleep 2
        # Clear terminal scrollback first to prevent lag (using tmux API directly)
        tmux -S "$TMUX_SOCKET" clear-history -t "$TARGET_PANE"
        tmux -S "$TMUX_SOCKET" send-keys -t "$TARGET_PANE" C-l
        sleep 1
        # Send /clear - Escape first to clear any pending input
        tmux -S "$TMUX_SOCKET" send-keys -t "$TARGET_PANE" Escape
        sleep 0.3
        tmux -S "$TMUX_SOCKET" send-keys -t "$TARGET_PANE" '/clear'
        sleep 0.5
        tmux -S "$TMUX_SOCKET" send-keys -t "$TARGET_PANE" Enter
        # Wait for /clear to fully process
        sleep 8
        # Use load-buffer for safe content transfer
        tmux -S "$TMUX_SOCKET" load-buffer "$HANDOFF_FILE"
        tmux -S "$TMUX_SOCKET" send-keys -t "$TARGET_PANE" ""
        sleep 0.3
        tmux -S "$TMUX_SOCKET" paste-buffer -t "$TARGET_PANE"
        sleep 0.3
        tmux -S "$TMUX_SOCKET" send-keys -t "$TARGET_PANE" C-m
        sleep 1
        rm -f "$HANDOFF_FILE"
    ) &
    disown

    echo ""
    echo "================================================"
    echo "WIPE SCHEDULED"
    echo "================================================"
    echo "  - Terminal scrollback clears in 2 seconds"
    echo "  - /clear runs 1 second after (clears context)"
    echo "  - Handoff arrives 8 seconds after clear"
    echo "  - Backup saved to clipboard"
    echo ""
    echo "Just wait ~12 seconds... or press Ctrl+C to abort"
    echo "================================================"
else
    echo ""
    echo "ERROR: Not running in tmux!"
    echo ""
    echo "Handoff saved to: $HANDOFF_FILE"
    echo "Backup copied to clipboard"
    echo ""
    echo "Manual steps:"
    echo "  1. Run /clear"
    echo "  2. Paste from clipboard (Ctrl+V)"
fi
```

## Important

- This only works inside tmux
- Clears terminal scrollback before /clear to prevent lag
- Uses literal mode (-l) for tmux send-keys to avoid special char issues
- The handoff is saved to clipboard as backup in case timing fails
- If something goes wrong, just paste from clipboard in a new session
- Timing: 2s scrollback → 1s /clear → 8s handoff (~12s total)
