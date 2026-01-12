#!/bin/bash
# plugin-registry.sh - Registry of plugins for selective loading via --plugin-dir
#
# Usage:
#   ./plugin-registry.sh                    # List all plugins with descriptions
#   ./plugin-registry.sh --search "react"   # Search plugins by keyword
#   ./plugin-registry.sh --match "fix ui"   # Match text to plugins, output --plugin-dir flags
#   ./plugin-registry.sh --flags ui-styling # Get --plugin-dir flag for specific plugin(s)
#   ./plugin-registry.sh --json             # Full registry as JSON
#
# For worker spawning:
#   claude $(./plugin-registry.sh --match "terminal resize bug") --continue
#
# Based on match-skills.sh pattern but outputs --plugin-dir flags instead of skill triggers.

set -euo pipefail

# ============================================================================
# SELF-LOCATING
# ============================================================================
find_registry_root() {
  local SCRIPT_DIR
  if [ -n "${BASH_SOURCE[0]:-}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # Script is in scripts/, parent is my-plugins root
    if [ -f "$SCRIPT_DIR/../.claude-plugin/marketplace.json" ]; then
      echo "$(dirname "$SCRIPT_DIR")"
      return 0
    fi
  fi

  # Check common locations
  if [ -d "$HOME/plugins/my-plugins" ]; then
    echo "$HOME/plugins/my-plugins"
    return 0
  fi

  if [ -d "$HOME/.claude/plugins/my-plugins" ]; then
    echo "$HOME/.claude/plugins/my-plugins"
    return 0
  fi

  echo ""
  return 1
}

REGISTRY_ROOT=$(find_registry_root)
if [ -z "$REGISTRY_ROOT" ]; then
  echo "Error: Could not find my-plugins directory" >&2
  exit 1
fi

# Get marketplace name from marketplace.json
MARKETPLACE_NAME=$(jq -r '.name // "my-plugins"' "$REGISTRY_ROOT/.claude-plugin/marketplace.json" 2>/dev/null || echo "my-plugins")

# ============================================================================
# ENABLED STATUS
# ============================================================================
# Check ~/.claude/settings.json for enabledPlugins

get_enabled_plugins() {
  local SETTINGS="$HOME/.claude/settings.json"
  if [ -f "$SETTINGS" ]; then
    jq -r '.enabledPlugins // {} | keys[]' "$SETTINGS" 2>/dev/null || echo ""
  fi
}

# Check if a plugin is enabled (format: plugin-name@marketplace-name)
is_plugin_enabled() {
  local PLUGIN_NAME="$1"
  local SETTINGS="$HOME/.claude/settings.json"
  local KEY="${PLUGIN_NAME}@${MARKETPLACE_NAME}"

  if [ -f "$SETTINGS" ]; then
    local VALUE=$(jq -r --arg key "$KEY" '.enabledPlugins[$key] // false' "$SETTINGS" 2>/dev/null)
    [ "$VALUE" = "true" ]
  else
    return 1
  fi
}

# Get count of enabled plugins in this marketplace
get_enabled_count() {
  local SETTINGS="$HOME/.claude/settings.json"
  if [ -f "$SETTINGS" ]; then
    jq -r --arg mp "@${MARKETPLACE_NAME}" '.enabledPlugins // {} | keys | map(select(endswith($mp))) | length' "$SETTINGS" 2>/dev/null || echo "0"
  else
    echo "0"
  fi
}

# ============================================================================
# PLUGIN DISCOVERY
# ============================================================================

# Get all plugin directories (those with plugin.json)
get_all_plugins() {
  find "$REGISTRY_ROOT/plugins" -name "plugin.json" -type f 2>/dev/null | while read -r PLUGIN_JSON; do
    dirname "$PLUGIN_JSON"
  done | sort
}

# Get plugin info as JSON
get_plugin_info() {
  local PLUGIN_DIR="$1"
  local PLUGIN_JSON="$PLUGIN_DIR/plugin.json"

  if [ ! -f "$PLUGIN_JSON" ]; then
    return 1
  fi

  local NAME=$(jq -r '.name // "unknown"' "$PLUGIN_JSON")
  local DESC=$(jq -r '.description // ""' "$PLUGIN_JSON")
  local VERSION=$(jq -r '.version // "1.0.0"' "$PLUGIN_JSON")

  # Get skills
  local SKILLS=""
  if [ -d "$PLUGIN_DIR/skills" ]; then
    SKILLS=$(find "$PLUGIN_DIR/skills" -name "SKILL.md" -type f 2>/dev/null | while read -r SKILL_FILE; do
      local SKILL_DIR=$(dirname "$SKILL_FILE")
      local SKILL_NAME=$(basename "$SKILL_DIR")
      local SKILL_DESC=$(grep -E "^description:" "$SKILL_FILE" 2>/dev/null | head -1 | sed 's/description:\s*//' | tr -d '"' | cut -c1-80)
      echo "{\"name\":\"$SKILL_NAME\",\"description\":\"$SKILL_DESC\"}"
    done | jq -s '.')
  fi
  [ -z "$SKILLS" ] && SKILLS="[]"

  # Get commands
  local COMMANDS=""
  if [ -d "$PLUGIN_DIR/commands" ]; then
    COMMANDS=$(find "$PLUGIN_DIR/commands" -name "*.md" -type f 2>/dev/null | while read -r CMD_FILE; do
      local CMD_NAME=$(basename "$CMD_FILE" .md)
      local CMD_DESC=$(grep -E "^description:" "$CMD_FILE" 2>/dev/null | head -1 | sed 's/description:\s*//' | tr -d '"' | cut -c1-80)
      echo "{\"name\":\"$CMD_NAME\",\"description\":\"$CMD_DESC\"}"
    done | jq -s '.')
  fi
  [ -z "$COMMANDS" ] && COMMANDS="[]"

  # Get agents
  local AGENTS=""
  if [ -d "$PLUGIN_DIR/agents" ]; then
    AGENTS=$(find "$PLUGIN_DIR/agents" -name "*.md" -type f 2>/dev/null | while read -r AGENT_FILE; do
      local AGENT_NAME=$(basename "$AGENT_FILE" .md)
      local AGENT_DESC=$(grep -E "^description:" "$AGENT_FILE" 2>/dev/null | head -1 | sed 's/description:\s*//' | tr -d '"' | cut -c1-80)
      echo "{\"name\":\"$AGENT_NAME\",\"description\":\"$AGENT_DESC\"}"
    done | jq -s '.')
  fi
  [ -z "$AGENTS" ] && AGENTS="[]"

  # Get keywords from marketplace.json
  local KEYWORDS=""
  local MARKETPLACE="$REGISTRY_ROOT/.claude-plugin/marketplace.json"
  if [ -f "$MARKETPLACE" ]; then
    KEYWORDS=$(jq -r --arg name "$NAME" '.plugins[] | select(.name == $name) | .keywords // [] | join(",")' "$MARKETPLACE" 2>/dev/null || echo "")
  fi

  # Check enabled status
  local ENABLED="false"
  if is_plugin_enabled "$NAME"; then
    ENABLED="true"
  fi

  # Build JSON
  jq -n \
    --arg name "$NAME" \
    --arg desc "$DESC" \
    --arg version "$VERSION" \
    --arg dir "$PLUGIN_DIR" \
    --arg keywords "$KEYWORDS" \
    --argjson enabled "$ENABLED" \
    --argjson skills "$SKILLS" \
    --argjson commands "$COMMANDS" \
    --argjson agents "$AGENTS" \
    '{
      name: $name,
      description: $desc,
      version: $version,
      directory: $dir,
      enabled: $enabled,
      keywords: ($keywords | split(",") | map(select(. != ""))),
      skills: $skills,
      commands: $commands,
      agents: $agents
    }'
}

