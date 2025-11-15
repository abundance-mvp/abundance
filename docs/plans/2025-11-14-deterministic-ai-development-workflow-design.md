# Deterministic AI Development Workflow Design

**Date**: 2025-11-14
**Status**: Design Complete - Ready for Stage 5.3 Implementation
**Context**: Brainstorming session to define enforcement mechanisms for deterministic AI-driven development

---

## Problem Statement

Ensure the Abundance app development workflow behaves **deterministically** throughout the entire development lifecycle by:

1. Creating clearly defined behaviors, instructions, and abstractions for AI agents to follow
2. Translating development workflow patterns into deterministic logic
3. Enforcing development standards outlined in workflow documents using available tools

**Key Requirement**: Strict enforcement of standards using Claude Code capabilities (hooks, commands, agents, plugins) integrated with git hooks and GitHub Actions.

---

## Architecture Overview

### Current Workflow (Stage 5.2)

```
User → /ios-sprint-executor → Superpowers Plugin → Code Implementation → PR
```

**Existing Documentation:**
- [DEVELOPMENT-WORKFLOW-001-git-branching-strategy](docs/validation/DEVELOPMENT-WORKFLOW-001-git-branching-strategy.md): Git branching strategy
- [DEVELOPMENT-WORKFLOW-002-pr-creation-automation](docs/validation/DEVELOPMENT-WORKFLOW-002-pr-creation-automation.md): PR creation automation
- [DEVELOPMENT-WORKFLOW-003-sprint-execution-guide](docs/validation/DEVELOPMENT-WORKFLOW-003-sprint-execution-guide.md): Sprint execution guide (7-phase lifecycle)
- [DEVELOPMENT-READINESS-CHECKLIST-001](docs/validation/DEVELOPMENT-READINESS-CHECKLIST-001.md): Prerequisites

**Gap Identified**: Documentation exists but enforcement mechanisms are **manual** - no automated guardrails.

---

### Proposed Enforcement Architecture (Stage 5.3)

```
┌────────────────────────────────────────────────────────────────┐
│                    ENFORCEMENT LAYERS                          │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  Layer 1: Claude Code Hooks (Pre-execution validation)        │
│    - pre-sprint.sh: Validate readiness checklist              │
│    - on-file-edit.sh: Template compliance                     │
│    - bash_command_validator.py: Enforce approved commands     │
│                                                                │
│  Layer 2: Claude Commands (Manual + Hook-invoked)             │
│    - /validate-docs: ADR cross-reference checks               │
│    - /check-drift: Scaffolding vs actual code drift           │
│    - /show-sprint-status: Progress tracking                   │
│                                                                │
│  Layer 3: Claude Agents (Spawned by hooks/commands)           │
│    - doc-reviewer: Enforces documentation quality             │
│    - drift-detector: Detects scaffolding drift                │
│    - cost-watchdog: Monitors AI API usage                     │
│                                                                │
│  Layer 4: Git Hooks (Local enforcement)                       │
│    - pre-commit: SwiftLint, ESLint, drift detection           │
│    - commit-msg: Conventional Commits format                  │
│    - pre-push: Block if CI would fail                         │
│                                                                │
│  Layer 5: GitHub Actions (CI/CD enforcement)                  │
│    - iOS build check                                           │
│    - Backend validation                                        │
│    - claude-code-action: Auto-fix failed CI                   │
│    - security-pr-review: Security analysis on PRs             │
│    - changelog-update: Auto-update CHANGELOG.md               │
│                                                                │
│  Layer 6: Required Plugins (Workflow extensions)              │
│    - code-review: Code review enforcement                     │
│    - feature-dev: Ad-hoc feature development                  │
│    - research-agent: Research capabilities                    │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

---

## Integration with ios-sprint-executor

### How Layers Interact (No Conflicts)

```
USER: /ios-sprint-executor sprint-2
  ↓
[.claude/hooks/pre-sprint.sh]
  ├─ Validates DEVELOPMENT-READINESS-CHECKLIST-001
  ├─ Checks git status clean
  └─ Confirms sprint plan exists
  ↓
ios-sprint-executor Phase 1: Setup
  └─ Loads docs, creates branch, fetches Apple docs
  ↓
