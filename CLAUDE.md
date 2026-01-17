# Claude Code Quick Reference

**Tech Stack:** Swift 6.0 (iOS SPM), TypeScript (Firebase Functions), Python (AI Pipeline)
**Architecture:** SwiftUI-only (ADR-010), MVVM, Firebase Backend

---

## Quick Commands

```bash
/ios-sprint <spec>      # Start iOS sprint from spec document
/ios-debug <issue>      # Debug iOS issue with Axiom skills
/device-tester          # Iterative testing on physical device w-16e
/gcp-deploy <fn>        # Deploy Cloud Function with verification
/validate-docs          # Check docs for broken links, staleness
/check-drift            # Verify ADR compliance (P0/P1/P2)
/show-sprint-status     # Display sprint progress
```

---

## iOS Superpowers (REQUIRED)

**CRITICAL:** For ALL iOS/Swift work, use `ios-superpowers` instead of raw superpowers skills.

This ensures Apple documentation is fetched before any workflow:

```bash
/ios-superpowers brainstorm <topic>     # Instead of superpowers:brainstorming
/ios-superpowers plan <feature>         # Instead of superpowers:writing-plans
/ios-superpowers execute <plan-path>    # Instead of superpowers:executing-plans
/ios-superpowers review                 # Instead of superpowers:requesting-code-review
/ios-superpowers debug <issue>          # Instead of superpowers:systematic-debugging
/ios-superpowers tdd <feature>          # Instead of superpowers:test-driven-development
/ios-superpowers parallel <tasks>       # Instead of superpowers:dispatching-parallel-agents
```

**Why:** Ensures Swift 6 concurrency patterns, SwiftUI APIs, and iOS frameworks are verified against current Apple documentation before implementation.

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

- **iOS Superpowers:** Use `/ios-superpowers` for ALL iOS work - **P0 requirement** (ensures Apple docs grounding)
- **ADR-010:** SwiftUI-only - `import UIKit` in Views/ViewModels is **P0 violation** (infrastructure OK)
- **Apple Docs:** iOS code changes require `apple-docs-fetcher` verification (auto-invoked by ios-superpowers)
- **Branch naming:** `feature/`, `fix/`, `docs/`, `chore/`, `test/`, `refactor/` only
- **Commits:** Conventional Commits (`feat:`, `fix:`, `docs:`, etc.)
- **TDD:** Write tests first, 80%+ coverage target
- **Budget:** $554/month (monitored by cost-watchdog)

---

## ⚠️ CRITICAL: docs/ Symlink

**Local:** `docs/` → symlink to `~/code/spec-kit/docs/`
**Remote:** `docs/` → actual files (not symlink)

**❌ NEVER delete files from docs/ or commit docs/ deletions**
**✅ To sync docs:** `./.claude/scripts/sync-docs.sh`

Git shows docs/ as "D" (deleted) - this is **expected** (symlink vs actual files)

---

## 📱 Device Screenshots (Iterative Development)

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

# Regenerate Xcode project if needed
./scripts/regenerate-xcode-project.sh
```

### During Development
- **Use `/ios-superpowers`** for all planning, debugging, code review, and TDD workflows
- Follow MVVM pattern (ViewModels in `Sources/`)
- TDD: Write failing test → implement → verify → commit
- SwiftUI only, no UIKit for UI (infrastructure exceptions per ADR-010)
- Deploy: `./scripts/sim.sh --device w-16e`

### If Build Fails
```bash
# Regenerate clean Xcode project
./scripts/regenerate-xcode-project.sh --yes
./scripts/sim.sh --device w-16e
```

### Before Committing
```bash
swift test              # All tests must pass
swiftlint              # Zero warnings required
/check-drift           # P0 violations block merge
```

---

## CI/CD

**Required checks:** ios-build-check, backend-validation, security-pr-review
**Debug:** Comment `@claude` in PR

## Common Tasks

```bash
swift test && /check-drift           # Test + compliance
firebase deploy --only firestore:rules
```

---

## Documentation

**Setup:** `.claude/docs/REPOSITORY-SETUP-CHECKLIST-001.md`
**ADRs:** `docs/adr/` | **Plans:** `docs/plans/` | **Automation:** `.claude/docs/`

---

**Updated:** 2026-01-16
- Added /device-tester for iterative physical device testing
- Added screenshots/ symlink to iCloud for device screenshot workflow
- Added /ios-sprint, /ios-debug, /gcp-deploy commands
- Added firebase-superpowers, gcp-superpowers, gemini-integration skills
- Updated verified-stage-development with agent routing matrix