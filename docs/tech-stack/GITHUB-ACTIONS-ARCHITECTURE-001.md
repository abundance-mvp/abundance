# GitHub Actions CI/CD Architecture

**ID**: GITHUB-ACTIONS-ARCHITECTURE-001
**Created**: 2025-11-14
**Status**: Approved
**Scope**: CI/CD pipeline design for Abundance MVP

## Overview

GitHub Actions provides automated testing, security scanning, and deployment workflows. This document specifies the architecture, optimization strategies, and integration patterns.

## Workflow Catalog

### 1. iOS Build Check (`ios-build-check.yml`)

**Trigger**: Push to `main`, PRs modifying `ios/**`

**Jobs**:
1. **swift-lint**: SwiftLint with strict mode
2. **build**: Swift package build with Xcode 16
3. **test**: Unit + integration tests with code coverage

**Key optimizations**:
- **Caching**: Swift packages via `actions/cache@v4`
  ```yaml
  - uses: actions/cache@v4
    with:
      path: .build
      key: ${{ runner.os }}-spm-${{ hashFiles('Package.resolved') }}
  ```
- **Conditional execution**: Only run if `ios/**` changed
- **Parallel tests**: Test suite split across 2 runners

**Success criteria**:
- ✅ SwiftLint: Zero warnings in strict mode
- ✅ Build: Xcode 16.0, Swift 6.0
- ✅ Tests: >80% code coverage

**Cost**: ~$0.008/run (macOS runner, 4 minutes avg)

---

### 2. Backend Validation (`backend-validation.yml`)

**Trigger**: Push to `main`, PRs modifying `backend/**`

**Jobs**:
1. **typescript-lint**: ESLint + Prettier check
2. **build**: TypeScript compilation
3. **test**: Jest unit tests
4. **rules-lint**: Firestore/Storage rules validation

**Key optimizations**:
- **Caching**: npm packages via `actions/cache@v4`
  ```yaml
  - uses: actions/cache@v4
    with:
      path: ~/.npm
      key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
  ```
- **Firebase emulator**: Local Firestore for rule testing
  ```yaml
  - run: firebase emulators:exec --only firestore "npm test"
  ```

**Success criteria**:
- ✅ ESLint: Zero errors, <5 warnings
- ✅ Build: TypeScript 5.3 strict mode
- ✅ Tests: >90% coverage (Firebase Functions critical)
- ✅ Rules: Firestore rules pass security audit

**Cost**: ~$0.002/run (Ubuntu runner, 3 minutes avg)

---

### 3. AI Pipeline Validation (`ai-pipeline-check.yml`)

**Trigger**: Push to `main`, PRs modifying `ai-pipeline/**`

**Jobs**:
1. **python-lint**: Ruff + Black formatting
2. **type-check**: mypy strict mode
3. **test**: pytest with coverage
4. **benchmark**: Latency tests for Claude/Gemini calls

**Key optimizations**:
- **Caching**: pip packages + pytest cache
- **Secrets**: ANTHROPIC_API_KEY, GOOGLE_API_KEY in environment
- **Benchmarking**: Fail if P95 latency >2s (per ADR-005)

**Success criteria**:
- ✅ Lint: Ruff clean, Black formatted
- ✅ Types: mypy 100% typed (strict mode)
- ✅ Tests: >85% coverage
- ✅ Benchmark: P95 latency <2s

**Cost**: ~$0.005/run + API costs (~$0.10 for test dataset)

---

### 4. Spec Validation (`spec-validation.yml`)

**Trigger**: Push to `main`, PRs modifying `docs/**`

**Jobs**:
1. **spec-lint**: Validate all spec documents (PRDs, ADRs, Design Docs)
2. **link-check**: Verify internal links
3. **context-map**: Validate context-map.json integrity

**Key optimizations**:
- **Custom linter**: `.claude/commands/validate-docs.md`
- **Doc-reviewer agent**: Claude Code integration
  ```yaml
  - name: Run doc-reviewer
    run: claude agent run doc-reviewer docs/
  ```

**Success criteria**:
- ✅ All specs follow template (PRD-TEMPLATE.md, etc.)
- ✅ Zero broken internal links
- ✅ context-map.json valid JSON with all stages

