---
name: ios-sprint-executor
description: Use when executing iOS sprints, reviewing iOS code with latest APIs, building apps on device, identifying UI/UX gaps with brainstorming, preventing spec drift, or answering iOS/Swift questions - orchestrates superpowers workflow with apple-docs-fetcher grounding for all iOS work
---

# iOS Sprint Executor

Orchestrates iOS development with superpowers integration, Apple documentation grounding, UI/UX brainstorming, spec drift prevention, and device deployment.

**Design Reference**: `docs/validation/DEVELOPMENT-WORKFLOW-003-sprint-execution-guide.md` (from Stage 5.2)

---

## Modes of Operation

This skill operates in two modes:

**Mode 1: Sprint Execution** - Execute full sprint with planning, implementation, review, and PR creation
- Invocation: `/ios-sprint-executor sprint-X`
- Example: `/ios-sprint-executor sprint-2`

**Mode 2: Q&A & Guidance** - Answer iOS/Swift questions grounded in Apple documentation
- Invocation: Direct questions about iOS APIs, Swift features, or implementation viability
- Automatically uses apple-docs-fetcher to ground all responses

---

## Purpose

This skill guarantees deterministic agentic development by:

1. **Detecting iOS work** in sprint plans automatically
2. **Fetching Apple documentation** using apple-docs-fetcher when needed (during setup, code review, and Q&A)
3. **Orchestrating superpowers workflow** (brainstorming → planning → execution → code review)
4. **Preventing spec drift** via verified-stage-development integration
5. **Building and deploying to devices** with best Xcode settings
6. **Identifying UI/UX gaps** and refining through Socratic brainstorming
7. **Enforcing token budgets** (18K-25K per sprint)
8. **Creating feature branches** and PRs with proper structure

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

   **IMPORTANT**: Use apple-docs-fetcher skill (Skill tool with skill: "apple-docs-fetcher")

   a. Extract focused API list from sprint plan (3-5 specific APIs):

   Example for Sprint 2:

   - `VNCoreMLRequest` (Vision Framework)
   - `VNDetectBarcodesRequest` (Vision Framework)
   - `AVCaptureSession` (AVFoundation)
   - `Task.detached` (Swift Concurrency)

   b. Invoke apple-docs-fetcher skill:

   ```
   Tool: Skill
   Parameters:
     skill: apple-docs-fetcher
   ```

   Pass the focused API list (3-5 APIs) to the skill. The skill will:
   - Search and fetch relevant documentation
   - Create concise summaries
   - Store in `docs/apple/` directory
   - Enforce token budgets automatically

   c. Display summary:

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

   Ready for UI/UX review...
   ```

---

### Phase 1.5: UI/UX Review & Brainstorming

**Purpose**: Identify UI/UX gaps and refine through Socratic brainstorming before planning

**Steps**:

1. **Review sprint plan for UI/UX requirements**

   - Read DESIGN docs referenced in sprint plan
   - Identify UI components, interactions, animations
   - Look for UX patterns: loading states, error handling, accessibility

2. **Compare with existing implementation (if iterating)**

   - Check what UI/UX features are already implemented
   - Identify gaps: missing animations, incomplete error states, accessibility issues
   - Compare against iOS Human Interface Guidelines

3. **Identify UI/UX gaps**

   Common gaps to check:
   - Loading states (skeleton screens, spinners)
   - Empty states (no data, no search results)
   - Error states (network errors, validation errors)
   - Animations and transitions
   - Haptic feedback
   - Accessibility (VoiceOver, Dynamic Type)
   - Context menus and swipe actions
   - Pull-to-refresh
   - Search and filtering
   - Responsive layouts (iPhone/iPad)

4. **If gaps identified: Invoke superpowers:brainstorm**

   **CRITICAL: This instruction applies in ALL contexts:**
   - During actual sprint execution ✓
   - During skill testing/evaluation ✓
   - During hypothetical scenario analysis ✓
   - When asked "what would you do" ✓
   - When describing the process ✓

   **If you identify gaps, invoke brainstorming. No exceptions.**

   ```
   Tool: Skill
   Parameters:
     skill: ios-superpowers
     args: brainstorm [UI/UX gaps identified]
   ```

   Use Socratic method to refine UI/UX:
   - Explore alternatives for missing features
   - Validate assumptions about user needs
   - Prioritize must-have vs nice-to-have
   - Ensure consistency with app-wide patterns
   - Consider implementation complexity vs UX benefit

   **Red flags - if you catch yourself thinking:**
   - "User only asked me to describe, not execute" ❌
   - "This is a test scenario, not real execution" ❌
   - "I'll just list the gaps without brainstorming" ❌
   - "Brainstorming would be overkill for this" ❌

   **These are rationalizations. Invoke brainstorming immediately.**

5. **Update sprint plan (if changes agreed upon)**

   - Document agreed-upon UI/UX improvements
   - Update success criteria
   - Add to implementation tasks

6. **Display summary**

   ```
   Phase 1.5: UI/UX Review - COMPLETE

   Gaps identified: 3
   - Loading states: Skeleton screens for list view
   - Error states: Network error with retry button
   - Accessibility: VoiceOver labels for all interactive elements

   Brainstorming outcome:
   ✅ Skeleton screens: High priority, standard iOS pattern
   ✅ Network error handling: High priority, improves UX
   ⚠️  Advanced accessibility: Medium priority, will implement basics

   Sprint plan updated with UI/UX tasks.

   Proceeding to Phase 2 (Planning)...
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

   Plan will be executed via ios-superpowers execute in batches.
   ```

3. **Invoke ios-superpowers plan**

   ```
   Tool: Skill
   Parameters:
     skill: ios-superpowers
     args: plan [sprint description]
   ```

   Pass context:
   - All loaded documents from step 1
   - Enhanced instructions from step 2

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

   - Run `ios-superpowers review`
   - Address feedback before next batch
   ```

