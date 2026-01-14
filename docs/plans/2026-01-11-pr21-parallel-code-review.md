# PR #21 Parallel Code Review Plan (iOS Superpowers Edition)

> **For Claude:** This plan uses `ios-superpowers` orchestration with Apple documentation grounding for all iOS code review.

**Goal:** Review all 168 files in PR #21 using parallel code review agents with Swift 6 concurrency verification.

**Architecture:** Files grouped into 10 review batches across 4 waves. Each batch review is grounded with relevant Apple documentation.

**Tech Stack:** Swift 6.0 (iOS/SPM), TypeScript (Firebase), Python (scripts), Markdown (docs)

---

## Apple Documentation Context (Pre-Fetched)

### Swift 6 Concurrency (Critical for this PR)
- **MainActor**: Singleton actor for UI, conforms to `Sendable`. Use `assumeIsolated(_:)` for synchronous contexts.
- **Data Isolation**: Swift 6 strict mode catches data races at compile time. Overlapping access to shared mutable state = risk.
- **Sendable**: Types crossing actor boundaries must conform. CVPixelBuffer is NOT inherently Sendable.

### AVFoundation Camera
- **AVCaptureSession**: MUST use `beginConfiguration()`/`commitConfiguration()` for changes.
- **Thread Safety**: Session runs on background thread, UI updates require MainActor hop.
- **CVPixelBuffer**: Type alias for CVImageBuffer, stores images in main memory - NOT thread-safe.

### Review Rules (from Apple Docs)
1. All `@MainActor` usage must be verified against isolation requirements
2. CVPixelBuffer access must be protected (locks, actors, or copy semantics)
3. Async/await patterns must respect actor isolation
4. Continuations must be resumed exactly once

---

## PR Overview

| Metric | Value |
|--------|-------|
| PR Number | #21 |
| Branch | `fix/ios-simulator-crashes` |
| Title | Fix iOS simulator crashes and Swift 6 concurrency warnings |
| Files Changed | 168 |
| Additions | +14,372 |
| Deletions | -1,521 |
| Commits | 91 ahead of main |

**Key Changes:**
1. **Layer 1→2 Catalog Pipeline Handoff** - Camera detection → cloud upload flow
2. **Single-Directory Xcode Workflow Refactor** - Eliminates two-directory sync
3. **Swift 6 Concurrency Fixes** - Actor isolation, Sendable conformance, data race prevention

---

## Parallel Review Strategy

### Execution Model

