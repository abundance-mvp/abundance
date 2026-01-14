# TEST-LAYER1-001: Layer 1 Real-Time Object Detection Validation Test Plan

**Created**: 2025-11-12
**Updated**: 2025-11-15 (v2.0 - Sprint 3 Real-Time Architecture Refactor)
**Stage**: 6.1 - Layer 1 Validation (iOS On-Device)
**Status**: Test Plan Refactored for Real-Time Detection
**References**:
- docs/validation/VALIDATION-MASTER-001.md (v2.0)
- docs/plans/2025-11-12-stage-6.1-layer-1-validation.md
- docs/plans/2025-11-15-realtime-object-detection-refactor.md
- docs/design/CODE-EXAMPLE-009-household-item-detector.md (v2.0)
- docs/design/DESIGN-012-camera-capture-implementation.md (v2.0)
- docs/adr/ADR-013-vision-framework-strategy.md

---

## Overview

This test plan validates Layer 1 (on-device Vision Framework + YOLOv11n + real-time streaming) capabilities before Sprint 2 implementation. Tests measure functional correctness, real-time performance, quality assessment, deduplication, and organic border mask generation.

**Validate-Before-Implement Philosophy**: These tests prove Layer 1 design assumptions before writing production code (Sprint 2).

**Architecture**: Continuous 2 FPS real-time detection with CVPixelBuffer streaming, parallel multi-object processing, organic borders, quality assessment, and visual fingerprinting deduplication.

**Note**: Barcode detection moved to Layer 2b (Stage 6.3 validation) per Sprint 3 architecture refactor.

---

## Test Environment

### Device Requirements
- **Primary**: iPhone 15 Pro (A17 Pro chip, Apple Neural Engine)
- **Fallback**: iOS Simulator (acceptable for functional tests, latency will be higher)
- **OS Version**: iOS 26.0+

### Test Infrastructure
- **Framework**: XCTest (Xcode 15.0+)
- **Test Target**: AbundanceTests
- **Test Suite**: `Layer1ValidationTests/`
- **Golden Dataset**: 100 diverse household item images + ground truth labels

---

## Test Categories

### TC-001: Household Item Detection (Functional - Real-Time)

**Purpose**: Validate YOLOv11n detects household items from 18 filtered COCO classes in real-time CVPixelBuffer stream

**Input**:
- Golden dataset (100 images across 6 categories) converted to CVPixelBuffer frames
- Categories: camping (20), kitchen (20), tools (20), electronics (20), furniture (10), clothing (10)
- Simulated 2 FPS streaming (process each image as CVPixelBuffer frame)

**Expected Output**:
- Each frame returns `[DetectedObject]` array with:
  - `label`: String (one of 18 household COCO classes)
  - `confidence`: Double (0.0-1.0)
  - `boundingBox`: CGRect
  - `qualityScore`: Double (0.0-1.0, composite aesthetic + blur + lighting + completeness)
  - `catalogMode`: CatalogMode (.automatic, .manual, or .ignore)
  - `mask`: VNInstanceMaskObservation (organic border contour)
  - `fingerprint`: String (VNImageFingerprint for deduplication)
  - `alternativeLabels`: [AlternativeLabel] (top-5 YOLO predictions)

**Household COCO Classes (18 filtered from 80)**:
  - Bags: backpack, handbag, suitcase, umbrella
  - Kitchen: bottle, cup, fork, knife, spoon, bowl, wine glass
  - Furniture: chair, bed, dining table, couch, potted plant
  - Miscellaneous: tie, toilet

**Pass Criteria**:
- Classification accuracy > 60% (correct category prediction)
- Formula: `(correct_category_predictions / total_items) × 100`

**Test Case ID**: TC-001
**Swift Test Method**: `testHouseholdItemDetectionAccuracyRealTime()`
**Status**: ⚪ Pending Execution

---

### TC-002: DEPRECATED - Barcode Detection Moved to Layer 2b

**Note**: Barcode detection (VNDetectBarcodesRequest) moved to Layer 2b per Sprint 3 architecture refactor. See Stage 6.3 validation (Layer 2b) for barcode testing.

