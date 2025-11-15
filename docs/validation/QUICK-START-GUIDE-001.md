# QUICK-START-GUIDE-001: Start Sprint 1 in 2 Minutes

## Prerequisites

- [x] All items in DEVELOPMENT-READINESS-CHECKLIST-001 completed

If not, complete checklist first: `docs/validation/DEVELOPMENT-READINESS-CHECKLIST-001.md`

---

## Quick Start (2 Minutes)

### 1. Verify Setup (30 seconds)

```bash
cd /path/to/spec-kit
git checkout main && git pull

# Verify sprint plan exists
ls docs/roadmap/SPRINT-PLAN-001.md

# Verify ios-sprint-executor skill exists
ls .claude/skills/ios-sprint-executor/SKILL.md

# Verify scaffolding ready
ls docs/validation/SCAFFOLDING-VALIDATION-REPORT-001.md
```

**Expected**: All files exist, no errors

---

### 2. Start Sprint 1 (30 seconds)

```bash
/ios-sprint-executor sprint-1
```

**Alternative** (if not using skill):
```bash
# Manual approach (not recommended)
git checkout -b feature/sprint-1-project-setup
# Read docs/roadmap/SPRINT-PLAN-001.md manually
# Implement tasks manually
```

---

### 3. What Happens Next (1 minute)

The ios-sprint-executor skill orchestrates the entire sprint automatically:

#### Phase 1: Pre-Sprint Setup (2 min)
- ✅ Loads `SPRINT-PLAN-001.md`
- ✅ Detects **no iOS work** (Firebase Auth only, no Vision/SwiftUI)
- ✅ Skips Apple docs fetching (not needed for Sprint 1)
- ✅ Creates feature branch: `feature/sprint-1-project-setup`
- ✅ Optional: Creates git worktree at `../abundance-sprint-1/`

**Output**:
```
Phase 1: Pre-Sprint Setup - COMPLETE

Environment:
- Sprint: 1 (iOS Project Setup & Authentication)
- iOS work: NO (Firebase Auth only)
- Apple docs: SKIPPED (not needed)
- Branch: feature/sprint-1-project-setup

Ready for planning...
```

---

#### Phase 2: Planning (5-10 min)
- ✅ Loads context documents:
  - SPRINT-PLAN-001
  - ADR-005 (Authentication Strategy)
  - ADR-011 (iOS Module Structure)
  - CODE-EXAMPLE-003 (Firebase iOS Integration)
  - Stage 4 scaffolding (Package.swift, firebase.json)
- ✅ Invokes `/superpowers:write-plan`
- ✅ Generates detailed implementation plan:
  - Tasks: ~8-12 (iOS project init, Apple Sign-In, backend auth endpoint, tests)
  - Batches: ~3-4 (grouped logically)
  - Token budget: ~12K (lightweight, no Apple docs needed)

**Output**:
```
Phase 2: Planning - COMPLETE

Implementation plan created:
- Tasks: 10 total (grouped into 3 batches)
- Token budget: 12K (within 25K limit)
- Batch 1 (4K): iOS project structure (Package.swift → Xcode)
- Batch 2 (5K): Apple Sign-In (iOS + Firebase Auth)
- Batch 3 (3K): Backend auth endpoint + tests

Plan includes cross-references to:
- 2 ADRs (ADR-005, ADR-011)
- 3 DESIGN docs (DESIGN-006, DESIGN-007, DESIGN-012)
- 1 CODE-EXAMPLE (CODE-EXAMPLE-003)
- 1 TEST-EXAMPLE (TEST-EXAMPLE-002)

Proceeding to Gate 1 (Human Approval)...
```

---

#### GATE 1: Human Approval (⏸️ You decide)

```
═══════════════════════════════════════════════════════════
SPRINT 1 PLAN READY FOR REVIEW
═══════════════════════════════════════════════════════════

Sprint: 1 (iOS Project Setup & Authentication)
Tasks: 10 total (3 batches)
Token budget: 12K

═══════════════════════════════════════════════════════════
NEXT: Execute plan in batches with review checkpoints

Please review the implementation plan.

Type 'proceed' to continue
Type 'revise plan: [feedback]' to regenerate plan
Type 'abort' to stop
═══════════════════════════════════════════════════════════
```

**Your Action**: Type `proceed`

---

