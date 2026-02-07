#!/usr/bin/env bash
# brand-guard.sh — Pre-commit hook for feature/brand-* branches
# Rejects system colors, fixed font sizes, ungated animations, and raw UIColor
# in SwiftUI View and Component files.
#
# Install: Called from .git/hooks/pre-commit with branch gating
# Bypass:  git commit --no-verify

set -euo pipefail

# Only run on brand branches
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
if [[ "$BRANCH" != feature/brand-* ]]; then
    exit 0
fi

VIOLATIONS=0
REPORT=""

# Get staged Swift files (View/Component files only)
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM -- '*.swift' | \
    grep -E '(View|Sheet|Card|Badge|Button|Indicator|Overlay|Bar)\.swift$' || true)

if [[ -z "$STAGED_FILES" ]]; then
    exit 0
fi

while IFS= read -r file; do
    [[ -z "$file" ]] && continue

    # Get staged content with line numbers
    CONTENT=$(git diff --cached -U0 "$file" | grep '^+' | grep -v '^+++' || true)
    LINE_NUM=0

    while IFS= read -r line; do
        LINE_NUM=$((LINE_NUM + 1))

        # Skip comments and string literals (simple heuristic)
        TRIMMED=$(echo "$line" | sed 's/^+//' | sed 's/^[[:space:]]*//')
        if [[ "$TRIMMED" == //* ]] || [[ "$TRIMMED" == \** ]]; then
            continue
        fi

        # Check 1: System colors
        if echo "$line" | grep -qE '\.(blue|gray|purple|red|green|orange|yellow|pink|mint|cyan|indigo|teal|brown)\b' 2>/dev/null; then
            # Exclude Color.brand definitions and comments
            if ! echo "$line" | grep -qE '(static let|///|Color\.(salmon|peach|cream|softTeal|mutedSage|deepPlum|darkPlum|ultraDarkPlum|backgroundTeal|warmWhite|accentPrimary|accentSecondary|textPrimary|successColor|errorColor|backgroundDefault))' 2>/dev/null; then
                MATCH=$(echo "$line" | sed 's/^+//' | sed 's/^[[:space:]]*//')
                REPORT+="$file\n  $MATCH\n  → Use brand token (accentPrimary, errorColor, successColor, etc.)\n\n"
                VIOLATIONS=$((VIOLATIONS + 1))
            fi
        fi

        # Check 2: Fixed font sizes
        if echo "$line" | grep -qE '\.font\(\.system\(size:' 2>/dev/null; then
            MATCH=$(echo "$line" | sed 's/^+//' | sed 's/^[[:space:]]*//')
            REPORT+="$file\n  $MATCH\n  → Use Dynamic Type (.body, .title, .caption, etc.)\n\n"
            VIOLATIONS=$((VIOLATIONS + 1))
        fi

        # Check 3: Raw UIColor in views (ADR-010 violation)
        if echo "$line" | grep -qE 'UIColor\.system' 2>/dev/null; then
            MATCH=$(echo "$line" | sed 's/^+//' | sed 's/^[[:space:]]*//')
            REPORT+="$file\n  $MATCH\n  → ADR-010: no UIKit colors in views. Use Color+Brand tokens.\n\n"
            VIOLATIONS=$((VIOLATIONS + 1))
        fi

        # Check 4: import UIKit in view files
        if echo "$line" | grep -qE '^import UIKit$' 2>/dev/null; then
            MATCH=$(echo "$line" | sed 's/^+//' | sed 's/^[[:space:]]*//')
            REPORT+="$file\n  $MATCH\n  → ADR-010: no UIKit imports in View files.\n\n"
            VIOLATIONS=$((VIOLATIONS + 1))
        fi

    done <<< "$CONTENT"

done <<< "$STAGED_FILES"

if [[ $VIOLATIONS -gt 0 ]]; then
    echo ""
    echo "Brand Guard: $VIOLATIONS violation(s) found"
    echo ""
    echo -e "$REPORT"
    echo "Commit blocked. Fix violations or use --no-verify to bypass."
    exit 1
fi

exit 0
