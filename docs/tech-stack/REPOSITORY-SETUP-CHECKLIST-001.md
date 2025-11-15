# Repository Setup Checklist

**ID**: REPOSITORY-SETUP-CHECKLIST-001
**Created**: 2025-11-14
**Status**: Approved
**Scope**: Step-by-step GitHub repository configuration for Abundance MVP

## Overview

This checklist guides the initial setup of the Abundance GitHub repository, including branch protection, CI/CD, secrets, and integrations.

---

## Phase 1: Repository Creation

### 1.1 Create Repository

- [ ] **Create repo**: `abundance-mvp` (or chosen name)
- [ ] **Visibility**: Private (until launch)
- [ ] **Initialize with**:
  - [ ] README.md (project overview)
  - [ ] .gitignore (Swift, Node, Python)
  - [ ] LICENSE (if open-source post-launch)
- [ ] **Default branch**: `main` (not `master`)

**Command**:
```bash
gh repo create abundance-mvp \
  --private \
  --description "Abundance MVP: AI-powered product discovery app" \
  --gitignore Swift,Node \
  --clone
```

---

### 1.2 Clone Scaffold

- [ ] **Copy scaffold files**: `abundance-scaffold/` → repo root
  ```bash
  cd abundance-mvp
  cp -r ../spec-kit/abundance-scaffold/* .
  cp -r ../spec-kit/abundance-scaffold/.github .
  cp -r ../spec-kit/abundance-scaffold/.claude .
  ```
- [ ] **Verify structure**:
  ```bash
  ls -la
  # Should see: .github/, .claude/, ios/, backend/, docs/, scripts/
  ```

---

### 1.3 Initial Commit

- [ ] **Stage all files**:
  ```bash
  git add .
  git status  # Verify all scaffold files staged
  ```
- [ ] **Create initial commit**:
  ```bash
  git commit -m "chore: initialize repository with CI/CD and automation scaffold

  - Add GitHub Actions workflows (iOS, backend, security, docs)
  - Add Claude Code automation (hooks, agents, commands)
  - Add PR/issue templates
  - Add setup scripts for developer onboarding
  - Add documentation (tech-stack, ADRs, specs)

  Generated with [Claude Code](https://claude.com/claude-code)

  Co-Authored-By: Claude <noreply@anthropic.com>"
  ```
- [ ] **Push to GitHub**:
  ```bash
  git push -u origin main
  ```

---

## Phase 2: Branch Protection

### 2.1 Protect `main` Branch

- [ ] Navigate to: Settings > Branches > Add rule
- [ ] **Branch name pattern**: `main`
- [ ] **Enable**:
  - [x] Require a pull request before merging
    - [x] Require 1 approval
    - [x] Dismiss stale pull request approvals
    - [x] Require review from Code Owners
  - [x] Require status checks to pass before merging
    - [x] Require branches to be up to date before merging
    - Select: `ios-build-check`, `backend-validation`, `security-pr-review`
  - [x] Require conversation resolution before merging
  - [x] Require linear history
  - [ ] Do not allow bypassing the above settings (enforce for admins)
- [ ] Click **Create**

**Verification**:
```bash
# Try to push directly to main (should fail)
git checkout main
echo "test" >> README.md
git add README.md
git commit -m "test: direct push"
git push
# Expected: Error: Protected branch
```

---

### 2.2 Configure CODEOWNERS

- [ ] **Create file**: `.github/CODEOWNERS`
  ```
  * @yourusername
  /ios/ @yourusername
  /backend/ @yourusername
  /docs/specs/ @yourusername
  /docs/adr/ @yourusername
  ```
- [ ] **Commit and push**:
  ```bash
  git add .github/CODEOWNERS
  git commit -m "chore: add CODEOWNERS for automated review assignment"
  git push
  ```

---

## Phase 3: Secrets and Environment Variables

### 3.1 Add Repository Secrets

- [ ] Navigate to: Settings > Secrets and variables > Actions > New repository secret
- [ ] **Add secrets**:
  - [x] `ANTHROPIC_API_KEY` (Claude API key for AI pipeline)
  - [x] `GOOGLE_API_KEY` (Gemini API key for AI pipeline)
  - [x] `FIREBASE_SERVICE_ACCOUNT` (JSON key for Firebase deployments)
  - [x] `SLACK_WEBHOOK_URL` (for cost-watchdog alerts, optional)