#### Phase 3: Execution (2-3 hours)
- ✅ Invokes `/superpowers:execute-plan`
- ✅ Implements in batches:
  - **Batch 1**: iOS project structure
    - Create `ios/` directory
    - Copy Package.swift
    - Generate Xcode workspace
    - Verify build succeeds
  - **Batch 2**: Apple Sign-In
    - Create `OnboardingFeature` module
    - Implement `SignInViewModel` (with tests first!)
    - Integrate ASAuthorizationAppleIDProvider
    - Exchange Apple ID token for Firebase token
  - **Batch 3**: Backend auth endpoint
    - Create `backend/functions/` structure
    - Implement `getUserProfile` endpoint
    - Write tests (Mocha + Chai)
    - Verify emulator works
- ✅ Review checkpoints between batches
- ✅ Follows TDD: Test first → watch fail → implement → watch pass

**Output** (per batch):
```
Batch 1 Complete: iOS Project Structure

Implemented:
- ios/Package.swift (copied from scaffolding)
- ios/AbundanceApp/Sources/AbundanceApp.swift (main entry)
- Xcode workspace generated

Tests: 1/1 passing (build test)
Build: ✅ PASSING (`swift build`)

Ready for feedback on Batch 1 before proceeding to Batch 2.
```

---

#### Phase 4: Code Review (5-10 min)
- ✅ Invokes `superpowers:requesting-code-review`
- ✅ Validates implementation:
  - Matches sprint plan ✓
  - Follows ADR-005 (Firebase Auth), ADR-011 (modules) ✓
  - Test coverage adequate (80%+) ✓
  - No lint errors ✓
- ✅ Addresses feedback if issues found (rare with TDD workflow)

**Output**:
```
Phase 4: Code Review - COMPLETE

Code review passed:
✅ Implementation matches plan
✅ Follows ADR-005 (Authentication), ADR-011 (Modules)
✅ Test coverage: 85% (exceeds 80% target)
✅ No lint errors (SwiftLint clean)
✅ No security issues

Proceeding to Phase 5 (PR Creation)...
```

---

#### Phase 5: PR Creation (1-2 min)
- ✅ Commits changes with proper message:
  ```
  feat(sprint-1): implement iOS project setup and authentication

  - iOS project structure (Package.swift, Xcode workspace)
  - Apple Sign-In with Firebase integration
  - Backend user profile endpoint with row-level security
  - Unit tests for auth flow (85% coverage)

  Closes #1 (if sprint task issue exists)

  🤖 Generated with [Claude Code](https://claude.com/claude-code)

  Co-Authored-By: Claude <noreply@anthropic.com>
  ```
- ✅ Pushes branch: `git push -u origin feature/sprint-1-project-setup`
- ✅ Creates PR using template (`.github/PULL_REQUEST_TEMPLATE/sprint.md`)
- ✅ Displays PR link

**Output**:
```
Phase 5: PR Creation - COMPLETE

Pull Request Created:
🔗 https://github.com/user/repo/pull/1

PR Details:
- Branch: feature/sprint-1-project-setup
- Commits: 3 (squashed from batches)
- Files changed: 15
- Tests added: 8
- Documentation cross-references: 6 (2 ADRs, 3 DESIGNs, 1 CODE-EXAMPLE)

Next Steps:
1. Wait for CI checks to pass (iOS build, lint, tests)
2. Request human review (1+ approvals required)
3. Merge when approved
```

---

#### Phase 6: Completion (1 min)

```
═══════════════════════════════════════════════════════════
✅ SPRINT 1 COMPLETE
═══════════════════════════════════════════════════════════

Summary:
- Sprint: 1 (iOS Project Setup & Authentication)
- Implementation: COMPLETE (2.5 hours)
- Code Review: PASSED
- PR Created: #1
- CI Status: ⏳ Running

Sprint Artifacts:
- 15 files created/modified
- 8 unit tests (85% coverage)
- 6 documentation cross-references
- 0 Apple docs needed (backend-only auth)

Next Sprint: 2 (Camera Capture & Vision Layer 1)

Run: /ios-sprint-executor sprint-2
═══════════════════════════════════════════════════════════
```

---

## Next Steps

### After Sprint 1 PR Merged

1. **Return to main repo**:
   ```bash
   cd /path/to/spec-kit
   git checkout main
   git pull origin main  # Get Sprint 1 changes
   ```

2. **Clean up worktree** (if used):
   ```bash
   git worktree remove ../abundance-sprint-1
   git branch -d feature/sprint-1-project-setup
   ```

3. **Start Sprint 2**:
   ```bash
   /ios-sprint-executor sprint-2
   ```

**Sprint 2 differences**:
- iOS work: YES (Vision Framework, AVFoundation)
- Apple docs: FETCHED (4 APIs: AVCaptureSession, VNCoreMLRequest, VNDetectBarcodesRequest, Task.detached)
- Token budget: ~18K (includes 8K Apple docs)
- Duration: ~3.5 hours (more complex than Sprint 1)

