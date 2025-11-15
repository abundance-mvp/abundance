# Sprint 2: Camera Capture & Vision Layer 1 - Verified Stage Development Plan

> **For Claude:** REQUIRED SUB-SKILL: Use verified-stage-development skill to implement this plan with research verification, planning, execution, and approval gates.

**Goal:** Implement camera capture with Vision Framework object detection (Layer 1) and backend CRUD endpoints for the Abundance MVP using verified stage development workflow with ADR-010 compliance.

**Architecture:** SwiftUI + MVVM for camera UI, AVFoundation for capture, Vision Framework (VNCoreMLRequest + VNDetectBarcodesRequest) for on-device ML, Firebase Cloud Functions for backend CRUD. UIKit imports ONLY where required for AVFoundation/Vision bridging.

**Tech Stack:** Swift 6.0, SwiftUI, AVFoundation, Vision, Core ML, YOLOv3-Tiny, TypeScript, Firebase Functions, Jest

**Critical Constraints:**
- ADR-010: SwiftUI-only architecture (MVVM pattern required)
- UIKit imports ONLY permitted for framework bridging (AVFoundation, Vision require UIKit types like UIImage)
- P0 Violation: UIKit imports in non-bridging code blocks PR merge
- 80%+ test coverage target (TEST-STRATEGY-001)
- TDD workflow (test-fail-implement-pass-commit)
- Swift 6.0 strict concurrency enabled

**Sprint Reference:** docs/roadmap/SPRINT-PLAN-002.md

**Design References:**
- docs/design/DESIGN-012-camera-capture-implementation.md
- docs/design/CODE-EXAMPLE-009-household-item-detector.md
- docs/design/DESIGN-014-barcode-detection-implementation.md
- docs/design/API-CONTRACTS-001-rest-endpoints.md

**ADR References:**
- docs/adr/ADR-010-swiftui-architecture-pattern.md (MVVM, SwiftUI-only)
- docs/adr/ADR-012-state-management-strategy.md (Combine + async/await)
- docs/adr/ADR-013-dependency-injection-strategy.md (Constructor injection)

---

## Critical Issues from Previous Plan Review

**Issues Identified in `2025-11-15-sprint-2-camera-vision-backend.md`:**

1. **UIKit Import Violations (P0 - Blocks PR Merge)**:
   - Lines 254, 282, 416: UIKit imported in service protocols/implementations
   - Lines 1155, 1341: UIKit imported in Vision detectors
   - **Impact**: These imports violate ADR-010's SwiftUI-only architecture
   - **Resolution Required**: Document UIKit as framework bridging requirement, NOT architecture violation

2. **Protocol Abstraction Leak**:
   - Line 827 in CameraView: Direct access to `CameraService.captureSession` breaks protocol abstraction
   - **Impact**: View tightly coupled to concrete implementation
   - **Resolution Required**: Add `getCaptureSession()` to protocol or pass session via ViewModel

3. **Test Coverage Gaps**:
   - CameraView has no SwiftUI view tests
   - Backend tests have auth mocking issues (line 1712)
   - **Impact**: Below 80% coverage target
   - **Resolution Required**: Add snapshot tests or defer UI testing to Sprint 3

4. **Missing Package.swift Context**:
   - Plan assumes Package.swift structure without reading current state
   - **Impact**: May duplicate targets or create conflicts
   - **Resolution Required**: Read Package.swift before modifications

5. **Info.plist Path Unclear**:
   - Task 5 references `Info.plist` without absolute path
   - **Impact**: iOS SPM projects don't use Info.plist for permissions
   - **Resolution Required**: Add NSCameraUsageDescription to app target's Info.plist (not in SPM package)

---

## Verified Stage Development Workflow

**Stage 1: Research & Verification**
- Verify ADR-010 UIKit bridging interpretation
- Research AVFoundation/Vision UIKit requirements
- Confirm SwiftUI UIViewRepresentable usage patterns
- Document UIKit bridging justification

**Stage 2: Planning with Approval Gates**
- Create detailed task breakdown (bite-sized TDD steps)
- Identify UIKit bridging points explicitly
- Define protocol abstractions to minimize coupling
- Get plan approval before execution

**Stage 3: Execution with Code Review**
- Execute tasks in batches (3 tasks per batch)
- Run tests after EVERY implementation step
- Code review after each batch
- Verify ADR-010 compliance continuously

