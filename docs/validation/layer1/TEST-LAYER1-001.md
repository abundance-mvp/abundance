# TEST-LAYER1-001: Layer 1 On-Device Validation Test Plan

**Created**: 2025-11-12
**Stage**: 6.1 - Layer 1 Validation (iOS On-Device)
**Status**: Test Plan Complete
**References**:
- docs/validation/VALIDATION-MASTER-001.md
- docs/plans/2025-11-12-stage-6.1-layer-1-validation.md
- docs/design/CODE-EXAMPLE-009-household-item-detector.md
- docs/adr/ADR-013-vision-framework-strategy.md

---

## Overview

This test plan validates Layer 1 (on-device Vision Framework + YOLOv3-Tiny + barcode detection) capabilities before Sprint 2 implementation. Tests measure functional correctness, performance benchmarks, and edge case handling.

**Validate-Before-Implement Philosophy**: These tests prove Layer 1 design assumptions before writing production code (Sprint 2).

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

### TC-001: Household Item Detection (Functional)

**Purpose**: Validate Vision Framework detects household items from 18 filtered COCO classes

**Input**:
- Golden dataset (100 images across 6 categories)
- Categories: camping (20), kitchen (20), tools (20), electronics (20), furniture (10), clothing (10)

**Expected Output**:
- Each image returns 1+ household item detections
- Detected label matches one of 18 household COCO classes:
  - Bags: backpack, handbag, suitcase, umbrella
  - Kitchen: bottle, cup, fork, knife, spoon, bowl, wine glass
  - Furniture: chair, bed, dining table, couch, potted plant
  - Miscellaneous: tie, toilet

**Pass Criteria**:
- Classification accuracy > 60% (correct category prediction)
- Formula: `(correct_category_predictions / total_items) × 100`

**Test Case ID**: TC-001
**Swift Test Method**: `testHouseholdItemDetectionAccuracy()`
**Status**: ⚪ Pending Execution

---

### TC-002: Barcode Detection (Functional)

**Purpose**: Validate VNDetectBarcodesRequest detects barcodes and extracts payloads

**Input**:
- 50 barcode-bearing images (subset of golden dataset where `barcode != null`)
- Symbologies: UPC-A, EAN-13, QR Code (primary), plus 21 additional symbologies

**Expected Output**:
- Barcode detected (bounding box)
- Payload string extracted correctly
- Example: UPC-A → 12-digit string "012345678905"

**Pass Criteria**:
- Detection success rate > 95%
- Formula: `(correctly_detected_barcodes / total_barcode_images) × 100`
- "Correct" = barcode payload matches `ground_truth.barcode` field in manifest

**Test Case ID**: TC-002
**Swift Test Method**: `testBarcodeDetectionAccuracy()`
**Status**: ⚪ Pending Execution

---

### TC-003: Processing Latency (Performance)

**Purpose**: Validate end-to-end Layer 1 processing completes within 500ms (p90)

**Input**:
- Golden dataset (100 images)
- Device: iPhone 15 Pro with Neural Engine enabled (`MLModelConfiguration.computeUnits = .all`)

**Expected Output**:
- Latency measurement from `UIImage` input → `[HouseholdItem]` output
- Distribution: p50, p90, p95, p99, max

**Pass Criteria**:
- p90 latency < 500ms
- Formula: Sort latencies, take 90th percentile value
- Example: For 100 measurements, 90th value must be < 500ms

**Measurement Scope**:
- **Includes**: Object detection + household class filtering + NMS + confidence scoring
- **Excludes**: Edge case detection (blur) if disabled by default
- **Excludes**: Network/upload latency (that's Layer 2a)

**Test Case ID**: TC-003
**Swift Test Method**: `testProcessingLatency()`
**Status**: ⚪ Pending Execution

---

### TC-004: Confidence Categorization (Functional)

**Purpose**: Validate confidence scores are categorized correctly (high/medium/low)

**Input**:
- Sample confidence scores: 0.85, 0.75, 0.65, 0.5

**Expected Output** (from CODE-EXAMPLE-009):
- `ConfidenceScore(raw: 0.85).category == .high` (> 0.8)
- `ConfidenceScore(raw: 0.75).category == .medium` (0.6 - 0.8)
- `ConfidenceScore(raw: 0.65).category == .medium` (0.6 - 0.8)
- `ConfidenceScore(raw: 0.5).category == .low` (< 0.6)

**Pass Criteria**:
- All categorizations match CODE-EXAMPLE-009 specification

**Test Case ID**: TC-004
**Swift Test Method**: `testConfidenceCategorization()`
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

### TC-007: Edge Case Detection (Functional)

**Purpose**: Validate low-light and blur detection warnings

**Input**:
- Low-light image (brightness < 50)
- Blurry image (Laplacian variance < 100)

**Expected Output**:
- Low-light warning: "Image is too dark. Try using flash or better lighting."
- Blur warning: "Image is blurry. Hold camera steady and retake."

**Pass Criteria**:
- Warning messages generated for edge cases
- Brightness threshold: < 50
- Blur threshold: < 100 (Laplacian variance)

**Test Case ID**: TC-007
**Swift Test Method**: `testEdgeCaseDetection()`
**Status**: ⚪ Pending Execution

---

## Test Execution Plan

### Pre-Execution Checklist

- [ ] Golden dataset (100 images) collected and committed to `ios/AbundanceTests/Layer1ValidationTests/GoldenDataset/`
- [ ] Golden dataset manifest (`golden_dataset_manifest.json`) created with ground truth labels
- [ ] HouseholdItemDetector implementation available (from CODE-EXAMPLE-009 or Sprint 2 Story 2.2)
- [ ] BarcodeService implementation available
- [ ] Xcode test target configured
- [ ] iPhone 15 Pro device available (or iOS Simulator as fallback)

---

### Execution Sequence

1. **Setup Phase**:
   - Load golden dataset manifest
   - Initialize HouseholdItemDetector with real VisionService
   - Verify 100 images accessible

2. **Functional Tests** (TC-001, TC-002, TC-004, TC-005, TC-006, TC-007):
   - Run sequentially
   - Export results to CSV

3. **Performance Tests** (TC-003):
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
| TC-001: Household item detection | Classification accuracy | > 60% | ⚪ Pending |
| TC-002: Barcode detection | Detection success rate | > 95% | ⚪ Pending |
| TC-003: Processing latency | p90 latency | < 500ms | ⚪ Pending |
| TC-004: Confidence categorization | Manual verification | 100% | ⚪ Pending |
| TC-005: Household class filtering | Zero irrelevant classes | 100% | ⚪ Pending |
| TC-006: Non-Maximum Suppression | IoU threshold | < 0.5 | ⚪ Pending |
| TC-007: Edge case detection | Warning messages | Manual | ⚪ Pending |

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

---

**Status**: ✅ **TEST PLAN COMPLETE** — Ready for test implementation and execution
