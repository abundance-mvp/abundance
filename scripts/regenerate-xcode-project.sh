#!/bin/bash
# regenerate-xcode-project.sh - Clean Xcode Project Regeneration
#
# This script:
# 1. Deletes the existing Xcode project
# 2. Regenerates clean project using XcodeGen
#
# Usage: ./scripts/regenerate-xcode-project.sh [--yes]

set -e

AUTO_YES=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --yes|-y)
            AUTO_YES=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--yes]"
            exit 1
            ;;
    esac
done

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🔨 Regenerating Xcode Project"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check XcodeGen is installed
if ! command -v xcodegen &> /dev/null; then
    echo "❌ XcodeGen not found. Install with: brew install xcodegen"
    exit 1
fi

# Confirmation prompt
if [ "$AUTO_YES" = false ]; then
    echo "⚠️  This will DELETE and regenerate Abundance.xcodeproj"
    read -p "Continue? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
fi

# Delete and regenerate
echo ""
echo "🗑️  Removing old Xcode project..."
trash Abundance.xcodeproj 2>/dev/null || rm -rf Abundance.xcodeproj

echo "🔧 Generating new Xcode project..."
xcodegen generate --spec project.yml

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Xcode project regenerated!"
echo ""
echo "📁 Location: $PROJECT_ROOT/Abundance.xcodeproj"
echo ""
echo "Next steps:"
echo "  open Abundance.xcodeproj"
echo "  # or"
echo "  /project:device-tester build"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