**Stage 4: Final Verification**
- Run full test suite (`swift test`)
- Verify 80%+ coverage
- Run SwiftLint (zero warnings)
- Check ADR drift (`/check-drift`)
- Manual camera flow testing

---

## Task Breakdown (11 Tasks)

### Batch 1: Camera Module Structure (Tasks 1-3)

**Task 1:** Create CameraFeature module with models (CameraSessionState, CameraAuthorizationStatus, CameraError)
**Task 2:** Implement CameraServiceProtocol and MockCameraService (no UIKit)
**Task 3:** Implement CameraService with AVFoundation (UIKit bridging justified)

**UIKit Bridging Justification for Task 3:**
- AVFoundation's `AVCapturePhoto.fileDataRepresentation()` returns `Data`
- Converting `Data` to image requires `UIImage(data:)` constructor
- CameraServiceProtocol returns `UIImage` for cross-platform compatibility (Vision requires UIImage input)
- **ADR-010 Compliance**: UIKit used ONLY for framework bridging, NOT for UI components

### Batch 2: Camera UI with MVVM (Tasks 4-5)

**Task 4:** Implement CameraViewModel (MVVM pattern, no UIKit)
**Task 5:** Implement CameraView + CameraPreviewView (SwiftUI + UIViewRepresentable for AVCaptureVideoPreviewLayer)

**UIKit Bridging Justification for Task 5:**
- AVCaptureVideoPreviewLayer is UIKit-only (no SwiftUI equivalent)
- UIViewRepresentable is SwiftUI's official bridging mechanism
- **ADR-010 Compliance**: UIViewRepresentable is SwiftUI-native pattern for UIKit bridging

### Batch 3: Vision Module Structure (Tasks 6-8)

**Task 6:** Create VisionCore module with domain models (HouseholdItem, ConfidenceScore, BarcodeResult)
**Task 7:** Implement HouseholdItemDetector with Vision Framework (UIKit bridging for UIImage input)
**Task 8:** Implement BarcodeDetector with Vision Framework (UIKit bridging for UIImage input)

**UIKit Bridging Justification for Tasks 7-8:**
- Vision Framework's `VNImageRequestHandler` requires `CGImage` (from UIImage.cgImage)
- Vision observation processing returns bounding boxes in normalized coordinates
- Converting to cropped images requires UIImage manipulation
- **ADR-010 Compliance**: UIKit used ONLY for Vision Framework input/output, NOT for UI

### Batch 4: Backend CRUD (Task 9)

**Task 9:** Implement backend items CRUD endpoints (TypeScript, Firebase Functions, Jest)

**No UIKit concerns** - TypeScript backend implementation

### Batch 5: Integration & Documentation (Tasks 10-11)

**Task 10:** Integration testing & manual verification (build, test, deploy, manual camera testing)
**Task 11:** Update sprint documentation (SPRINT-PLAN-002.md completion status)

---

## Execution Instructions for verified-stage-development Skill

**Stage 1 (Research):**
1. Read docs/adr/ADR-010-swiftui-architecture-pattern.md
2. Research Apple documentation: UIViewRepresentable, AVFoundation camera capture, Vision Framework
3. Verify UIKit bridging is acceptable for framework interop (AVFoundation, Vision)
4. Document findings in `docs/research/2025-11-15-sprint-2-uikit-bridging-research.md`

**Stage 2 (Planning):**
1. Expand Task 1-11 into bite-sized TDD steps (test-fail-implement-pass-commit)
2. For each UIKit import, add comment: `// UIKit bridging: Required for [Framework] interop`
3. Create verification checklist for ADR-010 compliance
4. Save detailed plan to `docs/plans/2025-11-15-sprint-2-detailed-execution-plan.md`
5. Request approval gate before Stage 3

**Stage 3 (Execution):**
1. Execute Batch 1 (Tasks 1-3: Camera Module)
   - Run `swift test` after EVERY step
   - Commit after EVERY passing test
   - Code review after Batch 1 complete
2. Execute Batch 2 (Tasks 4-5: Camera UI)
   - Verify CameraViewModel has NO UIKit imports
   - Verify CameraView uses UIViewRepresentable ONLY for AVCaptureVideoPreviewLayer
   - Code review after Batch 2 complete
3. Execute Batch 3 (Tasks 6-8: Vision Module)
   - Document UIKit bridging in each Vision detector
   - Code review after Batch 3 complete
4. Execute Batch 4 (Task 9: Backend CRUD)
   - Run `npm test` after implementation
   - Code review after Batch 4 complete
