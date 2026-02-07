#!/bin/bash
# Setup git hooks for the abundance-mvp project
#
# This script installs Claude Code hooks into .git/hooks/
# Run from project root: ./scripts/setup-hooks.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
HOOKS_SOURCE="$PROJECT_ROOT/.claude/hooks"
HOOKS_DEST="$PROJECT_ROOT/.git/hooks"

echo "Setting up git hooks..."

# Ensure .git/hooks exists
mkdir -p "$HOOKS_DEST"

# Install pre-commit hook
if [[ -f "$HOOKS_SOURCE/pre-commit" ]]; then
    cp "$HOOKS_SOURCE/pre-commit" "$HOOKS_DEST/pre-commit"
    chmod +x "$HOOKS_DEST/pre-commit"
    echo "  ✅ Installed pre-commit hook"
fi

# Install pre-push hook
if [[ -f "$HOOKS_SOURCE/pre-push" ]]; then
    cp "$HOOKS_SOURCE/pre-push" "$HOOKS_DEST/pre-push"
    chmod +x "$HOOKS_DEST/pre-push"
    echo "  ✅ Installed pre-push hook"
fi

echo ""
echo "Git hooks installed successfully!"
echo ""
echo "Hooks will:"
echo "  • pre-commit: Brand guard (feature/brand-* only) + doc link validation"
echo "  • pre-push: Full doc validation before push to main"
