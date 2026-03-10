#!/usr/bin/env bash
# Setup a worktree with dependencies for a beads issue
# Usage: setup-worktree.sh <ISSUE_ID> [PROJECT_DIR]
#
# Uses `bd worktree create` which automatically:
# - Creates the worktree with a feature branch
# - Sets up beads database redirect
# - Configures proper gitignore
#
# Then calls init-worktree.sh for comprehensive dependency setup:
# - Multi-language deps (Node, Python, Rust, Go, Ruby, Elixir)
# - Monorepo support (frontend/backend subdirs)
# - Next.js build for LSP types
# - Pre-commit hooks

set -e

ISSUE="$1"
PROJECT_DIR="${2:-$(pwd)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Validate issue ID format (alphanumeric with dash/underscore only)
if [[ ! "$ISSUE" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo "ERROR: Invalid issue ID format: $ISSUE" >&2
  exit 1
fi

# bd worktree creates worktrees at ../<name> relative to project
WORKTREE="$(dirname "$PROJECT_DIR")/${ISSUE}"

# Lockfile for worktree creation (prevents race conditions with parallel workers)
WORKTREE_LOCK="/tmp/bd-worktree-$(basename "$PROJECT_DIR").lock"

# Use flock to serialize worktree creation across parallel workers
# Lock is automatically released when subshell exits (success or error)
(
  flock -x 200 || { echo "ERROR: Failed to acquire worktree lock" >&2; exit 1; }

  # Check if worktree already exists (another worker may have created it)
  if [ -d "$WORKTREE" ]; then
    echo "Worktree already exists: $WORKTREE"
    exit 0
  fi

  # Use bd worktree create - handles beads redirect automatically
  cd "$PROJECT_DIR"
  bd worktree create "$ISSUE" --branch "feature/${ISSUE}" 2>/dev/null || \
  bd worktree create "$ISSUE"  # Fallback: create without new branch if it exists
) 200>"$WORKTREE_LOCK"

# Initialize dependencies using the comprehensive init script
# This handles Node, Python, Rust, Go, monorepos, Next.js builds, etc.
if [ -x "$SCRIPT_DIR/init-worktree.sh" ]; then
  "$SCRIPT_DIR/init-worktree.sh" "$WORKTREE"
else
  # Fallback: basic Node deps only
  if [ -f "$WORKTREE/package.json" ] && [ ! -d "$WORKTREE/node_modules" ]; then
    echo "Installing dependencies..."
    cd "$WORKTREE"
    if [ -f "pnpm-lock.yaml" ]; then
      pnpm install --frozen-lockfile
    elif [ -f "yarn.lock" ]; then
      yarn install --frozen-lockfile
    else
      npm ci 2>/dev/null || npm install
    fi
  fi
fi

echo "READY: $WORKTREE"