# Build full registry
build_registry() {
  get_all_plugins | while read -r PLUGIN_DIR; do
    get_plugin_info "$PLUGIN_DIR"
  done | jq -s '.'
}

# ============================================================================
# KEYWORD MAPPINGS (like match-skills.sh)
# ============================================================================
# Format: pattern|plugin-names (comma-separated)
# Patterns use extended regex

PLUGIN_MAPPINGS=(
  # Terminal / xterm
  "terminal|xterm|pty|resize|buffer|fitaddon|websocket.*terminal|xterm-js"

  # UI / Frontend styling
  "ui|component|modal|styling|tailwind|shadcn|form|button|radix|ui-styling,frontend-design,aesthetic"

  # Frontend frameworks
  "react|next|vue|frontend|typescript|suspense|lazy|tanstack|frontend-development,web-frameworks"

  # Backend / API
  "backend|api|server|endpoint|express|fastapi|node|python|go|backend-development"

  # Databases
  "postgres|mongodb|redis|sql|database|query|schema|migration|databases"

  # Authentication
  "auth|login|oauth|session|token|jwt|passkey|rbac|better-auth"

  # DevOps / Infrastructure
  "docker|cloudflare|gcp|cicd|pipeline|deploy|infrastructure|devops,docker-mcp"

  # Browser automation
  "browser|screenshot|click|mcp|tabz|automation|chrome|tabz"

  # Visual / Media
  "canvas|generative|art|animation|drawing|canvas-design"
  "image|video|media|ffmpeg|imagemagick|encode|resize|media-processing"
  "gemini|multimodal|audio|transcribe|vision|ai-multimodal"

  # Documents
  "pdf|word|docx|presentation|spreadsheet|excel|document|document-skills"

  # Plugin development (meta)
  "plugin|manifest|marketplace|plugin-development"
  "skill|scaffold|template|skill-creator"
  "agent|subagent|spawn|agent-creator"
  "mcp|server|fastmcp|sdk|mcp-builder"
  "claude.*code|features|hooks|ide|claude-code"
  "context|engineering|optimization|memory|context-engineering"

  # Tools
  "debug|debugging|error|trace|bug|root-cause|debugging"
  "review|pr|pull.*request|lint|quality|code-review"
  "thinking|reasoning|step|complex|analysis|systematic|sequential-thinking"
  "problem|solving|framework|pattern|strategy|problem-solving"
  "validate|plan|project|analysis|review|validate-plan"
  "docs|documentation|llms.txt|repomix|docs-seeker,repomix"
  "codex|openai|analysis|query|claudeforcodex,codexforclaude"

  # Terminal utilities
  "tmux|prompt|send|session|pmux"
  "brief|summary|audio|spoken|tts|brief"
  "wipe|clear|context|handoff|reset|wipe,handoff"
  "restart|reload|plugin|exit|restart"

  # Specialized
  "bubbletea|tui|go|golang|charm|bubbletea"
  "shopify|ecommerce|graphql|polaris|liquid|shopify"
  "git|commit|push|pr|shortcut|git-commands"
  "google.*adk|agent.*kit|google-adk-python"
)

