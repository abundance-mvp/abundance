# DEVELOPMENT-READINESS-CHECKLIST-001

## Purpose

Complete onboarding checklist for developers (human or AI agents) before starting Sprint 1.

**Target Time**: 30-60 minutes (for human setup)
**Last Updated**: 2025-11-12

---

## Environment Setup

### macOS Development Machine
- [ ] macOS 14.0+ (Sonoma or later)
- [ ] Xcode 16.0+ installed from Mac App Store
- [ ] Command Line Tools: `xcode-select --install`
- [ ] Homebrew installed: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

---

### iOS Development Tools

- [ ] **Swift 6.0+** verified: `swift --version`
  - Expected: `Swift version 6.0` or higher
- [ ] **SwiftLint** installed: `brew install swiftlint`
  - Verify: `swiftlint version`
  - Expected: `0.62.2` or higher
- [ ] **Sourcery** installed: `brew install sourcery`
  - Verify: `sourcery --version`
  - Expected: `2.3.0` or higher
- [ ] **iOS 26 Simulator** installed in Xcode
  - Open Xcode → Settings → Platforms → Download iOS 26 Simulator

---

### Backend Development Tools

- [ ] **Node.js 20+** installed: `brew install node@20`
  - Verify: `node --version`
  - Expected: `v20.x.x` or higher
- [ ] **npm 10+** verified: `npm --version`
  - Expected: `10.x.x` or higher
- [ ] **Firebase CLI** installed: `npm install -g firebase-tools`
  - Verify: `firebase --version`
  - Expected: `13.0.0` or higher
- [ ] **Firebase logged in**: `firebase login`
  - Expected: Browser opens, successful authentication

---

### AI Pipeline Tools

- [ ] **Python 3.11+** installed (for Jupyter notebooks): `brew install python@3.11`
  - Verify: `python3 --version`
  - Expected: `3.11.x` or higher
- [ ] **Jupyter** installed: `pip3 install jupyter`
  - Verify: `jupyter --version`
- [ ] **Google Cloud SDK** installed: `brew install google-cloud-sdk`
  - Verify: `gcloud --version`
  - Expected: Latest version
- [ ] **gcloud authenticated**: `gcloud auth login`
  - Expected: Browser opens, successful authentication

---

### Git & Version Control

- [ ] **Git 2.40+** installed: `brew install git`
  - Verify: `git --version`
  - Expected: `2.40.x` or higher
- [ ] **GitHub CLI** installed: `brew install gh`
  - Verify: `gh --version`
  - Expected: `2.60.0` or higher
- [ ] **GitHub authenticated**: `gh auth login`
  - Expected: Successful authentication with repo access
- [ ] **Git worktree support** verified: `git worktree list`
  - Expected: Command runs without error (even if no worktrees yet)

---

### Claude Code (Recommended)

- [ ] **Claude Code** accessible (web or CLI)
- [ ] **Superpowers plugin** installed from marketplace
  - Visit: https://claude.ai/marketplace
  - Search: "superpowers"
  - Click: Install
- [ ] **Project skills** loaded: `.claude/skills/` directory exists
  - Verify: `ls .claude/skills/`
  - Expected: `ios-sprint-executor`, `verified-stage-development`, `apple-docs-fetcher`

---

## Project Setup

### Clone Repository

- [ ] Repository cloned to local machine
  ```bash
  git clone <repo-url>
  cd spec-kit
  ```
- [ ] **Main branch** checked out: `git checkout main`
- [ ] **All commits** pulled: `git pull origin main`
- [ ] **Git status** clean: `git status`
  - Expected: `nothing to commit, working tree clean`

---

### Load Context Map

- [ ] **Context map** read: `cat docs/context-map.json`
- [ ] **Stage 5.2 status** verified:
  ```bash
  cat docs/context-map.json | grep -A 5 '"stage-5.2"'
  ```
  - Expected: `"status": "completed"`
- [ ] **Agent prompts** verified (workflow documentation created):
  ```bash
  ls docs/validation/DEVELOPMENT-WORKFLOW-*.md
  ```
  - Expected: 3 files (001, 002, 003)

---

### Verify Scaffolding Files

- [ ] **iOS scaffolding** exists:
  ```bash
  ls docs/tech-stack/Package.swift
  ls docs/tech-stack/.swiftlint.yml
  ls docs/tech-stack/Sourcery.yml
  ```
  - Expected: All 3 files exist

- [ ] **Backend scaffolding** exists:
  ```bash
  ls docs/tech-stack/firebase.json
  ls docs/tech-stack/firestore.rules
  ls docs/tech-stack/storage.rules
  ls docs/tech-stack/functions-package.json
  ```
  - Expected: All 4 files exist

