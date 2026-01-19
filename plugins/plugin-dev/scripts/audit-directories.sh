#!/bin/bash
#
# audit-directories.sh - Validate plugin directory structure
# Ensures proper .claude-plugin/plugin.json pattern and component organization
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
echo -e "${BLUE}DIRECTORY STRUCTURE VALIDATION${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Initialize counters
total_plugins=0
compliant_plugins=0
plugins_with_violations=0

# Track issues
declare -a critical_violations=()
declare -a structure_warnings=()

# Process each plugin
while IFS= read -r plugin_json; do
    plugin_dir=$(dirname "$(dirname "$plugin_json")")
    plugin_name=$(basename "$plugin_dir")
    category=$(basename "$(dirname "$plugin_dir")")

    ((total_plugins++))

    echo "---"
    echo -e "Plugin #$total_plugins: ${BLUE}$plugin_name${NC}"
    echo "Location: $plugin_dir"

    has_violations=false
    has_warnings=false

    # CRITICAL: Check .claude-plugin is at root
    claude_plugin_dir=$(dirname "$plugin_json")
    expected_location="$plugin_dir/.claude-plugin"

    if [[ "$claude_plugin_dir" != "$expected_location" ]]; then
        echo -e "${RED}  CRITICAL: .claude-plugin/ not at plugin root${NC}"
        critical_violations+=("$plugin_name: .claude-plugin/ not at plugin root")
        has_violations=true
    else
        echo -e "${GREEN}  .claude-plugin/ at root level${NC}"
    fi

    # Check for plugin.json in WRONG locations
    wrong_locations=()

    if [[ -f "$plugin_dir/plugin.json" ]]; then
        wrong_locations+=("plugin.json at root (should be in .claude-plugin/)")
    fi
    if [[ -f "$plugin_dir/commands/plugin.json" ]]; then
        wrong_locations+=("commands/plugin.json")
    fi
    if [[ -f "$plugin_dir/agents/plugin.json" ]]; then
        wrong_locations+=("agents/plugin.json")
    fi

    if [[ ${#wrong_locations[@]} -gt 0 ]]; then
        echo -e "${RED}  VIOLATION: plugin.json in wrong locations:${NC}"
        for loc in "${wrong_locations[@]}"; do
            echo -e "${RED}    - $loc${NC}"
            critical_violations+=("$plugin_name: $loc")
        done
        has_violations=true
    fi

    # Check for components inside .claude-plugin (VIOLATION)
    if [[ -d "$plugin_dir/.claude-plugin/commands" ]]; then
        echo -e "${RED}  VIOLATION: commands/ inside .claude-plugin/${NC}"
        critical_violations+=("$plugin_name: commands/ inside .claude-plugin/")
        has_violations=true
    fi
    if [[ -d "$plugin_dir/.claude-plugin/agents" ]]; then
        echo -e "${RED}  VIOLATION: agents/ inside .claude-plugin/${NC}"
        critical_violations+=("$plugin_name: agents/ inside .claude-plugin/")
        has_violations=true
    fi
    if [[ -d "$plugin_dir/.claude-plugin/skills" ]]; then
        echo -e "${RED}  VIOLATION: skills/ inside .claude-plugin/${NC}"
        critical_violations+=("$plugin_name: skills/ inside .claude-plugin/")
        has_violations=true
    fi

    # Check component directories
    has_component=false

    # Check commands directory
    if [[ -d "$plugin_dir/commands" ]]; then
        cmd_count=$(find "$plugin_dir/commands" -name "*.md" -type f 2>/dev/null | wc -l)
        echo -e "${GREEN}  commands/: $cmd_count command(s)${NC}"
        has_component=true

        # Check for non-markdown files
        non_md=$(find "$plugin_dir/commands" -type f ! -name "*.md" 2>/dev/null | wc -l)
        if [[ $non_md -gt 0 ]]; then
            echo -e "${YELLOW}    WARNING: $non_md non-markdown files${NC}"
            structure_warnings+=("$plugin_name: non-markdown files in commands/")
            has_warnings=true
        fi
    fi

    # Check agents directory
    if [[ -d "$plugin_dir/agents" ]]; then
        agent_count=$(find "$plugin_dir/agents" -name "*.md" -type f 2>/dev/null | wc -l)
        echo -e "${GREEN}  agents/: $agent_count agent(s)${NC}"
        has_component=true
    fi

    # Check skills directory (my-plugins pattern: skills/<name>/SKILL.md)
    if [[ -d "$plugin_dir/skills" ]]; then
        skill_count=$(find "$plugin_dir/skills" -name "SKILL.md" -type f 2>/dev/null | wc -l)
        echo -e "${GREEN}  skills/: $skill_count skill(s)${NC}"
        has_component=true

        # Check for nested skills (VIOLATION)
        nested=$(find "$plugin_dir/skills" -path "*/skills/*/skills/*" -name "SKILL.md" 2>/dev/null | wc -l)
        if [[ $nested -gt 0 ]]; then
            echo -e "${RED}    VIOLATION: Nested skills detected (skills/x/skills/y)${NC}"
            critical_violations+=("$plugin_name: Nested skills structure")
            has_violations=true
        fi

        # Check each skill has proper structure
        while IFS= read -r skill_md; do
            skill_dir=$(dirname "$skill_md")
            skill_name=$(basename "$skill_dir")

            # Check for references in skill directory
            if [[ -d "$skill_dir/references" ]]; then
                ref_count=$(find "$skill_dir/references" -type f 2>/dev/null | wc -l)
                echo -e "    $skill_name: $ref_count reference file(s)"
            fi
        done < <(find "$plugin_dir/skills" -name "SKILL.md" -type f 2>/dev/null)
    fi

    # Check hooks directory
    if [[ -d "$plugin_dir/hooks" ]]; then
        if [[ -f "$plugin_dir/hooks/hooks.json" ]]; then
            echo -e "${GREEN}  hooks/: hooks.json present${NC}"
        else
            echo -e "${YELLOW}  hooks/: directory exists but no hooks.json${NC}"
            structure_warnings+=("$plugin_name: hooks/ without hooks.json")
            has_warnings=true
        fi
        has_component=true
    fi

    # Check for .mcp.json
    if [[ -f "$plugin_dir/.mcp.json" ]]; then
        echo -e "${GREEN}  .mcp.json: present${NC}"
        has_component=true
    fi

    # Check for scripts directory
    if [[ -d "$plugin_dir/scripts" ]]; then
        script_count=$(find "$plugin_dir/scripts" -type f -executable 2>/dev/null | wc -l)
        non_exec=$(find "$plugin_dir/scripts" -name "*.sh" -type f ! -executable 2>/dev/null | wc -l)
        echo -e "${GREEN}  scripts/: $script_count executable(s)${NC}"
        if [[ $non_exec -gt 0 ]]; then
            echo -e "${YELLOW}    WARNING: $non_exec .sh scripts not executable${NC}"
            structure_warnings+=("$plugin_name: non-executable .sh scripts")
            has_warnings=true
        fi
        has_component=true
    fi

    # Check documentation
    if [[ -f "$plugin_dir/README.md" ]]; then
        echo -e "${GREEN}  README.md: present${NC}"
    else
        echo -e "  README.md: not present"
    fi

    # Verify plugin has at least one component
    if ! $has_component; then
        echo -e "${YELLOW}  WARNING: No component directories found${NC}"
        structure_warnings+=("$plugin_name: No components (commands/agents/skills/hooks)")
        has_warnings=true
    fi

    # Tally results
    if $has_violations; then
        ((plugins_with_violations++))
        echo -e "STATUS: ${RED}STRUCTURE VIOLATIONS${NC}"
    elif $has_warnings; then
        ((compliant_plugins++))
        echo -e "STATUS: ${YELLOW}COMPLIANT WITH WARNINGS${NC}"
    else
        ((compliant_plugins++))
        echo -e "STATUS: ${GREEN}STRUCTURE COMPLIANT${NC}"
    fi

    echo ""
done < <(find "$PROJECT_ROOT/plugins" -path "*/.claude-plugin/plugin.json" -type f 2>/dev/null | sort)

# Summary
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}DIRECTORY STRUCTURE SUMMARY${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo "Total Plugins: $total_plugins"
echo -e "Structure Compliant: ${GREEN}$compliant_plugins${NC}"
echo -e "With Violations: ${RED}$plugins_with_violations${NC}"
echo ""

if [[ ${#critical_violations[@]} -gt 0 ]]; then
    echo -e "${RED}CRITICAL VIOLATIONS (${#critical_violations[@]}):${NC}"
    for violation in "${critical_violations[@]}"; do
        echo -e "  ${RED}$violation${NC}"
    done
    echo ""
fi

if [[ ${#structure_warnings[@]} -gt 0 ]]; then
    echo -e "${YELLOW}WARNINGS (${#structure_warnings[@]}):${NC}"
    for warning in "${structure_warnings[@]}"; do
        echo -e "  ${YELLOW}$warning${NC}"
    done
fi

echo ""
if [[ $total_plugins -gt 0 ]]; then
    rate=$(( (compliant_plugins * 100) / total_plugins ))
    echo "Structure Compliance Rate: $rate%"
else
    echo "No plugins found to validate"
fi

# Exit with error if violations found
[[ $plugins_with_violations -eq 0 ]]
