# Stage: Real-time Object Detection Architecture Refactor

> **For Claude:** REQUIRED SUB-SKILL: Use `verified-stage-development` to implement this plan with research verification, planning gate, execution, and approval gates.

**Goal:** Refactor Layer 1 from single-photo capture to real-time continuous object detection with organic glowing borders, quality assessment, and visual fingerprinting deduplication.

**Architecture:** Transform existing PR #8 (Sprint 3) from button-triggered single photo capture to continuous 2 FPS real-time detection pipeline with VNGenerateForegroundInstanceMaskRequest for organic borders, parallel multi-object processing, and three-tier confidence system (automatic/manual/ignore).

**Tech Stack:** Swift 6.0, SwiftUI, Vision Framework (iOS 26+), YOLOv11n CoreML, AVFoundation, Firebase Storage, Firestore

---

## Context & Decision: Refactor PR #8 vs Fresh Start

### Current State Analysis (PR #8: `feature/sprint-2-camera-vision-layer-1`)

**What's Already Implemented (KEEP):**
- ✅ YOLOv11n.mlmodelc integrated (5.2 MB, 80 COCO classes)
- ✅ `HouseholdItemDetector.swift` with Vision Framework integration
- ✅ `StorageService.swift` with Firebase upload (timeout, retry logic)
- ✅ `CameraViewModel.swift` with AVFoundation camera service
- ✅ Firestore triggers (`onItemCreated`, `onLayer2aComplete`, `onLayer2bComplete`)
- ✅ Backend scheduled jobs (cleanup, subscription expiry)
- ✅ 96% test coverage, all CI/CD passing

**What Needs Refactoring (CHANGE):**
- ❌ Single-photo capture model (`capturePhoto()` button → single UIImage)
- ❌ Synchronous detection (blocks UI during YOLO inference)
- ❌ No real-time frame processing
- ❌ No deduplication logic
- ❌ No quality assessment
- ❌ No organic border rendering
- ❌ No multi-object parallel processing

### Decision: **REFACTOR PR #8 IN PLACE**

**Rationale:**
1. **Preserve YOLOv11n integration** - Model already working, tested, and optimized
2. **Keep Firebase infrastructure** - Storage, triggers, auth already production-ready
3. **Maintain test coverage** - 40+ Swift tests, 15 TypeScript tests all passing
4. **Lower risk** - Incremental refactor vs complete rewrite
5. **Faster delivery** - Build on existing foundation

**Refactoring Strategy:**
- Keep existing files, add new services alongside
- Deprecate `capturePhoto()`, add `processFrame()` pipeline
- Extend `HouseholdItemDetector` with `detectInStream()` method
- Add new ViewModels for real-time detection state
- Update specs in parallel with code changes

---

## Specification Documents Requiring Updates

### Files to Locate and Refactor

#### **High Priority (Core Architecture)**

1. **`docs/design/DESIGN-012-camera-capture-implementation.md`**
   - **Current:** Describes capture button → single photo flow
   - **Update:** Real-time 2 FPS stream processing, no capture button
   - **Changes:**
     - Replace button-triggered capture with continuous frame processing
     - Add throttling logic (every 0.5s)
     - Document CVPixelBuffer → YOLO pipeline

2. **`docs/design/CODE-EXAMPLE-009-household-item-detector.md`**
   - **Current:** Shows `detectHouseholdItems(in image: UIImage)` API
   - **Update:** Add `detectInStream(pixelBuffer: CVPixelBuffer)` method
   - **Changes:**
     - Add parallel detection example
     - Document real-time performance characteristics (23ms YOLO + 50-80ms mask)
     - Add quality assessment integration

3. **`docs/design/DESIGN-027-camera-capture-view-specification.md`**
   - **Current:** UI with capture button, single preview
   - **Update:** Live detection overlays, glowing borders, no button
   - **Changes:**
     - Replace capture button with continuous detection UI
     - Add OrganicBorderOverlay component spec
     - Document double-tap manual catalog gesture
     - Add sparkle animation spec

4. **`docs/design/DESIGN-004-computer-vision-pipeline.md`**
   - **Current:** Single-image detection pipeline
   - **Update:** Real-time streaming pipeline with deduplication
   - **Changes:**
     - Add VNGenerateForegroundInstanceMaskRequest integration
     - Add VNImageFingerprint deduplication logic
     - Document three-tier confidence system (auto/manual/ignore)
     - Add quality assessment pipeline

