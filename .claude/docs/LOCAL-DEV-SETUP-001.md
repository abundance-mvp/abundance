# Local Development Setup Guide

**ID**: LOCAL-DEV-SETUP-001
**Created**: 2025-11-14
**Status**: Approved
**Scope**: Developer onboarding for Abundance MVP

## Overview

This guide walks through setting up a local development environment for iOS, backend, and AI pipeline development.

**Time estimate**: 1-2 hours (depending on download speeds)

---

## Prerequisites

### System Requirements

- **macOS**: 14.0+ (Sonoma) for Xcode 16
- **RAM**: 16GB minimum (32GB recommended for iOS Simulator)
- **Storage**: 50GB free (Xcode is ~15GB)
- **Internet**: Stable connection for dependency downloads

---

## Phase 1: Core Development Tools

### 1.1 Install Homebrew

**Check if installed**:
```bash
brew --version
```

**Install if missing**:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Verify**:
```bash
brew --version
# Expected: Homebrew 4.0.0+
```

---

### 1.2 Install Xcode

**Option A: Mac App Store** (recommended)
1. Open App Store
2. Search "Xcode"
3. Click "Get" (15GB download)
4. Wait for installation (15-30 minutes)

**Option B: Direct download**
1. Visit: https://developer.apple.com/download/
2. Download Xcode 16.0+
3. Move to `/Applications/Xcode.app`

**Accept license**:
```bash
sudo xcodebuild -license accept
```

**Install Command Line Tools**:
```bash
xcode-select --install
```

**Verify**:
```bash
xcodebuild -version
# Expected: Xcode 16.0 or later
```

---

### 1.3 Install SwiftLint

**Install via Homebrew**:
```bash
brew install swiftlint
```

**Verify**:
```bash
swiftlint version
# Expected: 0.55.0+
```

---

### 1.4 Install Node.js

**Install via Homebrew**:
```bash
brew install node@20
```

**Verify**:
```bash
node --version  # Expected: v20.10.0+
npm --version   # Expected: 10.2.0+
```

---

### 1.5 Install Python

**Install via Homebrew**:
```bash
brew install python@3.12
```

**Verify**:
```bash
python3 --version  # Expected: 3.12.0+
pip3 --version     # Expected: 23.0+
```

---

### 1.6 Install Firebase CLI

**Install via npm**:
```bash
npm install -g firebase-tools
```

**Verify**:
```bash
firebase --version
# Expected: 13.0.0+
```

**Login**:
```bash
firebase login
```

---

### 1.7 Install GitHub CLI

**Install via Homebrew**:
```bash
brew install gh
```

**Verify**:
```bash
gh --version
# Expected: 2.40.0+
```

**Login**:
```bash
gh auth login
# Select: GitHub.com
# Select: HTTPS
# Select: Login with a web browser
```

---

## Phase 2: Clone Repository

### 2.1 Clone Repo

**Via GitHub CLI**:
```bash
gh repo clone abundance-mvp
cd abundance-mvp
```

**Verify structure**:
```bash
ls -la
# Should see: .github/, .claude/, ios/, backend/, ai-pipeline/, docs/, scripts/
```

---

### 2.2 Run Environment Validation

**Execute validation script**:
```bash
chmod +x scripts/validate-environment.sh
./scripts/validate-environment.sh
```

**Expected output**:
```
✅ Xcode Command Line Tools: Xcode 16.0
✅ SwiftLint: 0.55.0
✅ Node.js: v20.10.0
✅ NPM: 10.2.0
✅ Firebase CLI: 13.0.0
✅ GitHub CLI: 2.40.0
✅ Git: 2.42.0
⚠️  WARNING: ANTHROPIC_API_KEY not set
⚠️  WARNING: GOOGLE_API_KEY not set
```

**Fix warnings** (see Phase 3)

---

## Phase 3: Environment Variables

### 3.1 Create `.env` File

**Location**: Project root

**Contents**:
```bash
# AI Pipeline API Keys
ANTHROPIC_API_KEY=sk-ant-api03-...
GOOGLE_API_KEY=AIzaSy...

# Firebase Configuration (optional for local dev)
FIREBASE_PROJECT_ID=abundance-mvp
FIREBASE_STORAGE_BUCKET=abundance-mvp.appspot.com

# Development Mode
NODE_ENV=development
```

**Sources**:
- Claude API key: https://console.anthropic.com/
- Google API key: https://aistudio.google.com/app/apikey
- Firebase config: `.firebaserc` file

---

### 3.2 Load Environment Variables

**Add to shell profile** (`~/.zshrc` or `~/.bashrc`):
```bash
# Abundance MVP environment
export ANTHROPIC_API_KEY="sk-ant-api03-..."
export GOOGLE_API_KEY="AIzaSy..."
```

**Reload shell**:
```bash
source ~/.zshrc
```

