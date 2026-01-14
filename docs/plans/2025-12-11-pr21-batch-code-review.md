# PR #21 Batch Code Review Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Review PR #21 (145 files, 13,456 additions) in logical batches using code review agents

**Architecture:** Files grouped by feature/module relationships to enable focused, context-aware reviews

**Tech Stack:** Swift 6.0 (iOS), TypeScript (Firebase), Python (scripts), Markdown (docs)

---

## PR Overview

**Title:** Fix iOS simulator crashes and Swift 6 concurrency warnings

**Two Main Features:**
1. **Layer 1→2 Catalog Pipeline Handoff** - Camera detection → cloud upload flow
2. **Single-Directory Xcode Workflow Refactor** - Eliminates two-directory sync

**Stats:** 145 files | +13,456 | -1,164

---

## Review Batches

### Batch 1: Claude Automation (Commands & Skills)
**Priority:** Medium | **Files:** 10 | **Lines:** ~1,000

Developer experience tooling changes.

**Files:**
- `.claude/commands/apple-docs-fetcher.md` (DELETED)
- `.claude/commands/dispatch.md` (NEW +122)
- `.claude/commands/enrich-issue.md` (NEW +261)
- `.claude/commands/super-code-review.md` (+84 -8)
- `.claude/commands/triage-issues.md` (NEW +249)
- `.claude/commands/troubleshoot.md` (+83 -7)
- `.claude/skills/apple-docs-fetcher/SKILL.md` (DELETED -274)
- `.claude/skills/apple-docs-fetcher/SKILL.md` (+66 -9)
- `.claude/skills/capture-issue/SKILL.md` (NEW +217)
- `.claude/skills/capture-issue/baseline-findings.md` (NEW +39)

**Review Focus:**
- Command/skill coherence and completeness
- No broken references to deleted files
- Workflow documentation clarity

---

### Batch 2: Build System & Configuration
**Priority:** HIGH | **Files:** 8 | **Lines:** ~400

Critical build infrastructure changes.

**Files:**
- `.github/workflows/spec-validation.yml` (+1 -19)
- `.gitignore` (+19 -7)
- `Abundance.entitlements` (NEW +5)
- `Package.swift` (+20 -2)
- `Package.swift.backup` (NEW +127) ⚠️ Should this be committed?
- `project.yml` (in PR, changes for in-place generation)
- `.debug/.gitkeep` (NEW +2)
- `.debug/README.md` (NEW +146)

**Review Focus:**
- ADR-010 compliance (SwiftUI-only)
- Package.swift dependencies correct
- .gitignore completeness for new workflow
- Entitlements necessary and minimal
- Package.swift.backup - accidental commit?

---

### Batch 3: App Entry & Navigation
**Priority:** HIGH | **Files:** 8 | **Lines:** ~350

Application startup and navigation structure.

**Files:**
- `App/AbundanceApp.swift` (+25 -7)
- `App/CameraTabView.swift` (+10 -1)
- `App/FloatingTabBar.swift` (+1)
- `App/Info.plist` (+22 -2)
- `App/MainTabView.swift` (+3 -3)
- `App/Assets.xcassets/AccentColor.colorset/Contents.json` (NEW +38)
- `App/Animation+Extensions.swift` (DELETED -29)
- `App/Color+Extensions.swift` (DELETED -129)

**Review Focus:**
- App entry point concurrency safety (Swift 6)
- Navigation flow correctness
- Deleted extensions moved to Core (not lost)
- Info.plist permissions appropriate

---

### Batch 4: Camera Feature - Core Logic
**Priority:** CRITICAL | **Files:** 4 | **Lines:** ~230

Main implementation of Layer 1→2 handoff.

**Files:**
- `Sources/CameraFeature/Services/CameraService.swift` (+45 -1)
- `Sources/CameraFeature/Services/CameraServiceProtocol.swift` (+3)
- `Sources/CameraFeature/ViewModels/CameraDetectionViewModel.swift` (+82 -20)
- `Sources/CameraFeature/ViewModels/CameraViewModel.swift` (-2)

**Review Focus:**
- Swift 6 concurrency (`@MainActor`, `Sendable`)
- Upload flow correctness (auto + manual triggers)
- Error handling completeness
- Memory management (no retain cycles)
- ADR-010 compliance

---

### Batch 5: Camera Feature - Views
**Priority:** HIGH | **Files:** 5 | **Lines:** ~450

New camera detection UI components.

**Files:**
- `Sources/CameraFeature/Views/CameraDetectionView.swift` (NEW +233)
- `Sources/CameraFeature/Views/CameraView.swift` (+7 -1)
- `Sources/CameraFeature/Views/OrganicBorderOverlay.swift` (NEW +107)
- `Sources/CameraFeature/Views/OrganicBorderShape.swift` (NEW +20)
- `Sources/CameraFeature/Views/SparkleAnimation.swift` (NEW +85)