5. **`docs/abundance-analysis-pipeline-design.md`**
   - **Current:** Layer 1 described as "capture → detect → crop"
   - **Update:** Layer 1 as "continuous stream → parallel detect → quality filter → deduplicate → catalog"
   - **Changes:**
     - Update Layer 1 architecture diagram
     - Add Layer 1 output schema (multiple cropped images per frame)
     - Document FIFO processing to Layer 2

#### **Medium Priority (Integration & Patterns)**

6. **`docs/design/DESIGN-037-ui-mvvm-integration-patterns.md`**
   - **Update:** Add real-time detection ViewModel patterns
   - **Changes:**
     - Add `CameraDetectionViewModel` with `@Published var detectedObjects`
     - Document async/await frame processing
     - Add state management for parallel object detection

7. **`docs/design/CODE-EXAMPLE-002-catalog-mvvm-implementation.md`**
   - **Update:** Show automatic catalog flow (no user button press)
   - **Changes:**
     - Remove manual "Save" button flow
     - Add automatic catalog on mint border
     - Add manual catalog on double-tap

8. **`docs/design/DESIGN-013-vision-framework-integration-patterns.md`**
   - **Update:** Add iOS 17+ Vision APIs (subject masks, quality assessment)
   - **Changes:**
     - Add VNGenerateForegroundInstanceMaskRequest examples
     - Add VNCalculateImageAestheticsScoresRequest
     - Add VNDetectLensSmudgeRequest
     - Add VNGenerateImageFeaturePrintRequest

#### **Low Priority (Documentation & Testing)**

9. **`docs/roadmap/SPRINT-PLAN-003.md`**
   - **Update:** Reflect real-time detection instead of single-photo
   - **Changes:** Update Story 2.2 acceptance criteria

10. **`docs/plans/SPRINT-3-COMPLETION-REPORT.md`**
    - **Update:** Add note about real-time refactor
    - **Changes:** Link to this implementation plan

11. **`docs/design/DESIGN-028-catalog-view-specification.md`**
    - **Update:** Document automatic catalog entries (no manual "Add" flow)
    - **Changes:** Items appear in catalog automatically as mint borders trigger

12. **`docs/design/DESIGN-002-ios-client-architecture.md`**
    - **Update:** Layer 1 architecture from request/response to streaming
    - **Changes:** Update sequence diagrams

---

## New Files to Create

### Services (Sources/VisionCore/Services/)

1. **`SubjectMaskGenerator.swift`**
   - Actor for generating VNInstanceMaskObservation
   - Wraps VNGenerateForegroundInstanceMaskRequest
   - Returns organic object masks for UI rendering

2. **`ImageQualityAssessor.swift`**
   - Actor for calculating composite quality score (0.0-1.0)
   - Integrates: aesthetic score, blur detection, lighting, completeness
   - Threshold: 0.65 for automatic cataloging

3. **`ObjectDeduplicator.swift`**
   - Actor for VNImageFingerprint generation + cache
   - 5-minute TTL cache
   - Similarity threshold: 0.90

### Models (Sources/VisionCore/Models/)

4. **`DetectedObject.swift`**
   - Struct with: id, label, confidence, boundingBox, qualityScore, catalogMode, mask, fingerprint
   - Identifiable, Equatable
   - Computed property: borderColor (mint/grey based on catalogMode)

5. **`CatalogMode.swift`**
   - Enum: automatic, manual, ignore
   - Determines UI treatment and upload trigger

### ViewModels (Sources/CameraFeature/ViewModels/)

6. **`CameraDetectionViewModel.swift`**
   - MainActor class managing real-time detection state
   - `@Published var detectedObjects: [DetectedObject]`
   - Pipeline: processFrame() → parallel processing → UI updates
   - Handles double-tap gesture for manual catalog

### Views (Sources/CameraFeature/Views/)

7. **`OrganicBorderOverlay.swift`**
   - SwiftUI View rendering VNInstanceMaskObservation as Path
   - Glowing border effect using .shadow()
   - Animated pulse (1s ease-in-out repeat)
   - SparkleAnimation for automatic catalog

8. **`CameraDetectionView.swift`**
   - Main view replacing old CameraView
   - ZStack: CameraPreview + ForEach(detectedObjects) { OrganicBorderOverlay }
   - Double-tap gesture handler
   - No capture button