2. **Invoke ios-superpowers execute**

   ```
   Tool: Skill
   Parameters:
     skill: ios-superpowers
     args: execute [plan from Phase 2]
   ```

   Pass context:
   - Implementation plan from Phase 2
   - All context documents
   - Enhanced instructions from step 1

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

**Purpose**: Request code review via ios-superpowers orchestrator

**Steps**:

1. **Invoke code reviewer via ios-superpowers**

   ```
   Tool: Skill
   Parameters:
     skill: ios-superpowers
     args: review
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

   Proceeding to Phase 4.5 (Apple Docs Verification)...
   ```

---

### Phase 4.5: Apple Docs Verification for Code Review

**Purpose**: Verify iOS code uses latest Apple APIs correctly by fetching current documentation

**When to run**: After code review, if implementation includes iOS framework code (SwiftUI, UIKit, Vision, AVFoundation, etc.)

**Steps**:

1. **Detect iOS framework usage**

   Scan implemented code for iOS framework imports:
   ```swift
   import SwiftUI
   import Vision
   import AVFoundation
   import Combine
   // etc.
   ```

2. **Extract APIs used**

   Identify specific APIs, classes, modifiers, and features:
   - SwiftUI modifiers: `.animation()`, `.containerRelativeFrame()`, etc.
   - Swift features: `@Observable`, `@MainActor`, typed throws, etc.
   - Framework APIs: `VNCoreMLRequest`, `AVCaptureSession`, etc.

3. **Invoke apple-docs-fetcher for each API**

   ```
   Tool: Skill
   Parameters:
     skill: apple-docs-fetcher
   ```

   For each identified API:
   - Fetch latest documentation
   - Verify API signature matches usage
   - Check availability (iOS version requirements)
   - Verify parameters and return types
   - Check for deprecation warnings

4. **Compare code against docs**

   For each API usage in code:
   - Does the signature match latest docs?
   - Are parameters used correctly?
   - Are required iOS versions met (deployment target)?
   - Any deprecation warnings?
   - Using latest best practices per docs?

5. **Report findings**

   ```
   Phase 4.5: Apple Docs Verification - COMPLETE

   APIs verified: 8
   ✅ @Observable (Swift 6.0) - Correct usage, iOS 17.0+
   ✅ .containerRelativeFrame() (SwiftUI) - Correct usage, iOS 17.0+
   ✅ .animation(.smooth) (SwiftUI) - Correct usage, iOS 17.0+
   ✅ VNCoreMLRequest (Vision) - Correct usage, iOS 11.0+
   ⚠️  AVCaptureSession (AVFoundation) - Using deprecated method .startRunning()
        Recommendation: Use Task-based async API instead

   Issues found: 1 deprecation warning
   Action: Fix AVCaptureSession deprecation before PR

   Proceeding to Phase 5 (Spec Drift Detection)...
   ```

6. **Fix issues if found**

   If API usage doesn't match latest docs:
   - Update code to match current best practices
   - Fix deprecation warnings
   - Update to newer APIs if available
   - Re-run tests
   - Re-run code review (Phase 4) if significant changes

---

### Phase 5: Spec Drift Detection & Sync

