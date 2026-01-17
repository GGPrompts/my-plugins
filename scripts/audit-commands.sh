#!/bin/bash
#
# audit-commands.sh - Validate slash commands
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
echo -e "${BLUE}SLASH COMMANDS VALIDATION${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Initialize counters
total_plugins=0
plugins_with_commands=0
total_commands=0
compliant_commands=0
non_compliant_commands=0

# Track issues
declare -a command_violations=()
declare -a command_warnings=()

# Process each plugin
while IFS= read -r plugin_json; do
    plugin_dir=$(dirname "$(dirname "$plugin_json")")
    plugin_name=$(basename "$plugin_dir")

    ((total_plugins++))

    # Check if plugin has commands directory
    if [[ ! -d "$plugin_dir/commands" ]]; then
        continue
    fi

    ((plugins_with_commands++))

    echo "---"
    echo -e "Plugin: ${BLUE}$plugin_name${NC}"
    echo "Commands: $plugin_dir/commands"

    # Find all markdown files in commands directory
    command_files=$(find "$plugin_dir/commands" -name "*.md" -type f 2>/dev/null | sort)

    if [[ -z "$command_files" ]]; then
        echo -e "${YELLOW}  No command files found${NC}"
        command_warnings+=("$plugin_name: commands/ exists but empty")
        continue
    fi

    # Check each command file
    while IFS= read -r cmd_file; do
        cmd_name=$(basename "$cmd_file" .md)
        ((total_commands++))

        echo ""
        echo -e "  Command: ${BLUE}$cmd_name${NC}"

        has_violation=false
        has_warning=false

        # Check for frontmatter
        if ! head -1 "$cmd_file" | grep -q "^---$"; then
            echo -e "${RED}    Missing frontmatter delimiters${NC}"
            command_violations+=("$plugin_name/$cmd_name: Missing frontmatter")
            has_violation=true
            ((non_compliant_commands++))
            continue
        fi

        # Extract frontmatter (between first and second ---)
        frontmatter=$(awk '/^---$/{f++;next}f==1' "$cmd_file")

        # Check for description field (REQUIRED)
        if echo "$frontmatter" | grep -q "^description:"; then
            description=$(echo "$frontmatter" | grep "^description:" | cut -d: -f2- | sed 's/^ *//;s/ *$//')
            desc_length=${#description}

            if [[ $desc_length -lt 10 ]]; then
                echo -e "${YELLOW}    Description too short ($desc_length chars)${NC}"
                command_warnings+=("$plugin_name/$cmd_name: Description too short")
                has_warning=true
            else
                echo -e "${GREEN}    description: $desc_length chars${NC}"
            fi
        else
            echo -e "${RED}    Missing 'description' in frontmatter${NC}"
            command_violations+=("$plugin_name/$cmd_name: Missing description")
            has_violation=true
        fi

        # Check for optional fields
        if echo "$frontmatter" | grep -q "^name:"; then
            echo -e "${GREEN}    name: present${NC}"
        fi

        if echo "$frontmatter" | grep -q "^allowed-tools:"; then
            echo -e "${GREEN}    allowed-tools: present${NC}"
        fi

        if echo "$frontmatter" | grep -q "^argument-hint:"; then
            echo -e "${GREEN}    argument-hint: present${NC}"
        fi

        # Check content after frontmatter
        content_after=$(awk '/^---$/{f++;next}f==2' "$cmd_file")
        content_lines=$(echo "$content_after" | wc -l)

        # Check for heading
        if echo "$content_after" | head -10 | grep -q "^# "; then
            echo -e "${GREEN}    Has heading${NC}"
        else
            echo -e "${YELLOW}    No heading found${NC}"
            command_warnings+=("$plugin_name/$cmd_name: No heading")
            has_warning=true
        fi

        # Check content length
        if [[ $content_lines -lt 5 ]]; then
            echo -e "${YELLOW}    Minimal content ($content_lines lines)${NC}"
            command_warnings+=("$plugin_name/$cmd_name: Minimal content")
            has_warning=true
        else
            echo -e "${GREEN}    Content: $content_lines lines${NC}"
        fi

        # Tally results
        if ! $has_violation; then
            ((compliant_commands++))
            echo -e "    STATUS: ${GREEN}COMPLIANT${NC}"
        else
            ((non_compliant_commands++))
            echo -e "    STATUS: ${RED}NON-COMPLIANT${NC}"
        fi
    done <<< "$command_files"

    echo ""
done < <(find "$PROJECT_ROOT/plugins" -path "*/.claude-plugin/plugin.json" -type f 2>/dev/null | sort)

# Summary
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}COMMANDS VALIDATION SUMMARY${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo "Total Plugins: $total_plugins"
echo "Plugins with Commands: $plugins_with_commands"
echo "Total Command Files: $total_commands"
echo -e "Compliant Commands: ${GREEN}$compliant_commands${NC}"
echo -e "Non-Compliant Commands: ${RED}$non_compliant_commands${NC}"
echo ""

if [[ ${#command_violations[@]} -gt 0 ]]; then
    echo -e "${RED}VIOLATIONS (${#command_violations[@]}):${NC}"
    for violation in "${command_violations[@]}"; do
        echo -e "  ${RED}$violation${NC}"
    done
    echo ""
fi

if [[ ${#command_warnings[@]} -gt 0 ]]; then
    echo -e "${YELLOW}WARNINGS (${#command_warnings[@]}):${NC}"
    for warning in "${command_warnings[@]}"; do
        echo -e "  ${YELLOW}$warning${NC}"
    done
fi

echo ""
if [[ $total_commands -gt 0 ]]; then
    rate=$(( (compliant_commands * 100) / total_commands ))
    echo "Command Compliance Rate: $rate%"
else
    echo "No commands found to validate"
fi

# Exit with error if violations found
[[ $non_compliant_commands -eq 0 ]]
