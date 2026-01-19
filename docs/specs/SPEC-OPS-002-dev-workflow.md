# SPEC-OPS-002: Developer Workflow

**Created:** 2026-01-18
**Status:** Active
**Author:** Claude Code Audit

---

## 1. Overview

This specification documents the development environment, workflow standards, and tooling for the Abundance MVP project. The project uses a multi-stack architecture:

- **iOS Client:** Swift 6.0, SwiftUI-only (ADR-010), MVVM pattern
- **Backend:** Firebase Cloud Functions (TypeScript)
- **AI Pipeline:** Python (Gemini integration)

All development integrates with Claude Code for AI-assisted development, using project-specific skills and commands.

---

## 2. Environment Setup

### 2.1 Required Tools

The following tools must be installed for development. Use `scripts/validate-environment.sh` to verify your setup.

| Tool | Purpose | Required Version |
|------|---------|------------------|
| Xcode | iOS development | 16+ (for iOS 26) |
| Swift | Swift toolchain | 6.0+ |
| SwiftLint | Code linting | Latest |
| Node.js | Backend development | 20+ |
| NPM | Package management | Latest |
| Firebase CLI | Firebase operations | Latest |
| GitHub CLI (gh) | PR management | Latest |
| Git | Version control | Latest |

### 2.2 Environment Validation

Run the validation script before starting development:

```bash
./scripts/validate-environment.sh
```

This script checks:
- All required tools are installed with version info
- Xcode 16+ for iOS 26 development
- Firebase project configuration (`.firebaserc`)
- GitHub CLI authentication status
- Required environment variables (`ANTHROPIC_API_KEY`, `GOOGLE_API_KEY`)

### 2.3 Authentication

#### Firebase/GCP Authentication

```bash
firebase login           # Authenticate with Firebase
gcloud auth login        # Authenticate with GCP (if needed)
```

Verify Firebase project is configured:
```bash
cat .firebaserc          # Check default project
firebase projects:list   # List accessible projects
```

#### GitHub CLI Authentication

```bash
gh auth login            # Authenticate with GitHub
gh auth status           # Verify authentication
```

---

## 3. Branch Conventions

### 3.1 Branch Naming

All branches must use one of the following prefixes:

| Prefix | Purpose | Example |
|--------|---------|---------|
| `feature/` | New functionality | `feature/camera-capture` |
| `fix/` | Bug fixes | `fix/memory-leak-viewmodel` |
| `docs/` | Documentation changes | `docs/update-readme` |
| `chore/` | Maintenance tasks | `chore/update-dependencies` |
| `test/` | Test additions/changes | `test/add-capture-tests` |
| `refactor/` | Code refactoring | `refactor/extract-camera-service` |

### 3.2 Branch Workflow

```bash
# Start from main
git checkout main && git pull

# Create feature branch
git checkout -b feature/your-feature

# Validate environment
./scripts/validate-environment.sh
```

---

## 4. Commit Message Format

### 4.1 Conventional Commits