### Tests

9. **`SubjectMaskGeneratorTests.swift`**
10. **`ImageQualityAssessorTests.swift`**
11. **`ObjectDeduplicatorTests.swift`**
12. **`CameraDetectionViewModelTests.swift`**

---

## Files to Deprecate (Not Delete)

1. **`Sources/CameraFeature/Views/CameraView.swift`** (if exists)
   - Mark deprecated, replace usage with CameraDetectionView

2. **`CameraViewModel.capturePhoto()`**
   - Mark deprecated, keep for backward compatibility
   - Add comment directing to CameraDetectionViewModel

---

## Implementation Plan Structure

### Stage 0: Research Verification (Gate 1)

**Objective:** Verify all Vision Framework APIs, performance benchmarks, and architectural assumptions before implementation.

**Research Questions:**
1. ✅ Does VNGenerateForegroundInstanceMaskRequest work with YOLO bounding boxes?
2. ✅ Can we extract contour paths from VNInstanceMaskObservation for SwiftUI rendering?
3. ✅ Does VNImageFingerprint support similarity comparison (not just equality)?
4. ✅ Can VNCalculateImageAestheticsScoresRequest run on cropped regions?
5. ✅ What's the realistic latency for mask generation? (Research found: 50-80ms)
6. ✅ Can we process 5 objects in parallel without thermal throttling?

**Deliverables:**
- Research validation document confirming all APIs work as expected
- Performance benchmark with 5 simultaneous objects
- SwiftUI contour rendering proof-of-concept
- Go/No-Go decision

**Gate 1 Success Criteria:**
- All 6 research questions answered with working code examples
- Performance benchmark shows <120ms per object
- No blockers identified

---

### Stage 1: Foundation Services (No UI Changes)

**Objective:** Implement core services (mask generator, quality assessor, deduplicator) with 100% test coverage before touching UI.

#### Task 1.1: SubjectMaskGenerator Service

**Files:**
- Create: `Sources/VisionCore/Services/SubjectMaskGenerator.swift`
- Create: `Tests/VisionCoreTests/Services/SubjectMaskGeneratorTests.swift`

**Implementation:**
```swift
actor SubjectMaskGenerator {
    func generateMask(pixelBuffer: CVPixelBuffer, boundingBox: CGRect) async -> VNInstanceMaskObservation
    private func emptyMask() -> VNInstanceMaskObservation
}
```

**Tests:**
- Test successful mask generation
- Test empty mask fallback on error
- Test performance (<100ms per mask)

**Verification:**
```bash
swift test --filter SubjectMaskGeneratorTests
```

#### Task 1.2: ImageQualityAssessor Service

**Files:**
- Create: `Sources/VisionCore/Services/ImageQualityAssessor.swift`
- Create: `Tests/VisionCoreTests/Services/ImageQualityAssessorTests.swift`

**Implementation:**
```swift
actor ImageQualityAssessor {
    func assess(pixelBuffer: CVPixelBuffer, boundingBox: CGRect) async -> Double
    private func calculateAestheticScore(_:boundingBox:) async -> Double
    private func calculateBlurScore(_:boundingBox:) async -> Double
    private func calculateLightingScore(_:boundingBox:) -> Double
    private func calculateCompletenessScore(_:imageSize:) -> Double
}
```

**Tests:**
- Test aesthetic score calculation
- Test blur detection
- Test lighting assessment
- Test completeness score (edge detection)
- Test composite score > 0.65 threshold

**Verification:**
```bash
swift test --filter ImageQualityAssessorTests
```

#### Task 1.3: ObjectDeduplicator Service

**Files:**
- Create: `Sources/VisionCore/Services/ObjectDeduplicator.swift`
- Create: `Tests/VisionCoreTests/Services/ObjectDeduplicatorTests.swift`

**Implementation:**
```swift
actor ObjectDeduplicator {
    func generateFingerprint(pixelBuffer: CVPixelBuffer, boundingBox: CGRect) async -> String
    func isDuplicate(_ fingerprint: String) async -> Bool
    func addToCache(_ fingerprint: String) async
    private func cleanCache()
}
```

**Tests:**
- Test fingerprint generation
- Test cache hit/miss
- Test TTL expiration (5 minutes)
- Test similarity threshold (0.90)

**Verification:**
```bash
swift test --filter ObjectDeduplicatorTests
swift test # All tests must still pass
```

---