**Review Focus:**
- SwiftUI-only (ADR-010) - NO UIKit imports
- Animation performance (60fps target)
- Accessibility compliance
- Memory efficiency for animations

---

### Batch 6: Core Infrastructure
**Priority:** HIGH | **Files:** 6 | **Lines:** ~620

Design system and logging infrastructure.

**Files:**
- `Sources/Core/DesignSystem/Components/PrimaryButton.swift` (+10 -2)
- `Sources/Core/DesignSystem/Extensions/Animation+Brand.swift` (+1 -1)
- `Sources/Core/DesignSystem/Extensions/Color+Brand.swift` (+1 -1)
- `Sources/Core/Logging/AppLogger+Examples.swift` (NEW +228)
- `Sources/Core/Logging/AppLogger.swift` (NEW +375)

**Review Focus:**
- Logging implementation correctness
- No sensitive data in logs
- Design system consistency
- Performance impact of logging

---

### Batch 7: Inventory Feature
**Priority:** Medium | **Files:** 6 | **Lines:** ~70

Inventory updates and code cleanup.

**Files:**
- `Sources/InventoryFeature/EmptyStateCard.swift` (+1)
- `Sources/InventoryFeature/InventoryView.swift` (+13 -3)
- `Sources/InventoryFeature/InventoryViewModel.swift` (+1 -1)
- `Sources/InventoryFeature/ItemCard.swift` (+1)
- `Sources/InventoryFeature/PrimaryButton.swift` (DELETED -84) → moved to Core
- `Sources/OnboardingFeature/Animation+Extensions.swift` (DELETED -29)
- `Sources/OnboardingFeature/Color+Extensions.swift` (DELETED -129)

**Review Focus:**
- Deleted code properly moved (not lost)
- Import statements updated for Core
- No duplicate implementations

---

### Batch 8: Persistence & Firebase
**Priority:** CRITICAL | **Files:** 3 | **Lines:** ~70

Firebase integration for Layer 1→2 handoff.

**Files:**
- `Sources/Persistence/Firebase/ItemService.swift` (NEW +64)
- `Sources/Persistence/Firebase/StorageService.swift` (+5 -2)
- `Sources/Persistence/KeychainManager.swift` (+1 -1)

**Review Focus:**
- Firestore document structure correctness
- Storage path format (`users/{userId}/items/{itemId}.jpg`)
- Error handling for network failures
- Security rules alignment (pending status trigger)

---

### Batch 9: VisionCore
**Priority:** HIGH | **Files:** 9 | **Lines:** ~100

Vision framework and image processing.

**Files:**
- `Sources/VisionCore/Extensions/CVPixelBuffer+Sendable.swift` (NEW +16)
- `Sources/VisionCore/Services/BarcodeDetector.swift` (+1 -1)
- `Sources/VisionCore/Services/HouseholdItemDetector.swift` (+2 -2)
- `Sources/VisionCore/Services/HouseholdItemDetectorProtocol.swift` (-7)
- `Sources/VisionCore/Services/ObjectDeduplicator.swift` (+2 -2)
- `Sources/VisionCore/Services/SubjectMaskGenerator.swift` (+1 -1)
- `Sources/VisionCore/Utilities/PixelBufferCropper.swift` (NEW +66)
- `Sources/VisionCore/Utilities/PlatformTypes.swift` (NEW +11)

**Review Focus:**
- Swift 6 Sendable conformance for CVPixelBuffer
- Coordinate transformation (Vision → UIKit coords)
- Memory management for pixel buffers
- Platform abstraction correctness (iOS vs macOS)

---

### Batch 10: Camera Feature Tests
**Priority:** HIGH | **Files:** 10 | **Lines:** ~740

Tests for camera detection feature.

**Files:**
- `Tests/CameraFeatureTests/Integration/CameraDetectionIntegrationTests.swift` (NEW +136)
- `Tests/CameraFeatureTests/Manual/TestHouseholdItemDetection.swift` (NEW +311)
- `Tests/CameraFeatureTests/Mocks/MockCameraService.swift` (+11)
- `Tests/CameraFeatureTests/Mocks/MockImageQualityAssessor.swift` (+4)
- `Tests/CameraFeatureTests/Mocks/MockItemService.swift` (NEW +71)
- `Tests/CameraFeatureTests/ViewModels/CameraDetectionViewModelTests.swift` (+44 -3)
- `Tests/CameraFeatureTests/Views/CameraDetectionViewTests.swift` (NEW +32)
- `Tests/CameraFeatureTests/Views/OrganicBorderOverlayTests.swift` (NEW +84)
- `Tests/CameraFeatureTests/Views/OrganicBorderShapeTests.swift` (NEW +30)
- `Tests/CameraFeatureTests/Views/SparkleAnimationTests.swift` (NEW +17)