**Source**:
- Claude API key: https://console.anthropic.com/
- Google API key: https://aistudio.google.com/app/apikey
- Firebase service account: `firebase init` → Service accounts

**Verification**:
```bash
# Trigger AI pipeline workflow to verify secrets work
git checkout -b test/verify-secrets
echo "# Test" >> ai-pipeline/README.md
git add ai-pipeline/README.md
git commit -m "test: verify AI pipeline secrets"
git push -u origin test/verify-secrets
# Open PR, check workflow runs without auth errors
```

---

### 3.2 Configure Dependabot Secrets

- [ ] Navigate to: Settings > Secrets and variables > Dependabot
- [ ] **Add secrets** (if Dependabot needs private package access):
  - [ ] `NPM_TOKEN` (for private npm packages, if any)

**Skip if**: Only using public packages (default for MVP)

---

## Phase 4: GitHub Actions Setup

### 4.1 Enable GitHub Actions

- [ ] Navigate to: Settings > Actions > General
- [ ] **Actions permissions**:
  - [x] Allow all actions and reusable workflows
- [ ] **Workflow permissions**:
  - [x] Read and write permissions
  - [x] Allow GitHub Actions to create and approve pull requests
- [ ] Click **Save**

**Rationale**: Allows workflows to auto-update CHANGELOG.md and create release PRs

---

### 4.2 Verify Workflows

- [ ] Navigate to: Actions tab
- [ ] **Check status**:
  - [ ] `ios-build-check.yml` - Waiting for iOS changes
  - [ ] `backend-validation.yml` - Waiting for backend changes
  - [ ] `spec-validation.yml` - Should have run on initial commit
- [ ] **Review spec-validation run**:
  - [ ] Click on workflow run
  - [ ] Verify all steps passed
  - [ ] Check for any warnings

**Troubleshooting**:
- If workflows don't appear: Check `.github/workflows/` directory exists
- If runs fail: Check secrets are set correctly
- For help: Comment `@claude` in PR to invoke CI debugging

---

## Phase 5: Claude Code Integration

### 5.1 Run Setup Scripts

- [ ] **Make scripts executable**:
  ```bash
  chmod +x scripts/*.sh
  ```
- [ ] **Validate environment**:
  ```bash
  ./scripts/validate-environment.sh
  ```
  **Expected output**:
  ```
  ✅ Xcode: Xcode 16.0
  ✅ SwiftLint: 0.55.0
  ✅ Node.js: v20.10.0
  ✅ Firebase CLI: 13.0.0
  ✅ GitHub CLI: 2.40.0
  ```
- [ ] **Setup Claude hooks**:
  ```bash
  ./scripts/setup-claude-hooks.sh
  ```
- [ ] **Setup git hooks**:
  ```bash
  ./scripts/setup-git-hooks.sh
  ```
- [ ] **Install Claude plugins**:
  ```bash
  ./scripts/install-claude-plugins.sh
  ```

**Troubleshooting**:
- Missing tools: Follow error messages to install (e.g., `brew install swiftlint`)
- Xcode version mismatch: Update to Xcode 16+ from Mac App Store

---

### 5.2 Test Claude Code Automation

- [ ] **Test bash validator hook**:
  ```bash
  # Should block
  ./.claude/hooks/bash_command_validator.py "rm -rf /"
  # Expected: ❌ BLOCKED: Dangerous command pattern

  # Should allow
  ./.claude/hooks/bash_command_validator.py "ls -la"
  # Expected: ✅ Command allowed: ls -la
  ```
- [ ] **Test doc-reviewer agent** (via Claude Code):
  ```bash
  claude agent run doc-reviewer docs/
  ```
- [ ] **Test drift-detector** (via Claude Code):
  ```bash
  claude agent run drift-detector ios/
  ```

---

## Phase 6: Firebase Setup

### 6.1 Initialize Firebase

- [ ] **Login to Firebase**:
  ```bash
  firebase login
  ```
- [ ] **Initialize project**:
  ```bash
  firebase init
  ```
  - Select: Firestore, Storage, Functions, Hosting
  - Choose: Existing project → abundance-mvp
  - Accept defaults (Firestore rules, Functions directory)
