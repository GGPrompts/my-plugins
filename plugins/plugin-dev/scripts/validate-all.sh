#!/bin/bash
#
# validate-all.sh - Plugin validation runner
# Quick validation of Claude Code plugins before commits
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Target directory (default to current working directory)
TARGET_DIR="${1:-$(pwd)}"

# Detect if target is a marketplace (has plugins/ subdir) or single plugin
if [[ -d "$TARGET_DIR/plugins" ]]; then
    SCAN_DIR="$TARGET_DIR/plugins"
    PROJECT_TYPE="marketplace"
elif [[ -d "$TARGET_DIR/.claude-plugin" ]]; then
    SCAN_DIR="$TARGET_DIR"
    PROJECT_TYPE="plugin"
else
    SCAN_DIR="$TARGET_DIR"
    PROJECT_TYPE="directory"
fi

echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}     PLUGIN VALIDATION SUITE${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""
echo "Target: $TARGET_DIR"
echo "Type: $PROJECT_TYPE"
echo "Scanning: $SCAN_DIR"
echo ""

# Counters
ERRORS=0
WARNINGS=0

# Function to run a check
run_check() {
    local name="$1"
    local check_cmd="$2"

    echo -e "${BLUE}$name${NC}"
    if eval "$check_cmd"; then
        echo -e "${GREEN}  PASSED${NC}"
    else
        echo -e "${RED}  FAILED${NC}"
        ERRORS=$((ERRORS + 1))
    fi
    echo ""
}

# 1. JSON Syntax Validation
echo -e "${BLUE}[1/6] Validating JSON files...${NC}"
json_errors=0
while IFS= read -r json_file; do
    if ! jq empty "$json_file" 2>/dev/null; then
        echo -e "${RED}  Invalid JSON: $json_file${NC}"
        json_errors=$((json_errors + 1))
    fi
done < <(find "$SCAN_DIR" -name "*.json" -type f 2>/dev/null)

# Also check marketplace.json
if [[ -f "$TARGET_DIR/.claude-plugin/marketplace.json" ]]; then
    if ! jq empty "$TARGET_DIR/.claude-plugin/marketplace.json" 2>/dev/null; then
        echo -e "${RED}  Invalid JSON: marketplace.json${NC}"
        json_errors=$((json_errors + 1))
    fi
fi

if [[ $json_errors -eq 0 ]]; then
    echo -e "${GREEN}  All JSON valid${NC}"
else
    echo -e "${RED}  $json_errors JSON errors${NC}"
    ERRORS=$((ERRORS + json_errors))
fi
echo ""

# 2. Plugin Manifest Validation
echo -e "${BLUE}[2/6] Validating plugin manifests...${NC}"
manifest_errors=0
while IFS= read -r plugin_json; do
    plugin_name=$(basename "$(dirname "$(dirname "$plugin_json")")")

    # Check required field: name
    if ! jq -e '.name' "$plugin_json" >/dev/null 2>&1; then
        echo -e "${RED}  $plugin_name: Missing 'name'${NC}"
        manifest_errors=$((manifest_errors + 1))
    fi

    # Check required field: description
    if ! jq -e '.description' "$plugin_json" >/dev/null 2>&1; then
        echo -e "${RED}  $plugin_name: Missing 'description'${NC}"
        manifest_errors=$((manifest_errors + 1))
    fi
done < <(find "$SCAN_DIR" -path "*/.claude-plugin/plugin.json" -type f 2>/dev/null)

if [[ $manifest_errors -eq 0 ]]; then
    echo -e "${GREEN}  All manifests valid${NC}"
else
    echo -e "${RED}  $manifest_errors manifest errors${NC}"
    ERRORS=$((ERRORS + manifest_errors))
fi
echo ""

# 3. Frontmatter Validation (Commands & Agents)
echo -e "${BLUE}[3/6] Validating frontmatter...${NC}"
frontmatter_errors=0
while IFS= read -r md_file; do
    if ! head -1 "$md_file" | grep -q "^---$"; then
        echo -e "${RED}  Missing frontmatter: $md_file${NC}"
        frontmatter_errors=$((frontmatter_errors + 1))
    fi
done < <(find "$SCAN_DIR" \( -path "*/commands/*.md" -o -path "*/agents/*.md" \) -type f 2>/dev/null | head -100)

if [[ $frontmatter_errors -eq 0 ]]; then
    echo -e "${GREEN}  All frontmatter valid${NC}"
else
    echo -e "${RED}  $frontmatter_errors frontmatter errors${NC}"
    ERRORS=$((ERRORS + frontmatter_errors))
fi
echo ""

# 4. Skills Validation
echo -e "${BLUE}[4/6] Validating skills...${NC}"
skill_errors=0
while IFS= read -r skill_file; do
    skill_name=$(basename "$(dirname "$skill_file")")

    # Check frontmatter exists
    if ! head -1 "$skill_file" | grep -q "^---$"; then
        echo -e "${RED}  $skill_name: Missing frontmatter${NC}"
        skill_errors=$((skill_errors + 1))
        continue
    fi

    # Check required fields in frontmatter
    frontmatter=$(awk '/^---$/{f++;next}f==1' "$skill_file")
    if ! echo "$frontmatter" | grep -q "^name:"; then
        echo -e "${RED}  $skill_name: Missing 'name'${NC}"
        skill_errors=$((skill_errors + 1))
    fi
    if ! echo "$frontmatter" | grep -q "^description:"; then
        echo -e "${RED}  $skill_name: Missing 'description'${NC}"
        skill_errors=$((skill_errors + 1))
    fi
done < <(find "$SCAN_DIR" -name "SKILL.md" -type f 2>/dev/null)

if [[ $skill_errors -eq 0 ]]; then
    echo -e "${GREEN}  All skills valid${NC}"
else
    echo -e "${RED}  $skill_errors skill errors${NC}"
    ERRORS=$((ERRORS + skill_errors))
fi
echo ""

# 5. Directory Structure Validation
echo -e "${BLUE}[5/6] Validating directory structure...${NC}"
structure_errors=0
while IFS= read -r plugin_json; do
    plugin_dir=$(dirname "$(dirname "$plugin_json")")
    plugin_name=$(basename "$plugin_dir")

    # Check for plugin.json in wrong locations
    if [[ -f "$plugin_dir/plugin.json" ]]; then
        echo -e "${RED}  $plugin_name: plugin.json at root (should be in .claude-plugin/)${NC}"
        structure_errors=$((structure_errors + 1))
    fi

    # Check for nested skills
    if find "$plugin_dir/skills" -path "*/skills/*/skills/*" -name "SKILL.md" 2>/dev/null | grep -q .; then
        echo -e "${RED}  $plugin_name: Nested skills detected${NC}"
        structure_errors=$((structure_errors + 1))
    fi
done < <(find "$SCAN_DIR" -path "*/.claude-plugin/plugin.json" -type f 2>/dev/null)

if [[ $structure_errors -eq 0 ]]; then
    echo -e "${GREEN}  All structures valid${NC}"
else
    echo -e "${RED}  $structure_errors structure errors${NC}"
    ERRORS=$((ERRORS + structure_errors))
fi
echo ""

# 6. Script Executability
echo -e "${BLUE}[6/6] Checking script permissions...${NC}"
script_warnings=0
while IFS= read -r script; do
    if [[ ! -x "$script" ]]; then
        echo -e "${YELLOW}  Not executable: $script${NC}"
        script_warnings=$((script_warnings + 1))
    fi
done < <(find "$SCAN_DIR" -name "*.sh" -type f 2>/dev/null)

if [[ $script_warnings -eq 0 ]]; then
    echo -e "${GREEN}  All scripts executable${NC}"
else
    echo -e "${YELLOW}  $script_warnings non-executable scripts${NC}"
    WARNINGS=$((WARNINGS + script_warnings))
fi
echo ""

# Summary
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}VALIDATION SUMMARY${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""

# Count totals
plugin_count=$(find "$SCAN_DIR" -path "*/.claude-plugin/plugin.json" -type f 2>/dev/null | wc -l)
skill_count=$(find "$SCAN_DIR" -name "SKILL.md" -type f 2>/dev/null | wc -l)
command_count=$(find "$SCAN_DIR" -path "*/commands/*.md" -type f 2>/dev/null | wc -l)
agent_count=$(find "$SCAN_DIR" -path "*/agents/*.md" -type f 2>/dev/null | wc -l)

echo "Plugins: $plugin_count"
echo "Skills: $skill_count"
echo "Commands: $command_count"
echo "Agents: $agent_count"
echo ""

if [[ $ERRORS -eq 0 ]] && [[ $WARNINGS -eq 0 ]]; then
    echo -e "${GREEN}ALL CHECKS PASSED${NC}"
    echo -e "${GREEN}Safe to commit and deploy.${NC}"
    exit 0
elif [[ $ERRORS -eq 0 ]]; then
    echo -e "${YELLOW}PASSED WITH $WARNINGS WARNING(S)${NC}"
    echo "Review warnings above before proceeding."
    exit 0
else
    echo -e "${RED}FAILED WITH $ERRORS ERROR(S) AND $WARNINGS WARNING(S)${NC}"
    echo "Fix errors above before proceeding."
    exit 1
fi
