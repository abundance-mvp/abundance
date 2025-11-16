# Abundance MVP Scaffold

**Version**: 0.1.0 (Stage 5.3)
**Created**: 2025-11-14
**Purpose**: CI/CD and automation infrastructure template for Abundance MVP

---

## Overview

This scaffold provides a complete project initialization template with:

- ✅ **GitHub Actions CI/CD** (8 workflows)
- ✅ **Claude Code Automation** (hooks, agents, commands)
- ✅ **PR/Issue Templates** (7 templates)
- ✅ **Developer Tooling** (setup scripts, validation)
- ✅ **Comprehensive Documentation** (8 tech-stack docs)

---

## Quick Start

### Option 1: Automated Bootstrap (Recommended)

Run the interactive bootstrap script from the **parent directory of spec-kit**:

```bash
cd /path/to/parent-directory  # Directory containing spec-kit/
./spec-kit/abundance-scaffold/scripts/bootstrap-repository.sh
```

**What it does**:

1. ✅ Creates `abundance-mvp` GitHub repository (private)
2. ✅ Clones repository locally
3. ✅ Copies all scaffold files (including `.github/`, `.claude/`)
4. ✅ Makes scripts executable
5. ✅ Runs environment validation
6. ✅ Sets up git hooks
7. ✅ Sets up Claude Code hooks
8. ✅ Creates initial commit
9. ✅ Pushes to GitHub
10. 🎯 **Interactive menu** for next steps (secrets, Firebase, IDE)

**Time**: ~5 minutes (excluding manual configuration)

---

### Option 2: Manual Setup

If you prefer step-by-step control:

#### 1. Create Repository

```bash
gh repo create abundance-mvp \
  --private \
  --description "Abundance MVP: AI-powered product discovery" \
  --clone \
  --gitignore Swift,Node
```

#### 2. Copy Scaffold Files

```bash
cd abundance-mvp

# Copy regular files
cp -r ../spec-kit/abundance-scaffold/* .

# Copy hidden directories
cp -r ../spec-kit/abundance-scaffold/.github .
cp -r ../spec-kit/abundance-scaffold/.claude .
```

#### 3. Run Setup Scripts

```bash
chmod +x scripts/*.sh

./scripts/validate-environment.sh  # Check prerequisites
./scripts/setup-git-hooks.sh       # Install pre-commit/pre-push hooks
./scripts/setup-claude-hooks.sh    # Configure Claude Code hooks
```

#### 4. Initial Commit

```bash
git add .
git commit -m "chore: initialize repository with CI/CD scaffold"
git push -u origin main
```

---

## Interactive Bootstrap Features

The bootstrap script includes an **interactive menu** with these options:

1. **Configure GitHub secrets** - Step-by-step secret setup
2. **Open repository in browser** - Quick access to GitHub UI
3. **Open documentation** - View setup checklist
4. **Initialize Firebase** - Guided Firebase setup
5. **Open in VS Code** - Launch IDE
6. **Open iOS project in Xcode** - Open Swift package
7. **Exit** - Complete setup manually

**Example**:

```
What would you like to do next?
  1) Configure GitHub secrets (recommended first)
  2) Open repository in browser
  3) Open documentation (REPOSITORY-SETUP-CHECKLIST-001.md)
  4) Initialize Firebase
  5) Open in VS Code
  6) Open iOS project in Xcode
  7) Exit (continue manually)

Select option [1-7]:
```

---

## Manual Configuration Required

After running the bootstrap script, complete these **manual steps**:

### 1. GitHub Secrets

Navigate to: **Settings > Secrets and variables > Actions**

Add these secrets:

| Secret                     | Source                                 | Required    |
| -------------------------- | -------------------------------------- | ----------- |
| `ANTHROPIC_API_KEY`        | https://console.anthropic.com/         | ✅ Yes      |
| `GOOGLE_API_KEY`           | https://aistudio.google.com/app/apikey | ✅ Yes      |
| `FIREBASE_SERVICE_ACCOUNT` | Firebase Console (JSON key)            | ✅ Yes      |
| `SLACK_WEBHOOK_URL`        | Slack workspace settings               | ⚠️ Optional |

**Quick command**:

```bash
gh secret set ANTHROPIC_API_KEY
gh secret set GOOGLE_API_KEY
gh secret set FIREBASE_SERVICE_ACCOUNT
```

---

### 2. Enable GitHub Actions

Navigate to: **Settings > Actions > General**

Enable:

- ✅ Allow all actions and reusable workflows
- ✅ Read and write permissions
- ✅ Allow GitHub Actions to create and approve pull requests

---

### 3. Branch Protection Rules

Navigate to: **Settings > Branches > Add rule**