**Purpose**: Detect and prevent spec drift by syncing implementation with design docs

**Steps**:

1. **Compare implementation with DESIGN docs**

   For each DESIGN doc referenced in sprint plan:
   - Read the design specification
   - Compare with actual implementation
   - Identify drift: naming changes, architectural differences, missing features

   Common drift patterns:
   - Feature names differ (CatalogView spec vs InventoryView implementation)
   - Directory structure differs (spec says Packages/ but implemented in Sources/)
   - MVVM pattern variations (spec has ViewModel, code uses @Observable directly)
   - UI components added/removed during implementation
   - API changes made for technical reasons

2. **If drift detected: Invoke verified-stage-development**

   ```
   Tool: Skill
   Parameters:
     skill: verified-stage-development
   ```

   Use verified-stage-development to:
   - Document actual implementation decisions
   - Update DESIGN docs to match implementation
   - Create ADR if architectural pattern changed
   - Update sprint success criteria if scope changed
   - Ensure docs/ directory reflects reality

3. **Verify no drift remains**

   - Re-read updated DESIGN docs
   - Confirm implementation matches updated specs
   - Check ADRs are current
   - Verify sprint plan success criteria still valid

4. **Display summary**

   ```
   Phase 5: Spec Drift Detection - COMPLETE

   Drift detected: YES
   - DESIGN-028 specified "CatalogView", implemented as "InventoryView"
   - Directory structure: spec says Packages/, code uses Sources/
   - Grid/list toggle: Added mid-sprint, not in original spec

   verified-stage-development invoked:
   ✅ Updated DESIGN-028 to reflect InventoryView naming
   ✅ Updated directory structure documentation
   ✅ Added ADR-XXX: Grid/List Toggle UX Pattern
   ✅ Updated sprint success criteria

   Specs now in sync with implementation.

   Proceeding to Phase 5.5 (PR Creation)...
   ```

---

### Phase 5.5: PR Creation

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

   - Planning: ios-superpowers plan (22K tokens)
   - Execution: ios-superpowers execute (4 batches, 3.5 hours)
   - Code Review: ios-superpowers review (passed)
   - Apple Docs: apple-docs-fetcher (7.6K tokens, 4 APIs)

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

### Phase 6.5: Device Build & Deploy (Optional)

**Purpose**: Build and install iOS app on physical device via CLI with best settings

**When to run**: Optional phase after PR creation, when testing on physical device is needed

**Steps**:

1. **Detect connected iOS devices**

   ```bash
   xcrun devicectl list devices
   ```

   Or for older Xcode versions:
   ```bash
   xcrun xctrace list devices
   ```

2. **Verify device info**

   - Device UDID
   - iOS version
   - Device name
   - Connection status

3. **Apply best Xcode build settings for Swift 6.0/iOS 18**

   Create or update `.xcodebuild-settings` with:

   ```bash
   # Swift 6.0 settings
   SWIFT_VERSION=6.0
   SWIFT_STRICT_CONCURRENCY=complete
   ENABLE_UPCOMING_FEATURE_STRICTCONCURRENCY=YES

   # iOS 18 deployment
   IPHONEOS_DEPLOYMENT_TARGET=18.0

   # Code signing
   CODE_SIGN_STYLE=Automatic
   DEVELOPMENT_TEAM=[Your Team ID]

   # Optimization
   SWIFT_OPTIMIZATION_LEVEL=-Onone  # Debug builds
   SWIFT_COMPILATION_MODE=wholemodule

   # Debugging
   DEBUG_INFORMATION_FORMAT=dwarf-with-dsym
   ENABLE_TESTABILITY=YES
   ```

4. **Build for device**

   ```bash
   xcodebuild \
     -scheme [AppName] \
     -destination 'platform=iOS,id=[DEVICE_UDID]' \
     -configuration Debug \
     clean build \
     CODE_SIGN_STYLE=Automatic \
     DEVELOPMENT_TEAM=[TEAM_ID] \
     -allowProvisioningUpdates \
     SWIFT_VERSION=6.0 \
     SWIFT_STRICT_CONCURRENCY=complete \
     IPHONEOS_DEPLOYMENT_TARGET=18.0
   ```

5. **Create archive (if installing)**

   ```bash
   xcodebuild archive \
     -scheme [AppName] \
     -destination 'generic/platform=iOS' \
     -archivePath /tmp/[AppName].xcarchive \
     CODE_SIGN_STYLE=Automatic \
     DEVELOPMENT_TEAM=[TEAM_ID] \
     -allowProvisioningUpdates \
     SKIP_INSTALL=NO \
     SWIFT_VERSION=6.0
   ```

