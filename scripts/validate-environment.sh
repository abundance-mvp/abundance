#!/bin/bash
# Validate Development Environment
# Checks for required tools and credentials

set -euo pipefail

echo "🔍 Validating development environment..."

ERRORS=0

# Check required tools
REQUIRED_TOOLS=(
  "swift:Xcode Command Line Tools"
  "swiftlint:SwiftLint"
  "node:Node.js"
  "npm:NPM"
  "firebase:Firebase CLI"
  "gh:GitHub CLI"
  "git:Git"
)

for entry in "${REQUIRED_TOOLS[@]}"; do
  IFS=':' read -r cmd name <<< "$entry"
  if command -v "$cmd" &> /dev/null; then
    VERSION=$("$cmd" --version 2>&1 | head -n1)
    echo "✅ $name: $VERSION"
  else
    echo "❌ $name: NOT INSTALLED"
    ((ERRORS++))
  fi
done

# Check Xcode version (iOS development)
if command -v xcodebuild &> /dev/null; then
  XCODE_VERSION=$(xcodebuild -version | head -n1)
  echo "✅ Xcode: $XCODE_VERSION"
  if [[ ! $XCODE_VERSION =~ "16." ]]; then
    echo "⚠️  WARNING: Xcode 16+ required for iOS 26 development"
  fi
else
  echo "❌ Xcode: NOT INSTALLED"
  ((ERRORS++))
fi

# Check Firebase project configured
if [ -f ".firebaserc" ]; then
  PROJECT_ID=$(grep -oP '"default":\s*"\K[^"]+' .firebaserc)
  echo "✅ Firebase project: $PROJECT_ID"
else
  echo "⚠️  WARNING: Firebase project not configured"
  echo "   Run: firebase init"
fi

# Check GitHub CLI authenticated
if gh auth status &> /dev/null; then
  echo "✅ GitHub CLI: Authenticated"
else
  echo "⚠️  WARNING: GitHub CLI not authenticated"
  echo "   Run: gh auth login"
fi

# Check for required environment variables
ENV_VARS=("ANTHROPIC_API_KEY" "GOOGLE_API_KEY")
for var in "${ENV_VARS[@]}"; do
  if [ -n "${!var:-}" ]; then
    echo "✅ $var: Set"
  else
    echo "⚠️  WARNING: $var not set"
  fi
done

# Summary
echo ""
if [ $ERRORS -eq 0 ]; then
  echo "✅ Environment validation complete: Ready for development"
  exit 0
else
  echo "❌ Environment validation failed: $ERRORS missing dependencies"
  exit 1
fi