ios-sprint-executor Phase 2: Planning
  └─ Invokes /superpowers:write-plan
  ↓
Gate 1: Human Approval
  ↓
ios-sprint-executor Phase 3: Execution
  └─ Invokes /superpowers:execute-plan
      ↓
      [.claude/hooks/on-file-edit.sh] ← Every file write
        └─ Enforces template compliance
      ↓
      Superpowers subagents write code
  ↓
ios-sprint-executor Phase 4: Code Review
  └─ Invokes superpowers:code-reviewer
  ↓
ios-sprint-executor Phase 5: PR Creation
  ↓
  [.git/hooks/pre-commit]
    ├─ SwiftLint validation
    ├─ ESLint validation
    └─ Drift detection
  ↓
  git commit + git push
  ↓
  gh pr create
  ↓
  [GitHub Action: on PR create]
    ├─ Runs CI checks (build, test)
    ├─ Triggers claude-code-action (if CI fails)
    └─ Spawns security-pr-review agent
  ↓
  [.claude/hooks/on-pr-create.sh]
    └─ Spawns doc-reviewer agent
        ├─ Validates ADR cross-references in code
        ├─ Checks DESIGN doc references
        └─ Enforces documentation quality standards
  ↓
PR ready for human review
```

**Key Insight**: Superpowers handles **implementation workflow** (TDD, batching, code quality). Project agents handle **compliance enforcement** (docs, drift, security). They're **complementary**, not conflicting.

---

## Detailed Component Specifications

### 1. Claude Code Hooks

#### `.claude/hooks/pre-sprint.sh`
**Purpose**: Validate environment before sprint execution
**Trigger**: Before `/ios-sprint-executor sprint-X`
**Actions**:
- Check DEVELOPMENT-READINESS-CHECKLIST-001 prerequisites
- Verify git status clean
- Confirm sprint plan exists
- Validate scaffolding files present
- Check API keys configured (Firebase, Anthropic, etc.)

**Exit codes**:
- 0: Ready to proceed
- 1: Prerequisites missing (blocks sprint execution)

---

#### `.claude/hooks/on-file-edit.sh`
**Purpose**: Enforce template compliance on file creation/edit
**Trigger**: Every file write during Phase 3 execution
**Actions**:
- Check Swift files have header comments with ADR references
- Validate test files follow TEST-EXAMPLE patterns
- Ensure TypeScript files follow CODE-EXAMPLE structure
- Block writes that violate template standards

**Templates enforced**:
- Swift: ADR cross-reference in header
- Test: Given/When/Then structure
- TypeScript: Provider interface compliance

---

#### `.claude/hooks/bash_command_validator.py`
**Purpose**: Enforce approved bash command usage (replaces CLAUDE.md guidance)
**Trigger**: Before any bash command execution
**Actions**:
- Whitelist approved commands (git, npm, xcodebuild, firebase, etc.)
- Block dangerous commands (rm -rf, chmod 777, etc.)
- Log all command invocations for audit trail
- Suggest safer alternatives when blocking

**Example**:
```python
# Block
$ rm -rf node_modules/
ERROR: Use 'npm clean-install' instead of 'rm -rf'

# Allow
$ npm ci
✓ Command approved: npm clean-install
```

**Reference**: https://github.com/anthropics/claude-code/blob/main/examples/hooks/bash_command_validator_example.py

---

### 2. Claude Commands

#### `/validate-docs`
**Purpose**: Manual check for ADR/DESIGN cross-references
**Usage**: Developer or hook invokes to validate documentation
**Actions**:
- Scan recent commits for code changes
- Check Swift/TypeScript files for ADR comments
- Validate cross-references exist in docs/adr/
- Report missing references

**Output**:
```
Documentation Validation Report:
✓ CameraView.swift: References ADR-010 (MVVM)
✗ VisionService.swift: Missing ADR reference (expected ADR-013)
✓ FirebaseAuth.swift: References ADR-005 (Authentication)

