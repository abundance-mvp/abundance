#!/bin/bash
# Bootstrap Abundance MVP Repository
# Creates and initializes the abundance-mvp repository with CI/CD and automation infrastructure

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCAFFOLD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PARENT_DIR="$(dirname "$SCAFFOLD_DIR")"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Abundance MVP Repository Bootstrap                      ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo ""

# Step 0: Verify we're in the right location
echo -e "${YELLOW}→ Verifying scaffold location...${NC}"
if [ ! -f "$SCAFFOLD_DIR/CHANGELOG.md" ]; then
  echo -e "${RED}❌ ERROR: Not running from abundance-scaffold directory${NC}"
  echo -e "${RED}   Expected CHANGELOG.md at: $SCAFFOLD_DIR/CHANGELOG.md${NC}"
  exit 1
fi
echo -e "${GREEN}✅ Scaffold directory verified: $SCAFFOLD_DIR${NC}"
echo ""

# Interactive Configuration
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Repository Configuration                                 ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo ""

# Prompt for repository name
echo -e "${YELLOW}Enter repository name:${NC}"
read -p "$(echo -e ${GREEN}Repository name [abundance-mvp]: ${NC})" REPO_NAME_INPUT
REPO_NAME="${REPO_NAME_INPUT:-abundance-mvp}"
echo ""

# Prompt for repository description
echo -e "${YELLOW}Enter repository description:${NC}"
read -p "$(echo -e ${GREEN}Description [Abundance MVP: AI-powered product discovery app]: ${NC})" REPO_DESC_INPUT
REPO_DESCRIPTION="${REPO_DESC_INPUT:-Abundance MVP: AI-powered product discovery app}"
echo ""

# Prompt for target directory
DEFAULT_PARENT_DIR="$PARENT_DIR"
echo -e "${YELLOW}Enter target directory for repository:${NC}"
echo -e "${BLUE}  Default: $DEFAULT_PARENT_DIR/$REPO_NAME${NC}"
read -p "$(echo -e ${GREEN}Target directory [$DEFAULT_PARENT_DIR]: ${NC})" TARGET_PARENT_INPUT
TARGET_PARENT="${TARGET_PARENT_INPUT:-$DEFAULT_PARENT_DIR}"

# Expand ~ to home directory if present
TARGET_PARENT="${TARGET_PARENT/#\~/$HOME}"

# Set final target directory
TARGET_DIR="$TARGET_PARENT/$REPO_NAME"
echo ""

# Step 1: Check prerequisites
echo -e "${YELLOW}→ Checking prerequisites...${NC}"

MISSING_TOOLS=0

if ! command -v gh &> /dev/null; then
  echo -e "${RED}❌ GitHub CLI (gh) not installed${NC}"
  echo -e "   Install: brew install gh"
  ((MISSING_TOOLS++))
else
  echo -e "${GREEN}✅ GitHub CLI installed: $(gh --version | head -n1)${NC}"
fi

if ! command -v git &> /dev/null; then
  echo -e "${RED}❌ Git not installed${NC}"
  ((MISSING_TOOLS++))
else
  echo -e "${GREEN}✅ Git installed: $(git --version)${NC}"
fi

if [ $MISSING_TOOLS -gt 0 ]; then
  echo -e "${RED}❌ Missing $MISSING_TOOLS required tool(s). Please install and re-run.${NC}"
  exit 1
fi

# Check if gh is authenticated
if ! gh auth status &> /dev/null; then
  echo -e "${RED}❌ GitHub CLI not authenticated${NC}"
  echo -e "   Run: gh auth login"
  exit 1
else
  echo -e "${GREEN}✅ GitHub CLI authenticated${NC}"
fi

echo ""

# Step 2: Confirm repository creation
echo -e "${YELLOW}→ Repository Configuration:${NC}"
echo -e "   Name: ${GREEN}$REPO_NAME${NC}"
echo -e "   Description: ${GREEN}$REPO_DESCRIPTION${NC}"
echo -e "   Location: ${GREEN}$TARGET_DIR${NC}"
echo -e "   Visibility: ${YELLOW}Private${NC}"
echo ""

read -p "$(echo -e ${YELLOW}Create repository? [y/N]: ${NC})" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "${RED}❌ Aborted by user${NC}"
  exit 0
fi

