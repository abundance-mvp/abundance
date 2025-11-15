---
name: ios-sprint-executor
aliases: [sprint-executor, ios-executor]
description: Executes sprint tasks with superpowers integration and automatic apple-docs-fetcher for iOS work
---

# iOS Sprint Executor

Orchestrates sprint execution with superpowers plugin integration and automatic Apple documentation fetching for iOS sprints.

**Design Reference**: `docs/validation/DEVELOPMENT-WORKFLOW-003-sprint-execution-guide.md` (from Stage 5.2)

**Invocation**: `/ios-sprint-executor sprint-X`

**Example**: `/ios-sprint-executor sprint-2` (executes Sprint 2: Camera Capture & Vision Layer 1)

---

## Purpose

This skill guarantees deterministic agentic development by:

1. **Detecting iOS work** in sprint plans automatically
2. **Fetching Apple documentation** using apple-docs-fetcher-lite when needed
3. **Orchestrating superpowers workflow** (`/superpowers:write-plan` → `/superpowers:execute-plan`)
4. **Enforcing token budgets** (18K-25K per sprint)
5. **Creating feature branches** and PRs with proper structure

---

## Parameters

- `sprint-number` (required): Sprint identifier (e.g., `sprint-2`, `sprint-3`)

---

## Process

### Phase 1: Pre-Sprint Setup

**Purpose**: Validate prerequisites and create working environment

**Steps**:

1. **Parse sprint number from invocation**

   - Extract from command: `/ios-sprint-executor sprint-2` → `2`
   - Validate format: `sprint-X` where X is digit (1-8)

2. **Load sprint plan**

   - File: `docs/roadmap/SPRINT-PLAN-00X.md` (e.g., `SPRINT-PLAN-002.md`)
   - If missing: ERROR and stop

     ```
     ERROR: Sprint plan not found.

     Expected: docs/roadmap/SPRINT-PLAN-00X.md

     Run Stage 5.1 first to generate sprint plans.
     ```

3. **Detect iOS work**

   Read sprint plan and search for iOS-specific keywords:

   - **iOS frameworks**: Vision, SwiftUI, AVFoundation, UIKit, Combine, CoreML
   - **iOS APIs**: VNCoreMLRequest, AVCaptureSession, @MainActor, @Observable
   - **iOS patterns**: MVVM, dependency injection, Task.detached

   If ANY iOS keyword found → `ios_work_detected = true`

4. **Check Apple documentation (if iOS work detected)**

   a. Check if `docs/apple/` directory exists

   b. If exists, check freshness:

   - Read `docs/apple/MANIFEST.md` (if exists)
   - Check `fetch_date` field
   - If > 30 days old → `apple_docs_stale = true`

   c. Decision logic:

   - If `docs/apple/` missing → **fetch required**
   - If apple_docs_stale → **fetch recommended** (warn but continue)
   - If fresh (< 30 days) → **no fetch needed**

5. **Fetch Apple documentation (if needed)**

   **IMPORTANT**: Use apple-docs-fetcher-lite pattern (NOT full apple-docs-fetcher)

   a. Extract focused API list from sprint plan (3-5 specific APIs):

   Example for Sprint 2:

   - `VNCoreMLRequest` (Vision Framework)
   - `VNDetectBarcodesRequest` (Vision Framework)
   - `AVCaptureSession` (AVFoundation)
   - `Task.detached` (Swift Concurrency)

   b. For each API:

   - Use `mcp__sosumi__searchAppleDocumentation` to search
   - Extract key info from search results (parameters, return types, examples)
   - If search insufficient: Use `mcp__sosumi__fetchAppleDocumentation` selectively
   - Create concise summary (< 2K tokens per API)
   - Discard full docs immediately

   c. Token budget enforcement:

   - 8K tokens per API max
   - 25K tokens total max
   - If exceeded: Stop and error with clear message

   d. Create verification summary:

   - File: `docs/apple/sprint-X-api-verification.md`
   - Contains: Concise summaries of 3-5 APIs (10K tokens total)
   - This summary is loaded into context for planning

   e. Display summary:

   ```
   Phase 1: Pre-Sprint Setup
   ✅ Sprint plan loaded: SPRINT-PLAN-002.md
   ✅ iOS work detected: Vision Framework, AVFoundation
   ✅ Apple docs fetched (lite mode):
      - VNCoreMLRequest (2.1K tokens)
      - VNDetectBarcodesRequest (1.8K tokens)
      - AVCaptureSession (2.5K tokens)
      - Task.detached (1.2K tokens)
      Total: 7.6K tokens (within 25K budget)
   ✅ Created: docs/apple/sprint-2-api-verification.md

   Proceeding to Phase 2 (Git Worktree Setup)...
   ```