**Reason**: Real-time architecture prioritizes continuous object detection. Barcode scanning integrated into Layer 2b product search pipeline for hybrid barcode-first + visual fallback strategy.

**TC-002 Status**: ❌ Deleted (moved to Stage 6.3)

---

### TC-003: Per-Object Processing Latency (Performance - Real-Time)

**Purpose**: Validate per-object Layer 1 processing completes within 120ms (p90)

**Input**:
- Golden dataset (100 images) converted to CVPixelBuffer frames
- Device: iPhone 15 Pro with Neural Engine enabled (`MLModelConfiguration.computeUnits = .all`)

**Expected Output**:
- Latency measurement from `CVPixelBuffer` input → `DetectedObject` output (per object)
- Distribution: p50, p90, p95, p99, max
- Latency breakdown:
  - YOLO inference (YOLOv11n): ~23ms
  - Mask generation (VNGenerateForegroundInstanceMaskRequest): ~50-80ms
  - Quality assessment (VNCalculateImageAestheticsScoresRequest): ~35ms
  - Fingerprint generation (VNImageFingerprint): ~10ms
  - **Total per object**: ~108-138ms

**Pass Criteria**:
- p90 per-object latency < 120ms
- Formula: Sort latencies, take 90th percentile value
- Example: For 100 objects, 90th value must be < 120ms