# Step 3: Check if repository already exists locally
if [ -d "$TARGET_DIR" ]; then
  echo -e "${RED}❌ ERROR: Directory already exists: $TARGET_DIR${NC}"
  echo -e "${YELLOW}   Remove it first: rm -rf $TARGET_DIR${NC}"
  exit 1
fi

# Step 4: Create GitHub repository
echo -e "${YELLOW}→ Creating GitHub repository...${NC}"
# Create parent directory if it doesn't exist
mkdir -p "$TARGET_PARENT"
# Change to target parent directory so --clone puts repo in the right place
cd "$TARGET_PARENT" || exit 1

# Capture output and exit code properly (PIPESTATUS captures exit code before pipe)
gh repo create "$REPO_NAME" \
  --private \
  --description "$REPO_DESCRIPTION" \
  --clone \
  --gitignore Swift \
  --disable-wiki \
  2>&1 | tee /tmp/gh-create.log
GH_EXIT_CODE=${PIPESTATUS[0]}

if [ $GH_EXIT_CODE -eq 0 ]; then
  echo -e "${GREEN}✅ Repository created and cloned${NC}"
else
  echo -e "${RED}❌ Failed to create repository${NC}"
  echo -e "${RED}   Check if repository already exists remotely: gh repo view $REPO_NAME${NC}"
  exit 1
fi
echo ""

# Step 5: Navigate to repository
cd "$TARGET_DIR" || exit 1
echo -e "${YELLOW}→ Working directory: $(pwd)${NC}"
echo ""

# Step 6: Copy scaffold files
echo -e "${YELLOW}→ Copying scaffold files...${NC}"