**Verify**:
```bash
echo $ANTHROPIC_API_KEY
# Should print your API key
```

---

## Phase 4: iOS Setup

### 4.1 Install Swift Dependencies

**Navigate to iOS directory**:
```bash
cd ios
```

**Resolve dependencies**:
```bash
swift package resolve
```

**Expected output**:
```
Fetching https://github.com/firebase/firebase-ios-sdk.git
Fetched https://github.com/firebase/firebase-ios-sdk.git (5.23s)
Computing version for https://github.com/firebase/firebase-ios-sdk.git
Computed https://github.com/firebase/firebase-ios-sdk.git at 10.20.0 (0.65s)
```

---

### 4.2 Build iOS Project

**Build via Xcode**:
```bash
open Package.swift
# Xcode opens
# Product > Build (⌘B)
```

**OR build via command line**:
```bash
swift build
```

**Expected output**:
```
Build complete! (15.32s)
```

---

### 4.3 Run iOS Tests

**Via Xcode**:
```
Product > Test (⌘U)
```

**Via command line**:
```bash
swift test
```

**Expected output**:
```
Test Suite 'All tests' passed at 2025-11-14 10:23:45.678
    Executed 12 tests, with 0 failures (0 unexpected) in 2.345 (2.567) seconds
```

---

### 4.4 Configure Firebase for iOS

**Download `GoogleService-Info.plist`**:
1. Visit: https://console.firebase.google.com/project/abundance-mvp
2. iOS app settings > Download `GoogleService-Info.plist`
3. Move to: `ios/Config/GoogleService-Info.plist`

**Verify**:
```bash
ls ios/Config/GoogleService-Info.plist
# Should exist
```

---

## Phase 5: Backend Setup

### 5.1 Install Backend Dependencies

**Navigate to backend directory**:
```bash
cd backend/functions
```

**Install npm packages**:
```bash
npm install
```

**Expected output**:
```
added 347 packages, and audited 348 packages in 8s
```

---

### 5.2 Run Backend Linter

**Execute ESLint**:
```bash
npm run lint
```

**Expected output**:
```
✨ All files passed linting!
```

---

### 5.3 Run Backend Tests

**Execute Jest**:
```bash
npm test
```

**Expected output**:
```
PASS  src/auth/auth.test.ts
PASS  src/analysis/pipeline.test.ts

Test Suites: 2 passed, 2 total
Tests:       15 passed, 15 total
Snapshots:   0 total
Time:        3.456 s
```

---

### 5.4 Start Firebase Emulator

**Start emulator**:
```bash
firebase emulators:start
```

**Expected output**:
```
┌─────────────────────────────────────────────────────────────┐
│ ✔  All emulators ready! It is now safe to connect your app. │
│ i  View Emulator UI at http://127.0.0.1:4000                │
└─────────────────────────────────────────────────────────────┘

┌────────────────┬────────────────┬─────────────────────────────────┐
│ Emulator       │ Host:Port      │ View in Emulator UI             │
├────────────────┼────────────────┼─────────────────────────────────┤
│ Authentication │ 127.0.0.1:9099 │ http://127.0.0.1:4000/auth      │
│ Firestore      │ 127.0.0.1:8080 │ http://127.0.0.1:4000/firestore │
│ Storage        │ 127.0.0.1:9199 │ http://127.0.0.1:4000/storage   │
│ Functions      │ 127.0.0.1:5001 │ http://127.0.0.1:4000/functions │
└────────────────┴────────────────┴─────────────────────────────────┘
```

**Test in browser**: Visit http://127.0.0.1:4000

---

## Phase 6: AI Pipeline Setup

### 6.1 Install Python Dependencies

**Navigate to AI pipeline directory**:
```bash
cd ai-pipeline
```

**Create virtual environment**:
```bash
python3 -m venv venv
source venv/bin/activate
```

**Install packages**:
```bash
pip install -r requirements.txt
```

**Expected output**:
```
Successfully installed anthropic-0.18.0 google-generativeai-0.3.2 ...
```

---

### 6.2 Run AI Pipeline Tests

**Execute pytest**:
```bash
pytest tests/
```

**Expected output**:
```
============================== test session starts ===============================
collected 8 items

tests/test_claude_client.py ........                                      [ 50%]
tests/test_gemini_client.py ........                                      [100%]

=============================== 8 passed in 2.34s ================================
```

---

### 6.3 Run Linter

**Execute Ruff**:
```bash
ruff check .
```

**Expected output**:
```
All checks passed!
```

**Format with Black**:
```bash
black .
```

**Expected output**:
```
All done! ✨ 🍰 ✨
12 files left unchanged.
```

---

## Phase 7: Git Hooks Setup

### 7.1 Install Git Hooks

**Run setup script**:
```bash
chmod +x scripts/setup-git-hooks.sh
./scripts/setup-git-hooks.sh
```