**Measurement Scope**:
- **Includes**: YOLO inference + mask generation + quality assessment + fingerprint generation + catalog mode determination
- **Excludes**: Network/upload latency (that's Layer 2a)
- **Excludes**: UI rendering (border drawing)

**Test Case ID**: TC-003
**Swift Test Method**: `testPerObjectProcessingLatency()`
**Status**: ⚪ Pending Execution

---

### TC-004: Three-Tier Catalog Mode Determination (Functional)

**Purpose**: Validate three-tier catalog mode logic (automatic/manual/ignore) based on confidence + quality

**Input**:
- Sample test cases with various confidence and quality scores:
  - Case 1: confidence 0.92, quality 0.85
  - Case 2: confidence 0.89, quality 0.55
  - Case 3: confidence 0.75, quality 0.70
  - Case 4: confidence 0.65, quality 0.60
  - Case 5: confidence 0.35, quality 0.80

**Expected Output** (from 2025-11-15-realtime-object-detection-refactor.md):
- Case 1: `catalogMode == .automatic` (conf > 0.70 && quality > 0.65) → **mint green border**
- Case 2: `catalogMode == .manual` (conf > 0.70 but quality < 0.65) → **grey border**
- Case 3: `catalogMode == .automatic` (conf > 0.70 && quality > 0.65) → **mint green border**
- Case 4: `catalogMode == .manual` (conf 0.40-0.69 regardless of quality) → **grey border**
- Case 5: `catalogMode == .ignore` (conf < 0.40) → **no border, not cataloged**

**Logic**:
```swift
if confidence < 0.40 {
    return .ignore
} else if confidence > 0.70 && quality > 0.65 {
    return .automatic  // Mint green, sparkle animation, auto-upload
} else {
    return .manual     // Grey, requires double-tap to catalog
}
```

**Pass Criteria**:
- All 5 test cases return correct catalog mode

**Test Case ID**: TC-004
**Swift Test Method**: `testThreeTierCatalogModeLogic()`
**Status**: ⚪ Pending Execution

---

### TC-005: Household Class Filtering (Functional)

**Purpose**: Validate detector filters out irrelevant COCO classes (person, car, dog, etc.)

**Input**:
- Test image with mixed classes (e.g., "person holding backpack in front of car")

**Expected Output**:
- Only household-relevant classes detected: `["backpack"]`
- Irrelevant classes filtered out: `["person", "car"]` NOT in results

**Pass Criteria**:
- Zero detections from irrelevant classes (person, car, dog, bicycle, cat, horse, etc.)
- Only 18 household classes returned

**Test Case ID**: TC-005
**Swift Test Method**: `testHouseholdClassFiltering()`
**Status**: ⚪ Pending Execution

---

### TC-006: Non-Maximum Suppression (Functional)

**Purpose**: Validate NMS removes duplicate detections (overlapping bounding boxes with IoU > 0.5)

**Input**:
- Test image with overlapping objects (e.g., two backpacks stacked)

**Expected Output**:
- Duplicate detections removed
- IoU (Intersection over Union) between remaining bounding boxes < 0.5
- Example: 3 raw detections → NMS → 1-2 final detections

**Pass Criteria**:
- No more than 1-2 detections per distinct physical object
- NMS threshold: IoU > 0.5 triggers removal

**Test Case ID**: TC-006
**Swift Test Method**: `testNonMaximumSuppression()`
**Status**: ⚪ Pending Execution

---

### TC-007: Quality Assessment Integration (Functional)

**Purpose**: Validate composite quality score calculation (aesthetic + blur + lighting + completeness)

**Input**:
- Test images with known quality characteristics:
  - High quality: Well-lit, sharp, complete object, aesthetically pleasing
  - Medium quality: Acceptable lighting, slight blur, partial edge clipping
  - Low quality: Dark/overexposed, blurry, poor framing, low aesthetic score

**Expected Output**:
- Quality score (0.0-1.0) from `ImageQualityAssessor`
- Composite formula: `(aesthetic × 0.4) + (blur × 0.3) + (lighting × 0.2) + (completeness × 0.1)`
- High quality → score > 0.75
- Medium quality → score 0.50-0.75
- Low quality → score < 0.50

**Pass Criteria**:
- Quality scores align with subjective quality assessment
- Threshold validation: score > 0.65 → automatic catalog mode
- Threshold validation: score < 0.65 → manual catalog mode (grey border)

**Test Case ID**: TC-007
**Swift Test Method**: `testQualityAssessmentAccuracy()`
**Status**: ⚪ Pending Execution

---

### TC-008: Real-Time Streaming (2 FPS) (Performance - NEW)

**Purpose**: Validate frame throttling at 2 FPS (every 0.5s) for continuous detection

**Input**:
- Simulated 30 FPS camera stream (AVCaptureVideoDataOutput)
- Test duration: 10 seconds (300 frames)

**Expected Output**:
- Frames processed: ~20 (10s ÷ 0.5s = 20 frames)
- Frame throttling logic: `lastProcessedTime + 0.5s` interval
- Dropped frames: ~280 (300 - 20 = 280 frames dropped per throttling)

**Pass Criteria**:
- Processing rate: 2 FPS ± 0.2 FPS (1.8-2.2 FPS acceptable)
- Frame drop rate: > 90% (efficient throttling)

**Test Case ID**: TC-008
**Swift Test Method**: `testRealTimeStreamingThrottling()`
**Status**: ⚪ Pending Execution

---

### TC-009: Organic Border Mask Generation (Functional - NEW)

**Purpose**: Validate VNGenerateForegroundInstanceMaskRequest generates subject masks for organic borders

**Input**:
- Golden dataset (100 images) converted to CVPixelBuffer
- Each detected object bounding box

**Expected Output**:
- `VNInstanceMaskObservation` with pixel mask
- Mask success rate: > 95% (fallback to rectangular border if mask generation fails)
- Mask generation latency: 50-80ms per object

**Pass Criteria**:
- Mask generation success rate > 95%
- Mask latency p90 < 100ms

**Test Case ID**: TC-009
**Swift Test Method**: `testOrganicBorderMaskGeneration()`
**Status**: ⚪ Pending Execution

---

### TC-010: Visual Fingerprinting Deduplication (Functional - NEW)

**Purpose**: Validate VNImageFingerprint prevents re-cataloging same objects

**Input**:
- Same object photographed twice (5 different objects)
- Different objects (10 pairs of similar objects)

**Expected Output**:
- Duplicate detection: Same object → similarity > 0.90 → marked as duplicate
- Non-duplicate: Different objects → similarity < 0.90 → not marked as duplicate
- Cache TTL: Fingerprints expire after 5 minutes

**Pass Criteria**:
- False positive rate < 5% (different objects marked as duplicate)
- False negative rate < 5% (same object not marked as duplicate)
- Similarity threshold: 0.90

**Test Case ID**: TC-010
**Swift Test Method**: `testVisualFingerprintingDeduplication()`
**Status**: ⚪ Pending Execution

---

### TC-011: Parallel Multi-Object Processing (Performance - NEW)

**Purpose**: Validate 5 objects processed in parallel within ~120ms total (not sequential 5×120ms = 600ms)

**Input**:
- Test image with 5 detected household items
- Each object requires: YOLO (23ms) + mask (50-80ms) + quality (~35ms) = ~108-138ms

**Expected Output**:
- Sequential processing: 5 × 120ms = 600ms (expected if NOT parallel)
- Parallel processing: ~120ms total (using TaskGroup)

**Pass Criteria**:
- Total processing time < 150ms for 5 objects (parallel)
- Speedup factor: > 3× compared to sequential (600ms → 150ms)

**Test Case ID**: TC-011
**Swift Test Method**: `testParallelMultiObjectProcessing()`
**Status**: ⚪ Pending Execution

---

### TC-012: Deduplication Cache TTL (Functional - NEW)

**Purpose**: Validate fingerprint cache expires after 5 minutes

**Input**:
- Object photographed at t=0
- Same object photographed at t=4min (should be marked as duplicate)
- Same object photographed at t=6min (cache expired, should NOT be marked as duplicate)

**Expected Output**:
- t=0: Fingerprint added to cache
- t=4min: Cache hit → marked as duplicate
- t=6min: Cache miss (expired) → NOT marked as duplicate, new fingerprint added

**Pass Criteria**:
- TTL validation: Cache expires after 5 minutes ± 10 seconds

**Test Case ID**: TC-012
**Swift Test Method**: `testDeduplicationCacheTTL()`
**Status**: ⚪ Pending Execution

---

### TC-013: CVPixelBuffer → DetectedObject Pipeline (Integration - NEW)

**Purpose**: Validate end-to-end CVPixelBuffer input → DetectedObject output with all fields populated

**Input**:
- Single CVPixelBuffer frame with 1 household item

**Expected Output**:
- `DetectedObject` with all fields:
  - `id`: UUID (non-nil)
  - `label`: String (one of 18 household classes)
  - `confidence`: Double (0.0-1.0)
  - `boundingBox`: CGRect (valid coordinates)
  - `qualityScore`: Double (0.0-1.0)
  - `catalogMode`: CatalogMode (.automatic, .manual, or .ignore)
  - `mask`: VNInstanceMaskObservation (non-nil)
  - `fingerprint`: String (non-empty)
  - `alternativeLabels`: [AlternativeLabel] (top-5 YOLO predictions)

**Pass Criteria**:
- All fields non-nil and valid
- No crashes or errors during pipeline execution

**Test Case ID**: TC-013
**Swift Test Method**: `testCVPixelBufferToDetectedObjectPipeline()`
**Status**: ⚪ Pending Execution

---

## Test Execution Plan

### Pre-Execution Checklist

- [ ] Golden dataset (100 images) collected and committed to `ios/AbundanceTests/Layer1ValidationTests/GoldenDataset/`
- [ ] Golden dataset manifest (`golden_dataset_manifest.json`) created with ground truth labels
- [ ] HouseholdItemDetector implementation available (from CODE-EXAMPLE-009 v2.0 or Sprint 2 Story 2.2)
- [ ] SubjectMaskGenerator implementation available
- [ ] ImageQualityAssessor implementation available
- [ ] ObjectDeduplicator implementation available
- [ ] Xcode test target configured
- [ ] iPhone 15 Pro device available (or iOS Simulator as fallback)
- [ ] YOLOv11n model (yolo11n.mlmodelc) bundled in test target resources

---

### Execution Sequence

1. **Setup Phase**:
   - Load golden dataset manifest
   - Initialize HouseholdItemDetector with real VisionService (YOLOv11n)
   - Initialize SubjectMaskGenerator, ImageQualityAssessor, ObjectDeduplicator
   - Verify 100 images accessible
   - Convert images to CVPixelBuffer frames

2. **Functional Tests** (TC-001, TC-004, TC-005, TC-006, TC-007, TC-009, TC-010, TC-012, TC-013):
   - Run sequentially
   - Export results to CSV

3. **Performance Tests** (TC-003, TC-008, TC-011):
   - Run on iPhone 15 Pro device (required for accurate latency)
   - Measure p50, p90, p95, p99, max latencies
   - Export latency distribution to CSV

4. **Post-Execution**:
   - Aggregate results into validation report (VALIDATION-LAYER1-001.md)
   - Make GO/NO-GO decision based on acceptance criteria

---

## Test Execution Command

```bash
# Run on device (recommended)
xcodebuild test \
  -scheme AbundanceApp \
  -destination 'platform=iOS,name=iPhone 15 Pro' \
  -only-testing:AbundanceTests/Layer1ValidationTests

# Run on simulator (fallback)
xcodebuild test \
  -scheme AbundanceApp \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=26.0' \
  -only-testing:AbundanceTests/Layer1ValidationTests
```

---

## Test Results Export Format

### Accuracy Results CSV

**File**: `layer1_accuracy_results.csv`

```csv
id,predicted,expected,correct
camping-001,backpack,camping,true
camping-002,suitcase,camping,true
kitchen-001,cup,kitchen,true
kitchen-002,fork,kitchen,false
...
```

---

### Latency Distribution CSV

**File**: `layer1_latency_distribution.csv`

```csv
image_index,latency_ms
0,320
1,450
2,380
...
```

---

## Acceptance Criteria Summary

| Test Case | Metric | Threshold | Pass/Fail |
|-----------|--------|-----------|-----------|
| TC-001: Household item detection (real-time) | Classification accuracy | > 60% | ⚪ Pending |
| TC-002: Barcode detection | DEPRECATED | Moved to Stage 6.3 | ❌ Deleted |
| TC-003: Per-object latency | p90 latency | < 120ms | ⚪ Pending |
| TC-004: Three-tier catalog mode | Logic correctness | 100% | ⚪ Pending |
| TC-005: Household class filtering | Zero irrelevant classes | 100% | ⚪ Pending |
| TC-006: Non-Maximum Suppression | IoU threshold | < 0.5 | ⚪ Pending |
| TC-007: Quality assessment | Score accuracy | Subjective | ⚪ Pending |
| **TC-008: Real-time streaming (NEW)** | **Processing rate** | **2 FPS ± 0.2** | ⚪ Pending |
| **TC-009: Organic border masks (NEW)** | **Mask success rate** | **> 95%** | ⚪ Pending |
| **TC-010: Deduplication (NEW)** | **False positive rate** | **< 5%** | ⚪ Pending |
| **TC-011: Parallel processing (NEW)** | **5 objects total time** | **< 150ms** | ⚪ Pending |
| **TC-012: Cache TTL (NEW)** | **Expiry time** | **5 min ± 10s** | ⚪ Pending |
| **TC-013: CVPixelBuffer pipeline (NEW)** | **Integration test** | **All fields valid** | ⚪ Pending |

---

## Risks & Mitigations

### Risk 1: Golden Dataset Quality Issues
**Symptom**: Accuracy < 60% due to mislabeled ground truth
**Mitigation**: Manually review failed predictions, correct manifest labels, re-run tests

### Risk 2: Device Unavailable (iPhone 15 Pro)
**Symptom**: Cannot measure latency accurately on simulator
**Mitigation**: Accept simulator results with documented limitation, plan device testing for Sprint 2

### Risk 3: YOLO Model Not Bundled
**Symptom**: `YOLOv3Tiny.mlmodel` missing from test bundle
**Mitigation**: Download from Apple Core ML Models repository, add to test target resources

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-12 | 1.0 | Initial test plan | iOS Architecture Expert + Computer Vision & ML Engineer |
| 2025-11-15 | 2.0 | **MAJOR REFACTOR**: Update for Sprint 3 real-time object detection architecture. Update YOLOv3-Tiny → YOLOv11n, UIImage → CVPixelBuffer, latency 500ms → 120ms per object. DELETE TC-002 (barcode moved to Layer 2b). UPDATE TC-001/003/004/007 for real-time. ADD 6 NEW test cases: TC-008 (streaming), TC-009 (organic masks), TC-010 (deduplication), TC-011 (parallel), TC-012 (cache TTL), TC-013 (pipeline integration). | Stage 6.x Documentation Refactor |

---

**Status**: ✅ **TEST PLAN COMPLETE** — Ready for test implementation and execution
