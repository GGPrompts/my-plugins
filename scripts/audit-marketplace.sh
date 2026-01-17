#!/bin/bash
#
# audit-marketplace.sh - Validate marketplace.json
# Checks structure, plugin references, and consistency
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

MARKETPLACE_JSON="$PROJECT_ROOT/.claude-plugin/marketplace.json"

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}MARKETPLACE.JSON VALIDATION${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Track issues
declare -a violations=()
declare -a warnings=()
has_errors=false

# Check marketplace.json exists
if [[ ! -f "$MARKETPLACE_JSON" ]]; then
    echo -e "${RED}CRITICAL: marketplace.json not found at $MARKETPLACE_JSON${NC}"
    exit 1
fi

echo "Location: $MARKETPLACE_JSON"
echo ""

# Validate JSON syntax
if ! jq empty "$MARKETPLACE_JSON" 2>/dev/null; then
    echo -e "${RED}CRITICAL: Invalid JSON syntax${NC}"
    exit 1
fi
echo -e "${GREEN}JSON syntax valid${NC}"

# Check required fields
echo ""
echo "Checking required fields..."

# Check name
name=$(jq -r '.name // empty' "$MARKETPLACE_JSON")
if [[ -z "$name" ]]; then
    echo -e "${RED}  Missing 'name' field${NC}"
    violations+=("Missing 'name' field")
    has_errors=true
else
    echo -e "${GREEN}  name: $name${NC}"
fi

# Check plugins array
if ! jq -e '.plugins' "$MARKETPLACE_JSON" >/dev/null 2>&1; then
    echo -e "${RED}  Missing 'plugins' array${NC}"
    violations+=("Missing 'plugins' array")
    has_errors=true
else
    plugin_count=$(jq '.plugins | length' "$MARKETPLACE_JSON")
    echo -e "${GREEN}  plugins: $plugin_count entries${NC}"
fi

# Validate each plugin entry
echo ""
echo "Validating plugin entries..."

total_entries=0
valid_entries=0
missing_plugins=0
orphaned_plugins=0

# Get list of actual plugins
declare -a actual_plugins=()
while IFS= read -r plugin_json; do
    plugin_dir=$(dirname "$(dirname "$plugin_json")")
    plugin_name=$(basename "$plugin_dir")
    actual_plugins+=("$plugin_name")
done < <(find "$PROJECT_ROOT/plugins" -path "*/.claude-plugin/plugin.json" -type f 2>/dev/null)

# Track referenced plugins
declare -a referenced_plugins=()

# Check each entry in marketplace.json
while IFS= read -r entry; do
    ((total_entries++))

    entry_name=$(echo "$entry" | jq -r '.name // empty')
    entry_source=$(echo "$entry" | jq -r '.source // empty')
    entry_desc=$(echo "$entry" | jq -r '.description // empty')
    entry_category=$(echo "$entry" | jq -r '.category // empty')

    echo ""
    echo -e "  Entry: ${BLUE}$entry_name${NC}"

    entry_valid=true

    # Check required fields
    if [[ -z "$entry_name" ]]; then
        echo -e "${RED}    Missing 'name'${NC}"
        violations+=("Entry missing 'name'")
        entry_valid=false
    fi

    if [[ -z "$entry_source" ]]; then
        echo -e "${RED}    Missing 'source'${NC}"
        violations+=("$entry_name: Missing 'source'")
        entry_valid=false
    else
        # Validate source path exists
        source_path="$PROJECT_ROOT/${entry_source#./}"
        if [[ ! -d "$source_path" ]]; then
            echo -e "${RED}    Source path not found: $entry_source${NC}"
            violations+=("$entry_name: Source path not found")
            entry_valid=false
            ((missing_plugins++))
        elif [[ ! -f "$source_path/.claude-plugin/plugin.json" ]]; then
            echo -e "${RED}    Missing plugin.json in $entry_source${NC}"
            violations+=("$entry_name: No plugin.json in source")
            entry_valid=false
        else
            echo -e "${GREEN}    source: $entry_source${NC}"
            referenced_plugins+=("$(basename "$source_path")")
        fi
    fi

    if [[ -z "$entry_desc" ]]; then
        echo -e "${YELLOW}    Missing 'description'${NC}"
        warnings+=("$entry_name: Missing description")
    else
        desc_length=${#entry_desc}
        if [[ $desc_length -gt 200 ]]; then
            echo -e "${YELLOW}    Description long ($desc_length chars)${NC}"
            warnings+=("$entry_name: Long description")
        else
            echo -e "${GREEN}    description: $desc_length chars${NC}"
        fi
    fi

    if [[ -z "$entry_category" ]]; then
        echo -e "${YELLOW}    Missing 'category'${NC}"
        warnings+=("$entry_name: Missing category")
    else
        echo -e "${GREEN}    category: $entry_category${NC}"
    fi

    # Check for keywords
    keywords_count=$(echo "$entry" | jq '.keywords // [] | length')
    if [[ $keywords_count -gt 0 ]]; then
        echo -e "${GREEN}    keywords: $keywords_count${NC}"
    fi

    if $entry_valid; then
        ((valid_entries++))
        echo -e "    STATUS: ${GREEN}VALID${NC}"
    else
        echo -e "    STATUS: ${RED}INVALID${NC}"
        has_errors=true
    fi
done < <(jq -c '.plugins[]' "$MARKETPLACE_JSON" 2>/dev/null)

# Check for orphaned plugins (exist but not in marketplace)
echo ""
echo "Checking for orphaned plugins..."
for plugin in "${actual_plugins[@]}"; do
    found=false
    for ref in "${referenced_plugins[@]}"; do
        if [[ "$plugin" == "$ref" ]]; then
            found=true
            break
        fi
    done
    if ! $found; then
        echo -e "${YELLOW}  Orphaned: $plugin (not in marketplace.json)${NC}"
        warnings+=("Orphaned plugin: $plugin")
        ((orphaned_plugins++))
    fi
done

if [[ $orphaned_plugins -eq 0 ]]; then
    echo -e "${GREEN}  No orphaned plugins${NC}"
fi

# Check for duplicate entries
echo ""
echo "Checking for duplicates..."
duplicates=$(jq -r '.plugins[].name' "$MARKETPLACE_JSON" | sort | uniq -d)
if [[ -n "$duplicates" ]]; then
    echo -e "${RED}  Duplicate entries found:${NC}"
    echo "$duplicates" | while read -r dup; do
        echo -e "${RED}    - $dup${NC}"
        violations+=("Duplicate entry: $dup")
    done
    has_errors=true
else
    echo -e "${GREEN}  No duplicates${NC}"
fi

# Summary
echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}MARKETPLACE VALIDATION SUMMARY${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo "Total Entries: $total_entries"
echo -e "Valid Entries: ${GREEN}$valid_entries${NC}"
echo -e "Missing Plugins: ${RED}$missing_plugins${NC}"
echo -e "Orphaned Plugins: ${YELLOW}$orphaned_plugins${NC}"
echo ""

if [[ ${#violations[@]} -gt 0 ]]; then
    echo -e "${RED}VIOLATIONS (${#violations[@]}):${NC}"
    for violation in "${violations[@]}"; do
        echo -e "  ${RED}$violation${NC}"
    done
    echo ""
fi

if [[ ${#warnings[@]} -gt 0 ]]; then
    echo -e "${YELLOW}WARNINGS (${#warnings[@]}):${NC}"
    for warning in "${warnings[@]}"; do
        echo -e "  ${YELLOW}$warning${NC}"
    done
fi

echo ""
if [[ $total_entries -gt 0 ]]; then
    rate=$(( (valid_entries * 100) / total_entries ))
    echo "Marketplace Validity Rate: $rate%"
fi

# Exit with error if violations found
! $has_errors