```
┌─────────────────────────────────────────────────────────────────────┐
│                     WAVE 1 (Critical Path - P0)                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │
│  │   Batch 1    │  │   Batch 2    │  │   Batch 3    │               │
│  │ Camera Core  │  │  VisionCore  │  │  Persistence │               │
│  │  (9 files)   │  │  (8 files)   │  │  (3 files)   │               │
│  │ Swift 6 conc │  │ CVPixelBuffer│  │  Firebase    │               │
│  └──────────────┘  └──────────────┘  └──────────────┘               │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                     WAVE 2 (Supporting - P1)                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │
│  │   Batch 4    │  │   Batch 5    │  │   Batch 6    │               │
│  │  App Entry   │  │  Core Infra  │  │  Inventory   │               │
│  │  (8 files)   │  │  (5 files)   │  │  (7 files)   │               │
│  │ @MainActor   │  │   Logging    │  │   SwiftUI    │               │
│  └──────────────┘  └──────────────┘  └──────────────┘               │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                     WAVE 3 (Tests & Infra - P1)                     │
│  ┌──────────────┐  ┌──────────────┐                                 │
│  │   Batch 7    │  │   Batch 8    │                                 │
│  │    Tests     │  │ Build/Scripts│                                 │
│  │  (15 files)  │  │  (12 files)  │                                 │
│  │  Assertions  │  │  Package.swift│                                │
│  └──────────────┘  └──────────────┘                                 │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                     WAVE 4 (Documentation - P2)                     │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │   Batch 9: Claude Automation (18 files)                        │ │
│  │   Batch 10: Documentation (78 files) - Quick scan only         │ │
│  └────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

### Review Criteria (iOS Superpowers Enhanced)

| Priority | Criteria | Apple Docs Reference | Action |
|----------|----------|---------------------|--------|
| P0 | ADR-010 violation (UIKit import in Views) | HIG/SwiftUI | Block PR |
| P0 | Data race (shared mutable state) | Swift/adoptingswift6 | Block PR |
| P0 | CVPixelBuffer unsafe access | CoreVideo/CVPixelBuffer | Block PR |
| P0 | MainActor violation | Swift/MainActor | Block PR |
| P0 | Security (hardcoded secrets) | - | Block PR |
| P1 | Missing continuation resumption | Swift Concurrency | Request changes |
| P1 | Missing error handling | - | Request changes |
| P1 | Weak test assertions | XCTest | Request changes |
| P2 | Code style / naming | - | Comment |
| P2 | Documentation gaps | - | Comment |

---

## Batch Definitions

### Batch 1: Camera Feature - Core Logic (CRITICAL)
**Priority:** P0 | **Files:** 9 | **Apple Docs:** MainActor, AVCaptureSession, CVPixelBuffer

The heart of Layer 1→2 handoff. Camera service, detection ViewModel, and views.

**Files:**
```
Sources/CameraFeature/Services/CameraService.swift
Sources/CameraFeature/Services/CameraServiceProtocol.swift
Sources/CameraFeature/ViewModels/CameraDetectionViewModel.swift
Sources/CameraFeature/ViewModels/CameraViewModel.swift
Sources/CameraFeature/Views/CameraDetectionView.swift
Sources/CameraFeature/Views/CameraView.swift
Sources/CameraFeature/Views/OrganicBorderOverlay.swift
Sources/CameraFeature/Views/OrganicBorderShape.swift
Sources/CameraFeature/Views/SparkleAnimation.swift
```

**Review Focus (Apple Docs Grounded):**
- [ ] `@MainActor` isolation correct per MainActor docs
- [ ] AVCaptureSession uses beginConfiguration/commitConfiguration
- [ ] CVPixelBuffer access is protected (NSLock verified in recent fix)
- [ ] Continuations resumed exactly once
- [ ] Upload flow respects actor boundaries
- [ ] ADR-010: SwiftUI-only, NO UIKit imports for UI

**Agent Prompt:**
```
Review PR #21 Batch 1: Camera Feature Core.

APPLE DOCS CONTEXT:
- MainActor: Singleton actor for UI, use assumeIsolated() for sync contexts
- AVCaptureSession: MUST use beginConfiguration/commitConfiguration
- CVPixelBuffer: NOT thread-safe, requires protection

FILES: Sources/CameraFeature/**/*.swift (9 files)

FOCUS:
1. Swift 6 actor isolation - @MainActor correct?
2. CVPixelBuffer data races - protected by lock/actor?
3. Continuations - resumed exactly once?
4. ADR-010 - SwiftUI only, no UIKit?

Report P0/P1/P2 issues with file:line references.
```

---

### Batch 2: VisionCore (CRITICAL)
**Priority:** P0 | **Files:** 8 | **Apple Docs:** CVPixelBuffer, Vision framework

Vision framework integration, pixel buffer handling, platform abstractions.

**Files:**
```
Sources/VisionCore/Extensions/CVPixelBuffer+Sendable.swift
Sources/VisionCore/Services/BarcodeDetector.swift
Sources/VisionCore/Services/HouseholdItemDetector.swift
Sources/VisionCore/Services/HouseholdItemDetectorProtocol.swift
Sources/VisionCore/Services/ObjectDeduplicator.swift
Sources/VisionCore/Services/SubjectMaskGenerator.swift
Sources/VisionCore/Utilities/PixelBufferCropper.swift
Sources/VisionCore/Utilities/PlatformTypes.swift
```

**Review Focus (Apple Docs Grounded):**
- [ ] CVPixelBuffer+Sendable: Is @unchecked Sendable safe? Document invariants.
- [ ] HouseholdItemDetector: Actor conversion verified (recent fix)
- [ ] Coordinate transformations: Vision → UIKit coords
- [ ] Memory management: No leaks from retained buffers
- [ ] Platform abstraction: iOS vs macOS types correct

**Agent Prompt:**
```
Review PR #21 Batch 2: VisionCore.

APPLE DOCS CONTEXT:
- CVPixelBuffer: Type alias for CVImageBuffer, NOT inherently Sendable
- To make Sendable safe: Copy data OR ensure single-owner semantics
- Vision requests operate on immutable snapshots

