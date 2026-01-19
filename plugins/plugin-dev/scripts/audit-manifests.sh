#!/bin/bash
#
# audit-manifests.sh - Validate plugin.json manifests
# Adapted for my-plugins marketplace structure
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
echo -e "${BLUE}PLUGIN MANIFEST VALIDATION${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Initialize counters
total_plugins=0
compliant_plugins=0
plugins_with_violations=0
plugins_with_warnings=0

# Track issues
declare -a critical_violations=()
declare -a major_violations=()
declare -a minor_warnings=()

# Validation functions
validate_semver() {
    [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

validate_kebab_case() {
    [[ "$1" =~ ^[a-z0-9-]+$ ]]
}

validate_url() {
    [[ "$1" =~ ^https?:// ]]
}

# Process each plugin
while IFS= read -r plugin_json; do
    plugin_dir=$(dirname "$(dirname "$plugin_json")")
    plugin_name=$(basename "$plugin_dir")
    category=$(basename "$(dirname "$plugin_dir")")

    ((total_plugins++))

    echo "---"
    echo -e "Plugin #$total_plugins: ${BLUE}$plugin_name${NC} (category: $category)"
    echo "Location: $plugin_dir"

    has_critical=false
    has_major=false
    has_minor=false

    # Check if file is valid JSON
    if ! jq empty "$plugin_json" 2>/dev/null; then
        echo -e "${RED}  CRITICAL: Invalid JSON syntax${NC}"
        critical_violations+=("$plugin_name: Invalid JSON syntax")
        has_critical=true
        ((plugins_with_violations++))
        continue
    fi

    # Check REQUIRED fields

    # 1. Check name field (required)
    name=$(jq -r '.name // empty' "$plugin_json")
    if [[ -z "$name" ]]; then
        echo -e "${RED}  CRITICAL: Missing required field 'name'${NC}"
        critical_violations+=("$plugin_name: Missing 'name' field")
        has_critical=true
    elif ! validate_kebab_case "$name"; then
        echo -e "${RED}  CRITICAL: Name '$name' not in kebab-case format${NC}"
        critical_violations+=("$plugin_name: Name '$name' not kebab-case")
        has_critical=true
    else
        echo -e "${GREEN}  name: $name${NC}"
    fi

    # 2. Check version field (optional but recommended)
    version=$(jq -r '.version // empty' "$plugin_json")
    if [[ -n "$version" ]]; then
        if validate_semver "$version"; then
            echo -e "${GREEN}  version: $version${NC}"
        else
            echo -e "${YELLOW}  WARNING: Version '$version' not in semver format${NC}"
            minor_warnings+=("$plugin_name: Version not semver")
            has_minor=true
        fi
    fi

    # 3. Check description field (required)
    description=$(jq -r '.description // empty' "$plugin_json")
    if [[ -z "$description" ]]; then
        echo -e "${RED}  CRITICAL: Missing required field 'description'${NC}"
        critical_violations+=("$plugin_name: Missing 'description' field")
        has_critical=true
    else
        desc_length=${#description}
        if [[ $desc_length -lt 10 ]]; then
            echo -e "${YELLOW}  WARNING: Description too short ($desc_length chars)${NC}"
            minor_warnings+=("$plugin_name: Description too short")
            has_minor=true
        elif [[ $desc_length -gt 400 ]]; then
            echo -e "${YELLOW}  WARNING: Description too long ($desc_length chars, max 400)${NC}"
            minor_warnings+=("$plugin_name: Description too long")
            has_minor=true
        else
            echo -e "${GREEN}  description: Present ($desc_length chars)${NC}"
        fi
    fi

    # Check for unknown/invalid fields
    ALLOWED_FIELDS='["$schema","name","version","description","author","repository","homepage","license","keywords","mcpServers"]'
    INVALID_FIELDS=$(jq -r --argjson allowed "$ALLOWED_FIELDS" 'keys - $allowed | .[]' "$plugin_json" 2>/dev/null || true)

    if [[ -n "$INVALID_FIELDS" ]]; then
        echo -e "${YELLOW}  WARNING: Unknown fields found:${NC}"
        echo "$INVALID_FIELDS" | while read -r field; do
            echo -e "${YELLOW}    - $field${NC}"
        done
        minor_warnings+=("$plugin_name: Unknown fields in manifest")
        has_minor=true
    fi

    # Tally results
    if $has_critical; then
        ((plugins_with_violations++))
        echo -e "STATUS: ${RED}NON-COMPLIANT (Critical)${NC}"
    elif $has_major; then
        ((plugins_with_violations++))
        echo -e "STATUS: ${RED}NON-COMPLIANT (Major)${NC}"
    elif $has_minor; then
        ((plugins_with_warnings++))
        ((compliant_plugins++))
        echo -e "STATUS: ${YELLOW}COMPLIANT WITH WARNINGS${NC}"
    else
        ((compliant_plugins++))
        echo -e "STATUS: ${GREEN}FULLY COMPLIANT${NC}"
    fi

    echo ""
done < <(find "$PROJECT_ROOT/plugins" -path "*/.claude-plugin/plugin.json" -type f 2>/dev/null | sort)

# Summary
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}MANIFEST VALIDATION SUMMARY${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo "Total Plugins: $total_plugins"
echo -e "Fully Compliant: ${GREEN}$compliant_plugins${NC}"
echo -e "With Violations: ${RED}$plugins_with_violations${NC}"
echo -e "With Warnings: ${YELLOW}$plugins_with_warnings${NC}"
echo ""

if [[ ${#critical_violations[@]} -gt 0 ]]; then
    echo -e "${RED}CRITICAL VIOLATIONS (${#critical_violations[@]}):${NC}"
    for violation in "${critical_violations[@]}"; do
        echo -e "  ${RED}$violation${NC}"
    done
    echo ""
fi

if [[ ${#major_violations[@]} -gt 0 ]]; then
    echo -e "${RED}MAJOR VIOLATIONS (${#major_violations[@]}):${NC}"
    for violation in "${major_violations[@]}"; do
        echo -e "  ${RED}$violation${NC}"
    done
    echo ""
fi

if [[ ${#minor_warnings[@]} -gt 0 ]]; then
    echo -e "${YELLOW}WARNINGS (${#minor_warnings[@]}):${NC}"
    for warning in "${minor_warnings[@]}"; do
        echo -e "  ${YELLOW}$warning${NC}"
    done
fi

echo ""
if [[ $total_plugins -gt 0 ]]; then
    rate=$(( (compliant_plugins * 100) / total_plugins ))
    echo "Compliance Rate: $rate%"
else
    echo "No plugins found to validate"
fi

# Exit with error if violations found
if [[ $plugins_with_violations -gt 0 ]]; then
    exit 1
fi
exit 0