6. **Export .ipa for device installation**

   Create ExportOptions.plist:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>method</key>
       <string>development</string>
       <key>teamID</key>
       <string>[TEAM_ID]</string>
       <key>uploadBitcode</key>
       <false/>
       <key>compileBitcode</key>
       <false/>
       <key>uploadSymbols</key>
       <true/>
   </dict>
   </plist>
   ```

   Export:
   ```bash
   xcodebuild -exportArchive \
     -archivePath /tmp/[AppName].xcarchive \
     -exportPath /tmp/[AppName]-ipa \
     -exportOptionsPlist ExportOptions.plist
   ```

7. **Install on device**

   Using devicectl (Xcode 15+):
   ```bash
   xcrun devicectl device install app \
     --device [DEVICE_UDID] \
     /tmp/[AppName]-ipa/[AppName].ipa
   ```

   Or using ios-deploy (if installed):
   ```bash
   ios-deploy --id [DEVICE_UDID] \
     --bundle /tmp/[AppName]-ipa/[AppName].app
   ```

8. **Troubleshooting common issues**

   **Code signing error:**
   - Verify DEVELOPMENT_TEAM is correct (check Apple Developer account)
   - Run: `security find-identity -v -p codesigning`
   - Ensure device is registered in Apple Developer Portal

   **Provisioning profile error:**
   - Use `-allowProvisioningUpdates` flag
   - Or manually download profile from developer.apple.com

   **"No such module" error:**
   - Clean build folder: `xcodebuild clean`
   - Verify SPM dependencies resolved: `xcodebuild -resolvePackageDependencies`

   **App not installing:**
   - Check device has enough storage
   - Check iOS version compatibility
   - Try: `xcrun devicectl device reboot device --device [UDID]`

9. **Display summary**

   ```
   Phase 6.5: Device Build & Deploy - COMPLETE

   Device: iPhone 15 Pro (00008140-000C75163A2B001C)
   iOS Version: 18.1
   Build Configuration: Debug
   Swift Version: 6.0
   Deployment Target: iOS 18.0

   Build: ✅ SUCCESS (2m 34s)
   Archive: ✅ SUCCESS (1m 12s)
   Export: ✅ SUCCESS (45s)
   Install: ✅ SUCCESS

   App installed and ready to test on device.

   Next: Test app functionality on physical device
   ```

---

## Mode 2: Q&A & Guidance

**Purpose**: Answer iOS/Swift questions with Apple documentation grounding

**When to use**: Any time you have questions about iOS APIs, Swift features, or implementation viability

**Process**:

1. **Detect iOS/Swift question**

   Questions that trigger this mode:
   - "How do I use [SwiftUI feature]?"
   - "Can I use [Swift feature] with [iOS framework]?"
   - "What's the latest way to [iOS task]?"
   - "Is it possible to [iOS implementation idea]?"
   - "Show me examples of [Apple API]"

2. **Invoke apple-docs-fetcher for grounding**

   ```
   Tool: Skill
   Parameters:
     skill: apple-docs-fetcher
   ```

   For EVERY iOS/Swift question:
   - Extract API/framework names from question
   - Use apple-docs-fetcher to fetch latest docs
   - Ground answer in fetched documentation
   - Cite documentation sources

3. **Answer with grounded response**

   Structure:
   - Direct answer to question
   - Code examples from Apple docs
   - API signatures and parameters
   - Availability (iOS version requirements)
   - Best practices per documentation
   - Links to source docs

4. **Never answer from training data alone**

   **RED FLAGS - STOP and fetch docs:**
   - "I know this from training data"
   - "This is straightforward"
   - "Fetching docs takes time"
   - "I'm confident about this"

   **If you catch yourself thinking these → fetch docs immediately**

5. **Example Q&A flow**

   User: "Can I use Swift's typed throws with async sequences?"

   Agent:
   1. Identifies iOS/Swift question ✓
   2. Invokes apple-docs-fetcher ✓
   3. Fetches AsyncThrowingStream docs ✓
   4. Provides answer with code examples ✓
   5. Cites documentation source ✓

   **DO NOT:**
   - Answer from memory
   - Skip docs fetching "for simple questions"
   - Assume API signature from training data

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

iOS work detected but apple-docs-fetcher failed.

Options:
1. Type 'retry' to re-run apple-docs-fetcher
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

Recommendation: Reduce apple-docs-fetcher scope (fewer APIs)
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