FILES: Sources/VisionCore/**/*.swift (8 files)

FOCUS:
1. CVPixelBuffer+Sendable - is @unchecked justified? Invariants documented?
2. HouseholdItemDetector - actor isolation correct?
3. Memory management - buffers released properly?
4. Thread safety in detection services

Report P0/P1/P2 issues with file:line references.
```

---

### Batch 3: Persistence & Firebase (CRITICAL)
**Priority:** P0 | **Files:** 3 | **Apple Docs:** N/A (Firebase)

Firebase integration for Layer 1→2 handoff. Item creation, storage paths.

**Files:**
```
Sources/Persistence/Firebase/ItemService.swift
Sources/Persistence/Firebase/StorageService.swift
Sources/Persistence/KeychainManager.swift
```

**Review Focus:**
- [ ] Firestore document structure correct
- [ ] Storage path format: `users/{userId}/items/{itemId}.jpg`
- [ ] NO hardcoded user IDs (security - recent fix verified)
- [ ] Error handling for network failures
- [ ] Keychain security best practices

**Agent Prompt:**
```
Review PR #21 Batch 3: Persistence & Firebase.

FILES: Sources/Persistence/**/*.swift (3 files)

FOCUS:
1. NO hardcoded user IDs anywhere (P0 security)
2. Firestore schema correct for pending items
3. Storage paths follow pattern users/{userId}/items/{itemId}.jpg
4. Network error handling complete
5. Keychain usage follows best practices

Report P0/P1/P2 issues with file:line references.
```

---

### Batch 4: App Entry & Navigation (HIGH)
**Priority:** P1 | **Files:** 8 | **Apple Docs:** MainActor, SwiftUI App lifecycle

Application startup, tab navigation, app-level configuration.

**Files:**
```
App/AbundanceApp.swift
App/CameraTabView.swift
App/FloatingTabBar.swift
App/MainTabView.swift
App/Info.plist
App/Assets.xcassets/AccentColor.colorset/Contents.json
App/Animation+Extensions.swift (DELETED)
App/Color+Extensions.swift (DELETED)
```

**Review Focus (Apple Docs Grounded):**
- [ ] App entry point: @main + @MainActor correct
- [ ] Debug prints wrapped in `#if DEBUG`
- [ ] Navigation flow SwiftUI-only
- [ ] Deleted extensions moved to Core (not lost)
- [ ] Info.plist permissions minimal

**Agent Prompt:**
```
Review PR #21 Batch 4: App Entry & Navigation.

APPLE DOCS CONTEXT:
- SwiftUI @main apps run on MainActor by default
- SwiftUI lifecycle: App -> Scene -> View

FILES: App/**/* (8 files)

FOCUS:
1. @main + @MainActor correct on app entry
2. #if DEBUG guards on all debug prints
3. Deleted extensions moved to Core
4. Info.plist permissions justified

Report P0/P1/P2 issues with file:line references.
```

---

### Batch 5: Core Infrastructure (HIGH)
**Priority:** P1 | **Files:** 5 | **Apple Docs:** os.Logger

Design system components and logging infrastructure.

**Files:**
```
Sources/Core/DesignSystem/Components/PrimaryButton.swift
Sources/Core/DesignSystem/Extensions/Animation+Brand.swift
Sources/Core/DesignSystem/Extensions/Color+Brand.swift
Sources/Core/Logging/AppLogger.swift
Sources/Core/Logging/AppLogger+Examples.swift
```

**Review Focus:**
- [ ] Logging: NO sensitive data logged (PII, user IDs - recent fix)
- [ ] Logging: Values truncated to prevent data exposure
- [ ] Design system: Brand consistency
- [ ] ADR-010: No UIKit imports

**Agent Prompt:**
```
Review PR #21 Batch 5: Core Infrastructure.

FILES: Sources/Core/**/*.swift (5 files)

FOCUS:
1. Logging - NO PII, user IDs sanitized, values truncated
2. Design system brand consistency
3. ADR-010 compliance - no UIKit

Report P0/P1/P2 issues with file:line references.
```

---

### Batch 6: Inventory Feature (MEDIUM)
**Priority:** P2 | **Files:** 7

Inventory UI updates, code consolidation from deleted duplicates.

