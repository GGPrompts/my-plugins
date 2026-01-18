# Beads Commands Reference

Complete command reference for beads issue tracking.

## Issue Lifecycle

```bash
# Create
bd create "Title"                    # Basic issue
bd create "Title" --priority 1       # With priority (0=critical, 4=backlog)
bd create "Title" --type bug         # Types: task, bug, feature, epic, chore
bd create "Title" --label frontend   # With labels

# Read
bd list                              # All issues
bd list --status open                # Filter by status
bd list --label frontend             # Filter by label
bd show ID                           # Full details
bd show ID --json                    # JSON output

# Update
bd update ID --priority 1            # Change priority
bd update ID --status in_progress    # Change status
bd update ID --title "New title"     # Change title
bd update ID --description "..."     # Change description
bd update ID --notes "..."           # Add notes (for prompts!)
bd update ID --estimate 60           # Estimate in minutes
bd update ID --assignee "name"       # Assign

# Close
bd close ID                          # Close with prompt for reason
bd close ID --reason "done"          # Close with reason
```

## Dependencies

```bash
bd dep add BLOCKED BLOCKER           # BLOCKED is blocked by BLOCKER
bd dep remove BLOCKED BLOCKER        # Remove dependency
bd dep list ID                       # Show dependencies for issue
bd blocked                           # Show all blocked issues
bd ready                             # Show unblocked issues
```

## Labels

```bash
bd label add ID frontend,urgent      # Add labels
bd label remove ID urgent            # Remove label
bd label list                        # List all labels in use
```

## Organization

```bash
bd stats                             # Overview statistics
bd ready                             # What can be worked on now
bd ready --json                      # JSON for scripting
bd blocked                           # What's stuck
bd blocked --json                    # JSON with blocker details
```

## Sync & Daemon

```bash
bd sync                              # Sync with git (JSONL)
bd daemon start                      # Start background sync
bd daemon stop                       # Stop daemon
bd daemon status                     # Check daemon health
```

## Worktrees (for parallel workers)

```bash
bd worktree create PATH --branch NAME   # Create isolated worktree
bd worktree list                        # List worktrees
bd worktree remove PATH                 # Remove worktree
```

## Advanced

```bash
# Defer (hide until date)
bd update ID --defer "+2d"           # Show in 2 days
bd update ID --defer "2025-02-01"    # Show on date
bd update ID --defer ""              # Clear defer

# External references
bd update ID --external-ref "gh-123" # Link to GitHub issue

# Due dates
bd update ID --due "+1w"             # Due in 1 week
bd update ID --due "friday"          # Due Friday

# Claiming (atomic assign + in_progress)
bd update ID --claim                 # Claim issue for yourself
```

## Output Formats

Most commands support `--json` for scripting:

```bash
bd list --json | jq '.[].title'
bd ready --json | jq -r '.[].id'
bd show ID --json | jq -r '.[0].notes'
```
