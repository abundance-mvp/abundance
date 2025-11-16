# Stage 6.x Documentation Refactor Analysis

**Date**: 2025-11-15
**Purpose**: Identify and document all Stage 6.0, 6.1, 6.2 validation documents impacted by Sprint 3 real-time object detection architecture changes
**Related**: CHECKPOINT-stage-6.1-documentation-refactor-2025-11-15.md, 2025-11-15-realtime-object-detection-refactor.md

---

## Executive Summary

Sprint 3 introduced a **major architectural shift** from button-triggered single-photo capture to continuous 2 FPS real-time object detection with organic borders, quality assessment, and visual fingerprinting deduplication. This refactor documented 5 high-priority spec files (DESIGN-012, CODE-EXAMPLE-009, DESIGN-027, DESIGN-004, abundance-analysis-pipeline-design.md).

However, **Stage 6.x validation documents** (created in Stage 6.0/6.1/6.2 BEFORE Sprint 3) still reference the **OLD architecture** and must be refactored to align with the new Layer 1 design.

---

## Sprint 3 Architectural Changes Summary

### OLD Architecture (Pre-Sprint 3)
- **Trigger**: Button press → single photo capture
- **Model**: YOLOv3-Tiny (34 MB, 80 COCO classes)
- **Input**: UIImage (captured photo)
- **Processing**: VNCoreMLRequest + VNDetectBarcodesRequest
- **Output**: Bounding boxes, household items (18 filtered classes), barcodes
- **Latency**: 300-500ms per photo
- **UI**: Capture button, rectangular bounding boxes
- **Confidence**: Simple high/medium/low categorization

### NEW Architecture (Sprint 3)
- **Trigger**: Continuous 2 FPS automatic detection
- **Model**: YOLOv11n (5.2 MB compiled, 10x smaller, faster, more accurate)
- **Input**: CVPixelBuffer (real-time camera stream)
- **Processing**:
  - VNCoreMLRequest (YOLOv11n)
  - **NEW**: VNGenerateForegroundInstanceMaskRequest (organic subject masks)
  - **NEW**: VNImageFingerprint (visual deduplication, 5-min cache, 0.90 similarity)
  - **NEW**: VNCalculateImageAestheticsScoresRequest (quality assessment)
  - **NEW**: Parallel multi-object processing (5 objects simultaneously in ~120ms)
- **Output**: Cropped objects + quality scores + deduplication fingerprints + organic masks
- **Latency**: 23ms YOLO + 50-80ms mask + quality assessment = **~120ms per object**
- **UI**: Organic glowing borders (mint green/grey), sparkle animations, double-tap gesture for manual catalog
- **Confidence**: Three-tier catalog mode (automatic >0.70 && quality>0.65, manual 0.40-0.69, ignore <0.40)
- **Privacy**: Full frames NEVER leave device (only cropped objects uploaded)

### New Services Documented
1. **SubjectMaskGenerator**: VNGenerateForegroundInstanceMaskRequest wrapper (50-80ms per object)
2. **ImageQualityAssessor**: Composite quality score (aesthetic + blur + lighting + completeness)
3. **ObjectDeduplicator**: VNImageFingerprint cache (5-min TTL, 0.90 similarity threshold)

### Deprecated Components
- **CameraViewModel.capturePhoto()**: Marked @available(*, deprecated)
- **HouseholdItemDetector.detectHouseholdItems(UIImage)**: Marked deprecated
- **Capture Button UI**: Removed
- **Rectangular Bounding Boxes**: Replaced with organic borders

---

## Impacted Stage 6.x Documents

### Stage 6.0: VALIDATION-MASTER-001.md

**File**: `docs/validation/VALIDATION-MASTER-001.md`
**Status**: Created 2025-11-12 (BEFORE Sprint 3 refactor)
**Impact**: **MEDIUM** — References OLD architecture

**Specific Changes Needed**:

1. **Line 50**: `Technology: Vision Framework + Core ML (YOLOv3-Tiny)`
   - ❌ OLD: YOLOv3-Tiny
   - ✅ NEW: **YOLOv11n**