All commits must follow [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

#### Types

| Type | Purpose |
|------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Code style (formatting, no logic change) |
| `refactor` | Code refactoring (no feature/fix) |
| `test` | Adding or updating tests |
| `chore` | Build process, dependencies, etc. |
| `perf` | Performance improvements |
| `ci` | CI/CD changes |

#### Examples

```bash
feat(camera): add burst capture mode
fix(viewmodel): resolve memory leak in CaptureViewModel
docs(api): update API documentation for v2 endpoints
refactor(networking): extract HTTP client to separate module
test(capture): add unit tests for image processing
```

### 4.2 AI-Assisted Commits

When commits are created with Claude Code assistance, include the Co-Authored-By footer:

```
feat(capture): implement real-time object detection

Added Vision framework integration for detecting household items
in the camera preview stream.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

---

## 5. Claude Code Integration

### 5.1 Directory Structure

The `.claude/` directory contains all Claude Code automation:

```
.claude/
├── skills/                    # Auto-loaded context skills
│   ├── ios-superpowers/       # iOS development orchestrator
│   ├── backend-superpowers/   # Firebase + GCP unified skill
│   ├── device-tester.md       # Physical device testing
│   ├── gemini-integration/    # AI pipeline patterns
│   └── file-issue/            # Issue filing workflow
├── commands/                  # User-invoked via /project:<name>
│   ├── ios-superpowers.md     # /project:ios-superpowers
│   ├── ios-debug.md           # /project:ios-debug
│   ├── device-tester.md       # /project:device-tester
│   ├── gcp-deploy.md          # /project:gcp-deploy
│   ├── dispatch.md            # /project:dispatch
│   └── file-issue.md          # /project:file-issue
├── hooks/                     # Automatic triggers
│   ├── pre-commit             # Doc reference validation
│   ├── pre-sprint.sh          # Sprint preparation
│   ├── on-pr-create.sh        # PR creation automation
│   └── on-file-edit.sh        # File edit triggers
└── settings.json              # Plugin configuration
```

### 5.2 Skills and Commands

#### Primary Skills

| Skill | Purpose | Invoke |
|-------|---------|--------|
| `ios-superpowers` | iOS development orchestrator | Use for ALL iOS/Swift work |
| `backend-superpowers` | Firebase + GCP operations | Use for ALL backend work |
| `device-tester` | Physical device testing | Device debugging |
| `gemini-integration` | AI pipeline patterns | Auto-routed from backend-superpowers |

#### Commands

| Command | Purpose |
|---------|---------|
| `/project:ios-superpowers <action>` | iOS workflows (debug, tdd, review, plan, execute, brainstorm, parallel) |
| `/project:ios-debug <issue>` | Quick iOS debugging |
| `/project:device-tester` | Physical device testing workflow |
| `/project:gcp-deploy <fn>` | Deploy Cloud Function with verification |
| `/project:dispatch` | Dispatch parallel agents |
| `/project:file-issue` | File standardized issues |

### 5.3 iOS Superpowers Requirement (P0)

**CRITICAL:** For ALL iOS/Swift work, use `ios-superpowers` instead of raw superpowers skills.

This ensures:
- Apple documentation is fetched via `/axiom:apple-docs-research`
- Swift 6 concurrency patterns are verified
- SwiftUI APIs match current documentation

```bash
# Instead of superpowers:brainstorming
/project:ios-superpowers brainstorm <topic>

# Instead of superpowers:writing-plans
/project:ios-superpowers plan <feature>

# Instead of superpowers:systematic-debugging
/project:ios-superpowers debug <issue>

# Instead of superpowers:test-driven-development
/project:ios-superpowers tdd <feature>

# Instead of superpowers:requesting-code-review
/project:ios-superpowers review
```

### 5.4 Backend Superpowers

For ALL backend work, use `backend-superpowers`:

```bash
# Invoke the skill
Skill(skill="backend-superpowers")
```

This provides access to 59 MCP tools across:
- Firestore, Cloud Functions, Auth, FCM, Remote Config, RTDB
- Cloud Logging, Monitoring, Tracing, Error Reporting
- GCS Storage operations
- General gcloud commands

Auto-routes Gemini/AI pipeline work to `gemini-integration` skill.

---

## 6. Testing Requirements

### 6.1 TDD Approach

Follow Test-Driven Development:

1. **Write failing test** - Define expected behavior
2. **Implement** - Write minimal code to pass
3. **Verify** - Run tests to confirm
4. **Refactor** - Clean up while keeping tests green
5. **Commit** - Commit working, tested code

Use the TDD workflow command:
```bash
/project:ios-superpowers tdd <feature>
```

### 6.2 Coverage Target

**Target: 80%+ code coverage**

### 6.3 Running Tests

#### iOS Tests

```bash
# Run all Swift tests
swift test

# Run with parallel execution
swift test --parallel

# Run specific test
swift test --filter TestClassName
```

#### Backend Tests

```bash
cd functions

# Run all tests
npm test

# Run with coverage
npm run test:coverage
```

### 6.4 Pre-Commit Testing

**Always run before committing:**

```bash
# iOS
swift test

# Backend
cd functions && npm test
```

---

## 7. Code Quality

### 7.1 SwiftLint

SwiftLint is required for all Swift code. Zero warnings required.

```bash
# Run linting
swiftlint

# Run with strict mode (CI uses this)
swiftlint lint --strict

# Auto-fix issues
swiftlint --fix
```

SwiftLint runs automatically in CI via the `ios-build-check` workflow.

### 7.2 TypeScript Compilation

All TypeScript must compile without errors:

```bash
cd functions

# Build
npm run build

# Type check without emitting
npx tsc --noEmit
```

TypeScript build runs automatically in CI via the `backend-validation` workflow.

### 7.3 Architecture Constraints

#### SwiftUI-Only (ADR-010)

- `import UIKit` in Views/ViewModels is a **P0 violation**
- Infrastructure code (networking, storage) may use UIKit
- Use SwiftUI equivalents for all UI work

#### MVVM Pattern

- ViewModels in `Sources/` following MVVM
- Views should not contain business logic
- Use `@Observable` (Swift 6) or `ObservableObject`

---

## 8. PR Process

### 8.1 Required CI Checks

All PRs must pass these required checks before merge:

| Check | Workflow | Validates |
|-------|----------|-----------|
| `ios-build-check` | `.github/workflows/ios-build-check.yml` | Swift build, SwiftLint, unit tests |
| `backend-validation` | `.github/workflows/backend-validation.yml` | TypeScript build, tests, rules lint |
| `security-pr-review` | `.github/workflows/security-pr-review.yml` | OWASP Top 10 security review |

### 8.2 iOS Build Check

Runs on PRs affecting `ios/**`:
- Swift build (debug configuration)
- SwiftLint with strict mode
- Unit tests with parallel execution

### 8.3 Backend Validation

Runs on PRs affecting `backend/**`, Firestore rules, or Storage rules:
- Node.js 20 setup
- npm ci (clean install)
- TypeScript build
- npm test
- Firestore rules dry-run deploy
- Storage rules dry-run deploy

### 8.4 Security Review

Runs on all PRs:
- Uses Claude Code Action
- Reviews for OWASP Top 10 vulnerabilities
- Provides line-by-line feedback with severity ratings

### 8.5 Review Requirements

1. **All required checks must pass**
2. **At least one approving review** (for non-trivial changes)
3. **No unresolved comments** blocking merge

### 8.6 Getting Help with PRs

Comment `@claude` in the PR to get Claude Code assistance with:
- Build failures
- Test failures
- Security review findings
- Code suggestions

---

## 9. Quick Reference

### 9.1 Starting a Feature

```bash
# Update main
git checkout main && git pull

# Create branch
git checkout -b feature/your-feature

# Validate environment
./scripts/validate-environment.sh

# Plan with iOS superpowers
/project:ios-superpowers plan <feature>
```

### 9.2 During Development

```bash
# Use TDD approach
/project:ios-superpowers tdd <feature>

# Debug issues
/project:ios-superpowers debug <issue>

# Test on device
/project:device-tester
```

### 9.3 Before Committing

```bash
# Run tests
swift test

# Run linting
swiftlint

# Backend tests (if applicable)
cd functions && npm test
```

### 9.4 Code Review

```bash
# Request review with audits
/project:ios-superpowers review
```

### 9.5 If Build Fails

```bash
# Debug build failure
/project:ios-debug <issue>

# Or use specific Axiom commands
/axiom:axiom-xcode-debugging
/axiom:axiom-build-debugging
```

---

## 10. Related Documentation

- **Project Instructions:** `CLAUDE.md`
- **Claude Configuration:** `.claude/README.md`
- **Commands Reference:** `.claude/commands/README.md`
- **ADRs:** `docs/adr/`
- **Specs:** `docs/specs/`
- **Plans:** `docs/plans/`
