# SPEC-OPS-001: CI/CD Workflows

**Created:** 2026-01-18
**Status:** Active
**Author:** Claude Code Audit

---

## 1. Overview

The Abundance MVP project uses a comprehensive CI/CD strategy built on GitHub Actions for automated testing, security review, and deployment. The strategy is designed to support:

- **iOS Development**: Swift 6.0 with SPM, SwiftUI-only architecture
- **Backend Services**: Firebase Cloud Functions (TypeScript), Firestore, Storage
- **Documentation**: Automated generation and validation

### Tools and Technologies

| Category | Tool | Purpose |
|----------|------|---------|
| CI/CD Platform | GitHub Actions | Workflow automation |
| iOS Build | Xcode 16.1, Swift | Build and test iOS app |
| Linting | SwiftLint, ESLint | Code quality |
| Backend | Firebase CLI, Node.js 20 | Functions deployment |
| Security | Claude Code Action | AI-powered security review |
| Documentation | SourceDocs, TypeDoc | API documentation generation |

---

## 2. GitHub Actions Workflows

| Workflow | File | Trigger | Purpose |
|----------|------|---------|---------|
| iOS Build Check | `ios-build-check.yml` | PR (ios/**), push to main | Build iOS app, run SwiftLint, execute unit tests |
| Backend Validation | `backend-validation.yml` | PR (backend/**), push to main | Build TypeScript, run tests, validate security rules |
| Security PR Review | `security-pr-review.yml` | PR opened/synchronized | AI-powered OWASP security analysis |
| Firebase Functions Deploy | `firebase-functions-deploy.yml` | Push to main, manual | Deploy functions, Firestore rules, Storage rules |
| Firebase Functions Test | `firebase-functions-test.yml` | PR (functions/**), push to main | Integration tests with Firebase Emulator |
| Documentation Generation | `docs-generation.yml` | Push to main | Generate Swift and TypeScript API docs |
| Changelog Update | `changelog-update.yml` | Release published | Auto-update CHANGELOG.md |
| Claude Code CI Debug | `claude-code-action-ci-fix.yml` | PR comment with @claude | AI-assisted CI debugging |
| Spec Validation | `spec-validation.yml` | PR (docs/**), push to main | Validate document links and ADR numbering |

---

## 3. Workflow Details

### 3.1 iOS Build Check (`ios-build-check.yml`)

**Purpose**: Ensures iOS code compiles and passes all tests before merge.

**Trigger Conditions**:
- Pull request with changes to `ios/**` or the workflow file itself
- Push to `main` branch

**Jobs**:
1. **build** (runs-on: `macos-14`)
   - Checkout code
   - Set up Xcode 16.1
   - Cache Swift packages (`.build`, DerivedData)
   - Build iOS project (`swift build -c debug`)
   - Run SwiftLint with `--strict` flag
   - Execute unit tests (`swift test --parallel`)

**Required Secrets**: None

**Artifacts**: None (tests run in-place)

**Cache Strategy**:
```yaml
key: ${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved') }}
restore-keys: ${{ runner.os }}-spm-
```

---

### 3.2 Backend Validation (`backend-validation.yml`)

**Purpose**: Validates backend TypeScript code and Firebase security rules.

**Trigger Conditions**:
- Pull request with changes to `backend/**`, security rules, or workflow file
- Push to `main` branch

**Jobs**:
1. **validate** (runs-on: `ubuntu-latest`)
   - Checkout code
   - Set up Node.js 20 with npm caching
   - Install dependencies (`npm ci`)
   - Build TypeScript (`npm run build`)
   - Run tests (`npm test`)
   - Lint Firestore rules (`firebase deploy --only firestore:rules --dry-run`)
   - Lint Storage rules (`firebase deploy --only storage:rules --dry-run`)

**Required Secrets**: None (uses dry-run for rule validation)

**Artifacts**: None

---

### 3.3 Security PR Review (`security-pr-review.yml`)

**Purpose**: AI-powered security analysis for OWASP Top 10 vulnerabilities.

**Trigger Conditions**:
- Pull request opened or synchronized

**Jobs**:
1. **security-review** (runs-on: `ubuntu-latest`)
   - Checkout code with full history (`fetch-depth: 0`)
   - Get changed files using `tj-actions/changed-files@v46`
   - Invoke Claude Code Action for security review

**Permissions**:
- `contents: read`
- `pull-requests: write`

**Required Secrets**:
- `ANTHROPIC_API_KEY` - Claude API key
- `GITHUB_TOKEN` - Auto-provided by GitHub

**Security Checks**:
- SQL injection vulnerabilities
- XSS vulnerabilities
- Authentication/authorization issues
- Sensitive data exposure
- Security misconfigurations
- Insecure deserialization
- Components with known vulnerabilities

---

### 3.4 Firebase Functions Deploy (`firebase-functions-deploy.yml`)

**Purpose**: Deploys Firebase Functions and security rules to production.

**Trigger Conditions**:
- Push to `main` with changes to `functions/**`, `firestore.rules`, or `storage.rules`
- Manual workflow dispatch (with environment selection)

**Environment Selection** (manual dispatch):
- `production` (default)
- `staging`

**Jobs**:
1. **deploy** (runs-on: `ubuntu-latest`)
   - Checkout code
   - Set up Node.js 20
   - Install Firebase CLI
   - Install function dependencies
   - Build TypeScript
   - Run tests
   - Authenticate to Firebase (Google Cloud auth)
   - Deploy Firebase Functions (`--force`)
   - Deploy Firestore Rules
   - Deploy Storage Rules
   - Post-deployment validation (30s wait + health checks)
   - Create deployment summary

**Required Secrets**:
- `FIREBASE_SERVICE_ACCOUNT` - Service account JSON credentials
- `FIREBASE_TOKEN` - Firebase CLI token

**Artifacts**:
- GitHub Step Summary with deployment details

**Post-Deployment**:
```bash
# Deployment summary includes:
- Environment name
- Commit SHA
- Deployer
- Timestamp
- List of deployed components
```

---

### 3.5 Firebase Functions Test (`firebase-functions-test.yml`)

**Purpose**: Integration tests using Firebase Emulator Suite.

**Trigger Conditions**:
- Pull request with changes to `functions/**`, security rules, or workflow file
- Push to `main` branch

**Jobs**:
1. **integration-test** (runs-on: `ubuntu-latest`)
   - Checkout code
   - Set up Node.js 20
   - Install Firebase CLI
   - Install function dependencies
   - Build TypeScript
   - Run unit tests
   - Start Firebase Emulators (functions, firestore, auth, storage)
   - Run integration tests
   - Stop emulators
   - Upload test results

**Emulator Ports**:
| Service | Port |
|---------|------|
| Firestore | 8080 |
| Auth | 9099 |
| Storage | 9199 |
| Emulator UI | 4000 |

**Environment Variables**:
```yaml
FIRESTORE_EMULATOR_HOST: localhost:8080
FIREBASE_AUTH_EMULATOR_HOST: localhost:9099
FIREBASE_STORAGE_EMULATOR_HOST: localhost:9199
GOOGLE_CLOUD_PROJECT: abundance-mvp-test
```

**Artifacts**:
- `test-results` - Coverage reports (7-day retention)

---

### 3.6 Documentation Generation (`docs-generation.yml`)

**Purpose**: Auto-generates API documentation from source code.

**Trigger Conditions**:
- Push to `main` with changes to `ios/**/*.swift` or `backend/**/*.ts`

**Jobs**:
1. **generate** (runs-on: `ubuntu-latest`)
   - Checkout code
   - Generate Swift docs (SourceDocs)
   - Generate TypeScript docs (TypeDoc)
   - Commit and push generated docs

**Generated Outputs**:
- `docs/api/ios/` - Swift API documentation
- `docs/api/backend/` - TypeScript API documentation

**Git Configuration**:
```yaml
user.name: github-actions[bot]
user.email: github-actions[bot]@users.noreply.github.com
```

---

### 3.7 Changelog Update (`changelog-update.yml`)

**Purpose**: Automatically updates CHANGELOG.md when a release is published.

**Trigger Conditions**:
- Release published

**Jobs**:
1. **update** (runs-on: `ubuntu-latest`)
   - Checkout code with full history
   - Generate changelog entry from commits since last tag
   - Prepend new entry to CHANGELOG.md
   - Commit and push changes

**Changelog Format**:
```markdown
## [v1.0.0] - 2026-01-18

- abc123f feat: add new feature
- def456a fix: resolve bug
```

---

### 3.8 Claude Code CI Debug (`claude-code-action-ci-fix.yml`)

**Purpose**: Provides AI-assisted debugging when developers mention @claude in PR comments.

**Trigger Conditions**:
- Issue comment created (PR comments are issue comments in GitHub's API)
- Comment body contains `@claude`

**Jobs**:
1. **debug-ci** (runs-on: `ubuntu-latest`)
   - Checkout PR code
   - Get PR details via GitHub API
   - Invoke Claude Code Action with debugging prompt

**Permissions**:
- `contents: read`
- `issues: write`
- `pull-requests: write`

**Required Secrets**:
- `ANTHROPIC_API_KEY` - Claude API key
- `GITHUB_TOKEN` - Auto-provided by GitHub

---

### 3.9 Spec Validation (`spec-validation.yml`)

**Purpose**: Validates documentation structure and cross-references.

**Trigger Conditions**:
- Pull request with changes to `docs/**` or workflow file
- Push to `main` branch

**Jobs**:
1. **validate** (runs-on: `ubuntu-latest`)
   - Checkout code
   - Check for broken links (`validate_doc_references.py`)
   - Validate ADR numbering (no duplicates)
   - Check DESIGN doc cross-references (should reference ADRs)

**Validation Rules**:
- All markdown links must resolve to existing files
- ADR numbers must be unique (excludes `docs/archive/`)
- DESIGN docs should reference at least one ADR (warning only)

---

## 4. Testing Requirements

### 4.1 Unit Tests

| Platform | Framework | Command | Location |
|----------|-----------|---------|----------|
| iOS | XCTest | `swift test --parallel` | `Tests/` |
| Backend | Jest/Mocha | `npm test` | `functions/` |

### 4.2 Integration Tests

| Platform | Framework | Command | Environment |
|----------|-----------|---------|-------------|
| Backend | Jest | `npm run test:integration` | Firebase Emulator |

### 4.3 Required Checks for PR Merge

The following status checks must pass before a PR can be merged to `main`:

1. **ios-build-check** - iOS build and tests
2. **backend-validation** - Backend build and tests
3. **security-pr-review** - Security analysis (AI-powered)

**Branch Protection Configuration**:
```
Branch: main
- Require pull request before merging
- Require 1 approval
- Require status checks to pass:
  - ios-build-check
  - backend-validation
  - security-pr-review
- Require conversation resolution
```

---

## 5. Deployment Targets

### 5.1 Staging

| Attribute | Value |
|-----------|-------|
| Trigger | Manual (workflow_dispatch) |
| Environment | `staging` |
| Firebase Project | Configured per environment |

### 5.2 Production

| Attribute | Value |
|-----------|-------|
| Trigger | Automatic (push to main) or Manual |
| Environment | `production` |
| Firebase Project | Configured per environment |

### 5.3 Deployment Matrix

| Component | Auto-Deploy | Manual | Notes |
|-----------|-------------|--------|-------|
| Firebase Functions | Yes | Yes | On push to main or manual |
| Firestore Rules | Yes | Yes | Deployed with functions |
| Storage Rules | Yes | Yes | Deployed with functions |
| iOS App | No | Yes | Requires App Store submission |

---

## 6. Scripts

### 6.1 Environment and Setup

| Script | Purpose | Usage |
|--------|---------|-------|
| `validate-environment.sh` | Validates development environment prerequisites | `./scripts/validate-environment.sh` |
| `bootstrap-repository.sh` | Creates and initializes new repository from scaffold | `./scripts/bootstrap-repository.sh` |
| `setup-git-hooks.sh` | Installs pre-commit and pre-push hooks | `./scripts/setup-git-hooks.sh` |
| `setup-claude-hooks.sh` | Configures Claude Code hooks | `./scripts/setup-claude-hooks.sh` |
| `install-claude-plugins.sh` | Creates symlinks to Claude Code plugins | `./scripts/install-claude-plugins.sh` |
| `install-system-plugins.sh` | Installs MCP servers (gcloud, storage, observability, firebase) | `./scripts/install-system-plugins.sh` |

### 6.2 Development Tools

| Script | Purpose | Usage |
|--------|---------|-------|
| `sim.sh` | Fast iOS development loop (simulator or device) | `./scripts/sim.sh [--device\|--sim] [device-name]` |
| `regenerate-xcode-project.sh` | Regenerates Xcode project from XcodeGen spec | `./scripts/regenerate-xcode-project.sh [--yes]` |
| `check-health.sh` | Checks health of external dependencies | `./scripts/check-health.sh` |

### 6.3 Documentation Tools

| Script | Purpose | Usage |
|--------|---------|-------|
| `validate_doc_references.py` | Validates markdown links are not broken | `python3 scripts/validate_doc_references.py` |
| `fix_doc_references.py` | Fixes broken document references | `python3 scripts/fix_doc_references.py [--apply]` |
| `map_documents.py` | Maps document IDs to file paths (library) | Imported by other scripts |
| `extract-spec-assertions.py` | Extracts testable assertions from specs | `python3 scripts/extract-spec-assertions.py` |

### 6.4 Script Details

#### validate-environment.sh

Checks for required development tools:
- Swift (Xcode Command Line Tools)
- SwiftLint
- Node.js / npm
- Firebase CLI
- GitHub CLI
- Git
- Xcode 16+

Also validates:
- Firebase project configuration (`.firebaserc`)
- GitHub CLI authentication
- Environment variables (`ANTHROPIC_API_KEY`, `GOOGLE_API_KEY`)

#### setup-git-hooks.sh

Installs two Git hooks:

**Pre-commit hook**:
- SwiftLint for `.swift` files
- ESLint for `.ts` files
- Document validation for `docs/*.md` files

**Pre-push hook**:
- iOS tests if `.swift` files changed
- Backend tests if `functions/*.ts` files changed

#### sim.sh

Fast iteration script for iOS development:
```bash
# Run on simulator (default)
./scripts/sim.sh

# Run on physical device
./scripts/sim.sh --device w-16e

# Force regenerate Xcode project
./scripts/sim.sh --regenerate
```

Features:
- Auto-generates Xcode project with XcodeGen
- Builds for simulator or device
- Captures logs to `.debug/logs/`
- Provides issue capture workflow

---

## 7. Required Secrets Summary

| Secret | Used By | Purpose |
|--------|---------|---------|
| `ANTHROPIC_API_KEY` | security-pr-review, claude-code-action-ci-fix | Claude API access |
| `FIREBASE_SERVICE_ACCOUNT` | firebase-functions-deploy | GCP authentication |
| `FIREBASE_TOKEN` | firebase-functions-deploy | Firebase CLI authentication |
| `GITHUB_TOKEN` | All workflows | Auto-provided by GitHub |

---

## 8. Workflow Dependencies

```
PR Opened/Updated
       │
       ├──► ios-build-check (if ios/** changed)
       │         └──► SwiftLint + Unit Tests
       │
       ├──► backend-validation (if backend/** changed)
       │         └──► TypeScript Build + Tests + Rule Validation
       │
       ├──► security-pr-review
       │         └──► OWASP Security Analysis
       │
       └──► spec-validation (if docs/** changed)
                 └──► Link Validation + ADR Numbering

PR Merged to main
       │
       ├──► firebase-functions-deploy (if functions/** changed)
       │         └──► Functions + Rules Deployment
       │
       └──► docs-generation (if source changed)
                 └──► API Documentation

Release Published
       │
       └──► changelog-update
                 └──► CHANGELOG.md Update
```

---

## 9. Troubleshooting

### Common Issues

**iOS Build Fails**:
1. Check Xcode version (requires 16.1)
2. Verify Swift package dependencies resolve
3. Run `swift package clean` locally

**Firebase Deployment Fails**:
1. Verify `FIREBASE_SERVICE_ACCOUNT` secret is valid JSON
2. Check `FIREBASE_TOKEN` is not expired
3. Ensure Firebase project is properly configured

**Security Review Not Running**:
1. Verify `ANTHROPIC_API_KEY` secret exists
2. Check PR is not from a fork (secrets not available)

**Spec Validation Fails**:
1. Run `python3 scripts/validate_doc_references.py` locally
2. Fix broken links before pushing
3. Ensure ADR numbers are unique

### Debug with @claude

Comment `@claude` in any PR to invoke AI-assisted debugging:
```
@claude Why is the ios-build-check failing?
```

---

## 10. References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)
- [Claude Code Action](https://github.com/anthropics/claude-code-action)
- [CLAUDE.md](../../CLAUDE.md) - Project quick reference
