#!/bin/bash
# UserPromptSubmit hook that enforces skill evaluation before implementation
#
# Based on: https://github.com/spences10/svelte-claude-skills
# Research shows forced-eval achieves 100% activation vs 20% for simple reminders

cat <<'EOF'
INSTRUCTION: Before implementing, follow this sequence:

1. EVALUATE: Check available skills against this task. Note any that are relevant.
2. ACTIVATE: Call Skill(name) for each relevant skill NOW - do not skip this step.
3. AGENTS: If task benefits from parallel work, use Task(subagent_type: "agent-name").
4. IMPLEMENT: Only proceed after activation complete.

Skipping activation defeats the purpose of evaluation.
EOF