**Expected output**:
```
✅ Installed: pre-commit hook
✅ Installed: pre-push hook
✅ Git hooks setup complete
```

---

### 7.2 Test Pre-Commit Hook

**Create test commit**:
```bash
git checkout -b test/git-hooks
echo "// Bad formatting" >> ios/Sources/App.swift
git add ios/Sources/App.swift
git commit -m "test: verify pre-commit hook"
```

**Expected**: SwiftLint runs and may reject commit if formatting is bad

---

## Phase 8: Claude Code Setup

### 8.1 Install Claude Code Plugins

**Run installation script**:
```bash
chmod +x scripts/install-claude-plugins.sh
./scripts/install-claude-plugins.sh
```

**Expected output**:
```
⚠️  WARNING: code-review plugin not found in cache
   Install via Claude Code marketplace first
⚠️  WARNING: feature-dev plugin not found in cache
   Install via Claude Code marketplace first
```

**Action required**:
1. Open Claude Code
2. Navigate to marketplace
3. Install: `superpowers`, `document-skills`
4. Re-run script

---

### 8.2 Setup Claude Code Hooks

**Run setup script**:
```bash
chmod +x scripts/setup-claude-hooks.sh
./scripts/setup-claude-hooks.sh
```

**Expected output**:
```
✅ Made hooks executable
✅ pre-sprint.sh: OK
✅ bash_command_validator.py: OK
✅ Claude Code hooks setup complete
```

---

### 8.3 Test Claude Code Agents

**Via Claude Code CLI** (if available):
```bash
claude agent run doc-reviewer docs/
```

**OR via Claude Code UI**:
1. Open Claude Code
2. Type: `/validate-docs`
3. Verify agent runs and reports results

---

## Verification Checklist

**Your environment is ready when**:

- [ ] `./scripts/validate-environment.sh` shows all green checkmarks
- [ ] Xcode builds iOS project without errors
- [ ] `swift test` passes all tests
- [ ] `npm test` (backend) passes all tests
- [ ] `pytest tests/` (AI pipeline) passes all tests
- [ ] Firebase emulator starts successfully
- [ ] Git hooks execute on commit/push
- [ ] Claude Code agents respond to commands

**Time checkpoint**: ~1-2 hours from start

---

## Troubleshooting

### Xcode Issues

**Problem**: "Xcode license not accepted"
```bash
sudo xcodebuild -license accept
```

**Problem**: "Command Line Tools not found"
```bash
xcode-select --install
```

**Problem**: "iOS Simulator not found"
- Xcode > Settings > Platforms > iOS > Download

---

### Firebase Issues

**Problem**: "Firebase project not found"
```bash
firebase projects:list
firebase use abundance-mvp
```

**Problem**: "Emulator fails to start"
- Check port 8080 not in use: `lsof -i :8080`
- Kill conflicting process: `kill -9 <PID>`

---

### Python Issues

**Problem**: "Module not found"
```bash
# Ensure virtual environment activated
source venv/bin/activate
pip install -r requirements.txt
```

**Problem**: "Permission denied"
```bash
# Use virtual environment (never sudo pip)
python3 -m venv venv
source venv/bin/activate
```

---

### Git Hooks Issues

**Problem**: "Hooks not executing"
```bash
# Verify executable
ls -la .git/hooks/pre-commit
# Should show: -rwxr-xr-x

# Make executable if not
chmod +x .git/hooks/pre-commit
```

---

## Daily Development Workflow

### Starting Work

```bash
# 1. Pull latest changes
git checkout main
git pull

# 2. Create feature branch
git checkout -b feature/your-feature-name

# 3. Start Firebase emulator (in separate terminal)
firebase emulators:start

# 4. Open Xcode
cd ios && open Package.swift
```

### Before Committing

```bash
# 1. Run linters
cd ios && swiftlint lint
cd backend/functions && npm run lint
cd ai-pipeline && ruff check .

# 2. Run tests
cd ios && swift test
cd backend/functions && npm test
cd ai-pipeline && pytest tests/

# 3. Commit (hooks will run automatically)
git add .
git commit -m "feat: your feature description"
```

### Creating PR

```bash
# 1. Push branch
git push -u origin feature/your-feature-name

# 2. Create PR via GitHub CLI
gh pr create \
  --title "feat: your feature description" \
  --body "Implements PRD-XXX per DESIGN-YYY"

# 3. Wait for CI to pass
gh pr checks

# 4. Request review
gh pr review --approve
```

---

## References

- **REPOSITORY-SETUP-CHECKLIST-001**: Initial repo configuration
- **GITHUB-ACTIONS-ARCHITECTURE-001**: CI/CD workflows
- **CLAUDE-CODE-AUTOMATION-001**: Automation setup
- **BRANCH-PROTECTION-RULES-001**: Git workflow rules

## Changelog

- **2025-11-14**: Initial version with 8-phase setup process