**Cost**: ~$0.001/run (documentation only, fast)

---

### 5. Security PR Review (`security-pr-review.yml`)

**Trigger**: PR opened, synchronize

**Jobs**:
1. **owasp-scan**: Check for OWASP Top 10 patterns
2. **secret-scan**: Detect hardcoded secrets
3. **dependency-audit**: npm/Swift package vulnerabilities

**Key integrations**:
- **Changed files**: `tj-actions/changed-files@v44`
  ```yaml
  - uses: tj-actions/changed-files@v44
    id: changed
  - name: Scan changed files
    run: ./scripts/security-scan.sh ${{ steps.changed.outputs.all_changed_files }}
  ```
- **CodeQL**: GitHub native security scanning
- **Dependabot**: Automated dependency updates

**Success criteria**:
- ✅ Zero critical vulnerabilities
- ✅ No hardcoded secrets (API keys, passwords)
- ✅ All dependencies up-to-date or justified in ADR

**Cost**: ~$0.003/run (security scanning)

---

### 6. Claude Code Action - CI Fix (`claude-code-action-ci-fix.yml`)

**Trigger**: Issue comment containing `@claude`

**Behavior**:
1. Detect `@claude` mention in PR comment
2. Fetch CI failure logs
3. Invoke Claude Code to analyze and suggest fixes
4. Post comment with recommendations

**Key pattern**:
```yaml
on:
  issue_comment:
    types: [created]

jobs:
  debug-ci:
    if: |
      github.event.issue.pull_request &&
      contains(github.event.comment.body, '@claude')
    steps:
      - name: Fetch CI logs
        run: gh run view ${{ github.run_id }} --log-failed > ci-logs.txt

      - name: Invoke Claude Code
        run: |
          claude analyze ci-logs.txt \
            --context "PR #${{ github.event.issue.number }}" \
            --output fix-suggestions.md

      - name: Post comment
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs')
            const suggestions = fs.readFileSync('fix-suggestions.md', 'utf8')
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              body: `## CI Debugging\n\n${suggestions}`
            })