# ============================================================================
# MATCHING FUNCTIONS
# ============================================================================

# Match text to plugins, return plugin names
match_plugins() {
  local INPUT_TEXT="$1"
  local NORMALIZED=$(echo "$INPUT_TEXT" | tr '[:upper:]' '[:lower:]' | tr -s '[:space:]' ' ')

  local MATCHED=""

  for mapping in "${PLUGIN_MAPPINGS[@]}"; do
    local PATTERN="${mapping%|*}"
    local PLUGINS="${mapping##*|}"

    if echo "$NORMALIZED" | grep -qE "$PATTERN"; then
      if [ -n "$MATCHED" ]; then
        MATCHED="$MATCHED,$PLUGINS"
      else
        MATCHED="$PLUGINS"
      fi
    fi
  done

  # Deduplicate
  echo "$MATCHED" | tr ',' '\n' | sort -u | tr '\n' ',' | sed 's/,$//'
}

# Get --plugin-dir flags for plugin names
get_plugin_flags() {
  local PLUGIN_NAMES="$1"
  local FLAGS=""

  for NAME in $(echo "$PLUGIN_NAMES" | tr ',' ' '); do
    [ -z "$NAME" ] && continue

    # Find plugin directory
    local PLUGIN_DIR=$(find "$REGISTRY_ROOT/plugins" -name "plugin.json" -type f 2>/dev/null | while read -r PJ; do
      local PN=$(jq -r '.name' "$PJ" 2>/dev/null)
      if [ "$PN" = "$NAME" ]; then
        dirname "$PJ"
        break
      fi
    done | head -1)

    if [ -n "$PLUGIN_DIR" ]; then
      FLAGS="$FLAGS --plugin-dir $PLUGIN_DIR"
    fi
  done

  echo "$FLAGS" | sed 's/^ //'
}

# Search registry by keyword
search_plugins() {
  local QUERY="$1"
  local QUERY_LOWER=$(echo "$QUERY" | tr '[:upper:]' '[:lower:]')

  get_all_plugins | while read -r PLUGIN_DIR; do
    local INFO=$(get_plugin_info "$PLUGIN_DIR")
    local SEARCHABLE=$(echo "$INFO" | jq -r '[.name, .description, (.keywords | join(" ")), (.skills[].name // empty), (.skills[].description // empty)] | join(" ")' | tr '[:upper:]' '[:lower:]')

    if echo "$SEARCHABLE" | grep -q "$QUERY_LOWER"; then
      echo "$INFO"
    fi
  done | jq -s '.'
}

# ============================================================================
# DISPLAY FUNCTIONS
# ============================================================================