# Copy regular files
echo -e "   Copying files..."
cp -r "$SCAFFOLD_DIR"/* . 2>/dev/null || true

# Copy hidden directories (.github, .claude)
echo -e "   Copying .github directory..."
if [ -d "$SCAFFOLD_DIR/.github" ]; then
  cp -r "$SCAFFOLD_DIR/.github" .
  echo -e "${GREEN}   ✅ .github/ copied${NC}"
else
  echo -e "${RED}   ❌ .github/ not found in scaffold${NC}"
fi

echo -e "   Copying .claude directory..."
if [ -d "$SCAFFOLD_DIR/.claude" ]; then
  cp -r "$SCAFFOLD_DIR/.claude" .
  echo -e "${GREEN}   ✅ .claude/ copied${NC}"
else
  echo -e "${RED}   ❌ .claude/ not found in scaffold${NC}"
fi

echo -e "${GREEN}✅ Scaffold files copied${NC}"
echo ""

# Step 7: Make scripts executable
echo -e "${YELLOW}→ Making scripts executable...${NC}"
chmod +x scripts/*.sh
echo -e "${GREEN}✅ Scripts are now executable${NC}"
echo ""

# Step 8: Run environment validation
echo -e "${YELLOW}→ Run environment validation?${NC}"
echo -e "   This will check for: Xcode, SwiftLint, Node.js, Firebase CLI, etc."
read -p "$(echo -e ${YELLOW}Validate environment now? [Y/n]: ${NC})" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
  if ./scripts/validate-environment.sh; then
    echo -e "${GREEN}✅ Environment validation passed${NC}"
  else
    echo -e "${RED}⚠️  WARNING: Environment validation failed${NC}"
    echo -e "${YELLOW}   You may need to install missing tools before continuing${NC}"
    echo -e "${YELLOW}   See: docs/tech-stack/LOCAL-DEV-SETUP-001.md${NC}"
    echo ""
    read -p "$(echo -e ${YELLOW}Continue anyway? [y/N]: ${NC})" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo -e "${RED}❌ Aborted. Install missing tools and re-run bootstrap.${NC}"
      exit 1
    fi
  fi
else
  echo -e "${YELLOW}⏭️  Skipping environment validation${NC}"
fi
echo ""

# Step 9: Setup git hooks
echo -e "${YELLOW}→ Setting up git hooks...${NC}"
if ./scripts/setup-git-hooks.sh; then
  echo -e "${GREEN}✅ Git hooks installed${NC}"
else
  echo -e "${RED}❌ Failed to setup git hooks${NC}"
fi
echo ""

# Step 10: Setup Claude Code hooks
echo -e "${YELLOW}→ Setting up Claude Code hooks...${NC}"
if ./scripts/setup-claude-hooks.sh; then
  echo -e "${GREEN}✅ Claude Code hooks configured${NC}"
else
  echo -e "${RED}❌ Failed to setup Claude Code hooks${NC}"
fi
echo ""

# Step 11: Initial commit
echo -e "${YELLOW}→ Creating initial commit...${NC}"
git add .
git commit -m "chore: initialize repository with CI/CD and automation scaffold

- Add GitHub Actions workflows (iOS, backend, AI pipeline, security)
- Add Claude Code automation (hooks, agents, commands)
- Add PR/issue templates
- Add comprehensive documentation (8 tech-stack docs)
- Add setup scripts for developer onboarding
- Initialize CHANGELOG.md

Scaffold from Stage 5.3 completion.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

echo -e "${GREEN}✅ Initial commit created${NC}"
echo ""

# Step 12: Push to remote
echo -e "${YELLOW}→ Pushing to remote...${NC}"
if git push -u origin main; then
  echo -e "${GREEN}✅ Pushed to GitHub${NC}"
else
  echo -e "${RED}❌ Failed to push to remote${NC}"
  exit 1
fi
echo ""

# Step 13: Display manual configuration steps
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Repository Created Successfully!                        ║${NC}"
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo ""
echo -e "${BLUE}Repository URL:${NC}"
REPO_URL=$(gh repo view --json url -q .url)
echo -e "${GREEN}$REPO_URL${NC}"
echo ""

read -p "$(echo -e ${YELLOW}Open repository in browser? [Y/n]: ${NC})" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
  gh repo view --web
fi
echo ""

echo -e "${YELLOW}⚠️  MANUAL CONFIGURATION REQUIRED:${NC}"
echo ""
echo -e "${BLUE}1. Add GitHub Secrets:${NC}"
echo -e "   Navigate to: Settings > Secrets and variables > Actions"
echo -e "   Add the following secrets:"
echo -e "   ${GREEN}• ANTHROPIC_API_KEY${NC} (Claude API key from https://console.anthropic.com/)"
echo -e "   ${GREEN}• GOOGLE_API_KEY${NC} (Gemini API key from https://aistudio.google.com/app/apikey)"
echo -e "   ${GREEN}• FIREBASE_SERVICE_ACCOUNT${NC} (JSON key from Firebase Console)"
echo -e "   ${GREEN}• SLACK_WEBHOOK_URL${NC} (optional: for cost alerts)"
echo ""
echo -e "   Quick command:"
echo -e "   ${YELLOW}gh secret set ANTHROPIC_API_KEY${NC}"
echo -e "   ${YELLOW}gh secret set GOOGLE_API_KEY${NC}"
echo -e "   ${YELLOW}gh secret set FIREBASE_SERVICE_ACCOUNT${NC}"
echo ""

echo -e "${BLUE}2. Enable GitHub Actions:${NC}"
echo -e "   Navigate to: Settings > Actions > General"
echo -e "   ${GREEN}• Allow all actions and reusable workflows${NC}"
echo -e "   ${GREEN}• Read and write permissions${NC}"
echo -e "   ${GREEN}• Allow GitHub Actions to create and approve pull requests${NC}"
echo ""

echo -e "${BLUE}3. Set Branch Protection Rules:${NC}"
echo -e "   Navigate to: Settings > Branches > Add rule"
echo -e "   Branch name pattern: ${GREEN}main${NC}"
echo -e "   ${GREEN}• Require a pull request before merging${NC}"
echo -e "   ${GREEN}• Require 1 approval${NC}"
echo -e "   ${GREEN}• Require status checks: ios-build-check, backend-validation, security-pr-review${NC}"
echo -e "   ${GREEN}• Require conversation resolution${NC}"
echo ""
echo -e "   Or use the API:"
echo -e "   ${YELLOW}See: docs/tech-stack/BRANCH-PROTECTION-RULES-001.md${NC}"
echo ""

echo -e "${BLUE}4. Install Claude Code Plugins:${NC}"
echo -e "   ${GREEN}• Open Claude Code${NC}"
echo -e "   ${GREEN}• Navigate to marketplace${NC}"
echo -e "   ${GREEN}• Install: superpowers, document-skills${NC}"
echo -e "   ${GREEN}• Re-run: ./scripts/install-claude-plugins.sh${NC}"
echo ""

echo -e "${BLUE}5. Initialize Firebase:${NC}"
echo -e "   ${YELLOW}firebase login${NC}"
echo -e "   ${YELLOW}firebase init${NC}"
echo -e "   ${YELLOW}firebase deploy --only firestore:rules --dry-run${NC}"
echo ""

echo -e "${GREEN}📚 Documentation:${NC}"
echo -e "   • Repository Setup: ${BLUE}docs/tech-stack/REPOSITORY-SETUP-CHECKLIST-001.md${NC}"
echo -e "   • Local Dev Setup: ${BLUE}docs/tech-stack/LOCAL-DEV-SETUP-001.md${NC}"
echo -e "   • Branch Protection: ${BLUE}docs/tech-stack/BRANCH-PROTECTION-RULES-001.md${NC}"
echo -e "   • Claude Code Automation: ${BLUE}docs/tech-stack/CLAUDE-CODE-AUTOMATION-001.md${NC}"
echo ""

echo -e "${GREEN}✨ Repository ready for development!${NC}"
echo ""
echo -e "Current directory: ${GREEN}$(pwd)${NC}"
echo ""

# Interactive next steps
echo -e "${YELLOW}What would you like to do next?${NC}"
echo -e "  ${BLUE}1)${NC} Configure GitHub secrets (recommended first)"
echo -e "  ${BLUE}2)${NC} Open repository in browser"
echo -e "  ${BLUE}3)${NC} Open documentation (REPOSITORY-SETUP-CHECKLIST-001.md)"
echo -e "  ${BLUE}4)${NC} Initialize Firebase"
echo -e "  ${BLUE}5)${NC} Open in VS Code"
echo -e "  ${BLUE}6)${NC} Open iOS project in Xcode"
echo -e "  ${BLUE}7)${NC} Exit (continue manually)"
echo ""

while true; do
  read -p "$(echo -e ${YELLOW}Select option [1-7]: ${NC})" choice
  case $choice in
    1)
      echo -e "${BLUE}Configuring GitHub secrets...${NC}"
      echo -e "Run these commands to set secrets:"
      echo ""
      echo -e "  ${YELLOW}gh secret set ANTHROPIC_API_KEY${NC}"
      read -p "Press Enter to run this command..."
      gh secret set ANTHROPIC_API_KEY
      echo ""
      echo -e "  ${YELLOW}gh secret set GOOGLE_API_KEY${NC}"
      read -p "Press Enter to run this command..."
      gh secret set GOOGLE_API_KEY
      echo ""
      echo -e "  ${YELLOW}gh secret set FIREBASE_SERVICE_ACCOUNT${NC}"
      read -p "Press Enter to run this command..."
      gh secret set FIREBASE_SERVICE_ACCOUNT
      echo ""
      echo -e "${GREEN}✅ Secrets configured${NC}"
      ;;
    2)
      gh repo view --web
      ;;
    3)
      if command -v open &> /dev/null; then
        open docs/tech-stack/REPOSITORY-SETUP-CHECKLIST-001.md
      else
        cat docs/tech-stack/REPOSITORY-SETUP-CHECKLIST-001.md | less
      fi
      ;;
    4)
      echo -e "${YELLOW}Initializing Firebase...${NC}"
      if command -v firebase &> /dev/null; then
        firebase login
        firebase init
      else
        echo -e "${RED}❌ Firebase CLI not installed${NC}"
        echo -e "   Install: npm install -g firebase-tools"
      fi
      ;;
    5)
      if command -v code &> /dev/null; then
        code .
        echo -e "${GREEN}✅ Opened in VS Code${NC}"
      else
        echo -e "${RED}❌ VS Code not installed or 'code' command not in PATH${NC}"
      fi
      ;;
    6)
      if [ -f "ios/Package.swift" ]; then
        open ios/Package.swift
        echo -e "${GREEN}✅ Opening iOS project in Xcode${NC}"
      else
        echo -e "${YELLOW}⚠️  iOS project not found yet${NC}"
        echo -e "   You'll need to copy the iOS scaffold from stage-4.1 first"
      fi
      ;;
    7)
      echo -e "${GREEN}✅ Bootstrap complete!${NC}"
      echo -e "Next steps: Follow manual configuration checklist above"
      exit 0
      ;;
    *)
      echo -e "${RED}Invalid option. Please select 1-7.${NC}"
      ;;
  esac
  echo ""
  read -p "$(echo -e ${YELLOW}Perform another action? [Y/n]: ${NC})" -n 1 -r
  echo
  if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo -e "${GREEN}✅ Bootstrap complete!${NC}"
    exit 0
  fi
done