**Review Focus:**
- Test coverage completeness
- Mock implementations correct
- No flaky tests (timing-dependent)
- Integration tests isolated from network

---

### Batch 11: Other Tests
**Priority:** Medium | **Files:** 5 | **Lines:** ~520

Tests for logging, inventory, persistence, vision.

**Files:**
- `Tests/Core/LoggingTests/AppLoggerTests.swift` (NEW +214)
- `Tests/InventoryFeatureTests/InventoryNavigationIntegrationTests.swift` (NEW +70)
- `Tests/InventoryFeatureTests/InventoryViewTests.swift` (NEW +52)
- `Tests/PersistenceTests/ItemServiceTests.swift` (NEW +96)
- `Tests/VisionCoreTests/Utilities/PixelBufferCropperTests.swift` (NEW +89)

**Review Focus:**
- Test isolation (no shared state)
- Mock completeness for Firebase
- Edge case coverage

---

### Batch 12: Scripts
**Priority:** HIGH | **Files:** 6 | **Lines:** ~300

Build and development scripts.

**Files:**
- `scripts/README.md` (changes)
- `scripts/check-health.sh` (path updates)
- `scripts/regenerate-xcode-project.sh` (simplified ~50 lines)
- `scripts/setup-git-hooks.sh` (changes)
- `scripts/sim.sh` (simplified ~150 lines, rsync removed)
- `scripts/validate_doc_references.py` (changes)
- `scripts/extract-spec-assertions.py` (changes)
- `scripts/__pycache__/*` ⚠️ Should not be committed

**Review Focus:**
- Scripts work with new single-directory workflow
- No hardcoded paths
- Error handling
- __pycache__ should be in .gitignore

---

### Batch 13: Documentation - Dev Workflow
**Priority:** Medium | **Files:** 5 | **Lines:** ~1,500

New development workflow documentation.

**Files:**
- `docs/dev-workflow/BUG-FILING-WORKFLOW.md` (NEW +374)
- `docs/dev-workflow/DEV-ITERATION-SYSTEM-001.md` (NEW +448)
- `docs/dev-workflow/ENRICHED-ISSUE-SCHEMA.md` (NEW +395)
- `docs/dev-workflow/QUICK-REFERENCE.md` (NEW +241)
- `docs/dev-workflow/XCODE-REGENERATION-TROUBLESHOOTING.md` (NEW)

**Review Focus:**
- Documentation accuracy
- No contradictions with existing docs
- Actionable and clear

---

### Batch 14: Documentation - Bug Reports
**Priority:** Low | **Files:** 5 | **Lines:** ~1,100

Bug documentation.

**Files:**
- `docs/bugs/BLOCKER-001-firebase-bundle-id-mismatch.md` (NEW +251)
- `docs/bugs/BUG-001-camera-upload-hardcoded-user-id.md` (NEW +208)
- `docs/bugs/BUG-002-spec-drift-camera-detection-ui-not-implemented.md` (NEW +269)
- `docs/bugs/BUG-003-inventory-camera-button-unresponsive.md` (NEW +270)
- `docs/bugs/BUG-004-enrichment-subprocess-file-write-fails.md` (NEW +116)

**Review Focus:**
- Bug descriptions accurate
- Reproduction steps clear
- Linked to correct issues/PRs

---

### Batch 15: Documentation - Plans
**Priority:** Low | **Files:** 18 | **Lines:** Variable

Implementation plans (historical).

**Files:**
- `docs/plans/2025-11-08-stage-2.3-backend-cloud-architecture.md`
- `docs/plans/2025-11-09-pr-vs-branch-comparison.md`
- `docs/plans/2025-11-10-phase-3-restructure-layer-focused-research.md`
- `docs/plans/2025-11-10-stage-3.2-backend-implementation-research.md`
- `docs/plans/2025-11-11-stage-4.1-ios-project-scaffolding.md`
- `docs/plans/2025-11-11-stage-4.2-backend-project-scaffolding.md`
- `docs/plans/2025-11-11-stage-4.3-ai-pipeline-scaffolding.md`
- `docs/plans/2025-11-12-stage-5.1-phased-implementation-roadmap.md`
- `docs/plans/2025-11-12-stage-5.2-agent-prompts-pre-development-validation.md`
- `docs/plans/2025-11-14-audit-fix-document-references.md`
- `docs/plans/2025-11-14-deterministic-ai-development-workflow-design.md`
- `docs/plans/2025-11-14-stage-5.3-project-initialization-cicd-claude-automation.md`
- `docs/plans/2025-11-15-sprint-2-detailed-execution-plan.md`
- `docs/plans/2025-11-15-sprint-2-verified-stage-development.md`
- `docs/plans/2025-11-15-sprint-4-layer-2a-implementation.md`
- `docs/plans/2025-11-16-xcode-project-testflight-conversion.md`
- `docs/plans/2025-11-17-camera-detection-ui-implementation.md`
- `docs/plans/2025-11-18-camera-detection-layer1-layer2-handoff.md`
- `docs/plans/2025-11-19-design-system-consolidation-and-single-target-fixes.md`
- `docs/plans/2025-11-19-xcode-project-regeneration-automation.md`
- `docs/plans/2025-12-11-single-directory-xcode-workflow.md`
- `docs/plans/PLAN-SUMMARY-stage-5.2.md`

