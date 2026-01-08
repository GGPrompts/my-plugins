---
description: Exit and restart Claude Code with plugins reloaded
---

Restart Claude Code to reload plugins, hooks, and MCP servers.

Run the bash command with `run_in_background: true` so Claude finishes immediately:

```bash
TMUX_PANE=$(tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}' 2>/dev/null)
if [ -n "$TMUX_PANE" ]; then
    # Default restart command - always use --dangerously-skip-permissions --continue
    CLAUDE_CMD="claude --dangerously-skip-permissions --continue"
    echo "RESTART: $TMUX_PANE"
    echo "CMD: $CLAUDE_CMD"
    (
        sleep 5
        tmux send-keys -t "$TMUX_PANE" C-c
        sleep 1
        tmux send-keys -t "$TMUX_PANE" '/'
        sleep 0.5
        tmux send-keys -t "$TMUX_PANE" -l 'exit'
        sleep 0.3
        tmux send-keys -t "$TMUX_PANE" C-m
        sleep 4
        tmux send-keys -t "$TMUX_PANE" -l "$CLAUDE_CMD"
        sleep 0.3
        tmux send-keys -t "$TMUX_PANE" C-m
    ) &
fi
```

After running the script, say "Restart scheduled in 5 seconds." and stop - don't output anything else.
