#!/bin/bash
# Setup Git Hooks
# Installs pre-commit and pre-push hooks

set -euo pipefail

echo "🪝 Setting up Git hooks..."

# Pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Pre-commit hook: Run linters before commit

set -e

echo "🔍 Running pre-commit checks..."

# SwiftLint (if iOS files changed)
if git diff --cached --name-only | grep -q "\.swift$"; then
  echo "Running SwiftLint..."
  cd ios && swiftlint lint --strict
fi

# ESLint (if TypeScript files changed)
if git diff --cached --name-only | grep -q "\.ts$"; then
  echo "Running ESLint..."
  cd backend/functions && npm run lint
fi

echo "✅ Pre-commit checks passed"
EOF

chmod +x .git/hooks/pre-commit
echo "✅ Installed: pre-commit hook"

# Pre-push hook
cat > .git/hooks/pre-push << 'EOF'
#!/bin/bash
# Pre-push hook: Run tests before push

set -e

echo "🔍 Running pre-push checks..."

# iOS tests (if iOS files changed)
if git diff --name-only origin/main...HEAD | grep -q "\.swift$"; then
  echo "Running iOS tests..."
  cd ios && swift test
fi

# Backend tests (if backend files changed)
if git diff --name-only origin/main...HEAD | grep -q "backend/.*\.ts$"; then
  echo "Running backend tests..."
  cd backend/functions && npm test
fi

echo "✅ Pre-push checks passed"
EOF

chmod +x .git/hooks/pre-push
echo "✅ Installed: pre-push hook"

echo "✅ Git hooks setup complete"