Score: 2/3 files validated (66%)
Recommendation: Add ADR-013 reference to VisionService.swift
```

---

#### `/check-drift`
**Purpose**: Detect drift between Stage 4 scaffolding and actual implementation
**Usage**: Invoked by pre-commit hook or manually
**Actions**:
- Compare `docs/tech-stack/Package.swift` vs `ios/Package.swift`
- Check `docs/tech-stack/firebase.json` vs `backend/firebase.json`
- Identify unauthorized changes to scaffolding
- Alert if dependencies added without documentation update

**Output**:
```
Drift Detection Report:
✗ ios/Package.swift: Added dependency 'Alamofire 6.0.0' (not in scaffolding)
✓ backend/firebase.json: Matches scaffolding
✗ backend/firestore.rules: Added collection 'analytics' (not documented)

Recommendation: Update scaffolding docs or revert unauthorized changes
```

---

#### `/show-sprint-status`
**Purpose**: Display current sprint progress
**Usage**: Developer checks status during sprint
**Actions**:
- Parse ios-sprint-executor state
- Show Phase 1-6 completion status
- List completed batches from Phase 3
- Display token budget remaining

**Output**:
```
Sprint 2 Status:
✅ Phase 1: Pre-Sprint Setup (COMPLETE)
✅ Phase 2: Planning (COMPLETE)
✅ Gate 1: Human Approval (APPROVED)
⏳ Phase 3: Execution (IN PROGRESS - Batch 2/4)
   ✅ Batch 1: CameraView UI (8K tokens, 45 min)
   ⏳ Batch 2: VisionService (10K tokens, 1.2 hours)
   ⏸️  Batch 3: Barcode detection (pending)
   ⏸️  Batch 4: Unit tests (pending)

Token Budget: 18K / 25K used (72%)
Next: Complete Batch 2, review, proceed to Batch 3
```

---

### 3. Claude Agents

#### `doc-reviewer.md`
**Purpose**: Enforce documentation quality standards on PRs
**Spawned by**: `.claude/hooks/on-pr-create.sh`
**Behaviors**:
- Read all changed files in PR
- Check for ADR/DESIGN/CODE-EXAMPLE cross-references
- Validate test coverage references TEST-EXAMPLEs
- Add PR comment with findings
- Block merge if critical issues found

**Agent Prompt**:
```markdown
You are a Documentation Review Agent for the Abundance MVP.

Your role: Enforce documentation quality standards per DEVELOPMENT-WORKFLOW-002.

When spawned on PR creation:
1. Read all changed Swift/TypeScript files
2. Check for cross-references:
   - ADR references in header comments
   - DESIGN doc references for patterns
   - CODE-EXAMPLE references for implementations
   - TEST-EXAMPLE references in test files
3. Validate references exist in docs/ directory
4. Add PR comment with findings:
   - ✓ Files with proper references
   - ✗ Files missing references
   - Score: X/Y files validated
5. If score < 80%, add label 'documentation-needed' and block merge

Never auto-fix - only report. Human decides whether to fix or override.
```

**Output** (PR comment):
```markdown
## 📚 Documentation Review

**Score: 8/10 files validated (80%)**

### ✅ Properly Documented
- `CameraView.swift`: ADR-010 (MVVM) ✓
- `CameraViewModel.swift`: ADR-010, DESIGN-027 ✓
- `VisionService.swift`: ADR-013 (DI), CODE-EXAMPLE-004 ✓
- `CameraViewTests.swift`: TEST-EXAMPLE-004 ✓

### ✗ Missing Documentation
- `BarcodeDetector.swift`: No ADR reference (expected ADR-013)
- `ImageProcessor.swift`: No CODE-EXAMPLE reference

### Recommendation
Add ADR/CODE-EXAMPLE references to files listed above before merging.

---
*Spawned by `.claude/hooks/on-pr-create.sh` | Powered by doc-reviewer agent*
```

---

#### `drift-detector.md`
**Purpose**: Detect scaffolding drift during development
**Spawned by**: `/check-drift` command or pre-commit hook
**Behaviors**:
- Compare Stage 4 scaffolding vs actual files
- Detect unauthorized dependency additions
- Flag new Firebase collections not in scaffolding
- Alert if security rules modified without documentation update

**Agent Prompt**:
```markdown
You are a Drift Detection Agent for the Abundance MVP.

