---
description: Exit and restart Claude Code with plugins reloaded
---

Restart Claude Code to reload plugins, hooks, and MCP servers.

Run the bash command with `run_in_background: true` so Claude finishes immediately:

```bash
TMUX_PANE=$(tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}' 2>/dev/null)
if [ -n "$TMUX_PANE" ]; then
    # Capture current claude command to preserve args like --agent
    CLAUDE_CMD=$(ps aux | grep -E "[c]laude.*--" | grep -v grep | head -1 | sed 's/.*\(claude .*\)/\1/' | sed 's/--continue//' | xargs)
    # Ensure --dangerously-skip-permissions and --continue are present
    if [[ "$CLAUDE_CMD" != *"--dangerously-skip-permissions"* ]]; then
        CLAUDE_CMD="$CLAUDE_CMD --dangerously-skip-permissions"
    fi
    CLAUDE_CMD="$CLAUDE_CMD --continue"

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
        sleep 2
        tmux send-keys -t "$TMUX_PANE" -l "$CLAUDE_CMD"
        sleep 0.3
        tmux send-keys -t "$TMUX_PANE" C-m
    ) &
fi
```

After running the script, say "Restart scheduled in 5 seconds." and stop - don't output anything else.
