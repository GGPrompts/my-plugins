---
name: gg-wave-done
description: "Clean up after a wave of workers completes"
argument-hint: "[ISSUE_IDS...]"
---

# Wave Done - Cleanup

Clean up completed workers, worktrees, and sync beads. You handle this directly using MCP tools.

## Quick Cleanup (Single Issue)

Use the finalize script for complete cleanup:

```bash
ISSUE_ID="bd-abc"

# One command: checkpoints, capture, kill, merge, cleanup, push
./plugins/conductor/scripts/finalize-issue.sh "$ISSUE_ID"
```

```python
tabz_speak(text=f"{ISSUE_ID} finalized")
```

The script handles: verify closed → run checkpoints → capture transcript → kill terminal → merge → cleanup worktree → bd sync → git push

---

## Batch Cleanup (Multiple Issues)

```bash
ISSUES="bd-abc bd-def bd-ghi"

for ISSUE_ID in $ISSUES; do
    echo "=== Finalizing $ISSUE_ID ==="
    ./plugins/conductor/scripts/finalize-issue.sh "$ISSUE_ID" || echo "Failed: $ISSUE_ID"
done

echo "All issues finalized"
```

Each finalize-issue.sh call handles the full flow including its own bd sync and git push.

---

## Full Wave Cleanup

When all workers are done:

```python
# 1. List all workers
workers = tabz_list_terminals(state="active", response_format="json")

# 2. Find completed ones (check beads status)
completed = []
still_working = []

for w in workers['terminals']:
    name = w['name']
    if not name.startswith(('bd-', 'BD-', 'TabzChrome-', 'V4V-')):
        continue

    try:
        issue = mcp__beads__show(issue_id=name)
        if issue and issue[0]['status'] == 'closed':
            completed.append(name)
            print(f"✓ {name} - ready for cleanup")
        else:
            still_working.append(name)
            print(f"⏳ {name} - still in progress")
    except:
        print(f"? {name} - no matching issue")
```

```bash
# 3. Finalize all completed issues (one at a time)
for ISSUE_ID in bd-abc bd-def bd-ghi; do  # Replace with actual completed IDs
    echo "=== Finalizing $ISSUE_ID ==="
    ./plugins/conductor/scripts/finalize-issue.sh "$ISSUE_ID" || echo "Failed: $ISSUE_ID"
done
```

```python
# 4. Announce
tabz_speak(text="Wave complete! All finalized and merged.")
```

---

## Notes

- **finalize-issue.sh handles everything**: checkpoints, capture, kill, merge, cleanup, sync, push
- **Transcripts captured automatically**: Script saves to `.beads/transcripts/<issue-id>.txt`
- **Checkpoints from labels**: Add `gate:codex-review`, `gate:test-runner` labels to issues

## Checklist

Before calling wave done:

- [ ] All issues closed in beads (`mcp__beads__show` returns `status: closed`)

After cleanup (finalize-issue.sh does all of this):

- [x] Checkpoints run and verified
- [x] Transcripts captured
- [x] All workers killed
- [x] All worktrees removed
- [x] Branches deleted
- [x] Beads synced
- [x] Git pushed