**Branch name pattern**: `main`

Enable:

- ✅ Require a pull request before merging
  - Required approving reviews: **1**
  - Dismiss stale pull request approvals
  - Require review from Code Owners
- ✅ Require status checks to pass before merging
  - Require branches to be up to date
  - Status checks: `ios-build-check`, `backend-validation`, `security-pr-review`
- ✅ Require conversation resolution before merging
- ✅ Require linear history

**See**: `docs/tech-stack/BRANCH-PROTECTION-RULES-001.md` for API/Terraform setup

---

### 4. Claude Code Plugins

1. Open Claude Code
2. Navigate to marketplace
3. Install: `superpowers`, `document-skills`
4. Re-run: `./scripts/install-claude-plugins.sh`

---

### 5. Firebase Initialization

```bash
firebase login
firebase init
# Select: Firestore, Storage, Functions, Hosting
# Choose: Existing project → abundance-mvp
firebase deploy --only firestore:rules --dry-run
```

---

## What's Included

### GitHub Actions Workflows (`.github/workflows/`)

| Workflow                        | Purpose                                  | Triggers                                       |
| ------------------------------- | ---------------------------------------- | ---------------------------------------------- |
| `ios-build-check.yml`           | Swift 6.0 build, SwiftLint, tests        | Push to `main`, PRs modifying `ios/**`         |
| `backend-validation.yml`        | TypeScript build, ESLint, Firebase rules | Push to `main`, PRs modifying `backend/**`     |
| `ai-pipeline-check.yml`         | Python lint, mypy, pytest, benchmarks    | Push to `main`, PRs modifying `ai-pipeline/**` |
| `spec-validation.yml`           | Doc-reviewer agent, link checks          | Push to `main`, PRs modifying `docs/**`        |
| `claude-code-action-ci-fix.yml` | CI debugging via @claude mentions        | Issue comment with `@claude`                   |
| `security-pr-review.yml`        | OWASP Top 10 scanning                    | PR opened/synchronize                          |
| `docs-auto-update.yml`          | TOC generation, timestamp updates        | Push to `main`, weekly schedule                |
| `changelog-on-release.yml`      | CHANGELOG.md auto-update                 | Tag push (`v*`)                                |

---

### Claude Code Automation (`.claude/`)

#### Hooks (`.claude/hooks/`)

| Hook                        | Purpose                                       | Trigger               |
| --------------------------- | --------------------------------------------- | --------------------- |
| `pre-sprint.sh`             | Validates environment before sprint execution | Before sprint starts  |
| `pr_create_hook.sh`         | Enforces PR template compliance               | PR creation           |
| `file_edit_hook.sh`         | Detects sensitive data in commits             | File edits            |
| `bash_command_validator.py` | Blocks dangerous commands                     | Before bash execution |

**Blocked patterns**: `rm -rf /`, fork bombs, `curl\|bash`, destructive operations

#### Agents (`.claude/agents/`)

| Agent               | Purpose                              | Severity Levels         |
| ------------------- | ------------------------------------ | ----------------------- |
| `doc-reviewer.md`   | Link validation, staleness detection | Info                    |
| `drift-detector.md` | ADR compliance enforcement           | P0/P1/P2                |
| `cost-watchdog.md`  | Budget monitoring ($554/month)       | Warn/Critical/Emergency |

**Invoke**: `/validate-docs`, `/check-drift`, or `@doc-reviewer`

#### Commands (`.claude/commands/`)

| Command               | Purpose                                    | References                         |
| --------------------- | ------------------------------------------ | ---------------------------------- |
| `/validate-docs`      | Check docs for broken links, stale content | `.claude/agents/doc-reviewer.md`   |
| `/check-drift`        | ADR compliance with P0/P1/P2 severity      | `.claude/agents/drift-detector.md` |
| `/show-sprint-status` | Display sprint progress                    | `docs/roadmap/SPRINT-PLAN-*.md`    |

**Usage**:

```
/validate-docs
/check-drift
/show-sprint-status
```

**See**: `.claude/commands/README.md` for full documentation

---

### Documentation (`docs/tech-stack/`)

| Document                             | Description                            | Lines |
| ------------------------------------ | -------------------------------------- | ----- |
| `CLAUDE-CODE-AUTOMATION-001.md`      | Architecture overview (5 plugin types) | 312   |
| `AI-AGENT-BEHAVIORS-001.md`          | Agent personas, orchestration patterns | 418   |
| `GITHUB-ACTIONS-ARCHITECTURE-001.md` | CI/CD pipeline design, cost analysis   | 587   |
| `BRANCH-PROTECTION-RULES-001.md`     | GitHub protection rules                | 324   |
| `REPOSITORY-SETUP-CHECKLIST-001.md`  | 8-phase setup guide (2-3 hrs)          | 467   |
| `LOCAL-DEV-SETUP-001.md`             | Developer onboarding guide (1-2 hrs)   | 672   |
| `COST-MONITORING-AUTOMATION-001.md`  | Budget tracking, 3-tier alerting       | 598   |
| `CHANGELOG-AUTOMATION-001.md`        | Conventional Commits strategy          | 523   |

