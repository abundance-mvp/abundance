#!/bin/bash

# Sync documentation from spec-kit to abundance-mvp
# Usage: ./.claude/scripts/sync-docs.sh [commit-message]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SPEC_KIT_DOCS="$HOME/code/spec-kit/docs"
LOCAL_DOCS="docs"
COMMIT_MSG="${1:-docs: sync from spec-kit}"

echo -e "${YELLOW}🔄 Syncing docs from spec-kit...${NC}"

# Verify spec-kit docs exist
if [ ! -d "$SPEC_KIT_DOCS" ]; then
    echo -e "${RED}❌ Error: spec-kit docs not found at $SPEC_KIT_DOCS${NC}"
    exit 1
fi

# Verify we're in the right directory
if [ ! -f "Package.swift" ]; then
    echo -e "${RED}❌ Error: Must run from abundance-mvp root directory${NC}"
    exit 1
fi

# Check for uncommitted changes (excluding docs/)
if git diff --quiet --exit-code -- . ':!docs' && git diff --cached --quiet --exit-code -- . ':!docs'; then
    echo -e "${GREEN}✓ Working tree clean (excluding docs/)${NC}"
else
    echo -e "${RED}❌ Error: You have uncommitted changes. Please commit or stash them first.${NC}"
    git status --short -- . ':!docs'
    exit 1
fi

# Step 1: Remove symlink if it exists
echo -e "${YELLOW}📂 Removing symlink...${NC}"
if [ -L "$LOCAL_DOCS" ]; then
    unlink "$LOCAL_DOCS"
    echo -e "${GREEN}✓ Symlink removed${NC}"
elif [ -d "$LOCAL_DOCS" ]; then
    echo -e "${YELLOW}⚠ docs/ is already a directory (not a symlink)${NC}"
else
    echo -e "${YELLOW}⚠ docs/ doesn't exist${NC}"
fi

# Step 2: Copy files from spec-kit
echo -e "${YELLOW}📋 Copying files from spec-kit...${NC}"
cp -R "$SPEC_KIT_DOCS" "$LOCAL_DOCS"
echo -e "${GREEN}✓ Files copied${NC}"

# Step 3: Check for changes
if git diff --quiet --exit-code docs/ && git diff --cached --quiet --exit-code docs/; then
    echo -e "${YELLOW}ℹ No changes detected - docs are already up to date${NC}"

    # Restore symlink
    ln -sf "$SPEC_KIT_DOCS" "$LOCAL_DOCS"
    echo -e "${GREEN}✓ Symlink restored${NC}"
    echo -e "${GREEN}✅ Sync complete (no changes)${NC}"
    exit 0
fi

# Step 4: Show changes
echo -e "${YELLOW}📊 Changes detected:${NC}"
git status --short docs/ | head -20

# Step 5: Stage changes
echo -e "${YELLOW}➕ Staging changes...${NC}"
git add docs/
echo -e "${GREEN}✓ Changes staged${NC}"

# Step 6: Commit changes
echo -e "${YELLOW}💾 Committing changes...${NC}"
git commit -m "$COMMIT_MSG

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
echo -e "${GREEN}✓ Changes committed${NC}"

# Step 7: Push to remote
echo -e "${YELLOW}⬆️  Pushing to remote...${NC}"
git push origin main
echo -e "${GREEN}✓ Pushed to remote${NC}"

# Step 8: Restore symlink
echo -e "${YELLOW}🔗 Restoring symlink...${NC}"
/bin/rm -rf "$LOCAL_DOCS"
ln -sf "$SPEC_KIT_DOCS" "$LOCAL_DOCS"
echo -e "${GREEN}✓ Symlink restored${NC}"

# Final status
echo ""
echo -e "${GREEN}✅ Sync complete!${NC}"
echo ""
echo -e "Local:  ${YELLOW}docs/ → $SPEC_KIT_DOCS${NC}"
echo -e "Remote: ${GREEN}Updated with latest spec-kit docs${NC}"
