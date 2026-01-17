#!/bin/bash
#
# audit-agents.sh - Validate agent definitions
# Checks frontmatter, description, and content quality
#

set -uo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}AGENTS VALIDATION${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Initialize counters
total_plugins=0
plugins_with_agents=0
total_agents=0
compliant_agents=0
non_compliant_agents=0

# Track issues
declare -a agent_violations=()
declare -a agent_warnings=()

# Process each plugin
while IFS= read -r plugin_json; do
    plugin_dir=$(dirname "$(dirname "$plugin_json")")
    plugin_name=$(basename "$plugin_dir")

    ((total_plugins++))

    # Check if plugin has agents directory
    if [[ ! -d "$plugin_dir/agents" ]]; then
        continue
    fi

    ((plugins_with_agents++))

    echo "---"
    echo -e "Plugin: ${BLUE}$plugin_name${NC}"
    echo "Agents: $plugin_dir/agents"

    # Find all markdown files in agents directory
    agent_files=$(find "$plugin_dir/agents" -name "*.md" -type f 2>/dev/null | sort)

    if [[ -z "$agent_files" ]]; then
        echo -e "${YELLOW}  No agent files found${NC}"
        agent_warnings+=("$plugin_name: agents/ exists but empty")
        continue
    fi

    # Check each agent file
    while IFS= read -r agent_file; do
        agent_name=$(basename "$agent_file" .md)
        ((total_agents++))

        echo ""
        echo -e "  Agent: ${BLUE}$agent_name${NC}"

        has_violation=false
        has_warning=false

        # Check for frontmatter
        if ! head -1 "$agent_file" | grep -q "^---$"; then
            echo -e "${RED}    Missing frontmatter delimiters${NC}"
            agent_violations+=("$plugin_name/$agent_name: Missing frontmatter")
            has_violation=true
            ((non_compliant_agents++))
            continue
        fi

        # Extract frontmatter
        frontmatter=$(awk '/^---$/{f++;next}f==1' "$agent_file")

        # Check for description field (REQUIRED)
        if echo "$frontmatter" | grep -q "^description:"; then
            description=$(echo "$frontmatter" | grep "^description:" | cut -d: -f2- | sed 's/^ *//;s/ *$//')
            desc_length=${#description}

            if [[ $desc_length -lt 10 ]]; then
                echo -e "${YELLOW}    Description too short ($desc_length chars)${NC}"
                agent_warnings+=("$plugin_name/$agent_name: Description too short")
                has_warning=true
            else
                echo -e "${GREEN}    description: $desc_length chars${NC}"
            fi

            # Check for example blocks in description (recommended)
            if echo "$description" | grep -qi "example"; then
                echo -e "${GREEN}    Has example guidance${NC}"
            fi
        else
            echo -e "${RED}    Missing 'description' in frontmatter${NC}"
            agent_violations+=("$plugin_name/$agent_name: Missing description")
            has_violation=true
        fi

        # Check for name field
        if echo "$frontmatter" | grep -q "^name:"; then
            name_val=$(echo "$frontmatter" | grep "^name:" | cut -d: -f2- | sed 's/^ *//;s/ *$//')
            # Validate name format (lowercase, hyphens, 3-50 chars)
            if [[ ${#name_val} -lt 3 || ${#name_val} -gt 50 ]]; then
                echo -e "${YELLOW}    Name length should be 3-50 chars${NC}"
                agent_warnings+=("$plugin_name/$agent_name: Name length issue")
                has_warning=true
            elif [[ ! "$name_val" =~ ^[a-z0-9-]+$ ]]; then
                echo -e "${YELLOW}    Name should be lowercase with hyphens${NC}"
                agent_warnings+=("$plugin_name/$agent_name: Name format issue")
                has_warning=true
            else
                echo -e "${GREEN}    name: $name_val${NC}"
            fi
        fi

        # Check for model field
        if echo "$frontmatter" | grep -q "^model:"; then
            model_val=$(echo "$frontmatter" | grep "^model:" | cut -d: -f2- | sed 's/^ *//;s/ *$//')
            valid_models="inherit sonnet opus haiku"
            if echo "$valid_models" | grep -qw "$model_val"; then
                echo -e "${GREEN}    model: $model_val${NC}"
            else
                echo -e "${YELLOW}    Unknown model: $model_val${NC}"
                agent_warnings+=("$plugin_name/$agent_name: Unknown model")
                has_warning=true
            fi
        fi

        # Check for color field
        if echo "$frontmatter" | grep -q "^color:"; then
            color_val=$(echo "$frontmatter" | grep "^color:" | cut -d: -f2- | sed 's/^ *//;s/ *$//')
            valid_colors="blue cyan green yellow magenta red"
            if echo "$valid_colors" | grep -qw "$color_val"; then
                echo -e "${GREEN}    color: $color_val${NC}"
            else
                echo -e "${YELLOW}    Unknown color: $color_val${NC}"
                agent_warnings+=("$plugin_name/$agent_name: Unknown color")
                has_warning=true
            fi
        fi

        # Check for tools field
        if echo "$frontmatter" | grep -q "^tools:"; then
            echo -e "${GREEN}    tools: specified${NC}"
        fi

        # Check content after frontmatter
        content_after=$(awk '/^---$/{f++;next}f==2' "$agent_file")
        content_lines=$(echo "$content_after" | wc -l)

        # Check for heading
        if echo "$content_after" | head -10 | grep -q "^# "; then
            echo -e "${GREEN}    Has heading${NC}"
        else
            echo -e "${YELLOW}    No heading found${NC}"
            agent_warnings+=("$plugin_name/$agent_name: No heading")
            has_warning=true
        fi

        # Check content length (agents should have substantial prompts)
        if [[ $content_lines -lt 10 ]]; then
            echo -e "${YELLOW}    Minimal content ($content_lines lines)${NC}"
            agent_warnings+=("$plugin_name/$agent_name: Minimal content")
            has_warning=true
        else
            echo -e "${GREEN}    Content: $content_lines lines${NC}"
        fi

        # Check for role description patterns
        if echo "$content_after" | grep -qi "purpose\|capabilities\|when to use\|expertise\|specializ"; then
            echo -e "${GREEN}    Has role description${NC}"
        fi

        # Tally results
        if ! $has_violation; then
            ((compliant_agents++))
            echo -e "    STATUS: ${GREEN}COMPLIANT${NC}"
        else
            ((non_compliant_agents++))
            echo -e "    STATUS: ${RED}NON-COMPLIANT${NC}"
        fi
    done <<< "$agent_files"

    echo ""
done < <(find "$PROJECT_ROOT/plugins" -path "*/.claude-plugin/plugin.json" -type f 2>/dev/null | sort)

# Summary
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}AGENTS VALIDATION SUMMARY${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo "Total Plugins: $total_plugins"
echo "Plugins with Agents: $plugins_with_agents"
echo "Total Agent Files: $total_agents"
echo -e "Compliant Agents: ${GREEN}$compliant_agents${NC}"
echo -e "Non-Compliant Agents: ${RED}$non_compliant_agents${NC}"
echo ""

if [[ ${#agent_violations[@]} -gt 0 ]]; then
    echo -e "${RED}VIOLATIONS (${#agent_violations[@]}):${NC}"
    for violation in "${agent_violations[@]}"; do
        echo -e "  ${RED}$violation${NC}"
    done
    echo ""
fi

if [[ ${#agent_warnings[@]} -gt 0 ]]; then
    echo -e "${YELLOW}WARNINGS (${#agent_warnings[@]}):${NC}"
    for warning in "${agent_warnings[@]}"; do
        echo -e "  ${YELLOW}$warning${NC}"
    done
fi

echo ""
if [[ $total_agents -gt 0 ]]; then
    rate=$(( (compliant_agents * 100) / total_agents ))
    echo "Agent Compliance Rate: $rate%"
else
    echo "No agents found to validate"
fi

# Exit with error if violations found
[[ $non_compliant_agents -eq 0 ]]