- [ ] **AI Pipeline scaffolding** exists:
  ```bash
  ls docs/tech-stack/ai-provider-adapters.md
  ```
  - Expected: File exists

- [ ] **All scaffolding validated**:
  ```bash
  cat docs/validation/SCAFFOLDING-VALIDATION-REPORT-001.md
  ```
  - Expected: `Production-Ready: 10 (100%)`

---

### Verify Skills

- [ ] **ios-sprint-executor** skill exists:
  ```bash
  ls .claude/skills/ios-sprint-executor/SKILL.md
  ```
  - Expected: File exists

- [ ] **verified-stage-development** skill exists:
  ```bash
  ls .claude/skills/verified-stage-development/
  ```
  - Expected: Directory exists

- [ ] **apple-docs-fetcher** skill exists:
  ```bash
  ls .claude/skills/apple-docs-fetcher/
  ```
  - Expected: Directory exists

- [ ] **Superpowers plugin** accessible:
  - In Claude Code, type `/help`
  - Expected: Superpowers skills listed (test-driven-development, using-git-worktrees, etc.)

---

## Credentials & API Keys

### Firebase Project

- [ ] **Firebase project created** in console: https://console.firebase.google.com
  - Project ID: `abundance-mvp` (or your project ID)
- [ ] **GoogleService-Info.plist** downloaded (for iOS)
  - Location: Project Settings → iOS app → Download config file
- [ ] **Service account key** downloaded (for Backend)
  - Location: Project Settings → Service Accounts → Generate new private key
- [ ] **Environment variable** set:
  ```bash
  export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
  ```
- [ ] **Firebase services** enabled:
  - [x] Authentication (Apple Sign-In)
  - [x] Firestore Database
  - [x] Cloud Storage
  - [x] Cloud Functions

---

### AI Provider API Keys

- [ ] **Google Cloud project** created: https://console.cloud.google.com
- [ ] **APIs enabled** in Google Cloud:
  - [x] Vertex AI API (Gemini)
  - [x] Cloud Vision API (barcode detection)
- [ ] **Anthropic API key** obtained: https://console.anthropic.com
  - Format: `sk-ant-api03-xxx`
- [ ] **SerpAPI key** obtained: https://serpapi.com/manage-api-key
  - Free tier: 100 searches/month
- [ ] **UPCitemdb key** obtained (optional): https://www.upcitemdb.com/api
  - Free tier: 100 lookups/day
- [ ] **API keys stored** in `.env` file:
  ```bash
  cp docs/tech-stack/.env.ai-pipeline.template backend/functions/.env
  # Edit .env and fill in actual keys
  ```

---

### Apple Developer Account

- [ ] **Apple Developer Account** enrolled: https://developer.apple.com
  - Cost: $99/year
- [ ] **App ID registered** in developer portal
  - Bundle ID: `com.abundance.mvp` (or your bundle ID)
- [ ] **Sign in with Apple** capability enabled for App ID
- [ ] **Development certificate** created (if manual signing)
- [ ] **Provisioning profile** downloaded (if manual signing)

---

## Pre-Flight Checks

### iOS Project

- [ ] Navigate to iOS directory:
  ```bash
  cd ios
  ```
- [ ] Copy scaffolding files:
  ```bash
  cp docs/tech-stack/Package.swift .
  cp docs/tech-stack/.swiftlint.yml .
  cp docs/tech-stack/Sourcery.yml .
  ```
- [ ] Generate Xcode project:
  ```bash
  swift package generate-xcodeproj
  ```
  - Expected: `Abundance.xcodeproj` created
- [ ] Open workspace:
  ```bash
  open Abundance.xcworkspace
  ```
  - Expected: Xcode opens successfully
- [ ] **Build succeeds**: Cmd+B in Xcode
  - Expected: "Build Succeeded" message
- [ ] **Tests pass**: Cmd+U in Xcode
  - Expected: Test suite runs (0 tests initially)

---

### Backend Project

- [ ] Navigate to backend:
  ```bash
  cd backend
  ```
- [ ] Copy scaffolding files:
  ```bash
  cp docs/tech-stack/firebase.json .
  cp docs/tech-stack/firestore.rules .
  cp docs/tech-stack/storage.rules .
  mkdir -p functions
  cp docs/tech-stack/functions-package.json functions/package.json
  ```
- [ ] Install dependencies:
  ```bash
  cd functions
  npm install
  ```
  - Expected: Dependencies installed successfully
- [ ] **Start Firebase Emulator**:
  ```bash
  cd ..
  firebase emulators:start
  ```
  - Expected: Emulators running on localhost:4000