```

**Success criteria**:
- ✅ Responds within 2 minutes of @mention
- ✅ Provides actionable fix suggestions
- ✅ Links to relevant ADRs/docs

**Cost**: ~$0.50/invocation (Claude API call for log analysis)

---

### 7. Documentation Auto-Update (`docs-auto-update.yml`)

**Trigger**: Push to `main` modifying `docs/**`, weekly schedule

**Jobs**:
1. **generate-toc**: Update table of contents in README
2. **update-context-map**: Refresh context-map.json timestamps
3. **changelog**: Auto-generate CHANGELOG.md from commits

**Key automation**:
- **TOC generation**: `markdown-toc` npm package
- **Context map**: Python script to update `last_updated` fields
- **Changelog**: Conventional Commits → semantic versioning

**Success criteria**:
- ✅ TOCs always reflect current structure
- ✅ context-map.json timestamps accurate
- ✅ CHANGELOG.md updated post-merge

**Cost**: ~$0.001/run (minimal computation)

---

### 8. Changelog Generation (`changelog-on-release.yml`)

**Trigger**: Tag push (e.g., `v1.0.0`)

**Jobs**:
1. **generate-changelog**: Parse commits since last tag
2. **create-release**: GitHub Release with changelog
3. **notify**: Post to Slack #releases channel

**Key pattern**:
```yaml
on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - name: Generate changelog
        run: |
          git log $(git describe --tags --abbrev=0 HEAD^)..HEAD \
            --pretty=format:"- %s (%h)" > RELEASE_NOTES.md

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          body_path: RELEASE_NOTES.md
          draft: false
```

**Success criteria**:
- ✅ Release notes include all commits since last tag
- ✅ Conventional Commits formatted properly
- ✅ Slack notification sent

**Cost**: ~$0.001/release (triggered on tags only)

---

## Workflow Optimization Strategies

### 1. Caching

**Strategy**: Cache dependencies to reduce build time

**Implementation**:
- Swift packages: `.build/` directory
- npm modules: `~/.npm/` directory
- pip packages: `~/.cache/pip/` directory

**Impact**:
- iOS builds: 8 min → 3 min (62% faster)
- Backend builds: 5 min → 2 min (60% faster)

**Cost savings**: ~$0.005/run × 200 runs/month = $1/month

---

### 2. Conditional Execution

**Strategy**: Only run workflows when relevant files change

**Implementation**:
```yaml
on:
  push:
    paths:
      - 'ios/**'
      - 'Package.swift'
  pull_request:
    paths:
      - 'ios/**'
```

**Impact**:
- Docs-only PRs: Skip iOS/backend workflows (save 10 min)
- Backend-only PRs: Skip iOS workflows (save 8 min)

**Cost savings**: ~40% reduction in total CI minutes

---

### 3. Parallel Execution

**Strategy**: Run independent jobs concurrently

**Implementation**:
```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    # No dependencies, runs immediately

  test:
    runs-on: ubuntu-latest
    # Runs parallel to lint

  build:
    needs: [lint, test]
    # Waits for both to complete
```

**Impact**:
- Total workflow time: 15 min → 8 min (sequential → parallel)

---

### 4. Matrix Builds (Future)

**Strategy**: Test across multiple environments

**Use case**: iOS compatibility (iOS 18, iOS 17)

**Implementation**:
```yaml
strategy:
  matrix:
    ios-version: [18.0, 17.5]
    xcode-version: [16.0, 15.4]
steps:
  - name: Test on iOS ${{ matrix.ios-version }}
    run: swift test --platform ios-${{ matrix.ios-version }}
```

**Deferred**: MVP targets iOS 18 only per ADR-001

---

## Integration Patterns

### Claude Code + GitHub Actions

**Pattern 1**: Invoke agents from workflows
```yaml
- name: Check ADR compliance
  run: claude agent run drift-detector --severity P0
```

**Pattern 2**: CI-triggered Claude analysis
```yaml
- name: Analyze test failures
  if: failure()
  run: |
    claude analyze test-results.xml \
      --output failure-report.md
```

### Branch Protection Rules

**Protected branches**: `main`, `release/*`

**Required checks**:
- ✅ iOS Build Check (ios-build-check)
- ✅ Backend Validation (backend-validation)
- ✅ Security PR Review (security-pr-review)

**Config** (set via GitHub UI or API):
```json
{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "ios-build-check",
      "backend-validation",
      "security-pr-review"
    ]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1
  }
}
```

---

## Cost Analysis

**Monthly estimate** (30 days, 10 PRs/week):

| Workflow | Runs/Month | Cost/Run | Total |
|----------|------------|----------|-------|
| iOS Build Check | 80 | $0.008 | $0.64 |
| Backend Validation | 120 | $0.002 | $0.24 |
| AI Pipeline Check | 40 | $0.115 | $4.60 |
| Spec Validation | 60 | $0.001 | $0.06 |
| Security PR Review | 40 | $0.003 | $0.12 |
| CI Fix (Claude) | 10 | $0.500 | $5.00 |
| Docs Auto-Update | 20 | $0.001 | $0.02 |
| Changelog Generation | 4 | $0.001 | $0.00 |

**Total**: ~$10.68/month (1.9% of $554 total budget)

**Within budget**: Yes (allocation: $15/month per COST-MODEL-001)

---

## Monitoring and Alerts

### GitHub Actions Insights

**Metrics to track**:
- Workflow success rate (target: >95%)
- Average run time (track week-over-week)
- Cache hit rate (target: >80%)

**Dashboard**: GitHub Actions > Insights > Workflow usage

### Cost Monitoring

**Alert thresholds**:
- Daily spend >$1 → Slack notification
- Monthly projected >$15 → Email alert

**Integration**: cost-watchdog agent monitors GitHub billing API

---

## References

- **ADR-025**: Claude Code integration strategy
- **DEVELOPMENT-WORKFLOW-001**: Git branching strategy
- **DEVELOPMENT-WORKFLOW-002**: PR creation automation
- **COST-MODEL-001**: Budget allocation
- **CLAUDE-CODE-AUTOMATION-001**: Hook and agent architecture

## Changelog

- **2025-11-14**: Initial version with 8 workflows