### Stage 2: Models & Business Logic

**Objective:** Add new domain models and extend HouseholdItemDetector with real-time capabilities.

#### Task 2.1: DetectedObject Model

**Files:**
- Create: `Sources/VisionCore/Models/DetectedObject.swift`
- Create: `Sources/VisionCore/Models/CatalogMode.swift`
- Create: `Tests/VisionCoreTests/Models/DetectedObjectTests.swift`

**Implementation:**
```swift
struct DetectedObject: Identifiable, Equatable {
    let id: UUID
    let label: String
    let confidence: Double
    let boundingBox: CGRect
    let qualityScore: Double
    var catalogMode: CatalogMode
    let mask: VNInstanceMaskObservation
    let fingerprint: String
    let alternativeLabels: [AlternativeLabel]

    var borderColor: Color { ... }
}

enum CatalogMode {
    case automatic, manual, ignore
}
```

**Tests:**
- Test model initialization
- Test borderColor computed property
- Test Equatable conformance

#### Task 2.2: Extend HouseholdItemDetector

**Files:**
- Modify: `Sources/VisionCore/Services/HouseholdItemDetector.swift`
- Modify: `Sources/VisionCore/Services/HouseholdItemDetectorProtocol.swift`
- Update: `Tests/VisionCoreTests/Services/HouseholdItemDetectorTests.swift`

**Changes:**
```swift
// ADD to protocol
func detectInStream(pixelBuffer: CVPixelBuffer) async throws -> [YOLOResult]

// Keep existing method for backward compatibility
func detectHouseholdItems(in image: PlatformImage) async throws -> [HouseholdItem]
```

**New YOLOResult struct:**
```swift
struct YOLOResult {
    let label: String
    let confidence: Double
    let boundingBox: CGRect
    let alternativeLabels: [AlternativeLabel]
}
```

**Tests:**
- Test detectInStream with CVPixelBuffer
- Test parallel detection of 5 objects
- Test performance (<30ms for YOLO inference)

**Verification:**
```bash
swift test --filter HouseholdItemDetectorTests
```

---

### Stage 3: ViewModel & State Management (Gate 2)

**Objective:** Implement CameraDetectionViewModel with real-time frame processing pipeline.

**Gate 2 Review:**
- All Stage 1 & 2 tests passing
- Service implementations complete
- Models validated
- No regressions in existing tests

#### Task 3.1: CameraDetectionViewModel

**Files:**
- Create: `Sources/CameraFeature/ViewModels/CameraDetectionViewModel.swift`
- Create: `Tests/CameraFeatureTests/ViewModels/CameraDetectionViewModelTests.swift`

**Implementation:**
```swift
@MainActor
class CameraDetectionViewModel: ObservableObject {
    @Published var detectedObjects: [DetectedObject] = []
    @Published var isProcessing: Bool = false

    private let yoloDetector: HouseholdItemDetectorProtocol
    private let qualityAssessor: ImageQualityAssessor
    private let deduplicator: ObjectDeduplicator
    private let maskGenerator: SubjectMaskGenerator
    private let catalogService: CatalogServiceProtocol

    func processFrame(_ pixelBuffer: CVPixelBuffer) async
    private func processObject(_ yoloResult: YOLOResult, in pixelBuffer: CVPixelBuffer) async -> DetectedObject?
    private func determineCatalogMode(confidence: Double, quality: Double) -> CatalogMode
    func catalogObject(_ object: DetectedObject, pixelBuffer: CVPixelBuffer) async
    func handleDoubleTap(at location: CGPoint) async
}
```

**Tests:**
- Test processFrame with mock YOLO results
- Test parallel object processing
- Test catalog mode determination
  - confidence: 0.92, quality: 0.85 → automatic
  - confidence: 0.89, quality: 0.55 → manual
  - confidence: 0.35, quality: 0.70 → ignore
- Test double-tap handler
- Test deduplication integration

**Verification:**
```bash
swift test --filter CameraDetectionViewModelTests
swift test # All tests pass
```

#### Task 3.2: Deprecate Old CameraViewModel.capturePhoto()

**Files:**
- Modify: `Sources/CameraFeature/ViewModels/CameraViewModel.swift`

**Changes:**
```swift
@available(*, deprecated, message: "Use CameraDetectionViewModel for real-time detection")
public func capturePhoto() async { ... }
```