2. **Line 56-57**: `Processing latency < 500ms`
   - ❌ OLD: < 500ms (single-photo)
   - ✅ NEW: **< 120ms per object** (real-time streaming, parallel processing)
   - ✅ NEW: Add latency breakdown: YOLO 23ms + mask 50-80ms + quality ~35ms

3. **Missing Key Validations**:
   - ✅ ADD: Real-time streaming (2 FPS) validation
   - ✅ ADD: Organic border mask generation (VNGenerateForegroundInstanceMaskRequest)
   - ✅ ADD: Visual fingerprinting deduplication (VNImageFingerprint, 0.90 similarity)
   - ✅ ADD: Quality assessment (VNCalculateImageAestheticsScoresRequest)
   - ✅ ADD: Three-tier confidence system validation (automatic/manual/ignore)
   - ✅ ADD: Parallel multi-object processing (5 objects simultaneously)

4. **Line 171**: Barcode detection in Layer 1
   - ❌ OLD: Barcode detection is part of Layer 1
   - ✅ NEW: **Barcode moved to Layer 2b** (per DESIGN-027 refactor)
   - Update: Barcode detection validation should move from Stage 6.1 to Stage 6.3

5. **Test Infrastructure (Line 160-184)**:
   - ✅ ADD: Real-time frame processing test
   - ✅ ADD: CVPixelBuffer input validation
   - ✅ ADD: Mask contour extraction test
   - ✅ ADD: Deduplication cache test (5-min TTL)

6. **Acceptance Criteria (Line 228-234)**:
   - ❌ OLD: `Household item detection accuracy > 60%`
   - ✅ NEW: **Keep 60% threshold** (still valid for category accuracy)
   - ❌ OLD: `Barcode detection accuracy > 95%`
   - ✅ NEW: **Move to Stage 6.3** (Layer 2b validation)
   - ❌ OLD: `Processing latency < 500ms`
   - ✅ NEW: **Per-object latency < 120ms** (parallel processing)
   - ✅ ADD: `Quality assessment threshold > 0.65`
   - ✅ ADD: `Deduplication false positive rate < 5%`

---

### Stage 6.1: TEST-LAYER1-001.md

**File**: `docs/validation/layer1/TEST-LAYER1-001.md`
**Status**: Created 2025-11-12 (BEFORE Sprint 3 refactor)
**Impact**: **HIGH** — Core test plan outdated

**Specific Changes Needed**:

1. **Overview (Line 14-18)**:
   - ❌ OLD: "YOLOv3-Tiny + barcode detection"
   - ✅ NEW: **YOLOv11n + organic masks + quality assessment + deduplication** (barcode → Layer 2b)

2. **TC-001: Household Item Detection (Line 39-62)**:
   - ❌ OLD: Input = "Golden dataset (100 images)"
   - ✅ NEW: Input = **"CVPixelBuffer frames (simulating 2 FPS stream)"**
   - ❌ OLD: Expected Output = "Each image returns 1+ household item detections"
   - ✅ NEW: Expected Output = **"Each frame returns DetectedObject array with qualityScore, catalogMode, mask, fingerprint"**
   - Keep accuracy threshold: > 60% (still valid)

3. **TC-002: Barcode Detection (Line 66-86)**:
   - ❌ OLD: Barcode detection in Layer 1
   - ✅ NEW: **DELETE THIS TEST CASE** (barcode moved to Layer 2b, Stage 6.3 validation)

4. **TC-003: Processing Latency (Line 88-114)**:
   - ❌ OLD: "p90 latency < 500ms" (UIImage input)
   - ✅ NEW: **"Per-object latency < 120ms (p90)"** (CVPixelBuffer input, parallel processing)
   - ✅ NEW: Latency breakdown: YOLO 23ms + mask 50-80ms + quality ~35ms
   - ✅ NEW: Add parallel processing test: 5 objects simultaneously in ~120ms total

