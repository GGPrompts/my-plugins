#!/bin/bash
#
# audit-full.sh - Run complete audit suite
# Runs all individual audits and generates summary report
#

set -uo pipefail

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

# Output directory for logs (in target dir if writable, else temp)
if [[ -w "$TARGET_DIR" ]]; then
    LOG_DIR="$TARGET_DIR/.audit-logs"
else
    LOG_DIR="/tmp/plugin-audit-logs"
fi
mkdir -p "$LOG_DIR"

# Timestamp
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}   PLUGIN FULL AUDIT SUITE${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""
echo "Target: $TARGET_DIR"
echo "Logs: $LOG_DIR"
echo "Timestamp: $TIMESTAMP"
echo ""

# Make all audit scripts executable
chmod +x "$SCRIPT_DIR"/audit-*.sh 2>/dev/null || true

# Track results
declare -A results

# Run each audit
run_audit() {
    local name="$1"
    local script="$2"
    local target="${3:-$TARGET_DIR}"
    local log_file="$LOG_DIR/${name}-${TIMESTAMP}.log"

    echo -e "${BLUE}Running: $name...${NC}"

    if [[ -f "$SCRIPT_DIR/$script" ]]; then
        if "$SCRIPT_DIR/$script" "$target" > "$log_file" 2>&1; then
            results["$name"]="PASS"
            echo -e "${GREEN}  PASSED${NC} (see $log_file)"
        else
            results["$name"]="FAIL"
            echo -e "${RED}  FAILED${NC} (see $log_file)"
        fi
    else
        results["$name"]="SKIP"
        echo -e "${YELLOW}  SKIPPED (script not found)${NC}"
    fi
}

echo ""
echo "Running audits..."
echo ""

# Run all audits (pass target directory to each)
run_audit "marketplace" "audit-marketplace.sh" "$TARGET_DIR"
run_audit "manifests" "audit-manifests.sh" "$TARGET_DIR"
run_audit "directories" "audit-directories.sh" "$TARGET_DIR"
run_audit "skills" "audit-skills.sh" "$TARGET_DIR"
run_audit "commands" "audit-commands.sh" "$TARGET_DIR"
run_audit "agents" "audit-agents.sh" "$TARGET_DIR"

echo ""

# Generate summary report
REPORT_FILE="$LOG_DIR/audit-report-${TIMESTAMP}.md"

cat > "$REPORT_FILE" << EOF
# Audit Report

**Generated:** $(date)
**Project:** $PROJECT_ROOT

## Summary

| Audit | Status |
|-------|--------|
EOF

# Add results to report
pass_count=0
fail_count=0
for audit in marketplace manifests directories skills commands agents; do
    status="${results[$audit]:-SKIP}"
    if [[ "$status" == "PASS" ]]; then
        echo "| $audit | :white_check_mark: PASS |" >> "$REPORT_FILE"
        ((pass_count++))
    elif [[ "$status" == "FAIL" ]]; then
        echo "| $audit | :x: FAIL |" >> "$REPORT_FILE"
        ((fail_count++))
    else
        echo "| $audit | :warning: SKIP |" >> "$REPORT_FILE"
    fi
done

cat >> "$REPORT_FILE" << EOF

## Detailed Results

EOF

# Append individual log summaries
for audit in marketplace manifests directories skills commands agents; do
    log_file="$LOG_DIR/${audit}-${TIMESTAMP}.log"
    if [[ -f "$log_file" ]]; then
        echo "### ${audit^}" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo '```' >> "$REPORT_FILE"
        # Extract summary section (last 20 lines typically contain summary)
        tail -30 "$log_file" | grep -E "(SUMMARY|Total|Compliant|Violations|Warnings|Rate)" >> "$REPORT_FILE" 2>/dev/null || echo "No summary available" >> "$REPORT_FILE"
        echo '```' >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
done

# Print summary
echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}AUDIT SUMMARY${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""

for audit in marketplace manifests directories skills commands agents; do
    status="${results[$audit]:-SKIP}"
    case $status in
        PASS) echo -e "  ${GREEN}$audit: PASS${NC}" ;;
        FAIL) echo -e "  ${RED}$audit: FAIL${NC}" ;;
        SKIP) echo -e "  ${YELLOW}$audit: SKIP${NC}" ;;
    esac
done

echo ""
echo -e "Passed: ${GREEN}$pass_count${NC}"
echo -e "Failed: ${RED}$fail_count${NC}"
echo ""
echo "Full report: $REPORT_FILE"
echo "Individual logs: $LOG_DIR/*-${TIMESTAMP}.log"
echo ""

# Cleanup old logs (keep last 10)
find "$LOG_DIR" -name "*.log" -type f | sort -r | tail -n +61 | xargs rm -f 2>/dev/null || true
find "$LOG_DIR" -name "*.md" -type f | sort -r | tail -n +11 | xargs rm -f 2>/dev/null || true

# Exit with appropriate code
if [[ $fail_count -eq 0 ]]; then
    echo -e "${GREEN}All audits passed!${NC}"
    exit 0
else
    echo -e "${RED}$fail_count audit(s) failed. Review logs for details.${NC}"
    exit 1
fi