Your role: Ensure actual implementation matches Stage 4 scaffolding.

When invoked:
1. Read Stage 4 scaffolding files:
   - docs/tech-stack/Package.swift
   - docs/tech-stack/firebase.json
   - docs/tech-stack/firestore.rules
   - docs/tech-stack/ai-provider-adapters.md
2. Compare against actual files:
   - ios/Package.swift
   - backend/firebase.json
   - backend/firestore.rules
3. Identify drift:
   - Added dependencies not in scaffolding
   - New Firestore collections not documented
   - Modified security rules without ADR update
4. Report findings with severity:
   - CRITICAL: Security rule changes
   - HIGH: New dependencies
   - MEDIUM: Configuration changes
   - LOW: Comments/formatting

Never auto-fix - only detect and report. Human decides whether drift is intentional.
```

---

#### `cost-watchdog.md`
**Purpose**: Monitor AI API usage and alert on budget thresholds
**Spawned by**: Scheduled GitHub Action (daily) or manual invocation
**Behaviors**:
- Query Firestore `costLogs` collection
- Aggregate daily/monthly AI provider costs
- Compare against budget thresholds (80% warning, 95% critical)
- Send Slack notification if threshold exceeded

**Agent Prompt**:
```markdown
You are a Cost Monitoring Agent for the Abundance MVP.

Your role: Monitor AI API usage and alert on budget overruns.

When invoked (daily schedule):
1. Query Firestore collection 'costLogs'
2. Aggregate costs by provider:
   - Gemini 2.5 Flash-Lite
   - Claude Haiku 4.5
   - Claude Sonnet 4.5 (batch API)
   - SerpAPI Google Lens
   - UPCitemdb
3. Calculate totals:
   - Today's spend
   - Month-to-date spend
   - Projected month-end spend
4. Check thresholds:
   - Budget: $100/month (per COST-MODEL-001)
   - Warn at 80%: $80
   - Critical at 95%: $95
5. If threshold exceeded:
   - Generate alert report
   - Post to Slack #abundance-alerts channel
   - Create GitHub issue with cost breakdown

Never block functionality - only alert. Human decides mitigation.
```

---

### 4. Git Hooks

#### `pre-commit`
**Actions**:
- Run SwiftLint on changed Swift files
- Run ESLint on changed TypeScript files
- Invoke `/check-drift` command
- Block commit if critical drift detected

**Script** (`scripts/setup-git-hooks.sh`):
```bash
#!/bin/bash
# Install git hooks

# Pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
echo "Running pre-commit checks..."

# SwiftLint
if command -v swiftlint &> /dev/null; then
  swiftlint lint --strict
  if [ $? -ne 0 ]; then
    echo "❌ SwiftLint failed"
    exit 1
  fi
fi

# ESLint
if command -v eslint &> /dev/null; then
  eslint backend/functions/src/**/*.ts
  if [ $? -ne 0 ]; then
    echo "❌ ESLint failed"
    exit 1
  fi
fi

# Drift detection
echo "Checking scaffolding drift..."
# Invoke Claude command
/check-drift
if [ $? -eq 2 ]; then
  echo "❌ CRITICAL drift detected - commit blocked"
  exit 1
fi

echo "✅ Pre-commit checks passed"
exit 0
EOF

chmod +x .git/hooks/pre-commit
```

---

#### `commit-msg`
**Actions**:
- Validate Conventional Commits format
- Block non-compliant messages

**Script**:
```bash
#!/bin/bash
commit_msg=$(cat "$1")

# Conventional Commits regex
pattern="^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?: .+"

if ! [[ "$commit_msg" =~ $pattern ]]; then
  echo "❌ Commit message must follow Conventional Commits format"
  echo "Example: feat(sprint-2): implement camera capture"
  exit 1
fi

echo "✅ Commit message valid"
exit 0
```

---

### 5. GitHub Actions

#### `claude-code-action-ci-fix.yml`
**Purpose**: Auto-fix failed CI builds using Claude
**Trigger**: When iOS build or backend tests fail
**Reference**: https://github.com/anthropics/claude-code-action

**Workflow**:
```yaml
name: Claude Code Action - CI Auto-Fix