5. **TC-004: Confidence Categorization (Line 116-136)**:
   - ❌ OLD: Simple high/medium/low (> 0.8, 0.6-0.8, < 0.6)
   - ✅ NEW: **Three-tier catalog mode** (automatic/manual/ignore)
   - ✅ NEW: Test cases:
     - confidence 0.92, quality 0.85 → **automatic**
     - confidence 0.89, quality 0.55 → **manual**
     - confidence 0.75, quality 0.70 → **automatic**
     - confidence 0.35, quality 0.80 → **ignore**

6. **TC-006: Non-Maximum Suppression (Line 160-178)**:
   - ✅ KEEP: NMS still part of YOLO pipeline (YOLOv11n has built-in NMS)

7. **TC-007: Edge Case Detection (Line 180-203)**:
   - ❌ OLD: Low-light and blur detection warnings
   - ✅ NEW: **Quality assessment integrated** (aesthetic + blur + lighting + completeness)
   - ✅ UPDATE: Test quality score < 0.65 → catalogMode = manual (grey border)

8. **NEW TEST CASES NEEDED**:
   - **TC-NEW-001**: Real-Time Streaming (2 FPS frame throttling)
   - **TC-NEW-002**: Organic Border Mask Generation (VNGenerateForegroundInstanceMaskRequest)
   - **TC-NEW-003**: Visual Fingerprinting Deduplication (VNImageFingerprint, 0.90 similarity)
   - **TC-NEW-004**: Quality Assessment (VNCalculateImageAestheticsScoresRequest, threshold 0.65)
   - **TC-NEW-005**: Parallel Multi-Object Processing (5 objects simultaneously)
   - **TC-NEW-006**: Three-Tier Catalog Mode Logic

---

### Stage 6.1: BENCHMARK-LAYER1-001.md

**File**: `docs/validation/layer1/BENCHMARK-LAYER1-001.md`
**Status**: Created 2025-11-12 (BEFORE Sprint 3 refactor)
**Impact**: **HIGH** — Performance benchmarks outdated

**Specific Changes Needed**:

1. **Overview (Line 14-16)**:
   - ❌ OLD: "YOLOv3-Tiny"
   - ✅ NEW: **YOLOv11n**

2. **Category Mapping (Line 75-95)**:
   - ✅ VERIFY: 18 household COCO classes still valid for YOLOv11n (80 classes total)
   - Likely unchanged, but should verify YOLOv11n uses same COCO class IDs

3. **Accuracy Threshold (Line 97-103)**:
   - ❌ OLD: "YOLOv3-Tiny raw accuracy: 33.1% mAP on COCO"
   - ✅ NEW: **YOLOv11n raw accuracy: ~47% mAP on COCO** (significant improvement)
   - ✅ NEW: Update rationale: Better baseline accuracy → higher expected filtered accuracy

4. **Barcode Detection Accuracy (Line 115-142)**:
   - ❌ OLD: Barcode detection metrics
   - ✅ NEW: **DELETE THIS SECTION** (barcode moved to Layer 2b)

5. **Latency Metrics (Line 144-183)**:
   - ❌ OLD: "Processing latency: UIImage input → [HouseholdItem] output"
   - ✅ NEW: **"Per-object latency: CVPixelBuffer frame → DetectedObject with mask + quality + fingerprint"**
   - ❌ OLD: "p90 < 500ms"
   - ✅ NEW: **"p90 < 120ms per object"**
   - ✅ NEW: Latency breakdown:
     - YOLO inference: **23ms** (YOLOv11n, down from 300-500ms)
     - Mask generation: **50-80ms** (VNGenerateForegroundInstanceMaskRequest)
     - Quality assessment: **~35ms** (VNCalculateImageAestheticsScoresRequest)
     - Fingerprint generation: **~10ms** (VNImageFingerprint)
     - **Total**: ~108-138ms per object
   - ✅ NEW: Add parallel processing benchmark: 5 objects simultaneously in ~120ms total (not 5×120ms = 600ms)

