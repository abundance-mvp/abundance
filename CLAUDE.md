# Claude Code Quick Reference

**Tech Stack:** Swift 6.0 (iOS SPM), TypeScript (Firebase Functions), Python (AI Pipeline)
**Architecture:** SwiftUI-only (ADR-010), MVVM, Firebase Backend

---

## Quick Commands

```bash
/validate-docs          # Check docs for broken links, staleness
/check-drift           # Verify ADR compliance (P0/P1/P2)
/troubleshoot          # Debug CI/CD failures
/show-sprint-status    # Display sprint progress
```

---

## Repository Structure

```
├── .claude/           # Claude automation (agents, commands, hooks, docs)
├── .github/           # CI/CD workflows (8 workflows)
├── Sources/           # Swift source (MVVM modules)
├── Tests/             # XCTest suites
├── functions/         # Firebase Cloud Functions (TypeScript)
├── docs/              # Symlink to spec-kit/docs/ (ADRs, specs, plans)
└── scripts/           # Setup and validation
```

---

## Critical Constraints

- **ADR-010:** SwiftUI-only - `import UIKit` is **P0 violation** (blocks PR)
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

## Workflow

### Before Starting
```bash
git checkout main && git pull
git checkout -b feature/your-feature
./scripts/validate-environment.sh
```

### During Development
- Follow MVVM pattern (ViewModels in `Sources/`)
- TDD: Write failing test → implement → verify → commit
- SwiftUI only, no UIKit for UI

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

**Updated:** 2025-11-15