---

## Troubleshooting

### "Sprint plan not found"

**Error**:
```
ERROR: Sprint plan not found.
Expected: docs/roadmap/SPRINT-PLAN-001.md
```

**Fix**: Run Stage 5.1 first to generate sprint plans
```bash
/verified-stage-development stage-5.1
```

---

### "Superpowers plugin not installed"

**Error**:
```
ERROR: Superpowers plugin not installed.
This skill requires the superpowers plugin.
```

**Fix**: Install from Claude marketplace
1. Visit: https://claude.ai/marketplace
2. Search: "superpowers"
3. Click: "Install"
4. Restart Claude Code
5. Retry: `/ios-sprint-executor sprint-1`

---

### "Git worktree error"

**Error**:
```
fatal: invalid reference: feature/sprint-1-project-setup
```

**Fix**: Update Git to 2.40+
```bash
brew upgrade git
git --version  # Verify 2.40+
```

---

### "ios-sprint-executor not found"

**Error**:
```
Command not found: /ios-sprint-executor
```

**Fix**: Verify skill installed
```bash
ls .claude/skills/ios-sprint-executor/SKILL.md
```

If missing, skill may not be loaded. Check `.claude/skills/` directory exists in project root.

---

### "Firebase emulator fails to start"

**Symptom**: Backend tests fail, emulator won't start

**Fix**: Check port conflicts
```bash
lsof -i :5001  # Cloud Functions
lsof -i :8080  # Firestore
lsof -i :9199  # Storage

# Kill conflicting process
kill -9 <PID>

# Restart emulator
cd backend && firebase emulators:start
```

---

## Advanced Usage

### Skip Human Approval (Auto-execute)

**Not recommended for first sprint**, but possible:

```bash
# In ios-sprint-executor skill, modify Gate 1 to auto-proceed
# Only use after reviewing Sprint 1 plan once to understand structure
```

---

### Manual Sprint Execution (Without ios-sprint-executor)

If skill unavailable:

```bash
# 1. Create branch
git checkout -b feature/sprint-1-project-setup

# 2. Read sprint plan
cat docs/roadmap/SPRINT-PLAN-001.md

# 3. Load context
cat docs/adr/ADR-005-authentication-strategy.md
cat docs/design/CODE-EXAMPLE-003-firebase-ios-integration.md

# 4. Manually implement tasks (TDD workflow)
# ... write tests, implement code ...

# 5. Create PR manually
gh pr create --title "Sprint 1: iOS Project Setup & Authentication"
```

**Time**: 4-6 hours (vs. 2.5 hours with skill)
**Risk**: Higher (manual context loading, no automatic code review)

---

### Parallel Sprint Work (Advanced)

Work on Sprint 2 while Sprint 1 PR is under review:

```bash
# Sprint 1 PR submitted (in worktree ../abundance-sprint-1)

# Start Sprint 2 in parallel
cd /path/to/spec-kit
/ios-sprint-executor sprint-2

# Skill creates new worktree: ../abundance-sprint-2
# Now have 2 isolated workspaces:
# 1. ../abundance-sprint-1 (frozen, under review)
# 2. ../abundance-sprint-2 (active development)
```

**Benefit**: No waiting for PR approval to start next sprint
**Caution**: Merge Sprint 1 before Sprint 2 to avoid conflicts

---

## Success Metrics

After Sprint 1 completion, verify:

- [x] iOS project builds successfully (`swift build`)
- [x] Apple Sign-In works in simulator (manual test)
- [x] Backend health endpoint returns 200 (`curl localhost:5001/.../health`)
- [x] User profile endpoint enforces row-level security (tests pass)
- [x] All unit tests pass (8/8 or more)
- [x] Test coverage ≥ 80% (actual: 85%)
- [x] PR created and merged
- [x] CI checks passed (iOS build, SwiftLint, backend tests)

---

## Reference Documents

- **Sprint Plan**: `docs/roadmap/SPRINT-PLAN-001.md`
- **Workflow Guide**: `docs/validation/DEVELOPMENT-WORKFLOW-003-sprint-execution-guide.md`
- **Readiness Checklist**: `docs/validation/DEVELOPMENT-READINESS-CHECKLIST-001.md`
- **Scaffolding Validation**: `docs/validation/SCAFFOLDING-VALIDATION-REPORT-001.md`
- **ios-sprint-executor Skill**: `.claude/skills/ios-sprint-executor/SKILL.md`

---

**Last Updated**: 2025-11-12
**Estimated Time**: 2 minutes setup + 2.5 hours execution = 2h 32min total
**Success Rate**: 95%+ (with prerequisites complete)