**Files:**
```
Sources/InventoryFeature/EmptyStateCard.swift
Sources/InventoryFeature/InventoryView.swift
Sources/InventoryFeature/InventoryViewModel.swift
Sources/InventoryFeature/ItemCard.swift
Sources/InventoryFeature/PrimaryButton.swift (DELETED - moved to Core)
Sources/OnboardingFeature/Animation+Extensions.swift (DELETED)
Sources/OnboardingFeature/Color+Extensions.swift (DELETED)
```

**Review Focus:**
- [ ] Deleted code properly moved to Core
- [ ] Import statements updated for Core module
- [ ] No duplicate implementations remain
- [ ] ADR-010 compliance

**Agent Prompt:**
```
Review PR #21 Batch 6: Inventory Feature.

FILES: Sources/InventoryFeature/**/*.swift + Sources/OnboardingFeature/**/*.swift (7 files)

FOCUS:
1. Deleted code moved to Core (not lost)
2. Imports updated to Core module
3. No duplicate implementations
4. ADR-010 compliance

Report P0/P1/P2 issues with file:line references.
```

---

### Batch 7: All Tests (HIGH)
**Priority:** P1 | **Files:** 15 | **Apple Docs:** XCTest, Swift Testing

Test coverage for camera, logging, inventory, persistence, vision.

**Files:**
```
Tests/CameraFeatureTests/Integration/CameraDetectionIntegrationTests.swift
Tests/CameraFeatureTests/Manual/TestHouseholdItemDetection.swift
Tests/CameraFeatureTests/Mocks/MockCameraService.swift
Tests/CameraFeatureTests/Mocks/MockImageQualityAssessor.swift
Tests/CameraFeatureTests/Mocks/MockItemService.swift
Tests/CameraFeatureTests/ViewModels/CameraDetectionViewModelTests.swift
Tests/CameraFeatureTests/Views/CameraDetectionViewTests.swift
Tests/CameraFeatureTests/Views/OrganicBorderOverlayTests.swift
Tests/CameraFeatureTests/Views/OrganicBorderShapeTests.swift
Tests/CameraFeatureTests/Views/SparkleAnimationTests.swift
Tests/Core/LoggingTests/AppLoggerTests.swift
Tests/InventoryFeatureTests/InventoryNavigationIntegrationTests.swift
Tests/InventoryFeatureTests/InventoryViewTests.swift
Tests/PersistenceTests/ItemServiceTests.swift
Tests/VisionCoreTests/Utilities/PixelBufferCropperTests.swift
```

**Review Focus:**
- [ ] Test isolation: No shared state between tests
- [ ] Strong assertions: Not just "does not crash"
- [ ] No flaky tests: Task.yield NOT Task.sleep (recent fix)
- [ ] Mock completeness: All dependencies mocked
- [ ] Edge case coverage

**Agent Prompt:**
```
Review PR #21 Batch 7: Tests.

FILES: Tests/**/*.swift (15 files)

FOCUS:
1. Test isolation - no shared state
2. Strong assertions - not just "doesn't crash"
3. No Task.sleep - use Task.yield (recent fix verified)
4. Mocks complete for all dependencies
5. Edge cases covered

Report P0/P1/P2 issues with file:line references.
```

---

### Batch 8: Build System & Scripts (HIGH)
**Priority:** P1 | **Files:** 12

Build configuration, CI/CD, development scripts.

**Files:**
```
Package.swift
project.yml
Abundance.entitlements
.github/workflows/spec-validation.yml
.gitignore
.debug/.gitkeep
.debug/README.md
scripts/regenerate-xcode-project.sh
scripts/sim.sh
scripts/check-health.sh
scripts/setup-git-hooks.sh
scripts/validate_doc_references.py
scripts/extract-spec-assertions.py
scripts/README.md
scripts/__pycache__/map_documents.cpython-311.pyc (SHOULD NOT BE COMMITTED)
```

**Review Focus:**
- [ ] Package.swift dependencies minimal
- [ ] Entitlements necessary and justified
- [ ] Scripts work with single-directory workflow
- [ ] No hardcoded paths in scripts
- [ ] __pycache__ should NOT be committed
- [ ] .gitignore completeness

