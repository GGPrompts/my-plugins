#!/bin/bash
#
# audit-skills.sh - Validate skill definitions
# Checks SKILL.md frontmatter, structure, and quality
# Pattern: skills/<name>/SKILL.md with optional references/
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
echo -e "${BLUE}SKILLS VALIDATION${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Initialize counters
total_plugins=0
plugins_with_skills=0
total_skills=0
compliant_skills=0
non_compliant_skills=0

# Track issues
declare -a skill_violations=()
declare -a skill_warnings=()

# Quality metrics
total_desc_length=0
skills_with_refs=0

# Process each plugin
while IFS= read -r plugin_json; do
    plugin_dir=$(dirname "$(dirname "$plugin_json")")
    plugin_name=$(basename "$plugin_dir")

    ((total_plugins++))

    # Check if plugin has skills directory
    if [[ ! -d "$plugin_dir/skills" ]]; then
        continue
    fi

    ((plugins_with_skills++))

    echo "---"
    echo -e "Plugin: ${BLUE}$plugin_name${NC}"
    echo "Skills: $plugin_dir/skills"

    # Find all SKILL.md files
    skill_files=$(find "$plugin_dir/skills" -name "SKILL.md" -type f 2>/dev/null | sort)

    if [[ -z "$skill_files" ]]; then
        echo -e "${YELLOW}  No SKILL.md files found${NC}"
        skill_warnings+=("$plugin_name: skills/ exists but no SKILL.md")
        continue
    fi

    # Check each skill
    while IFS= read -r skill_file; do
        skill_dir=$(dirname "$skill_file")
        skill_name=$(basename "$skill_dir")
        ((total_skills++))

        echo ""
        echo -e "  Skill: ${BLUE}$skill_name${NC}"

        has_violation=false
        has_warning=false

        # Check for frontmatter
        if ! head -1 "$skill_file" | grep -q "^---$"; then
            echo -e "${RED}    Missing frontmatter delimiters${NC}"
            skill_violations+=("$plugin_name/$skill_name: Missing frontmatter")
            has_violation=true
            ((non_compliant_skills++))
            continue
        fi

        # Extract frontmatter
        frontmatter=$(awk '/^---$/{f++;next}f==1' "$skill_file")

        # Check for name field (REQUIRED)
        if echo "$frontmatter" | grep -q "^name:"; then
            name_val=$(echo "$frontmatter" | grep "^name:" | cut -d: -f2- | sed 's/^ *//;s/ *$//')
            echo -e "${GREEN}    name: $name_val${NC}"
        else
            echo -e "${RED}    Missing 'name' in frontmatter${NC}"
            skill_violations+=("$plugin_name/$skill_name: Missing name")
            has_violation=true
        fi

        # Check for description field (REQUIRED)
        if echo "$frontmatter" | grep -q "^description:"; then
            # Handle multi-line descriptions
            description=$(echo "$frontmatter" | awk '/^description:/{f=1;gsub(/^description: */,"");print;next}f&&/^[a-z-]+:/{f=0}f{print}' | tr '\n' ' ' | sed 's/^ *//;s/ *$//')
            desc_length=${#description}
            total_desc_length=$((total_desc_length + desc_length))

            if [[ $desc_length -lt 20 ]]; then
                echo -e "${YELLOW}    Description too short ($desc_length chars)${NC}"
                skill_warnings+=("$plugin_name/$skill_name: Description too short")
                has_warning=true
            elif [[ $desc_length -gt 400 ]]; then
                echo -e "${YELLOW}    Description too long ($desc_length chars, max 400)${NC}"
                skill_warnings+=("$plugin_name/$skill_name: Description too long")
                has_warning=true
            else
                echo -e "${GREEN}    description: $desc_length chars${NC}"
            fi

            # Check for action verbs in description
            if echo "$description" | grep -qiE "create|analyze|generate|build|debug|optimize|validate|test|deploy|fix|review|design"; then
                echo -e "${GREEN}    Has action verbs${NC}"
            else
                echo -e "${YELLOW}    Consider adding action verbs${NC}"
            fi

            # Check for trigger guidance
            if echo "$description" | grep -qiE "use this|when|for|trigger"; then
                echo -e "${GREEN}    Has trigger guidance${NC}"
            fi
        else
            echo -e "${RED}    Missing 'description' in frontmatter${NC}"
            skill_violations+=("$plugin_name/$skill_name: Missing description")
            has_violation=true
        fi

        # Check for user-invocable field
        if echo "$frontmatter" | grep -q "^user-invocable:"; then
            invocable=$(echo "$frontmatter" | grep "^user-invocable:" | cut -d: -f2- | sed 's/^ *//;s/ *$//')
            echo -e "${GREEN}    user-invocable: $invocable${NC}"
        fi

        # Check for model field
        if echo "$frontmatter" | grep -q "^model:"; then
            model_val=$(echo "$frontmatter" | grep "^model:" | cut -d: -f2- | sed 's/^ *//;s/ *$//')
            echo -e "${GREEN}    model: $model_val${NC}"
        fi

        # Check for tools restriction
        if echo "$frontmatter" | grep -q "^tools:"; then
            echo -e "${GREEN}    tools: restricted${NC}"
        fi

        # Check content after frontmatter
        content_after=$(awk '/^---$/{f++;next}f==2' "$skill_file")
        content_lines=$(echo "$content_after" | wc -l)
        content_words=$(echo "$content_after" | wc -w)

        # Check content length
        if [[ $content_lines -lt 10 ]]; then
            echo -e "${YELLOW}    Minimal content ($content_lines lines)${NC}"
            skill_warnings+=("$plugin_name/$skill_name: Minimal content")
            has_warning=true
        elif [[ $content_words -gt 5000 ]]; then
            echo -e "${YELLOW}    Content may be too long ($content_words words, limit 5000)${NC}"
            skill_warnings+=("$plugin_name/$skill_name: Content exceeds 5000 words")
            has_warning=true
        else
            echo -e "${GREEN}    Content: $content_lines lines, ~$content_words words${NC}"
        fi

        # Check for references directory
        if [[ -d "$skill_dir/references" ]]; then
            ref_count=$(find "$skill_dir/references" -type f 2>/dev/null | wc -l)
            echo -e "${GREEN}    references/: $ref_count file(s)${NC}"
            ((skills_with_refs++))

            # Check if references are used in SKILL.md
            if grep -q "references/" "$skill_file"; then
                echo -e "${GREEN}    References are linked${NC}"
            else
                echo -e "${YELLOW}    References exist but not linked in SKILL.md${NC}"
                skill_warnings+=("$plugin_name/$skill_name: Unlinked references")
                has_warning=true
            fi
        elif [[ $content_words -gt 2000 ]]; then
            echo -e "${YELLOW}    Consider using references/ for long content${NC}"
        fi

        # Check for scripts directory
        if [[ -d "$skill_dir/scripts" ]]; then
            script_count=$(find "$skill_dir/scripts" -type f -executable 2>/dev/null | wc -l)
            echo -e "${GREEN}    scripts/: $script_count executable(s)${NC}"
        fi

        # Check for examples directory
        if [[ -d "$skill_dir/examples" ]]; then
            example_count=$(find "$skill_dir/examples" -type f 2>/dev/null | wc -l)
            echo -e "${GREEN}    examples/: $example_count file(s)${NC}"
        fi

        # Tally results
        if ! $has_violation; then
            ((compliant_skills++))
            echo -e "    STATUS: ${GREEN}COMPLIANT${NC}"
        else
            ((non_compliant_skills++))
            echo -e "    STATUS: ${RED}NON-COMPLIANT${NC}"
        fi
    done <<< "$skill_files"

    echo ""
done < <(find "$PROJECT_ROOT/plugins" -path "*/.claude-plugin/plugin.json" -type f 2>/dev/null | sort)

# Summary
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}SKILLS VALIDATION SUMMARY${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo "Total Plugins: $total_plugins"
echo "Plugins with Skills: $plugins_with_skills"
echo "Total Skills: $total_skills"
echo -e "Compliant Skills: ${GREEN}$compliant_skills${NC}"
echo -e "Non-Compliant Skills: ${RED}$non_compliant_skills${NC}"
echo ""

# Quality metrics
if [[ $total_skills -gt 0 ]]; then
    avg_desc=$((total_desc_length / total_skills))
    echo "Quality Metrics:"
    echo "  Average description length: $avg_desc chars"
    echo "  Skills with references: $skills_with_refs"
    echo ""
fi

if [[ ${#skill_violations[@]} -gt 0 ]]; then
    echo -e "${RED}VIOLATIONS (${#skill_violations[@]}):${NC}"
    for violation in "${skill_violations[@]}"; do
        echo -e "  ${RED}$violation${NC}"
    done
    echo ""
fi

if [[ ${#skill_warnings[@]} -gt 0 ]]; then
    echo -e "${YELLOW}WARNINGS (${#skill_warnings[@]}):${NC}"
    for warning in "${skill_warnings[@]}"; do
        echo -e "  ${YELLOW}$warning${NC}"
    done
fi

echo ""
if [[ $total_skills -gt 0 ]]; then
    rate=$(( (compliant_skills * 100) / total_skills ))
    echo "Skill Compliance Rate: $rate%"
else
    echo "No skills found to validate"
fi

# Exit with error if violations found
[[ $non_compliant_skills -eq 0 ]]
