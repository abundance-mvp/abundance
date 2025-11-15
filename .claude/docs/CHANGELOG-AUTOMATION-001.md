# CHANGELOG Automation Strategy

**ID**: CHANGELOG-AUTOMATION-001
**Created**: 2025-11-14
**Status**: Approved
**Scope**: Automated CHANGELOG.md generation for Abundance MVP

## Overview

This document specifies the automated CHANGELOG.md generation strategy using Conventional Commits, GitHub Actions, and semantic versioning.

**Format**: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
**Versioning**: [Semantic Versioning 2.0.0](https://semver.org/)

---

## 1. Conventional Commits

### Commit Message Format

**Pattern**:
```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types**:
- `feat`: New feature (MINOR version bump)
- `fix`: Bug fix (PATCH version bump)
- `docs`: Documentation only
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring (no behavior change)
- `perf`: Performance improvement
- `test`: Test additions or fixes
- `chore`: Build process, dependencies, etc.
- `ci`: CI/CD configuration changes
- `BREAKING CHANGE`: Breaking API change (MAJOR version bump)

**Examples**:
```bash
# Feature commit (MINOR bump)
git commit -m "feat(auth): add biometric authentication

Implements Face ID/Touch ID login per PRD-001.
Refs: ADR-009 (iOS biometric integration)

🤖 Generated with [Claude Code](https://claude.com/claude-code)"

# Bug fix (PATCH bump)
git commit -m "fix(firestore): resolve query pagination issue

Pagination cursor was not persisting across sessions.
Closes #42"

# Breaking change (MAJOR bump)
git commit -m "feat(api): migrate to v2 authentication API

BREAKING CHANGE: Auth tokens now require 'Bearer ' prefix.
Migration guide: docs/MIGRATION-v2.md"
```

---

## 2. CHANGELOG.md Structure

### Format

**File**: `CHANGELOG.md` (project root)

**Template**:
```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- New features not yet released

### Fixed
- Bug fixes not yet released

## [1.0.0] - 2025-12-01

### Added
- Initial MVP release
- Barcode scanning with camera integration
- AI-powered product analysis (Claude + Gemini)
- Recommendations based on user criteria
- Cloud Firestore for user data persistence

### Security
- Firestore security rules enforcing user isolation
- Sign in with Apple integration

## [0.2.0] - 2025-11-20

### Added
- Biometric authentication (Face ID/Touch ID)
- Offline mode with local persistence

### Fixed
- Query pagination cursor persistence
- Image upload memory leak

## [0.1.0] - 2025-11-01

### Added
- Project initialization
- CI/CD pipeline setup
- Claude Code automation infrastructure
```

---

## 3. Automated Generation

### GitHub Action Workflow

**Location**: `.github/workflows/changelog-on-release.yml`

**Trigger**: Tag push (e.g., `v1.0.0`)

**Process**:
1. Fetch all commits since last tag
2. Parse Conventional Commits
3. Group by type (Added, Fixed, Changed, etc.)
4. Generate CHANGELOG.md section
5. Create GitHub Release with notes
6. Commit updated CHANGELOG.md to main

**Workflow**:
```yaml
name: Update Changelog on Release

on:
  push:
    tags:
      - 'v*'

jobs:
  changelog:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write

    steps:
      - name: Checkout repo
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for git log

      - name: Get previous tag
        id: prev_tag
        run: |
          PREV_TAG=$(git describe --tags --abbrev=0 HEAD^)
          echo "tag=$PREV_TAG" >> $GITHUB_OUTPUT

      - name: Generate changelog
        id: changelog
        run: |
          # Extract commits since last tag
          COMMITS=$(git log ${{ steps.prev_tag.outputs.tag }}..HEAD \
            --pretty=format:"%s|||%b" \
            --no-merges)

          # Parse commits by type
          echo "## [${{ github.ref_name }}] - $(date +%Y-%m-%d)" > release-notes.md
          echo "" >> release-notes.md

          # Added (feat)
          echo "### Added" >> release-notes.md
          echo "$COMMITS" | grep "^feat" | sed 's/feat(\(.*\)): \(.*\)|||.*/- **\1**: \2/' >> release-notes.md
          echo "" >> release-notes.md

          # Fixed (fix)
          echo "### Fixed" >> release-notes.md
          echo "$COMMITS" | grep "^fix" | sed 's/fix(\(.*\)): \(.*\)|||.*/- **\1**: \2/' >> release-notes.md
          echo "" >> release-notes.md

          # Changed (refactor, perf)
          echo "### Changed" >> release-notes.md
          echo "$COMMITS" | grep -E "^(refactor|perf)" | sed 's/\(.*\)(\(.*\)): \(.*\)|||.*/- **\2**: \3/' >> release-notes.md
          echo "" >> release-notes.md

          # Breaking changes
          if echo "$COMMITS" | grep -q "BREAKING CHANGE"; then
            echo "### ⚠️ BREAKING CHANGES" >> release-notes.md
            echo "$COMMITS" | grep "BREAKING CHANGE" | sed 's/.*BREAKING CHANGE: \(.*\)/- \1/' >> release-notes.md
            echo "" >> release-notes.md
          fi

      - name: Update CHANGELOG.md
        run: |
          # Insert new section after "## [Unreleased]"
          sed -i '/## \[Unreleased\]/r release-notes.md' CHANGELOG.md

          # Clear Unreleased section
          sed -i '/## \[Unreleased\]/,/## \[/{//!d}' CHANGELOG.md

      - name: Commit updated changelog
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add CHANGELOG.md
          git commit -m "docs: update CHANGELOG for ${{ github.ref_name }}

          🤖 Generated with [Claude Code](https://claude.com/claude-code)"
          git push origin main

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          body_path: release-notes.md
          draft: false
          prerelease: ${{ contains(github.ref_name, '-') }}  # e.g., v1.0.0-beta
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## 4. Semantic Versioning

### Version Bump Rules

**MAJOR** (1.0.0 → 2.0.0):
- Breaking API changes
- Commits with `BREAKING CHANGE` footer
- Example: Auth token format change

**MINOR** (1.0.0 → 1.1.0):
- New features (backwards-compatible)
- Commits with `feat:` type
- Example: Add biometric login

**PATCH** (1.0.0 → 1.0.1):
- Bug fixes (backwards-compatible)
- Commits with `fix:` type
- Example: Fix pagination bug

### Versioning Workflow

**Automated** (post-MVP):
```bash
# Install semantic-release
npm install --save-dev semantic-release @semantic-release/git @semantic-release/changelog

# Configure in package.json
{
  "release": {
    "branches": ["main"],
    "plugins": [
      "@semantic-release/commit-analyzer",
      "@semantic-release/release-notes-generator",
      "@semantic-release/changelog",
      "@semantic-release/npm",
      "@semantic-release/git"
    ]
  }
}

# Run on CI
npx semantic-release
```

**Manual** (MVP):
```bash
# Determine version bump
git log v0.2.0..HEAD --oneline | grep -E "^feat|^fix|BREAKING"

# Create tag
git tag v0.3.0 -m "Release v0.3.0"
git push origin v0.3.0

# GitHub Action triggers, updates CHANGELOG.md
```

---

## 5. Unreleased Section

### Purpose

Track changes not yet released (on `main` branch).

### Management

**Add to Unreleased**:
- Every PR merged to `main` adds changes here
- Grouped by type (Added, Fixed, Changed)
- Cleared on release (moved to version section)

**Example**:
```markdown
## [Unreleased]

### Added
- Camera permission request flow (PR #45)
- Product history view (PR #47)

### Fixed
- Image upload timeout on slow networks (PR #46)

### Changed
- Improved AI prompt for better accuracy (PR #48)
```

**Workflow**:
1. PR merged → Author updates Unreleased section
2. Pre-commit hook validates Unreleased has entry
3. On release → GitHub Action moves to version section

---

## 6. Pull Request Integration

### Enforce Changelog Updates

**GitHub Action**: `.github/workflows/pr-changelog-check.yml`

```yaml
name: PR Changelog Check

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Check CHANGELOG.md updated
        run: |
          # Check if CHANGELOG.md modified
          if ! git diff origin/main --name-only | grep -q "CHANGELOG.md"; then
            # Allow if only docs/tests/ci changed
            if git diff origin/main --name-only | grep -qE "^(docs|tests|\.github)"; then
              echo "✅ No changelog needed (docs/tests/ci only)"
              exit 0
            fi

            echo "❌ ERROR: CHANGELOG.md not updated"
            echo "Please add your changes to the [Unreleased] section"
            exit 1
          fi

          echo "✅ CHANGELOG.md updated"
```

**Enforcement**:
- PRs without CHANGELOG.md updates: CI fails
- Exception: docs-only, test-only, or CI-only changes

---

## 7. Release Process

### Step-by-Step

**1. Prepare release**:
```bash
# Ensure main is up-to-date
git checkout main
git pull

# Review Unreleased section
cat CHANGELOG.md

# Verify all PRs since last release are listed
git log v0.2.0..HEAD --oneline
```

**2. Create tag**:
```bash
# Determine next version (semantic versioning)
# Check for BREAKING CHANGE (major), feat (minor), fix (patch)

# Create annotated tag
git tag v0.3.0 -m "Release v0.3.0

- Added biometric authentication
- Fixed pagination bug
- Improved AI prompt accuracy"

# Push tag
git push origin v0.3.0
```

**3. GitHub Action triggers**:
- Generates changelog section from commits
- Updates CHANGELOG.md
- Creates GitHub Release with notes
- Commits updated CHANGELOG.md to main

**4. Verify release**:
- Check: https://github.com/owner/repo/releases
- Verify: CHANGELOG.md updated on main
- Test: Download release assets (if applicable)

---

## 8. Manual Changelog Entries

### When to use

**Automated parsing misses**:
- Migration guides
- Security advisories
- Deprecation notices

**How to add**:
1. Edit CHANGELOG.md directly
2. Add entry under appropriate version/type
3. Commit with `docs: update CHANGELOG`

**Example**:
```markdown
## [1.0.0] - 2025-12-01

### Added
- (auto-generated entries)

### Security
- **Manual entry**: Updated Firebase SDK to v10.20.0 to patch CVE-2024-XXXXX
  - Users must upgrade before 2026-01-01
  - Migration: No code changes required, run `pod update Firebase`
```

---

## 9. Tooling

### Commitlint

**Purpose**: Enforce Conventional Commits in CI

**Setup**:
```bash
npm install --save-dev @commitlint/cli @commitlint/config-conventional
```

**Config**: `.commitlintrc.json`
```json
{
  "extends": ["@commitlint/config-conventional"],
  "rules": {
    "type-enum": [2, "always", [
      "feat", "fix", "docs", "style", "refactor",
      "perf", "test", "chore", "ci"
    ]],
    "scope-enum": [2, "always", [
      "auth", "firestore", "storage", "ai", "ui", "api"
    ]]
  }
}
```

**Git hook**: `.git/hooks/commit-msg`
```bash
#!/bin/bash
npx --no -- commitlint --edit "$1"
```

---

### Standard Version (Alternative)

**Purpose**: Automate version bumping and CHANGELOG generation

**Deferred to post-MVP**: Manual tagging sufficient for MVP

**Future setup**:
```bash
npm install --save-dev standard-version

# Run on release
npx standard-version
# Auto-bumps version in package.json, updates CHANGELOG.md, creates tag
```

---

## 10. Best Practices

### Writing Good Commit Messages

**Do**:
- Use present tense: "add feature" not "added feature"
- Reference issues: "Closes #42"
- Include ADR references: "per ADR-009"
- Keep first line <50 chars

**Don't**:
- Vague messages: "fix bug", "update code"
- Missing scope: "feat: add thing" → "feat(auth): add thing"
- Skip body for complex changes

---

### Changelog Maintenance

**Monthly review**:
- Read full CHANGELOG.md for inconsistencies
- Ensure all releases have dates
- Verify links work (release tags, issue numbers)
- Check formatting (markdown rendering)

**Annual cleanup**:
- Archive old versions (>2 years) to CHANGELOG-archive.md
- Keep recent 2 years in main CHANGELOG.md

---

## References

- **Keep a Changelog**: https://keepachangelog.com/
- **Semantic Versioning**: https://semver.org/
- **Conventional Commits**: https://www.conventionalcommits.org/
- **DEVELOPMENT-WORKFLOW-001**: Git branching strategy
- **GITHUB-ACTIONS-ARCHITECTURE-001**: CI/CD workflows

## Changelog

- **2025-11-14**: Initial version with automated generation via GitHub Actions
