# Branch Protection Rules

**ID**: BRANCH-PROTECTION-RULES-001
**Created**: 2025-11-14
**Status**: Approved
**Scope**: GitHub branch protection configuration for Abundance MVP

## Overview

Branch protection rules enforce code quality, security, and review standards. This document specifies the protection rules for all critical branches.

## Protected Branches

### 1. `main` Branch

**Protection level**: Maximum

**Required status checks**:
- ✅ ios-build-check (Build, Lint, Test)
- ✅ backend-validation (Build, Lint, Test, Rules)
- ✅ security-pr-review (OWASP scan, Secret scan)
- ✅ spec-validation (Documentation checks)

**Pull request requirements**:
- Require pull request before merging: YES
- Required approving reviews: 1
- Dismiss stale reviews: YES (when new commits pushed)
- Require review from Code Owners: YES (CODEOWNERS file)

**Additional restrictions**:
- Require branches to be up-to-date: YES (must rebase before merge)
- Require conversation resolution: YES (all comments resolved)
- Require signed commits: NO (deferred to post-MVP)
- Restrict pushes: YES (admins only for hotfixes)

**Configuration** (apply via GitHub API or UI):
```json
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "ios-build-check",
      "backend-validation",
      "security-pr-review",
      "spec-validation"
    ]
  },
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "require_last_push_approval": false
  },
  "enforce_admins": false,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true
}
```

**Rationale**:
- `strict: true` prevents merging outdated branches (reduces conflicts)
- 1 approval balances speed with quality (solo dev during MVP)
- Code owners ensure domain expertise reviews

---

### 2. `release/*` Branches

**Protection level**: High

**Pattern**: `release/v*` (e.g., `release/v1.0`, `release/v1.1`)

**Required status checks**:
- Same as `main` (all workflows)

**Pull request requirements**:
- Required approving reviews: 2 (higher bar for releases)
- Require review from Code Owners: YES

**Additional restrictions**:
- Allow only merge commits: YES (no squash/rebase for releases)
- Tag creation required: YES (semantic versioning)

**Configuration**:
```json
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "ios-build-check",
      "backend-validation",
      "security-pr-review",
      "spec-validation",
      "changelog-on-release"
    ]
  },
  "required_pull_request_reviews": {
    "required_approving_review_count": 2,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true
  },
  "enforce_admins": true,
  "required_linear_history": true,
  "allow_force_pushes": false
}
```

**Rationale**:
- 2 approvals for releases (catches last-minute issues)
- Enforce admins ensures no shortcuts during crunch time
- Linear history simplifies rollback if needed

---

### 3. Feature Branches

**Pattern**: `feature/*`, `feat/*`

**Protection level**: Light (developer flexibility)

**Required status checks**:
- ✅ ios-build-check (if modifying ios/)
- ✅ backend-validation (if modifying backend/)
- Conditional based on changed files

**Pull request requirements**:
- Required approving reviews: 0 (self-merge allowed during rapid iteration)
- Auto-merge: Allowed (after CI passes)

**Configuration**:
```json
{
  "required_status_checks": {
    "strict": false,
    "contexts": []
  },
  "required_pull_request_reviews": null,
  "enforce_admins": false,
  "allow_force_pushes": true,
  "allow_deletions": true
}
```

**Rationale**:
- Feature branches are temporary (deleted after merge)
- Allow force push for cleanup before PR
- No required reviews (speed over process during solo dev)

---

### 4. Hotfix Branches

**Pattern**: `hotfix/*`

**Protection level**: Medium

**Required status checks**:
- ✅ ios-build-check (if iOS change)
- ✅ backend-validation (if backend change)
- ✅ security-pr-review (always, even for hotfixes)

**Pull request requirements**:
- Required approving reviews: 1
- Require review from Code Owners: YES
- Allow direct merge to `main`: YES (bypass for critical bugs)

**Configuration**:
```json
{
  "required_status_checks": {
    "strict": false,
    "contexts": [
      "security-pr-review"
    ]
  },
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "require_code_owner_reviews": true
  },
  "enforce_admins": false
}
```