6. **Create git worktree (optional but recommended)**

   **Check if superpowers:using-git-worktrees skill is available**:

   - If available: Offer to create worktree for sprint isolation
   - If not: Continue with current branch (manual branch creation)

   **If using worktree**:

   ```
   Tool: Skill
   Parameters:
     skill: superpowers:using-git-worktrees
   ```

   Worktree path: `../abundance-sprint-X/` (isolated directory)

7. **Create feature branch**

   Branch naming convention: `feature/sprint-X-{description}`

   Example for Sprint 2: `feature/sprint-2-camera-capture-vision`

   ```bash
   git checkout -b feature/sprint-2-camera-capture-vision
   ```

8. **Display phase completion**

   ```
   Phase 1: Pre-Sprint Setup - COMPLETE

   Environment:
   - Sprint: 2 (Camera Capture & Vision Layer 1)
   - iOS work: YES (Vision Framework, AVFoundation)
   - Apple docs: FETCHED (7.6K tokens)
   - Branch: feature/sprint-2-camera-capture-vision
   - Worktree: ../abundance-sprint-2/ (if using worktrees)

   Ready for planning...
   ```

---

### Phase 2: Planning with Superpowers

**Purpose**: Generate implementation plan using superpowers:write-plan with verified context

**Steps**:

1. **Load context documents**

   From sprint plan, load all referenced documents:

   - Sprint plan (already loaded)
   - ADRs referenced in sprint plan
   - DESIGN docs referenced in sprint plan
   - CODE-EXAMPLEs referenced in sprint plan
   - TEST-EXAMPLEs referenced in sprint plan
   - Apple docs verification summary (if iOS sprint)

   Track total tokens loaded (should be 18K-25K per sprint plan)

2. **Build enhanced instructions for write-plan**

   ```markdown
   You are creating an implementation plan for Sprint X of the Abundance MVP.

   ## CONTEXT PROVIDED

   Sprint Plan: docs/roadmap/SPRINT-PLAN-00X.md
   ADRs: [list from sprint plan]
   DESIGN docs: [list from sprint plan]
   CODE-EXAMPLEs: [list from sprint plan]
   TEST-EXAMPLEs: [list from sprint plan]
   [If iOS] Apple API Verification: docs/apple/sprint-X-api-verification.md

   ## MANDATORY REQUIREMENTS

   ### 1. Follow Sprint Plan Exactly

   Implement all tasks as specified in SPRINT-PLAN-00X.md.
   Use the "Use → Read → Implement → Test" pattern from sprint plan.

   ### 2. Reference Stage 4 Scaffolding

   Build on existing scaffolding:

   - iOS: docs/tech-stack/Package.swift (dependencies already defined)
   - Backend: docs/tech-stack/firebase.json (Firebase config ready)
   - AI Pipeline: docs/tech-stack/ai-provider-adapters.md (interfaces defined)

   ### 3. Use Verified Apple APIs (iOS only)

   All iOS APIs MUST reference the verification summary.
   Format: "Use VNCoreMLRequest per apple/sprint-X-api-verification.md, Section 1"

   ### 4. Test-Driven Development

   For each implementation task:

   - Given/When/Then acceptance criteria
   - Test example structure per TEST-EXAMPLE-XXX
   - 80%+ unit test coverage target

   ### 5. Token Budget Awareness

   This plan will be executed in batches per agent prompt token strategy:
   [Insert token batch breakdown from AGENT-PROMPT-00X]

   ### 6. Cross-Reference Success Criteria

   Your plan must accomplish all success criteria from sprint plan.

   ## OUTPUT STRUCTURE

   Create detailed implementation plan with:

   - Background & Context (sprint objectives)
   - Tasks (detailed, with test examples, cross-referenced to CODE-EXAMPLEs)
   - Batch grouping (per AGENT-PROMPT-00X token strategy)
   - Acceptance Criteria (traceable to sprint plan)
   - Dependencies & Risks

   Plan will be executed via /superpowers:execute-plan in batches.
   ```

