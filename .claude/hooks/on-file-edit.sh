#!/bin/bash
# File Edit Hook
# Enforces cross-reference comments in code

set -euo pipefail

FILE_PATH="$1"

echo "🔍 Checking file for cross-reference comments: $FILE_PATH"

# Skip non-code files
if [[ ! $FILE_PATH =~ \.(swift|ts|js)$ ]]; then
  exit 0
fi

# Check if file contains ADR references
if ! grep -q "// See ADR-[0-9]\+" "$FILE_PATH" && \
   ! grep -q "// Implements DESIGN-[0-9]\+" "$FILE_PATH"; then
  echo "⚠️  WARNING: File missing ADR/DESIGN cross-references"
  echo "   Add comments like:"
  echo "   // See ADR-010 for architecture rationale"
  echo "   // Implements DESIGN-027 camera UI specification"
fi

# Check if file contains TODO comments
if grep -q "// TODO" "$FILE_PATH"; then
  echo "⚠️  WARNING: File contains TODO comments"
  echo "   Convert TODOs to GitHub issues for tracking"
fi

echo "✅ File edit validation complete"