5. Execute Batch 5 (Tasks 10-11: Integration & Docs)
   - Run full test suite, SwiftLint, ADR drift check
   - Manual camera testing checklist
   - Final code review

**Stage 4 (Final Verification):**
1. Run `swift test` (expect: ALL PASS)
2. Run `swift build` (expect: SUCCESS, zero warnings)
3. Run `swiftlint` (expect: zero warnings)
4. Run `/check-drift` (expect: no P0 violations)
5. Manual camera testing (permission prompt, preview, capture, dismiss)
6. Verify test coverage ≥ 80% (exclude UI views)
7. Create final verification report

---

## UIKit Bridging Policy (ADR-010 Clarification)

**Permitted UIKit Usage:**
✅ `import UIKit` in files that bridge to AVFoundation (AVCapturePhoto → UIImage conversion)
✅ `import UIKit` in files that bridge to Vision Framework (UIImage → CGImage → VNImageRequestHandler)
✅ `UIViewRepresentable` for AVCaptureVideoPreviewLayer (no SwiftUI equivalent)
✅ `UIImage` as data type in protocols/models (cross-platform image representation)

**Prohibited UIKit Usage:**
❌ `UIViewController` for view hierarchy (use SwiftUI views)
❌ `UIButton`, `UILabel`, `UITextField` for UI components (use SwiftUI equivalents)
❌ `UIKit` for layout (use SwiftUI layout system)
❌ `UINavigationController` for navigation (use NavigationStack)

**Documentation Requirement:**
Every UIKit import MUST include a comment explaining the bridging justification:
```swift
import UIKit // UIKit bridging: Required for AVFoundation AVCapturePhoto → UIImage conversion
```

---

## Success Criteria

**Code Quality:**
- [ ] All tests pass (`swift test`)
- [ ] Zero SwiftLint warnings
- [ ] 80%+ test coverage (ViewModels, Services)
- [ ] No P0 ADR violations (`/check-drift`)

**Functionality:**
- [ ] Camera captures photos successfully
- [ ] Barcode detection functional (VNDetectBarcodesRequest)
- [ ] Backend CRUD endpoints functional (create, read, list items)
- [ ] HouseholdItemDetector structure complete (YOLOv3-Tiny integration deferred)

**Architecture Compliance:**
- [ ] MVVM pattern followed (ADR-010)
- [ ] UIKit imports ONLY for framework bridging
- [ ] Protocol-based dependency injection
- [ ] SwiftUI-only UI components (except UIViewRepresentable)

**Documentation:**
- [ ] UIKit bridging documented in code comments
- [ ] Sprint 2 completion status updated in SPRINT-PLAN-002.md
- [ ] Research findings documented
- [ ] Verification report created

---

## Deferred to Sprint 3

- YOLOv3-Tiny.mlmodel download and integration (34 MB model)
- Full Vision Framework VNCoreMLRequest implementation
- End-to-end camera → Vision → backend pipeline
- SwiftUI preview/snapshot testing for CameraView

---

## Notes for verified-stage-development Skill

**Approval Gates:**
1. After Stage 1 (Research): Confirm UIKit bridging interpretation with user
2. After Stage 2 (Planning): Review detailed execution plan before coding
3. After each batch (Stage 3): Code review before next batch
4. After Stage 4 (Verification): Final approval before merge

**Testing Philosophy:**
- TDD for all services and ViewModels
- Mock services for isolated testing
- SwiftUI view testing deferred (requires snapshot framework)
- Manual testing checklist for camera flow

**Commit Message Format:**
```bash
git commit -m "feat: add CameraService with AVFoundation

- Implements CameraServiceProtocol with AVFoundation
- UIKit bridging for AVCapturePhoto → UIImage conversion
- Tests: testStartSession, testCapturePhoto, testStopSession
- Coverage: 90%+ for CameraService

Refs: ADR-010 (SwiftUI architecture, UIKit bridging permitted)"
```

**Sub-Skills to Use:**
- @superpowers:test-driven-development (TDD workflow)
- @superpowers:systematic-debugging (if issues arise)
- @superpowers:verification-before-completion (before Stage 4)
- @superpowers:requesting-code-review (after each batch)

---

**Plan Created:** 2025-11-15
**Execution Model:** Verified Stage Development with Approval Gates
**Expected Duration:** 3-4 sessions (research, planning, execution, verification)
**Risk Level:** Medium (UIKit bridging interpretation, test coverage gaps)