# List all plugins with descriptions (human readable)
list_plugins() {
  local TOTAL=$(get_all_plugins | wc -l)
  local ENABLED_COUNT=$(get_enabled_count)

  echo "Plugin Registry: $REGISTRY_ROOT"
  echo "Marketplace: $MARKETPLACE_NAME ($ENABLED_COUNT/$TOTAL enabled)"
  echo "================================================"
  echo ""

  local CURRENT_CATEGORY=""

  get_all_plugins | while read -r PLUGIN_DIR; do
    local INFO=$(get_plugin_info "$PLUGIN_DIR")
    local NAME=$(echo "$INFO" | jq -r '.name')
    local DESC=$(echo "$INFO" | jq -r '.description')
    local ENABLED=$(echo "$INFO" | jq -r '.enabled')
    local SKILLS=$(echo "$INFO" | jq -r '.skills | length')
    local COMMANDS=$(echo "$INFO" | jq -r '.commands | length')
    local AGENTS=$(echo "$INFO" | jq -r '.agents | length')
    local KEYWORDS=$(echo "$INFO" | jq -r '.keywords | join(", ")')

    # Determine category from path
    local REL_PATH="${PLUGIN_DIR#$REGISTRY_ROOT/plugins/}"
    local CATEGORY=$(echo "$REL_PATH" | cut -d'/' -f1)

    # Print category header if changed
    if [ "$CATEGORY" != "$CURRENT_CATEGORY" ]; then
      echo ""
      echo "## $CATEGORY"
      echo ""
      CURRENT_CATEGORY="$CATEGORY"
    fi

    # Status indicator
    local STATUS="[ ]"
    [ "$ENABLED" = "true" ] && STATUS="[*]"

    printf "  %s %-22s %s\n" "$STATUS" "$NAME" "$DESC"

    # Show components if any
    local COMPONENTS=""
    [ "$SKILLS" -gt 0 ] && COMPONENTS="${COMPONENTS}${SKILLS} skills, "
    [ "$COMMANDS" -gt 0 ] && COMPONENTS="${COMPONENTS}${COMMANDS} commands, "
    [ "$AGENTS" -gt 0 ] && COMPONENTS="${COMPONENTS}${AGENTS} agents, "

    if [ -n "$COMPONENTS" ]; then
      COMPONENTS=$(echo "$COMPONENTS" | sed 's/, $//')
      printf "      %-22s [%s]\n" "" "$COMPONENTS"
    fi

    if [ -n "$KEYWORDS" ]; then
      printf "      %-22s keywords: %s\n" "" "$KEYWORDS"
    fi
  done

  echo ""
  echo "[*] = enabled globally, [ ] = disabled (use --plugin-dir to load)"
}

# List plugins compact (for quick reference)
list_compact() {
  get_all_plugins | while read -r PLUGIN_DIR; do
    local NAME=$(jq -r '.name' "$PLUGIN_DIR/plugin.json" 2>/dev/null)
    local DESC=$(jq -r '.description // ""' "$PLUGIN_DIR/plugin.json" 2>/dev/null | cut -c1-55)
    local STATUS="[ ]"
    is_plugin_enabled "$NAME" && STATUS="[*]"
    printf "%s %-22s %s\n" "$STATUS" "$NAME" "$DESC"
  done
}

# List only enabled plugins
list_enabled() {
  get_all_plugins | while read -r PLUGIN_DIR; do
    local NAME=$(jq -r '.name' "$PLUGIN_DIR/plugin.json" 2>/dev/null)
    if is_plugin_enabled "$NAME"; then
      local DESC=$(jq -r '.description // ""' "$PLUGIN_DIR/plugin.json" 2>/dev/null | cut -c1-60)
      printf "%-25s %s\n" "$NAME" "$DESC"
    fi
  done
}

# List only disabled plugins
list_disabled() {
  get_all_plugins | while read -r PLUGIN_DIR; do
    local NAME=$(jq -r '.name' "$PLUGIN_DIR/plugin.json" 2>/dev/null)
    if ! is_plugin_enabled "$NAME"; then
      local DESC=$(jq -r '.description // ""' "$PLUGIN_DIR/plugin.json" 2>/dev/null | cut -c1-60)
      printf "%-25s %s\n" "$NAME" "$DESC"
    fi
  done
}

