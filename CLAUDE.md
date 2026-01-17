# Claude Code Quick Reference

**Tech Stack:** Swift 6.0 (iOS SPM), TypeScript (Firebase Functions), Python (AI Pipeline)
**Architecture:** SwiftUI-only (ADR-010), MVVM, Firebase Backend

---

## System Commands

Never use `rm -rf` - Use `trash`
Never use `find` - Use `fd`
Never use `grep` - Use `rg`

---

## Quick Commands

```bash
# iOS Development
/project:ios-superpowers <action> <context>  # Axiom-powered iOS workflows
/project:ios-debug <issue>                   # Debug iOS issue with Axiom skills
/project:device-tester                       # Iterative testing on physical device w-16e
/axiom:apple-docs-research                   # Fetch Apple Developer documentation

# Backend Operations
/project:backend-superpowers                 # Firebase + GCP unified skill (59 MCP tools)
/project:gcp-deploy <fn>                     # Deploy Cloud Function with verification
```

---

## iOS Superpowers (REQUIRED)

**CRITICAL:** For ALL iOS/Swift work, use `ios-superpowers` instead of raw superpowers skills.

This ensures Apple documentation is fetched via `/axiom:apple-docs-research` before any workflow:

```bash
/project:ios-superpowers brainstorm <topic>     # Instead of superpowers:brainstorming
/project:ios-superpowers plan <feature>         # Instead of superpowers:writing-plans
/project:ios-superpowers execute <plan-path>    # Instead of superpowers:executing-plans
/project:ios-superpowers review                 # Instead of superpowers:requesting-code-review
/project:ios-superpowers debug <issue>          # Instead of superpowers:systematic-debugging
/project:ios-superpowers tdd <feature>          # Instead of superpowers:test-driven-development
/project:ios-superpowers parallel <tasks>       # Instead of superpowers:dispatching-parallel-agents
```

**Why:** Ensures Swift 6 concurrency patterns, SwiftUI APIs, and iOS frameworks are verified against current Apple documentation before implementation.

---

## Backend Superpowers (Firebase + GCP + Gemini)

**Skill:** `backend-superpowers` - Unified Firebase, GCP, and Gemini operations

Use for ALL backend work:

```bash
# Invoke the skill for Firebase/GCP/Gemini context
Skill(skill="backend-superpowers")
```

**Domain Routing:**
- Gemini patterns (tool calling, thought signatures) → Routes to `gemini-integration` skill
- Firebase/GCP patterns → Uses MCP tools directly

**Capabilities (59 MCP tools + Gemini routing):**

| Domain | Tools | Examples |
|--------|-------|----------|
| **Gemini** | routing | Tool calling, thought signatures, AI pipeline code |
| Firestore | 4 | Query, get, delete documents |
| Cloud Functions | 2 | List functions, get logs |
| Auth | 3 | Get/update users, SMS policy |
| FCM | 1 | Send push notifications |
| Remote Config | 2 | Get/update feature flags |
| RTDB | 2 | Get/set realtime data |
| Security Rules | 2 | Validate, get rules |
| Project Mgmt | 12 | Create projects, apps, init |
| Cloud Logging | 6 | Query logs, sinks, views |
| Monitoring | 4 | Metrics, time series, alerts |
| Tracing | 2 | List/get distributed traces |
| Error Reporting | 1 | Stack trace analysis |
| Cloud Storage | 17 | Buckets, objects, IAM |
| GCloud CLI | 1 | General gcloud commands |

**Note:** `firebase-superpowers` and `gcp-superpowers` are deprecated. Use `backend-superpowers` instead.

---

## Repository Structure

```
├── .claude/           # Claude automation (agents, commands, hooks, docs)
├── .github/           # CI/CD workflows (10 workflows)
├── Sources/           # Swift source (MVVM modules)
├── Tests/             # XCTest suites
├── functions/         # Firebase Cloud Functions (TypeScript)
├── docs/              # Symlink to spec-kit/docs/ (ADRs, specs, plans)
└── scripts/           # Setup and validation
```

---

## Critical Constraints

- **iOS Superpowers:** Use `/project:ios-superpowers` for ALL iOS work - **P0 requirement** (ensures Apple docs grounding)
- **ADR-010:** SwiftUI-only - `import UIKit` in Views/ViewModels is **P0 violation** (infrastructure OK)
- **Apple Docs:** iOS code changes require `axiom:` verification (auto-invoked by ios-superpowers)
- **Branch naming:** `feature/`, `fix/`, `docs/`, `chore/`, `test/`, `refactor/` only
- **Commits:** Conventional Commits (`feat:`, `fix:`, `docs:`, etc.)
- **TDD:** Write tests first, 80%+ coverage target

---

## ⚠️ CRITICAL: docs/ Symlink

**Remote:** `docs/` → actual files (not symlink)

**❌ NEVER delete files from docs/ or commit docs/ deletions**

---

## 📱 Device Screenshots (Iterative Development)

**Command:** `/project:device-tester` - Iterative testing on physical device w-16e
**Location:** `./screenshots/` → symlink to iCloud

**ALWAYS check for new screenshots** when debugging UI issues or iterating on device:

```bash
ls -lt screenshots/ | head -5    # Most recent first
```

**Workflow:**

1. User takes screenshot on device (w-16e)
2. Screenshot syncs via iCloud to `./screenshots/`
3. **Claude reads the screenshot** (multimodal) to analyze UI state
4. Fix issues → redeploy → repeat

**When user mentions a screenshot or UI issue:** Always `ls screenshots/` first to find the latest file, then read it.

---

## Workflow

### Before Starting

```bash
git checkout main && git pull
git checkout -b feature/your-feature
./scripts/validate-environment.sh

```

### During Development

- **Use `/project:ios-superpowers`** for all planning, debugging, code review, and TDD workflows
- Follow MVVM pattern (ViewModels in `Sources/`)
- TDD: Write failing test → implement → verify → commit
- SwiftUI only, no UIKit for UI (infrastructure exceptions per ADR-010)
- \*\*

### If Build Fails

```bash
/project:ios-debug <issue>
/axiom:axiom-xcode-debugging
/axiom:axiom-build-debugging
```

### Before Committing

```bash
swift test              # All tests must pass
swiftlint              # Zero warnings required
```

---

## CI/CD

**Required checks:** ios-build-check, backend-validation, security-pr-review
**Debug:** Comment `@claude` in PR

## Common Tasks

```bash
swift test                           # Run all tests
firebase deploy --only firestore:rules
```

---

## Documentation

**Specs:** `docs/specs/` | **Plans:** `docs/plans/` | **Issues**: `docs/issues/`

