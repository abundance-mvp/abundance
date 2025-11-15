#!/bin/bash
# PR Creation Hook
# Auto-populates PR description with sprint context

set -euo pipefail

BRANCH_NAME=$(git branch --show-current)

# Extract sprint number from branch name (e.g., feature/sprint-2-camera-layer-1)
if [[ $BRANCH_NAME =~ sprint-([0-9]+) ]]; then
  SPRINT_NUMBER="${BASH_REMATCH[1]}"
else
  echo "⚠️  WARNING: Branch name does not contain sprint number"
  echo "   Using default PR template"
  exit 0
fi

echo "🔍 Detected Sprint $SPRINT_NUMBER from branch: $BRANCH_NAME"

# Find sprint plan
SPRINT_PLAN="docs/roadmap/SPRINT-PLAN-00${SPRINT_NUMBER}.md"
if [ ! -f "$SPRINT_PLAN" ]; then
  echo "⚠️  WARNING: Sprint plan not found: $SPRINT_PLAN"
  exit 0
fi

# Extract sprint theme from plan
SPRINT_THEME=$(grep "^## Theme" "$SPRINT_PLAN" | sed 's/^## Theme: //')

echo "✅ Sprint theme: $SPRINT_THEME"
echo "✅ Auto-populating PR description with sprint context"

# Output PR template path (used by ios-sprint-executor)
echo ".github/PULL_REQUEST_TEMPLATE/sprint.md"