**Add comment:**
```swift
// DEPRECATED: Single-photo capture replaced with real-time detection
// See: CameraDetectionViewModel.processFrame() for new API
```

---

### Stage 4: SwiftUI Views & UI (Gate 3)

**Objective:** Implement organic border rendering, sparkle animations, and gesture handling.

**Gate 3 Review:**
- ViewModel tests passing
- Frame processing pipeline working
- Ready for UI integration

#### Task 4.1: OrganicBorderShape

**Files:**
- Create: `Sources/CameraFeature/Views/Components/OrganicBorderShape.swift`
- Create: `Tests/CameraFeatureTests/Views/OrganicBorderShapeTests.swift`

**Implementation:**
```swift
struct OrganicBorderShape: Shape {
    let mask: VNInstanceMaskObservation

    func path(in rect: CGRect) -> Path
    private func extractMaskPixels(from mask: VNInstanceMaskObservation) -> [[Bool]]
    private func traceContour(_ pixels: [[Bool]]) -> [CGPoint]
}
```

**Algorithm:** Marching squares for contour tracing

**Tests:**
- Test contour extraction from mask
- Test path generation
- Test empty mask fallback (rectangular path)

#### Task 4.2: OrganicBorderOverlay

**Files:**
- Create: `Sources/CameraFeature/Views/Components/OrganicBorderOverlay.swift`
- Create: `Sources/CameraFeature/Views/Components/SparkleAnimation.swift`

**Implementation:**
```swift
struct OrganicBorderOverlay: View {
    let object: DetectedObject
    @State private var isAnimating = false

    var body: some View { ... }
}

struct SparkleAnimation: View {
    @State private var sparkles: [Sparkle] = []

    private func generateSparkles()
}
```

**Features:**
- Glowing border with pulsing shadow
- Mint green for automatic, grey for manual
- Sparkle animation on automatic catalog

#### Task 4.3: CameraDetectionView

**Files:**
- Create: `Sources/CameraFeature/Views/CameraDetectionView.swift`

**Implementation:**
```swift
struct CameraDetectionView: View {
    @StateObject private var viewModel = CameraDetectionViewModel()
    @State private var cameraService: CameraService

    var body: some View {
        ZStack {
            CameraPreviewView(cameraService: cameraService)
            ForEach(viewModel.detectedObjects) { object in
                OrganicBorderOverlay(object: object)
            }
        }
        .gesture(doubleTapGesture)
        .task { processFrameLoop() }
    }
}
```

**Tests:** (SwiftUI Preview tests + manual testing)
- Preview with mock detections
- Verify border rendering
- Verify double-tap gesture

**Verification:**
```bash
# Manual testing checklist:
- [ ] Camera preview shows live feed
- [ ] Organic borders appear around detected objects
- [ ] Mint green for high confidence + quality
- [ ] Grey for low quality
- [ ] Double-tap triggers manual catalog
- [ ] Sparkles play on automatic catalog
- [ ] Borders fade after upload
```

---

### Stage 5: Integration & Catalog Service

**Objective:** Connect detection pipeline to Firebase Storage and Firestore (Layer 2 handoff).

#### Task 5.1: Update CatalogService

**Files:**
- Modify: `Sources/Persistence/Firebase/CatalogService.swift` (create if not exists)

**Add methods:**
```swift
protocol CatalogServiceProtocol {
    func upload(image: CIImage, metadata: CatalogMetadata) async throws -> UploadResult
    func catalogManually(_ object: DetectedObject) async throws
}

struct CatalogMetadata {
    let label: String
    let confidence: Double
    let qualityScore: Double
    let catalogMode: CatalogMode
    let fingerprint: String
    let boundingBox: CGRect
    let alternativeLabels: [AlternativeLabel]
}
```

**Integration:**
- Crop image using boundingBox
- Upload to GCS: `users/{userId}/items/{itemId}/{objectId}.jpg`
- Create Firestore document with Layer 1 schema
- Trigger backend `onItemCreated`

#### Task 5.2: Update Firestore Schema

**Files:**
- Update: `docs/design/DESIGN-XXX-firestore-schema.md` (locate or create)