**Review Focus:**
- Quick scan for accuracy
- Minimal review needed (historical)

---

### Batch 16: Documentation - Other
**Priority:** Low | **Files:** 20+ | **Lines:** Variable

ADRs, checkpoints, roadmap, status docs.

**Files:**
- `CLAUDE.md` (+14)
- `ITERATION-SYSTEM-SUMMARY.md` (NEW +228)
- `docs/E2E-TESTING-GUIDE.md` (+3 -3)
- `docs/STATUS-2025-11-16-ios-simulator-ready.md` (NEW +208)
- `docs/abundance-analysis-pipeline-design.md` (+3 -3)
- `docs/adr/ADR-018-barcode-product-lookup-strategy.md` (+3 -3)
- `docs/adr/ADR-024-observability-stack.md` (+1 -1)
- `docs/adr/ADR-025-vision-framework-strategy.md` (+1 -1)
- `docs/adr/ADR-026-payment-strategy.md` (+1 -1)
- `docs/checkpoints/CHECKPOINT-sprint-2-2025-11-15.md` (+8 -8)
- `docs/checkpoints/CHECKPOINT-stage-*.md` (7 files, minor edits)
- `docs/context-map.json` (+2 -2)
- `docs/design/DESIGN-002-ios-client-architecture.md` (+6 -6)
- `docs/design/SERPAPI-INTEGRATION-001-swift-rest-api-patterns.md` (+2 -2)
- `docs/implementation/2025-11-17-camera-detection-ui-implementation.md`
- `docs/roadmap/EPIC-BREAKDOWN-001-features-to-documents.md`
- `docs/roadmap/SPRINT-PLAN-001.md` through `SPRINT-PLAN-008.md`
- `docs/validation/DEVELOPMENT-WORKFLOW-002-pr-creation-automation.md`
- `docs/validation/TOOL-CALL-UPDATE-stage-3.6.md`

**Review Focus:**
- CLAUDE.md changes accurate
- No broken internal links
- Quick scan only

---

## Recommended Review Order

**Phase 1: Critical Path (Batches 4, 8, 2)**
1. Batch 4: Camera Feature - Core Logic (CRITICAL)
2. Batch 8: Persistence & Firebase (CRITICAL)
3. Batch 2: Build System & Configuration (HIGH)

**Phase 2: Supporting Implementation (Batches 5, 9, 6, 3)**
4. Batch 5: Camera Feature - Views (HIGH)
5. Batch 9: VisionCore (HIGH)
6. Batch 6: Core Infrastructure (HIGH)
7. Batch 3: App Entry & Navigation (HIGH)

**Phase 3: Tests (Batches 10, 11)**
8. Batch 10: Camera Feature Tests (HIGH)
9. Batch 11: Other Tests (Medium)

**Phase 4: Infrastructure & Cleanup (Batches 12, 7, 1)**
10. Batch 12: Scripts (HIGH)
11. Batch 7: Inventory Feature (Medium)
12. Batch 1: Claude Automation (Medium)

**Phase 5: Documentation (Batches 13-16)**
13. Batch 13: Documentation - Dev Workflow (Medium)
14. Batch 14: Documentation - Bug Reports (Low)
15. Batch 15: Documentation - Plans (Low)
16. Batch 16: Documentation - Other (Low)

---

## Execution Commands

For each batch, dispatch a code review agent with:

```bash
# Example for Batch 4 (Critical)
gh pr diff 21 -- Sources/CameraFeature/Services/*.swift Sources/CameraFeature/ViewModels/*.swift | head -500
```

**Review Criteria:**
- ADR-010 compliance (SwiftUI-only)
- Swift 6 concurrency correctness
- Error handling completeness
- Test coverage
- Security (no hardcoded secrets)

---

## Potential Issues to Watch

1. **Package.swift.backup** - Should this be committed?
2. **scripts/__pycache__/** - Should not be committed
3. **Deleted files** - Verify code moved to Core, not lost
4. **Swift 6 concurrency** - All actors/sendable correct?
5. **Firebase security** - No hardcoded user IDs remaining?

---

**Created:** 2025-12-11
**PR:** #21
**Branch:** fix/ios-simulator-crashes