6. **Baseline Comparisons (Line 241-256)**:
   - ❌ OLD: YOLOv3-Tiny baseline
   - ✅ NEW: **YOLOv11n baseline**
   - Update table:
     - mAP: 33.1% → **47%**
     - Latency: 300-500ms → **23ms** (10x faster)
     - Model Size: 34 MB → **5.2 MB** (compiled, 10x smaller)

7. **NEW METRICS NEEDED**:
   - **Quality Assessment Metrics**:
     - Aesthetic score distribution (0.0-1.0)
     - Blur detection accuracy (Laplacian variance threshold)
     - Lighting assessment accuracy
     - Completeness score accuracy (edge detection)
     - Composite quality score > 0.65 threshold validation
   - **Deduplication Metrics**:
     - False positive rate (same object marked as duplicate)
     - False negative rate (different object not marked as duplicate)
     - Similarity threshold validation (0.90)
     - Cache TTL validation (5 minutes)
   - **Mask Generation Metrics**:
     - Mask generation success rate
     - Contour extraction accuracy (IoU with ground truth)
     - Marching squares algorithm latency

---

### Stage 6.1: CHECKPOINT-stage-6.1.md

**File**: `docs/checkpoints/CHECKPOINT-stage-6.1.md`
**Status**: Created 2025-11-12 (BEFORE Sprint 3 refactor)
**Impact**: **MEDIUM** — References OLD architecture

**Specific Changes Needed**:

1. **Line 12**: "YOLOv3-Tiny object detection"
   - ❌ OLD: YOLOv3-Tiny
   - ✅ NEW: **YOLOv11n + real-time streaming + organic masks + quality assessment + deduplication**

2. **Line 181**: "YOLOv3-Tiny model (34 MB) downloaded"
   - ❌ OLD: YOLOv3-Tiny (34 MB)
   - ✅ NEW: **YOLOv11n (5.2 MB compiled)**

3. **Golden Dataset Requirements (Line 147-180)**:
   - ✅ ADD: Note that barcodes are no longer validated in Layer 1 (moved to Layer 2b)
   - ✅ UPDATE: 50% barcode requirement → **optional** (barcode validation deferred to Stage 6.3)

---

### Stage 6.0: CHECKPOINT-stage-6.0.md

**File**: `docs/checkpoints/CHECKPOINT-stage-6.0.md`
**Status**: Created 2025-11-12 (BEFORE Sprint 3 refactor)
**Impact**: **MEDIUM** — References OLD architecture

**Specific Changes Needed**:

1. **Line 181**: "YOLOv3-Tiny model (34 MB) downloaded"
   - ❌ OLD: YOLOv3-Tiny (34 MB)
   - ✅ NEW: **YOLOv11n (5.2 MB compiled)**

2. **Validation Timeline (Line 198-206)**:
   - ✅ UPDATE: Note Sprint 3 real-time refactor completed 2025-11-15
   - ✅ UPDATE: Stage 6.1 documentation refactored 2025-11-15

---

### Stage 6.2: Layer 2a Inputs

**File**: `docs/validation/layer2a/README.md` (and related files)
**Status**: Created 2025-11-14 (AFTER Sprint 3 refactor, but MAY need updates)
**Impact**: **LOW** — Layer 2a inputs should document new Layer 1 outputs

**Specific Changes Needed**:

1. **Layer 1 Output Schema**:
   - ✅ VERIFY: Does Layer 2a documentation reflect new Layer 1 outputs?
   - ✅ Expected inputs from Layer 1:
     - Cropped images (JPG)
     - **NEW**: Quality scores (0.0-1.0)
     - **NEW**: Catalog mode (automatic/manual/ignore)
     - **NEW**: Visual fingerprint (deduplication)
     - **NEW**: Alternative labels (top-5 YOLO predictions)
     - **NEW**: Organic mask metadata (if needed for UI)

2. **Firestore Schema**:
   - ✅ VERIFY: Does `layer1` Firestore document schema include:
     - `qualityScore: number`
     - `catalogMode: "automatic" | "manual"`
     - `fingerprint: string`
     - `alternativeLabels: [{ label, confidence }]`