**Agent Prompt:**
```
Review PR #21 Batch 8: Build System & Scripts.

FILES: Package.swift, project.yml, scripts/*, .github/*, .gitignore, Abundance.entitlements (12 files)

FOCUS:
1. Package.swift - minimal dependencies
2. Scripts - no hardcoded paths
3. __pycache__ must not be committed (P0)
4. .gitignore complete

Report P0/P1/P2 issues with file:line references.
```

---

### Batch 9: Claude Automation (MEDIUM)
**Priority:** P2 | **Files:** 18

Commands and skills for Claude Code automation.

**Files:**
```
.claude/commands/README.md
.claude/commands/apple-docs-fetcher-lite.md
.claude/commands/dispatch.md
.claude/commands/enrich-issue.md
.claude/commands/ios-sprint-executor.md
.claude/commands/super-code-review.md
.claude/commands/triage-issues.md
.claude/commands/troubleshoot.md
.claude/skills/apple-docs-fetcher-lite/SKILL.md
.claude/skills/apple-docs-fetcher/SKILL.md
.claude/skills/capture-issue/SKILL.md
.claude/skills/capture-issue/baseline-findings.md
.claude/skills/ios-sprint-executor/README.md
.claude/skills/ios-sprint-executor/SKILL.md
.claude/skills/ios-sprint-executor/baseline-findings.md
.claude/skills/ios-sprint-executor/baseline-test-scenarios.md
.claude/skills/ios-sprint-executor/green-phase-changes.md
.claude/skills/verified-stage-development/SKILL.md
```

**Review Focus:**
- [ ] No broken references to deleted files
- [ ] Command/skill coherence
- [ ] apple-docs-fetcher-lite → apple-docs-fetcher migration
- [ ] Workflow documentation clarity

**Agent Prompt:**
```
Review PR #21 Batch 9: Claude Automation.

FILES: .claude/**/*.md (18 files)

FOCUS:
1. No broken file references
2. apple-docs-fetcher-lite updated to apple-docs-fetcher
3. Command/skill coherence
4. Workflow docs clear

Report P0/P1/P2 issues with file:line references.
```

---

### Batch 10: Documentation (LOW)
**Priority:** P3 | **Files:** 78 | Quick scan only

Docs, plans, ADRs, checkpoints, roadmaps, validation reports.

**Files:**
```
CLAUDE.md
ITERATION-SYSTEM-SUMMARY.md
docs/**/*.md (78 files)
```

**Review Focus:**
- [ ] CLAUDE.md changes accurate
- [ ] No broken internal links
- [ ] No contradictions with existing docs
- [ ] Quick scan - minimal time investment

**Agent Prompt:**
```
Review PR #21 Batch 10: Documentation.

FILES: docs/**/*.md, CLAUDE.md, ITERATION-SYSTEM-SUMMARY.md (78 files)

FOCUS: QUICK SCAN ONLY
1. CLAUDE.md accuracy
2. No broken links
3. No contradictions

Report only P0/P1 issues with file:line references. Skip P2.
```

---

## Execution Commands

### Wave 1: Critical Path (3 Parallel Agents)

Dispatch Batch 1, 2, 3 simultaneously using Task tool with `superpowers:code-reviewer` subagent.

### Wave 2: Supporting (3 Parallel Agents)

After Wave 1 completes and P0 issues fixed, dispatch Batch 4, 5, 6.

### Wave 3: Tests & Infra (2 Parallel Agents)

After Wave 2 completes, dispatch Batch 7, 8.

### Wave 4: Documentation (2 Parallel Agents)

After Wave 3 completes, dispatch Batch 9, 10.

---

## Issue Tracking Template

```markdown
### [P0/P1/P2] Issue Title

**File:** `path/to/file.swift:123`
**Batch:** N
**Category:** [Security|Concurrency|ADR Violation|Test Quality|etc]
**Apple Docs Ref:** [If applicable]

**Description:**
[What's wrong]

**Suggested Fix:**
[How to fix it]
```

---

## Success Criteria

- [ ] All 10 batches reviewed
- [ ] Zero P0 issues remaining
- [ ] P1 issues documented with suggested fixes
- [ ] P2 issues noted as comments
- [ ] Final review posted to PR #21

---

**Created:** 2026-01-11
**Updated:** 2026-01-11 (iOS Superpowers Edition)
**PR:** #21
**Branch:** fix/ios-simulator-crashes