**Layer 1 Document Schema:**
```typescript
{
  itemId: string,
  userId: string,
  status: "processing" | "layer2a_complete" | "layer2b_complete" | "complete",

  layer1: {
    originalImageUrl?: string,  // Optional: full frame (if we want to save it)
    detectedObjects: [
      {
        uuid: string,
        label: string,
        confidence: number,
        boundingBox: { x, y, width, height },
        croppedImageUrl: string,
        croppedStoragePath: string,
        qualityScore: number,
        catalogMode: "automatic" | "manual",
        fingerprint: string,
        alternativeLabels: [{ label, confidence }]
      }
    ],
    processingMetadata: {
      yoloProcessingTime: number,
      modelVersion: "YOLOv11n",
      frameTimestamp: string,
      deviceModel: string,
      iosVersion: string
    },
    capturedAt: Timestamp
  },

  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

**Tests:**
- Test Firestore document creation
- Test schema validation
- Test trigger firing

---

### Stage 6: Documentation Updates (Gate 4)

**Objective:** Update all spec documents to reflect new architecture.

**Gate 4 Review:**
- All features implemented
- All tests passing
- Manual testing complete
- Ready for documentation

#### Task 6.1: Update Design Docs (Batch 1)

**Files to update:**
1. `docs/design/DESIGN-012-camera-capture-implementation.md`
2. `docs/design/CODE-EXAMPLE-009-household-item-detector.md`
3. `docs/design/DESIGN-027-camera-capture-view-specification.md`

**Changes:** See "Specification Documents Requiring Updates" section above

**Verification:**
```bash
# Run doc validator
./scripts/validate-docs.sh
```

#### Task 6.2: Update Design Docs (Batch 2)

**Files to update:**
4. `docs/design/DESIGN-004-computer-vision-pipeline.md`
5. `docs/abundance-analysis-pipeline-design.md`
6. `docs/design/DESIGN-013-vision-framework-integration-patterns.md`

#### Task 6.3: Update Design Docs (Batch 3)

**Files to update:**
7. `docs/design/DESIGN-037-ui-mvvm-integration-patterns.md`
8. `docs/design/CODE-EXAMPLE-002-catalog-mvvm-implementation.md`
9. `docs/design/DESIGN-028-catalog-view-specification.md`

#### Task 6.4: Update Sprint Plans

**Files to update:**
10. `docs/roadmap/SPRINT-PLAN-003.md`
11. `docs/plans/SPRINT-3-COMPLETION-REPORT.md`
12. `docs/design/DESIGN-002-ios-client-architecture.md`

---

### Stage 7: Performance Validation & Optimization (Final Gate)

**Objective:** Benchmark real-world performance and validate against budget.

#### Task 7.1: Performance Benchmarks

**Create:**
- `Tests/PerformanceTests/DetectionPipelineBenchmark.swift`

**Benchmarks:**
```swift
func testYOLOInferenceSpeed() {
    measure { /* Should be < 30ms */ }
}

func testMaskGenerationSpeed() {
    measure { /* Should be < 80ms */ }
}

func testQualityAssessmentSpeed() {
    measure { /* Should be < 35ms */ }
}

func testEndToEndPipelineSpeed() {
    measure { /* Should be < 120ms per object */ }
}