---

## Summary of Refactoring Scope

### Documents to Refactor (7 files)

1. ✅ **VALIDATION-MASTER-001.md** (Stage 6.0) — Update YOLOv11n, latency thresholds, add new validations
2. ✅ **TEST-LAYER1-001.md** (Stage 6.1) — Update test cases, remove barcode, add real-time/quality/dedup tests
3. ✅ **BENCHMARK-LAYER1-001.md** (Stage 6.1) — Update latency baselines, YOLOv11n metrics, add quality/dedup benchmarks
4. ✅ **CHECKPOINT-stage-6.1.md** (Stage 6.1) — Update model reference, golden dataset notes
5. ✅ **CHECKPOINT-stage-6.0.md** (Stage 6.0) — Update model reference, timeline notes
6. ⚠️ **VALIDATION-LAYER1-001-TEMPLATE.md** (Stage 6.1) — Verify template includes new metrics
7. ⚠️ **docs/validation/layer2a/README.md** (Stage 6.2) — Verify Layer 1 output schema updated

### Key Changes Summary

| Change Type | OLD (Pre-Sprint 3) | NEW (Sprint 3) |
|-------------|-------------------|----------------|
| **Model** | YOLOv3-Tiny (34 MB) | **YOLOv11n (5.2 MB)** |
| **Input** | UIImage (button capture) | **CVPixelBuffer (2 FPS stream)** |
| **Latency** | 300-500ms (p90) | **23ms YOLO + 50-80ms mask = 120ms per object** |
| **Processing** | Sequential | **Parallel (5 objects in ~120ms)** |
| **Barcode** | Layer 1 (VNDetectBarcodesRequest) | **Moved to Layer 2b** |
| **UI** | Capture button, rectangles | **Organic borders, sparkles, double-tap** |
| **Confidence** | High/Medium/Low | **Automatic/Manual/Ignore (quality-aware)** |
| **New Services** | None | **SubjectMaskGenerator, ImageQualityAssessor, ObjectDeduplicator** |

---

## Refactoring Strategy

### Phase 1: Update Core Validation Documents (High Priority)
1. VALIDATION-MASTER-001.md (Stage 6.0 master framework)
2. TEST-LAYER1-001.md (Stage 6.1 test plan)
3. BENCHMARK-LAYER1-001.md (Stage 6.1 benchmark methodology)

### Phase 2: Update Checkpoints (Medium Priority)
4. CHECKPOINT-stage-6.1.md
5. CHECKPOINT-stage-6.0.md

### Phase 3: Verify Templates & Downstream (Low Priority)
6. VALIDATION-LAYER1-001-TEMPLATE.md (verify template completeness)
7. docs/validation/layer2a/README.md (verify Layer 1 output schema)

---

## Next Steps

1. **Approval**: Get user confirmation to proceed with refactoring
2. **Refactoring**: Update all 7 documents systematically
3. **Cross-Reference**: Verify no contradictions with Sprint 3 spec updates
4. **Checkpoint**: Create `CHECKPOINT-stage-6-refactor-2025-11-15.md` documenting all changes
5. **Context Map**: Update `docs/context-map.json` with refactor notes

---

## Related Documents

- **Implementation Plan**: `docs/plans/2025-11-15-realtime-object-detection-refactor.md`
- **Refactor Checkpoint**: `docs/checkpoints/CHECKPOINT-stage-6.1-documentation-refactor-2025-11-15.md`
- **Updated Specs**:
  - DESIGN-012-camera-capture-implementation.md (v2.0)
  - CODE-EXAMPLE-009-household-item-detector.md (v2.0)
  - DESIGN-027-camera-capture-view-specification.md (v2.0)
  - DESIGN-004-computer-vision-pipeline.md (v2.0)
  - abundance-analysis-pipeline-design.md (Updated 2025-11-15)

---

**Analysis Complete**: Ready to proceed with systematic refactoring of Stage 6.x validation documents.