3. **Invoke superpowers:write-plan**

   ```
   Tool: SlashCommand
   Command: /superpowers:write-plan

   Pass context:
   - All loaded documents from step 1
   - Enhanced instructions from step 2
   ```

4. **Wait for write-plan completion**

   write-plan creates an implementation plan (not saved to disk by default)

5. **Display plan summary**

   ```
   Phase 2: Planning - COMPLETE

   Implementation plan created:
   - Tasks: 12 total (grouped into 4 batches)
   - Token budget: 22K (within 25K limit)
   - Batch 1 (8K): CameraView UI
   - Batch 2 (10K): VisionService implementation
   - Batch 3 (6K): Barcode detection
   - Batch 4 (4K): Unit tests

   Plan includes cross-references to:
   - 3 ADRs (ADR-010, ADR-011, ADR-013)
   - 5 DESIGN docs (DESIGN-027, DESIGN-013, etc.)
   - 3 CODE-EXAMPLEs (CODE-EXAMPLE-004, etc.)
   - 2 TEST-EXAMPLEs (TEST-EXAMPLE-004, etc.)

   Proceeding to Gate 1 (Human Approval)...
   ```

---

### GATE 1: Human Approval (Post-Planning)

**Purpose**: Human reviews plan before execution

**Steps**:

1. **Display gate header**

   ```
   ═══════════════════════════════════════════════════════════
   SPRINT X PLAN READY FOR REVIEW
   ═══════════════════════════════════════════════════════════
   ```

2. **Display plan summary**

   - Sprint objectives
   - Task count and batch breakdown
   - Token budget
   - Cross-references to documentation
   - Success criteria from sprint plan

3. **Display gate instructions**

   ```
   ═══════════════════════════════════════════════════════════
   NEXT: Execute plan in batches with review checkpoints

   Please review the implementation plan.

   Type 'proceed to execute' to continue
   Type 'revise plan: [feedback]' to regenerate plan
   Type 'abort' to stop
   ═══════════════════════════════════════════════════════════
   ```

4. **Wait for human response**

   - Listen for: "proceed", "execute", "continue", "yes"
   - If "revise plan": Ask for feedback, re-run write-plan with feedback
   - If "abort": Exit gracefully

5. **On approval, display transition**

   ```
   ✅ Approval received. Proceeding to Phase 3 (Execution)...
   ```

---

### Phase 3: Execution with Superpowers

**Purpose**: Execute plan in batches using superpowers:execute-plan

**Steps**:

1. **Build enhanced instructions for execute-plan**

   ```markdown
   You are executing the implementation plan for Sprint X.

   ## CONTEXT PROVIDED

   Implementation Plan: [from write-plan output]
   All context from planning phase (sprint plan, ADRs, DESIGN docs, CODE-EXAMPLEs, Apple verification)

   ## EXECUTION REQUIREMENTS

   ### 1. Execute in Batches

   Follow batch grouping from plan:

   - Batch 1: [description, token budget]
   - Batch 2: [description, token budget]
   - Batch 3: [description, token budget]
   - Batch 4: [description, token budget]

   Present work for review between batches.

   ### 2. Follow Scaffolding Structure

   - iOS code: Use Package.swift structure
   - Backend code: Use firebase.json structure
   - Follow module organization from Stage 4 scaffolding

   ### 3. Cross-Reference Documentation

   In code comments and docstrings:

   - "// See ADR-XXX for rationale"
   - "// Implements DESIGN-XXX pattern"
   - "// Tested per TEST-EXAMPLE-XXX"

   ### 4. Test-Driven Development

   For each implementation task:

   - Write test first (Given/When/Then)
   - Watch it fail
   - Write minimal code to pass
   - Refactor

   ### 5. Code Review Checkpoints

   After each batch completes:

   - Run `superpowers:requesting-code-review`
   - Address feedback before next batch
   ```

2. **Invoke superpowers:execute-plan**

   ```
   Tool: SlashCommand
   Command: /superpowers:execute-plan

   Pass context:
   - Implementation plan from Phase 2
   - All context documents
   - Enhanced instructions from step 1
   ```

3. **Monitor execution**

   execute-plan runs in batches with human review checkpoints