func testParallel5ObjectsSpeed() {
    measure { /* Should be < 120ms total (parallel) */ }
}
```

**Success Criteria:**
- YOLO: <30ms ✅
- Mask generation: <80ms ✅
- Quality assessment: <35ms ✅
- End-to-end per object: <120ms ✅
- 5 objects parallel: <120ms total ✅

#### Task 7.2: Battery Impact Testing

**Manual test:**
- 30-minute continuous detection session
- Measure battery drain
- Target: <15% battery consumption

**Log results:**
- Create: `Tests/manual-test-realtime-detection.log`

#### Task 7.3: Memory Profiling

**Instruments profiling:**
- Check for memory leaks
- Verify CVPixelBuffer cleanup
- Confirm actor isolation prevents data races

**Target:** No memory leaks, stable memory usage

---

## Acceptance Criteria (Final Approval Gate)

### Functionality
- [ ] Real-time detection at 2 FPS (every 0.5s)
- [ ] Organic glowing borders rendered using VNInstanceMaskObservation
- [ ] Three-tier confidence system working:
  - [ ] Automatic (mint green): confidence > 0.70 && quality > 0.65
  - [ ] Manual (grey): confidence 0.40-0.69 || quality < 0.65
  - [ ] Ignored: confidence < 0.40
- [ ] Visual fingerprinting deduplication (5-min cache, 0.90 similarity)
- [ ] Quality assessment (aesthetic + blur + lighting + completeness)
- [ ] Parallel processing of 5+ objects simultaneously
- [ ] Double-tap manual catalog working
- [ ] Sparkle animation on automatic catalog
- [ ] Firebase Storage upload with cropped images
- [ ] Firestore document creation with Layer 1 schema
- [ ] Backend trigger firing (`onItemCreated`)

### Performance
- [ ] YOLO inference: <30ms
- [ ] Subject mask generation: <80ms
- [ ] Total pipeline per object: <120ms
- [ ] 5 objects parallel: <120ms total
- [ ] Battery drain (30 min): <15%
- [ ] No memory leaks
- [ ] No thermal throttling under continuous use

### Code Quality
- [ ] 100% test coverage for new services
- [ ] All existing tests still passing (no regressions)
- [ ] SwiftLint: zero warnings
- [ ] ADR-010 compliance (SwiftUI-only, no UIKit for UI)
- [ ] All files properly documented (DocC comments)
- [ ] All TODOs resolved or tracked in issues

### Documentation
- [ ] All 12 spec documents updated
- [ ] Architecture diagrams reflect new pipeline
- [ ] Layer 1 → Layer 2 contract documented
- [ ] API documentation complete
- [ ] Manual testing log created

### Integration
- [ ] PR #8 updated with new implementation
- [ ] All CI/CD workflows passing
- [ ] No breaking changes to existing APIs (backward compatible)
- [ ] Migration guide for old CameraViewModel users

---

## Risk Mitigation

### Risk 1: VNGenerateForegroundInstanceMaskRequest Performance
**Impact:** High (may not achieve 120ms target)
**Mitigation:**
- Research phase validates performance first
- Fallback to rectangular borders if too slow
- Option to disable masks on older devices

### Risk 2: Deduplication False Positives
**Impact:** Medium (may skip valid objects)
**Mitigation:**
- Tunable similarity threshold (default 0.90)
- Short cache TTL (5 minutes)
- Manual mode always available

### Risk 3: Quality Assessment Accuracy
**Impact:** Medium (may misclassify good/bad images)
**Mitigation:**
- Conservative threshold (0.65)
- Manual mode fallback for grey borders
- User can always double-tap to force catalog

### Risk 4: iOS Version Compatibility
**Impact:** Low (iOS 26+ only)
**Mitigation:**
- Confirmed iOS 26 is target deployment
- VNGenerateForegroundInstanceMaskRequest available iOS 17+
- All APIs supported on target platform

---

## Rollback Plan

If critical issues found after implementation:

1. **Revert to PR #8 state:** `git revert <merge-commit>`
2. **Keep YOLOv11n model:** Already working
3. **Keep Firebase integration:** No changes needed
4. **Restore capture button:** Uncomment old CameraViewModel

**Rollback trigger conditions:**
- Performance <2 FPS sustained
- Battery drain >20% in 30 minutes
- Critical crash in production
- Test coverage drops below 80%

---

## Timeline Estimate

- **Stage 0 (Research):** 2-3 hours
- **Stage 1 (Services):** 4-6 hours
- **Stage 2 (Models):** 2-3 hours
- **Stage 3 (ViewModel):** 3-4 hours
- **Stage 4 (SwiftUI):** 4-6 hours
- **Stage 5 (Integration):** 3-4 hours
- **Stage 6 (Documentation):** 4-5 hours
- **Stage 7 (Performance):** 2-3 hours

**Total:** 24-34 hours (3-4 working days)

---

## Notes

- This refactors PR #8 branch: `feature/sprint-2-camera-vision-layer-1`
- Target iOS: 26+ (liquid glass Swift native app)
- YOLO model: YOLOv11n.mlmodelc (already integrated)
- Minimum confidence: 0.40 (manual mode), 0.70 (automatic)
- Quality threshold: 0.65
- Deduplication cache: 5 minutes, 0.90 similarity
- Frame rate: 2 FPS (every 0.5s)
- Max objects per frame: Unlimited (processes all in parallel)

---

**Generated by:** Brainstorming session (2025-11-15)
**Execution Method:** `verified-stage-development` skill
**Related Documents:**
- Original architecture: `Tests/VisionCoreTests/Resources/example-catalog-pipeline/README.md`
- PR #8: Sprint 3 Layer 1 Complete & Backend Integration
- Sprint Plan: `docs/roadmap/SPRINT-PLAN-003.md`