- [ ] **Health endpoint works** (in separate terminal):
  ```bash
  curl http://localhost:5001/abundance-mvp/us-central1/health
  ```
  - Expected: `{"status":"ok","timestamp":...}`
- [ ] **Stop emulators**: Ctrl+C

---

### AI Pipeline

- [ ] Navigate to backend functions:
  ```bash
  cd backend/functions
  ```
- [ ] Copy AI templates:
  ```bash
  cp docs/tech-stack/.env.ai-pipeline.template .env
  ```
- [ ] **Fill in API keys** in `.env`:
  ```bash
  nano .env
  # Replace placeholders with actual API keys
  # Save: Ctrl+X, Y, Enter
  ```
- [ ] **Test Gemini connection** (if test script exists):
  ```bash
  npm run test:gemini
  ```
  - Expected: Successful API call (or skip if script not yet created)

---

## Ready to Start

### Final Verification

All checkboxes above completed?

- [ ] **YES** → Proceed to Sprint 1
- [ ] **NO** → Fix missing prerequisites (see Troubleshooting below)

### Start Sprint 1

If all prerequisites complete:

```bash
/ios-sprint-executor sprint-1
```

**Expected**:
- Phase 1: Loads SPRINT-PLAN-001, creates feature branch
- Phase 2: Generates implementation plan via Superpowers
- Gate 1: Human approval prompt
- Phase 3: Executes plan in batches
- Phase 4: Code review
- Phase 5: Creates PR
- Phase 6: Completion banner

---

## Troubleshooting

### "Xcode build fails"

**Symptom**: Build errors in Xcode after opening project

**Fixes**:
1. Run `swift package resolve` to update dependencies
2. Regenerate project: `swift package generate-xcodeproj`
3. Clean build folder: Cmd+Shift+K in Xcode
4. Restart Xcode

---

### "Firebase emulator won't start"

**Symptom**: Emulator startup fails or port conflicts

**Fixes**:
1. Check port conflicts:
   ```bash
   lsof -i :4000  # Firebase Emulator UI
   lsof -i :5001  # Cloud Functions
   lsof -i :8080  # Firestore
   ```
2. Kill existing processes: `kill -9 <PID>`
3. Verify Firebase CLI: `firebase --version` (should be 13.0.0+)
4. Reinitialize: `firebase init` (select Functions, Firestore, Storage)

---

### "API key invalid"

**Symptom**: AI provider returns 401 Unauthorized

**Fixes**:
1. Verify `.env` file loaded:
   ```bash
   cat backend/functions/.env
   echo $ANTHROPIC_API_KEY
   ```
2. Check API key format:
   - Anthropic: `sk-ant-api03-xxx`
   - Google Cloud: Project ID (not API key for Vertex AI)
   - SerpAPI: Long alphanumeric string
3. Verify API key active in provider console
4. Restart development server to reload `.env`

---

### "Git worktree error"

**Symptom**: `git worktree add` fails

**Fixes**:
1. Update Git: `brew upgrade git` (need 2.40+)
2. Check existing worktrees: `git worktree list`
3. Remove stale worktrees: `git worktree prune`
4. Use absolute paths: `git worktree add /Users/you/abundance-sprint-1 -b feature/sprint-1`

---

### "Superpowers plugin not installed"

**Symptom**: `/superpowers:xxx` commands not recognized

**Fixes**:
1. Visit Claude marketplace: https://claude.ai/marketplace
2. Search for "superpowers"
3. Click "Install" button
4. Restart Claude Code (close and reopen session)
5. Verify: Type `/help` → Superpowers skills should be listed

---

### "Sprint plan not found"

**Symptom**: ios-sprint-executor says "Sprint plan not found"

**Fixes**:
1. Verify Stage 5.1 complete:
   ```bash
   cat docs/context-map.json | grep -A 2 '"stage-5.1"'
   ```
   - Expected: `"status": "completed"`
2. Check sprint plan exists:
   ```bash
   ls docs/roadmap/SPRINT-PLAN-001.md
   ```
3. If missing, run Stage 5.1:
   ```bash
   /verified-stage-development stage-5.1
   ```

---

## Next Steps

After completing this checklist:

1. ✅ Run: `/ios-sprint-executor sprint-1`
2. ✅ Follow 7-phase sprint lifecycle (see DEVELOPMENT-WORKFLOW-003)
3. ✅ After Sprint 1 PR merged, run: `/ios-sprint-executor sprint-2`
4. ✅ Repeat for all 8 sprints

---

**Checklist Version**: 1.0
**Last Updated**: 2025-11-12
**Next Review**: After Sprint 1 completion (verify any missing prerequisites)
