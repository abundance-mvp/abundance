#!/bin/bash
# Setup Claude Code Hooks
# Installs and enables Claude Code hooks

set -euo pipefail

echo "🪝 Setting up Claude Code hooks..."

# Hook directory
HOOK_DIR=".claude/hooks"

# Make all hooks executable
chmod +x "$HOOK_DIR"/*.sh
chmod +x "$HOOK_DIR"/*.py

echo "✅ Made hooks executable"

# Test hooks
echo "🧪 Testing hooks..."

# Test pre-sprint hook
if "$HOOK_DIR/pre-sprint.sh" 1 &>/dev/null; then
  echo "✅ pre-sprint.sh: OK"
else
  echo "⚠️  pre-sprint.sh: FAILED (may require sprint plan)"
fi

# Test bash command validator
if "$HOOK_DIR/bash_command_validator.py" "echo hello" &>/dev/null; then
  echo "✅ bash_command_validator.py: OK"
else
  echo "❌ bash_command_validator.py: FAILED"
fi

echo "✅ Claude Code hooks setup complete"
