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

After generating the summary, run this bash script with `run_in_background: true`. Replace the handoff content with your actual summary:

```bash
# Save handoff to temp file
HANDOFF_FILE="/tmp/claude-handoff-$$.txt"
cat > "$HANDOFF_FILE" << 'HANDOFF_EOF'
Here's the context from my previous session:

[INSERT YOUR GENERATED HANDOFF SUMMARY HERE]

---
Please acknowledge you've received this context, then let me know what you'd suggest we do next.
HANDOFF_EOF

# Copy to clipboard as backup
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

# Detect tmux pane (works in Claude's bash context)
TMUX_PANE=$(tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}' 2>/dev/null)

if [ -n "$TMUX_PANE" ]; then
    echo "Target: $TMUX_PANE"
    echo "WIPE: Starting in 5 seconds..."

    # Schedule: cancel pending, clear scrollback, /clear, then send handoff
    (
        sleep 5
        # Cancel any pending operation
        tmux send-keys -t "$TMUX_PANE" C-c
        sleep 1
        # Clear terminal scrollback
        tmux clear-history -t "$TMUX_PANE"
        tmux send-keys -t "$TMUX_PANE" C-l
        sleep 0.5
        # Send / first, wait for menu, then clear
        tmux send-keys -t "$TMUX_PANE" '/'
        sleep 0.5
        tmux send-keys -t "$TMUX_PANE" -l 'clear'
        sleep 0.3
        tmux send-keys -t "$TMUX_PANE" C-m
        # Wait for /clear to fully process
        sleep 8
        # Use load-buffer for safe content transfer
        tmux load-buffer "$HANDOFF_FILE"
        sleep 0.3
        tmux paste-buffer -t "$TMUX_PANE"
        sleep 0.3
        tmux send-keys -t "$TMUX_PANE" C-m
        sleep 1
        rm -f "$HANDOFF_FILE"
    ) &
else
    echo ""
    echo "ERROR: Not running in tmux!"
    echo "Handoff saved to: $HANDOFF_FILE"
    echo "Backup copied to clipboard"
    echo ""
    echo "Manual steps:"
    echo "  1. Run /clear"
    echo "  2. Paste from clipboard (Ctrl+V)"
fi
```

After running the script, say "Wipe scheduled in 5 seconds. Handoff backed up to clipboard." and stop.

## Important

- Run the bash with `run_in_background: true` so Claude finishes immediately
- This only works inside tmux
- Handoff is saved to clipboard as backup in case timing fails
- If something goes wrong, just paste from clipboard after /clear