4. **On completion, display summary**

   ```
   Phase 3: Execution - COMPLETE

   Sprint X implementation complete:
   ✅ Batch 1: CameraView UI (8K tokens, 45 min)
   ✅ Batch 2: VisionService (10K tokens, 1.2 hours)
   ✅ Batch 3: Barcode detection (6K tokens, 40 min)
   ✅ Batch 4: Unit tests (4K tokens, 30 min)

   Files created/modified: 18
   Tests added: 24 (87% coverage)
   Build status: ✅ PASSING

   Proceeding to Phase 4 (Code Review)...
   ```

---

### Phase 4: Code Review

**Purpose**: Request code review using superpowers:requesting-code-review

**Steps**:

1. **Invoke code reviewer**

   ```
   Tool: Skill
   Parameters:
     skill: superpowers:requesting-code-review
   ```

   Code reviewer validates:

   - Implementation matches plan
   - Follows ADRs and DESIGN docs
   - Test coverage adequate (80%+)
   - Code quality (no lint errors)

2. **Wait for code review completion**

   Code reviewer creates review report (not a blocking gate in Phase 1)

3. **Address feedback (if any)**

   If reviewer identifies issues:

   - Fix issues immediately
   - Re-run tests
   - Re-run code review

4. **Display summary**

   ```
   Phase 4: Code Review - COMPLETE

   Code review passed:
   ✅ Implementation matches plan
   ✅ Follows ADR-010 (MVVM), ADR-011 (modules), ADR-013 (DI)
   ✅ Test coverage: 87% (exceeds 80% target)
   ✅ No lint errors
   ✅ No security issues

   Reviewer comments: [summary]

   Proceeding to Phase 5 (PR Creation)...
   ```

---

### Phase 5: PR Creation

**Purpose**: Create pull request with proper structure

**Steps**:

1. **Commit changes**

   ```bash
   git add .
   git commit -m "feat(sprint-X): implement [sprint description]

   - Task 1: [description]
   - Task 2: [description]
   - Task 3: [description]

   Closes #X (if sprint task issue exists)
   ```

2. **Push branch**

   ```bash
   git push -u origin feature/sprint-X-{description}
   ```

3. **Generate PR body**

   Use feature PR template format:

   ```markdown
   # Sprint X: [Sprint Description]

   ## Sprint Reference

   - Sprint: X ([SPRINT-PLAN-00X.md](../docs/roadmap/SPRINT-PLAN-00X.md))
   - Agent Prompt: [AGENT-PROMPT-00X.md](../docs/agent-prompts/AGENT-PROMPT-00X.md)

   ## Documentation Cross-References

   ### ADRs

   - [ADR-XXX: Title](../docs/adr/ADR-XXX.md) - [why referenced]
   - [ADR-YYY: Title](../docs/adr/ADR-YYY.md) - [why referenced]

   ### Design Docs

   - [DESIGN-XXX: Title](../docs/design/DESIGN-XXX.md) - [why referenced]
   - [DESIGN-YYY: Title](../docs/design/DESIGN-YYY.md) - [why referenced]

   ### Code Examples & Tests

   - [CODE-EXAMPLE-XXX](../docs/design/CODE-EXAMPLE-XXX.md) - [pattern used]
   - [TEST-EXAMPLE-XXX](../docs/test/TEST-EXAMPLE-XXX.md) - [testing approach]

   ## Success Criteria Checklist

   - [ ] [Success criterion 1 from sprint plan]
   - [ ] [Success criterion 2 from sprint plan]
   - [ ] [Success criterion 3 from sprint plan]

   ## Testing Evidence

   ### Unit Tests

   - Test coverage: 87% (target: 80%+)
   - Tests passing: 24/24
   - [Screenshot or test output]

   ### Build Validation

   - iOS build: ✅ PASSING (`swift build`)
   - SwiftLint: ✅ PASSING (0 warnings)
   - [Screenshot or build output]

   ## Agent Execution Summary

   - Planning: superpowers:write-plan (22K tokens)
   - Execution: superpowers:execute-plan (4 batches, 3.5 hours)
   - Code Review: superpowers:requesting-code-review (passed)
   - Apple Docs: apple-docs-fetcher-lite (7.6K tokens, 4 APIs)

   ## Notes

   [Any special notes or context for reviewers]
   ```

4. **Create PR**

   ```bash
   gh pr create --title "Sprint X: [Sprint Description]" --body "[body from step 3]"
   ```