# Show plugin details
show_plugin() {
  local NAME="$1"

  local PLUGIN_DIR=$(find "$REGISTRY_ROOT/plugins" -name "plugin.json" -type f 2>/dev/null | while read -r PJ; do
    local PN=$(jq -r '.name' "$PJ" 2>/dev/null)
    if [ "$PN" = "$NAME" ]; then
      dirname "$PJ"
      break
    fi
  done | head -1)

  if [ -z "$PLUGIN_DIR" ]; then
    echo "Plugin not found: $NAME" >&2
    return 1
  fi

  local INFO=$(get_plugin_info "$PLUGIN_DIR")
  local ENABLED=$(echo "$INFO" | jq -r '.enabled')
  local STATUS="DISABLED"
  [ "$ENABLED" = "true" ] && STATUS="ENABLED"

  echo "Plugin: $NAME [$STATUS]"
  echo "================================================"
  echo "Description: $(echo "$INFO" | jq -r '.description')"
  echo "Directory:   $(echo "$INFO" | jq -r '.directory')"
  echo "Keywords:    $(echo "$INFO" | jq -r '.keywords | join(", ")')"
  echo "Status:      $STATUS (in ~/.claude/settings.json)"
  echo ""
  echo "Flag: --plugin-dir $PLUGIN_DIR"
  echo ""

  local SKILLS=$(echo "$INFO" | jq -r '.skills')
  if [ "$SKILLS" != "[]" ]; then
    echo "Skills:"
    echo "$SKILLS" | jq -r '.[] | "  - \(.name): \(.description)"'
    echo ""
  fi

  local COMMANDS=$(echo "$INFO" | jq -r '.commands')
  if [ "$COMMANDS" != "[]" ]; then
    echo "Commands:"
    echo "$COMMANDS" | jq -r '.[] | "  - /\(.name): \(.description)"'
    echo ""
  fi

  local AGENTS=$(echo "$INFO" | jq -r '.agents')
  if [ "$AGENTS" != "[]" ]; then
    echo "Agents:"
    echo "$AGENTS" | jq -r '.[] | "  - \(.name): \(.description)"'
  fi
}

# ============================================================================
# CLI
# ============================================================================

case "${1:-}" in
  --help|-h)
    cat <<'EOF'
Usage: plugin-registry.sh [OPTIONS] [ARGS]

Discovery:
  (no args)              List all plugins with descriptions and status
  --compact              Compact list (name + short description + status)
  --enabled              List only enabled plugins
  --disabled             List only disabled plugins
  --json                 Full registry as JSON
  --show NAME            Show details for a specific plugin

Search & Match:
  --search QUERY         Search plugins by keyword
  --match "TEXT"         Match text to plugins (like match-skills.sh)
  --flags NAME[,NAME]    Get --plugin-dir flags for plugin(s)

Status Legend:
  [*] = enabled globally in ~/.claude/settings.json
  [ ] = disabled (use --plugin-dir to load selectively)

For Worker Spawning:
  # Get flags for a task description
  ./plugin-registry.sh --match "fix terminal resize bug"
  # Output: --plugin-dir /path/to/xterm-js

  # Use directly in claude command
  claude $(./plugin-registry.sh --match "add react dashboard") --continue

  # Or with specific plugins
  claude $(./plugin-registry.sh --flags ui-styling,frontend-design) --continue

Examples:
  ./plugin-registry.sh                           # List all plugins with status
  ./plugin-registry.sh --enabled                 # List only enabled plugins
  ./plugin-registry.sh --disabled                # List plugins available via --plugin-dir
  ./plugin-registry.sh --search react            # Find React-related plugins
  ./plugin-registry.sh --match "database query"  # Get flags for DB work
  ./plugin-registry.sh --show ui-styling         # Show plugin details
  ./plugin-registry.sh --flags ui-styling,tabz   # Get specific plugin flags
EOF
    ;;

  --json)
    build_registry
    ;;

  --compact)
    list_compact
    ;;

  --enabled)
    list_enabled
    ;;

  --disabled)
    list_disabled
    ;;

  --show)
    shift
    show_plugin "$1"
    ;;

  --search)
    shift
    RESULTS=$(search_plugins "$*")
    if [ "$RESULTS" = "[]" ]; then
      echo "No plugins found matching: $*" >&2
      exit 1
    fi
    echo "$RESULTS" | jq -r '.[] | "\(.name): \(.description)"'
    ;;

  --match)
    shift
    PLUGINS=$(match_plugins "$*")
    if [ -z "$PLUGINS" ]; then
      echo "# No matching plugins for: $*" >&2
      exit 0
    fi
    get_plugin_flags "$PLUGINS"
    ;;

  --flags)
    shift
    get_plugin_flags "$1"
    ;;

  "")
    list_plugins
    ;;

  *)
    # Assume it's a search query
    RESULTS=$(search_plugins "$*")
    if [ "$RESULTS" = "[]" ]; then
      echo "No plugins found matching: $*" >&2
      exit 1
    fi
    echo "$RESULTS" | jq -r '.[] | "\(.name): \(.description)"'
    ;;
esac