- [ ] **Deploy rules** (dry run):
  ```bash
  firebase deploy --only firestore:rules --dry-run
  ```

---

### 6.2 Configure Firebase Project

- [ ] Navigate to: https://console.firebase.google.com/
- [ ] **Add iOS app**:
  - Bundle ID: `com.abundance.mvp`
  - Download `GoogleService-Info.plist` → `ios/Config/`
- [ ] **Enable Authentication**:
  - Providers: Email/Password, Sign in with Apple
- [ ] **Create Firestore database**:
  - Location: us-central1
  - Mode: Production (use rules from `firestore.rules`)
- [ ] **Create Storage bucket**:
  - Location: us-central1
  - Rules: Use `storage.rules`

---

## Phase 7: Local Development Verification

### 7.1 iOS Build

- [ ] **Open Xcode**:
  ```bash
  cd ios
  open Package.swift
  ```
- [ ] **Build project**:
  - Xcode > Product > Build (⌘B)
  - Expected: Build succeeds with 0 warnings
- [ ] **Run tests**:
  - Xcode > Product > Test (⌘U)
  - Expected: All tests pass

---

### 7.2 Backend Build

- [ ] **Install dependencies**:
  ```bash
  cd backend/functions
  npm install
  ```
- [ ] **Run linter**:
  ```bash
  npm run lint
  ```
- [ ] **Run tests**:
  ```bash
  npm test
  ```

---

### 7.3 AI Pipeline

- [ ] **Install Python dependencies**:
  ```bash
  cd ai-pipeline
  pip install -r requirements.txt
  ```
- [ ] **Run tests**:
  ```bash
  pytest tests/
  ```

---

## Phase 8: Final Verification

### 8.1 Create Test PR

- [ ] **Create feature branch**:
  ```bash
  git checkout -b feature/test-setup
  echo "# Setup verified" >> SETUP-VERIFIED.md
  git add SETUP-VERIFIED.md
  git commit -m "docs: verify repository setup"
  git push -u origin feature/test-setup
  ```
- [ ] **Open PR**:
  ```bash
  gh pr create \
    --title "docs: verify repository setup" \
    --body "Checklist verification PR - all setup steps completed"
  ```
- [ ] **Verify CI runs**:
  - [ ] spec-validation workflow passes
  - [ ] No other workflows triggered (only docs changed)
- [ ] **Merge PR**:
  ```bash
  gh pr merge --squash
  ```

---

### 8.2 Verify Branch Protection

- [ ] **Test direct push** (should fail):
  ```bash
  git checkout main
  git pull
  echo "test" >> README.md
  git add README.md
  git commit -m "test: direct push"
  git push
  # Expected: Error: Protected branch
  ```
- [ ] **Verify CODEOWNERS**:
  - Open any PR
  - Check: Reviewers auto-assigned based on changed files

---

## Completion Criteria

**Repository is ready when**:

- ✅ All 8 phases completed
- ✅ Branch protection enabled on `main`
- ✅ All GitHub Actions workflows green
- ✅ Secrets configured and verified
- ✅ Claude Code hooks/agents functional
- ✅ Firebase project initialized
- ✅ Local builds succeed (iOS, backend, AI pipeline)
- ✅ Test PR merged successfully

**Time estimate**: 2-3 hours for first-time setup

---

## Troubleshooting

### Common Issues

**Issue**: Workflows not running
- **Fix**: Check Settings > Actions > General > Allow all actions

**Issue**: Secrets not found in workflow
- **Fix**: Verify secret names match exactly in workflow YAML

**Issue**: Xcode version mismatch
- **Fix**: Update to Xcode 16+ from Mac App Store

**Issue**: Firebase deploy fails
- **Fix**: Run `firebase login` and verify project ID in `.firebaserc`

**Issue**: Claude Code hooks not executing
- **Fix**: Run `chmod +x .claude/hooks/*.sh` and `chmod +x .claude/hooks/*.py`

---

## References

- **BRANCH-PROTECTION-RULES-001**: Detailed protection rules
- **GITHUB-ACTIONS-ARCHITECTURE-001**: Workflow specifications
- **CLAUDE-CODE-AUTOMATION-001**: Hook and agent setup
- **LOCAL-DEV-SETUP-001**: Developer onboarding guide

## Changelog

- **2025-11-14**: Initial version with 8-phase setup process