5. **Display summary**

   ```
   Phase 5: PR Creation - COMPLETE

   Pull Request Created:
   🔗 https://github.com/user/repo/pull/XX

   PR Details:
   - Branch: feature/sprint-2-camera-capture-vision
   - Commits: 4 (squashed from batches)
   - Files changed: 18
   - Tests added: 24
   - Documentation cross-references: 8 (3 ADRs, 5 DESIGN docs)

   Next Steps:
   1. Wait for CI checks to pass (iOS build, lint, tests)
   2. Request human review (1+ approvals required)
   3. Merge when approved
   ```

---

### Phase 6: Completion & Cleanup

**Purpose**: Final summary and optional cleanup

**Steps**:

1. **Display completion banner**

   ```
   ═══════════════════════════════════════════════════════════
   ✅ SPRINT X COMPLETE
   ═══════════════════════════════════════════════════════════

   Summary:
   - Sprint: X ([sprint name])
   - Implementation: COMPLETE (3.5 hours)
   - Code Review: PASSED
   - PR Created: #XX
   - CI Status: ⏳ Running

   Sprint Artifacts:
   - 18 files created/modified
   - 24 unit tests (87% coverage)
   - 8 documentation cross-references
   - Apple docs verified (4 APIs)

   Next Sprint: X+1 ([next sprint name])

   Run: /ios-sprint-executor sprint-X+1
   ═══════════════════════════════════════════════════════════
   ```

2. **Optional: Git worktree cleanup**

   If using worktrees:

   ```
   After PR is merged, clean up worktree:

   cd [original directory]
   git worktree remove ../abundance-sprint-X/
   git branch -d feature/sprint-X-{description}
   ```

---

## Error Handling

### Sprint plan missing

```
ERROR: Sprint plan not found.

Expected: docs/roadmap/SPRINT-PLAN-00X.md

Run Stage 5.1 first to generate sprint plans:
/verified-stage-development stage-5.1
```

### Apple docs fetch failure

```
ERROR: Apple documentation fetch failed.

iOS work detected but apple-docs-fetcher-lite failed.

Options:
1. Type 'retry' to re-run apple-docs-fetcher-lite
2. Type 'skip' to continue without Apple docs (NOT RECOMMENDED)
3. Type 'abort' to stop
```

### Token budget exceeded

```
ERROR: Token budget exceeded.

Sprint token budget: 25K
Context loaded: 28.5K (over limit by 3.5K)

Possible causes:
- Too many documents loaded from sprint plan
- Apple docs fetch exceeded 25K limit

Recommendation: Reduce apple-docs-fetcher-lite scope (fewer APIs)
```

### Superpowers plugin not available

```
ERROR: Superpowers plugin not installed.

This skill requires the superpowers plugin.

Install via:
1. Visit marketplace: https://claude.ai/marketplace
2. Search for "superpowers"
3. Click "Install"
4. Restart Claude Code
5. Retry: /ios-sprint-executor sprint-X
```

### Git branch already exists

```
WARNING: Branch already exists: feature/sprint-X-{description}

Options:
1. Type 'continue' to use existing branch (continue sprint work)
2. Type 'new branch: [name]' to create different branch
3. Type 'abort' to stop
```

---

## Notes

- This skill orchestrates superpowers plugin for sprint execution
- Apple docs are fetched using lite pattern (8K per API, 25K max total)
- PR creation follows template from Stage 5.2 (DEVELOPMENT-WORKFLOW-002)
- Git workflow follows pattern from Stage 5.2 (DEVELOPMENT-WORKFLOW-001)
- Sprint execution follows pattern from Stage 5.2 (DEVELOPMENT-WORKFLOW-003)

---

## Usage Examples

**Sprint 1: iOS Project Setup & Authentication**

```
/ios-sprint-executor sprint-1
```

- No iOS framework work (Firebase Auth only)
- No Apple docs needed
- Creates: AuthService, AuthViewModel, unit tests

**Sprint 2: Camera Capture & Vision Layer 1**

```
/ios-sprint-executor sprint-2
```

- iOS work: Vision Framework, AVFoundation
- Apple docs: VNCoreMLRequest, AVCaptureSession, Task.detached
- Creates: CameraView, VisionService, barcode detection

**Sprint 3: Backend AI Pipeline**

```
/ios-sprint-executor sprint-3
```

- No iOS work (backend only)
- No Apple docs needed
- Creates: Cloud Functions for Layers 2a, 2b, 3

---