---

### Setup Scripts (`scripts/`)

| Script                      | Purpose                                            |
| --------------------------- | -------------------------------------------------- |
| `bootstrap-repository.sh`   | **Interactive repository creation** (recommended)  |
| `validate-environment.sh`   | Check Xcode 16+, SwiftLint, Firebase CLI, API keys |
| `setup-git-hooks.sh`        | Install pre-commit/pre-push hooks                  |
| `setup-claude-hooks.sh`     | Make Claude hooks executable, run tests            |
| `install-claude-plugins.sh` | Symlink marketplace plugins                        |

All scripts are executable (`chmod +x`)

---

## Verification Checklist

After setup, verify:

- [ ] Repository created: `gh repo view abundance-mvp`
- [ ] All files copied: `ls -la` shows `.github/`, `.claude/`
- [ ] Scripts executable: `ls -la scripts/` shows `-rwxr-xr-x`
- [ ] Environment validated: `./scripts/validate-environment.sh` passes
- [ ] Git hooks installed: `.git/hooks/pre-commit` exists
- [ ] Claude hooks executable: `.claude/hooks/bash_command_validator.py "echo test"` succeeds
- [ ] Secrets configured: `gh secret list` shows 3-4 secrets
- [ ] Actions enabled: **Settings > Actions** shows enabled
- [ ] Branch protection set: **Settings > Branches** shows `main` rule
- [ ] Test PR created: Workflows trigger on PR

---

## Cost Breakdown

**Monthly estimates** (from GITHUB-ACTIONS-ARCHITECTURE-001):

| Service              | Cost/Month  | Notes                        |
| -------------------- | ----------- | ---------------------------- |
| GitHub Actions       | $10.68      | 200 workflow runs/month      |
| Claude Code Agents   | $20-30      | 5 reviews/sprint × 4 sprints |
| Cost Monitoring      | $15         | Daily cost-watchdog runs     |
| **Total Automation** | **~$46-56** | 8-10% of $554 total budget   |

**Within budget**: Yes (COST-MODEL-001 allocation)

---

## Troubleshooting

### Bootstrap Script Fails

**Error**: "Repository already exists"

```bash
# Check if repo exists remotely
gh repo view abundance-mvp

# If yes, delete and re-run
gh repo delete abundance-mvp --yes
./scripts/bootstrap-repository.sh
```

**Error**: "GitHub CLI not authenticated"

```bash
gh auth login
```

---

### Environment Validation Fails

**Missing Xcode 16+**:

- Install from Mac App Store or https://developer.apple.com/download/

**Missing SwiftLint**:

```bash
brew install swiftlint
```

**Missing Firebase CLI**:

```bash
npm install -g firebase-tools
```

---

### Hooks Not Executing

**Check permissions**:

```bash
ls -la .claude/hooks/
# Should show: -rwxr-xr-x (executable)

# Fix if needed:
chmod +x .claude/hooks/*.sh
chmod +x .claude/hooks/*.py
```

**Test manually**:

```bash
./.claude/hooks/bash_command_validator.py "rm -rf /"
# Expected: ❌ BLOCKED: Dangerous command pattern
```

---

## Documentation Reference

- **Setup Guide**: `docs/tech-stack/REPOSITORY-SETUP-CHECKLIST-001.md`
- **Dev Onboarding**: `docs/tech-stack/LOCAL-DEV-SETUP-001.md`
- **Branch Protection**: `docs/tech-stack/BRANCH-PROTECTION-RULES-001.md`
- **Claude Code**: `docs/tech-stack/CLAUDE-CODE-AUTOMATION-001.md`
- **Cost Monitoring**: `docs/tech-stack/COST-MONITORING-AUTOMATION-001.md`

---

## Changelog

See `CHANGELOG.md` for version history.

**Current version**: 0.1.0 (Stage 5.3 completion)

---

## Support

- **Issues**: https://github.com/abundance-mvp/issues (after repository creation)
- **Documentation**: All `docs/tech-stack/*.md` files
- **Claude Code Docs**: https://code.claude.com/docs/

---

**Generated**: 2025-11-14 (Stage 5.3)
**Scaffold from**: spec-kit/abundance-scaffold
**Ready for**: Sprint 1 development