on:
  workflow_run:
    workflows: ["iOS Build Check", "Backend Validation"]
    types:
      - completed

jobs:
  auto-fix:
    if: ${{ github.event.workflow_run.conclusion == 'failure' }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Troubleshoot and Fix
        uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          prompt: |
            The CI build failed. Analyze the error logs, identify the root cause,
            and create a fix. Follow these steps:

            1. Read workflow logs from ${{ github.event.workflow_run.id }}
            2. Identify failing test or build error
            3. Read relevant source files
            4. Apply fix following ADR/DESIGN patterns
            5. Run tests locally to verify fix
            6. Commit fix with message: "fix(ci): resolve [issue]"
            7. Push to branch

          github_token: ${{ secrets.GITHUB_TOKEN }}
```

---

#### `security-pr-review.yml`
**Purpose**: Security analysis on every PR
**Trigger**: PR opened or updated
**Reference**: https://github.com/anthropics/claude-code-action/blob/main/docs/solutions.md#security-focused-pr-reviews

**Workflow**:
```yaml
name: Security PR Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  security-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Security Analysis
        uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          prompt: |
            Perform security analysis on PR #${{ github.event.pull_request.number }}.

            Check for:
            1. OWASP Top 10 vulnerabilities (XSS, SQL injection, etc.)
            2. Sensitive data exposure (API keys, secrets in code)
            3. Firebase security rule violations
            4. Insecure API endpoints (missing authentication)
            5. Unsafe Swift code (force unwrapping, force casting)

            For each finding:
            - Severity: CRITICAL | HIGH | MEDIUM | LOW
            - File:line reference
            - Recommendation

            Add findings as PR comment. If CRITICAL found, request changes.

          github_token: ${{ secrets.GITHUB_TOKEN }}
```

---

#### `changelog-update.yml`
**Purpose**: Auto-update CHANGELOG.md post-launch
**Trigger**: Tag push (version release)
**Reference**: https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md

**Workflow**:
```yaml
name: Update CHANGELOG

on:
  push:
    tags:
      - 'v*'

jobs:
  update-changelog:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Generate Changelog Entry
        uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          prompt: |
            Generate CHANGELOG.md entry for version ${{ github.ref_name }}.

            Steps:
            1. Read git log since last tag
            2. Group commits by type (feat, fix, docs, etc.)
            3. Format per Conventional Commits:
               - Added: New features
               - Changed: Updates to existing features
               - Fixed: Bug fixes
               - Security: Security patches
            4. Prepend entry to CHANGELOG.md
            5. Commit with message: "chore(changelog): update for ${{ github.ref_name }}"

            Format:
            ```markdown
            ## [1.0.0] - 2025-11-14

            ### Added
            - Camera capture with barcode detection (#42)

            ### Fixed
            - Vision processing memory leak (#45)
            ```

          github_token: ${{ secrets.GITHUB_TOKEN }}

      - name: Commit and Push
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add CHANGELOG.md
          git commit -m "chore(changelog): update for ${{ github.ref_name }}"
          git push
```

---

### 6. Required Plugins

#### Code Review Plugin
**Source**: https://github.com/anthropics/claude-code/tree/main/plugins/code-review
**Purpose**: Enforce code review standards
**Installation**: `scripts/install-claude-plugins.sh` copies to `.claude/plugins/code-review/`
**Integration**: Superpowers `code-reviewer` uses this plugin for reviews

---

#### Feature Dev Plugin
**Source**: https://github.com/anthropics/claude-code/tree/main/plugins/feature-dev
**Purpose**: Ad-hoc feature development outside sprint workflow
**Usage**: `/feature-dev "Add dark mode toggle to settings"`
**Integration**: Independent of ios-sprint-executor, for quick features

---

#### Research Agent Plugin
**Source**: https://github.com/anthropics/claude-agent-sdk-demos/tree/main/research-agent
**Purpose**: Research capabilities for technical decisions
**Usage**: Invoked during Stage 6.x validations to research APIs
**Integration**: Used by validation stages, not sprint workflow

---

## Implementation Plan (Stage 5.3)

### Phase 1: Research (2-4 hours)
**Objective**: Understand Claude Code architecture and best practices

**Tasks**:
1. Study official documentation: https://code.claude.com/docs/en/plugins
2. Review Anthropic GitHub repos:
   - claude-code examples
   - claude-code-action patterns
   - Plugin architectures
3. Analyze community best practices: https://blog.fsck.com/2025/10/09/superpowers/
4. Document findings in `CLAUDE-CODE-AUTOMATION-001.md`

**Deliverables**:
- `docs/tech-stack/CLAUDE-CODE-AUTOMATION-001.md` (research findings)
- `docs/tech-stack/AI-AGENT-BEHAVIORS-001.md` (agent spawn patterns)

---

### Phase 2: Claude Code Setup (3-5 hours)
**Objective**: Create hooks, commands, and agents

**Tasks**:
1. Create `.claude/hooks/`:
   - `pre-sprint.sh`
   - `on-pr-create.sh`
   - `on-file-edit.sh`
   - `bash_command_validator.py`
2. Create `.claude/commands/`:
   - `validate-docs.md`
   - `check-drift.md`
   - `show-sprint-status.md`
3. Create `.claude/agents/`:
   - `doc-reviewer.md`
   - `drift-detector.md`
   - `cost-watchdog.md`
4. Install plugins:
   - code-review
   - feature-dev
   - research-agent

**Deliverables**:
- `.claude/` directory structure complete
- `scripts/setup-claude-hooks.sh`
- `scripts/install-claude-plugins.sh`

---

### Phase 3: GitHub Actions (2-4 hours)
**Objective**: Create CI/CD workflows with claude-code-action

**Tasks**:
1. Create workflows:
   - `claude-code-action-ci-fix.yml`
   - `security-pr-review.yml`
   - `changelog-update.yml`
2. Configure GCP VertexAI integration
3. Set up GitHub secrets (ANTHROPIC_API_KEY)
4. Test workflows on sample PR

**Deliverables**:
- `.github/workflows/` complete
- `docs/tech-stack/GITHUB-ACTIONS-ARCHITECTURE-001.md`

---

### Phase 4: Git Hooks (1-2 hours)
**Objective**: Local enforcement with git hooks

**Tasks**:
1. Create `scripts/setup-git-hooks.sh`
2. Implement `pre-commit` hook
3. Implement `commit-msg` hook
4. Test hooks with sample commits

**Deliverables**:
- `scripts/setup-git-hooks.sh`
- Git hooks installed and tested

---

### Phase 5: CHANGELOG Automation (1 hour)
**Objective**: Auto-update CHANGELOG.md post-launch

**Tasks**:
1. Create `CHANGELOG.md` template
2. Configure `changelog-update.yml` workflow
3. Document versioning strategy

**Deliverables**:
- `CHANGELOG.md`
- `docs/tech-stack/CHANGELOG-AUTOMATION-001.md`

---

### Phase 6: Integration Testing (2-3 hours)
**Objective**: Validate entire enforcement architecture

**Tasks**:
1. Test pre-sprint hook with `/ios-sprint-executor sprint-1`
2. Test file edit hook during Phase 3 execution
3. Test PR creation hooks (doc-reviewer agent)
4. Test git hooks (pre-commit, commit-msg)
5. Test GitHub Actions (CI fix, security review)

**Deliverables**:
- Integration test results
- Bug fixes if issues found

---

### Phase 7: Documentation (1-2 hours)
**Objective**: Document setup and usage

**Tasks**:
1. Update `REPOSITORY-SETUP-CHECKLIST-001.md`
2. Update `LOCAL-DEV-SETUP-001.md`
3. Create `BRANCH-PROTECTION-RULES-001.md`
4. Create checkpoint document

**Deliverables**:
- `docs/tech-stack/REPOSITORY-SETUP-CHECKLIST-001.md`
- `docs/tech-stack/LOCAL-DEV-SETUP-001.md`
- `docs/tech-stack/BRANCH-PROTECTION-RULES-001.md`
- `docs/checkpoints/CHECKPOINT-stage-5.3.md`

---

## Success Criteria

### Enforcement Validation

**Pre-Sprint Validation**:
- [ ] `/ios-sprint-executor sprint-1` blocked if prerequisites missing
- [ ] Hook displays specific missing prerequisites

**File Edit Enforcement**:
- [ ] Writing Swift file without ADR reference triggers warning
- [ ] Hook suggests which ADR to reference based on file type

**PR Creation Enforcement**:
- [ ] doc-reviewer agent spawns on every PR
- [ ] Agent comments with documentation score
- [ ] PR labeled 'documentation-needed' if score < 80%

**Git Hook Enforcement**:
- [ ] Pre-commit blocks commit with SwiftLint errors
- [ ] Commit-msg blocks non-Conventional Commits messages
- [ ] Drift detection alerts on unauthorized dependency changes

**GitHub Actions**:
- [ ] CI failure triggers claude-code-action auto-fix
- [ ] Security review posts findings on every PR
- [ ] CHANGELOG.md updates automatically on tag push

---

## Integration with Existing Workflow

### No Breaking Changes

**ios-sprint-executor** workflow unchanged:
- Phase 1-6 remain identical
- Hooks add enforcement, don't modify execution
- Superpowers plugin integration preserved

**Superpowers agents** unaffected:
- `write-plan`, `execute-plan`, `code-reviewer` continue as-is
- Project agents operate **after** Superpowers completes
- No conflicts between agent types

**Human workflows** enhanced:
- More validation, fewer manual checks
- Auto-fix reduces debugging time
- Better compliance, same UX

---

## Decision: Modify Stage 5.3 Before Execution

**Rationale**:
1. Current Stage 5.3 lacks Claude Code automation scope
2. Research upfront ensures proper architecture
3. Integration with ios-sprint-executor validated early
4. One comprehensive stage vs fragmented efforts

**Modified Stage 5.3 Scope**:
- Added: `research_requirements` (Claude Code architecture)
- Added: `required_plugins` (code-review, feature-dev, research-agent)
- Added: `required_github_actions` (claude-code-action patterns)
- Added: `.claude/hooks/`, `.claude/agents/`, `.claude/commands/` to outputs
- Added: `CLAUDE-CODE-AUTOMATION-001.md`, `AI-AGENT-BEHAVIORS-001.md` docs
- Added: `CHANGELOG.md` and automation workflow

**Next Steps**:
1. Commit modified context-map.json
2. Execute `/verified-stage-development stage-5.3`
3. Stage 5.3 research phase validates proposed architecture
4. Stage 5.3 execution creates all enforcement mechanisms

---

## References

**Official Documentation**:
- https://code.claude.com/docs/en/plugins
- https://github.com/anthropics/claude-code/tree/main/plugins
- https://github.com/anthropics/claude-code-action
- https://github.com/anthropics/claude-agent-sdk-demos

**Community Resources**:
- https://blog.fsck.com/2025/10/09/superpowers/

**Project Documents**:
- [DEVELOPMENT-WORKFLOW-001-git-branching-strategy](docs/validation/DEVELOPMENT-WORKFLOW-001-git-branching-strategy.md): Git branching strategy
- [DEVELOPMENT-WORKFLOW-002-pr-creation-automation](docs/validation/DEVELOPMENT-WORKFLOW-002-pr-creation-automation.md): PR creation automation
- [DEVELOPMENT-WORKFLOW-003-sprint-execution-guide](docs/validation/DEVELOPMENT-WORKFLOW-003-sprint-execution-guide.md): Sprint execution guide
- [DEVELOPMENT-READINESS-CHECKLIST-001](docs/validation/DEVELOPMENT-READINESS-CHECKLIST-001.md): Prerequisites

**Anthropic Examples**:
- bash_command_validator_example.py: https://github.com/anthropics/claude-code/blob/main/examples/hooks/bash_command_validator_example.py
- CHANGELOG.md: https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md
- Security PR reviews: https://github.com/anthropics/claude-code-action/blob/main/docs/solutions.md#security-focused-pr-reviews
- GCP integration: https://github.com/anthropics/claude-code-action/blob/main/docs/cloud-providers.md

---

**Design Status**: Complete
**Implementation Stage**: Stage 5.3 (pending execution)
**Confidence Level**: High (architecture validated through brainstorming)