**Rationale**:
- Hotfixes may need fast-track (strict: false allows outdated branches)
- Security scan always runs (even urgent fixes can't skip)
- 1 approval (speed + safety balance)

---

## CODEOWNERS File

**Purpose**: Auto-assign reviewers based on file paths

**Location**: `.github/CODEOWNERS`

**Configuration**:
```
# Default: Solo dev owns everything
* @yourusername

# iOS code requires iOS expertise
/ios/ @yourusername
/Package.swift @yourusername

# Backend requires backend expertise
/backend/ @yourusername
/firestore.rules @yourusername

# Specs require PM/architect review
/docs/specs/ @yourusername
/docs/adr/ @yourusername

# Security-sensitive files require security review
/backend/functions/src/auth/ @yourusername
/firestore.rules @yourusername
/.github/workflows/security-*.yml @yourusername
```

**Rationale**:
- During MVP, solo dev owns all areas
- Post-launch, expand to team (e.g., `@ios-team`, `@backend-team`)
- Security files always get scrutiny

---

## Bypass Permissions

**Who can bypass**:
- Repository admins (for emergency hotfixes only)
- GitHub Actions bot (for automated commits like CHANGELOG.md)

**Audit trail**:
- All bypasses logged in GitHub audit log
- Weekly review: Check for misuse

**Configuration**:
```json
{
  "enforce_admins": false,
  "restrictions": {
    "users": [],
    "teams": [],
    "apps": ["github-actions"]
  }
}
```

---

## Rulesets (Future Enhancement)

**GitHub Rulesets** (beta feature, deferred to post-MVP):
- Centralized rule management across repos
- More granular conditions (e.g., file path patterns)
- Better enforcement of commit signing

**Migration plan**:
- Q2 2026: Evaluate GitHub Rulesets for multi-repo support
- Migrate from branch protection to rulesets if stable

---

## Setup Instructions

### 1. Via GitHub UI

1. Navigate to: Settings > Branches
2. Click "Add rule"
3. Enter branch name pattern (e.g., `main`)
4. Enable required status checks:
   - ☑ Require status checks to pass before merging
   - ☑ Require branches to be up to date before merging
   - Select: ios-build-check, backend-validation, security-pr-review
5. Enable pull request requirements:
   - ☑ Require a pull request before merging
   - Set: Require 1 approval
   - ☑ Dismiss stale pull request approvals
6. Save changes

### 2. Via GitHub API

```bash
# Set main branch protection
curl -X PUT \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/OWNER/REPO/branches/main/protection \
  -d @.github/protection-rules/main-branch.json

# Set release/* branch protection
curl -X PUT \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/OWNER/REPO/branches/release/*/protection \
  -d @.github/protection-rules/release-branch.json
```

**JSON files**: Store in `.github/protection-rules/` directory

### 3. Via Terraform (Infrastructure as Code)

```hcl
resource "github_branch_protection" "main" {
  repository_id = github_repository.abundance.id
  pattern       = "main"

  required_status_checks {
    strict   = true
    contexts = [
      "ios-build-check",
      "backend-validation",
      "security-pr-review"
    ]
  }

  required_pull_request_reviews {
    required_approving_review_count = 1
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true
  }

  enforce_admins = false
}
```

**Deferred**: MVP uses manual UI setup, Terraform in post-launch

---

## Monitoring and Compliance

### Weekly Checks

- Verify all required checks are enabled
- Review bypass audit log (should be empty except automated commits)
- Check CODEOWNERS file accuracy

### Monthly Review

- Evaluate status check effectiveness (false positive rate)
- Adjust required approvals based on team growth
- Update CODEOWNERS as team structure changes

### Metrics

Track in sprint retros:
- PRs blocked by branch protection: ~10% (healthy)
- Average time from PR open to merge: <24 hours
- Branch protection bypass count: 0 (except emergencies)

---

## References

- **ADR-025**: Claude Code integration strategy
- **DEVELOPMENT-WORKFLOW-001**: Git branching strategy
- **DEVELOPMENT-WORKFLOW-002**: PR creation automation
- **GITHUB-ACTIONS-ARCHITECTURE-001**: CI/CD workflows

## Changelog

- **2025-11-14**: Initial version with main, release/*, feature/*, hotfix/* rules
