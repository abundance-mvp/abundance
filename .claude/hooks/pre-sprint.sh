#!/bin/bash
# Pre-Sprint Validation Hook
# Runs before ios-sprint-executor starts a sprint

set -euo pipefail

SPRINT_NUMBER="$1"

echo "🔍 Validating environment for Sprint $SPRINT_NUMBER..."

# Check if sprint plan exists
SPRINT_PLAN="docs/roadmap/SPRINT-PLAN-00${SPRINT_NUMBER}.md"
if [ ! -f "$SPRINT_PLAN" ]; then
  echo "❌ ERROR: Sprint plan not found: $SPRINT_PLAN"
  exit 1
fi
echo "✅ Sprint plan found: $SPRINT_PLAN"

# Check if required tools installed
REQUIRED_TOOLS=("swift" "swiftlint" "npm" "firebase" "gh")
for tool in "${REQUIRED_TOOLS[@]}"; do
  if ! command -v "$tool" &> /dev/null; then
    echo "❌ ERROR: Required tool not installed: $tool"
    echo "   Run: scripts/validate-environment.sh"
    exit 1
  fi
done
echo "✅ All required tools installed"

# Check if Firebase project configured
if [ ! -f ".firebaserc" ]; then
  echo "❌ ERROR: Firebase project not configured"
  echo "   Run: firebase init"
  exit 1
fi
echo "✅ Firebase project configured"

# Check if Claude Code plugins installed
if [ ! -d ".claude/plugins/code-review" ]; then
  echo "⚠️  WARNING: code-review plugin not installed"
  echo "   Run: scripts/install-claude-plugins.sh"
fi

echo "✅ Pre-sprint validation complete"
