# BENCHMARK-LAYER1-001: Layer 1 Performance Benchmarks

**Created**: 2025-11-12
**Stage**: 6.1 - Layer 1 Validation (iOS On-Device)
**Status**: Benchmark Methodology Complete
**References**:
- docs/validation/VALIDATION-MASTER-001.md (Appendix A: Golden Dataset Specification)
- docs/plans/2025-11-12-stage-6.1-layer-1-validation.md
- docs/design/DESIGN-039-layer-1-performance-optimization.md

---

## Overview

This document specifies the benchmarking methodology for Layer 1 (on-device Vision Framework + YOLOv3-Tiny) performance validation. Benchmarks measure accuracy, latency, and cost against thresholds defined in VALIDATION-MASTER-001.

---

## Golden Dataset Specification

### Composition (100 Items)

| Category | Count | Examples |
|----------|-------|----------|
| **Camping** | 20 | Tents, stoves, backpacks, sleeping bags, coolers, lanterns, camp chairs |
| **Kitchen** | 20 | Pots, pans, utensils, blenders, toasters, coffee makers, dishes |
| **Tools** | 20 | Hand tools (hammers, wrenches), power tools (drills, saws), toolboxes |
| **Electronics** | 20 | Cameras, laptops, tablets, headphones, chargers, smart watches |
| **Furniture** | 10 | Chairs, tables, shelves, lamps, stools |
| **Clothing** | 10 | Jackets, shoes, hats, backpacks, gloves |
| **Total** | 100 | Diverse household items |

### Diversity Requirements

**Lighting Conditions**:
- Indoor (40%): Controlled lighting, typical home environment
- Outdoor (40%): Natural daylight, varying sun angles
- Mixed (20%): Low-light, shadows, high contrast

**Camera Angles**:
- Front (40%): Straight-on view
- Side (30%): 45-90° angle
- Top-down (20%): Overhead view
- Angled (10%): Oblique perspectives

**Backgrounds**:
- Clean (40%): Solid color, minimal clutter
- Cluttered (30%): Typical home environment with background objects
- Textured (30%): Wood, grass, concrete surfaces

**Item Conditions**:
- New (30%): Pristine, retail packaging
- Like-new (30%): Excellent condition, no visible wear
- Good (25%): Minor wear, functional
- Fair (10%): Visible wear, still usable
- Poor (5%): Significant damage, may not function

**Barcode Distribution**:
- With visible barcode (50%): Clear UPC-A, EAN-13, or QR code
- Without barcode (50%): No barcode visible in image

---

## Accuracy Metrics

### 1. Household Item Detection Accuracy

**Definition**: Percentage of images where predicted category matches ground truth category

**Formula**:
```
Accuracy = (Correct Category Predictions / Total Items) × 100
```

**Category Mapping** (COCO class → Golden dataset category):
```
backpack → camping
handbag → clothing
suitcase → camping
umbrella → camping
bottle → kitchen
cup → kitchen
fork → kitchen
knife → kitchen
spoon → kitchen
bowl → kitchen
wine glass → kitchen
chair → furniture
bed → camping (camping cot)
dining table → furniture
tie → clothing
couch → furniture
potted plant → furniture
toilet → tools (irrelevant, should be rare)
```

**Threshold**: > 60%

**Rationale** (from ADR-013):
- YOLOv3-Tiny raw accuracy: 33.1% mAP on COCO
- Household class filtering improves accuracy by removing false positives from irrelevant classes
- Target 60% reflects improved precision after filtering 80 COCO classes → 18 household classes

**Measurement**:
1. For each golden dataset image:
   - Run `detectHouseholdItems(in: image)`
   - Extract top detection label (highest confidence)
   - Map COCO class to golden dataset category
   - Compare to `ground_truth.category`
2. Count matches
3. Calculate accuracy percentage

---

### 2. Barcode Detection Accuracy

**Definition**: Percentage of barcode-bearing images where barcode is detected AND payload extracted correctly

**Formula**:
```
Accuracy = (Correctly Detected Barcodes / Total Barcode Images) × 100
```

**"Correctly Detected" Criteria**:
- VNDetectBarcodesRequest returns 1+ barcode observations
- Payload string (`payloadStringValue`) matches `ground_truth.barcode` exactly
- Example: Expected "012345678905", Detected "012345678905" → ✅

**Threshold**: > 95%

**Rationale** (from ADR-013):
- VNDetectBarcodesRequest high accuracy in ideal conditions (> 95%)
- 24 symbologies supported (UPC-A, EAN-13, QR Code primary)

**Measurement**:
1. Filter golden dataset to `barcode != null` entries (~50 images)
2. For each barcode image:
   - Run `detectBarcodes(in: image)`
   - Check if detected payload matches ground truth
3. Count matches
4. Calculate accuracy percentage

---

## Latency Metrics

### Processing Latency Measurement

**Definition**: Time from `UIImage` input → `[HouseholdItem]` output (end-to-end Layer 1 processing)

**Scope**:
- **Includes**:
  - VNCoreMLRequest execution (YOLOv3-Tiny inference)
  - Household class filtering (18 COCO classes)
  - Non-Maximum Suppression (IoU > 0.5)
  - Confidence scoring (high/medium/low)
  - Bounding box cropping

- **Excludes**:
  - Edge case detection (blur, brightness) — optional, disabled by default per DESIGN-039
  - Network/upload latency (Layer 2a responsibility)
  - UI rendering time

**Device Configuration**:
- **Device**: iPhone 15 Pro (A17 Pro chip)
- **Neural Engine**: Enabled (`MLModelConfiguration.computeUnits = .all`)
- **OS**: iOS 26.0+
- **Background apps**: Closed/minimized

**Percentile Metrics**:
- **p50 (median)**: 50% of images processed faster than this
- **p90**: 90% of images processed faster than this (**threshold target**)
- **p95**: 95% of images processed faster than this
- **p99**: 99% of images processed faster than this
- **max**: Slowest processing time

**Threshold**: p90 < 500ms

**Rationale** (from DESIGN-039):
- Object detection baseline: 300-500ms (iPhone 15 Pro)
- Household filtering: < 1ms
- NMS: < 5ms
- Total expected: 350-600ms (acceptable range)

**Percentile Calculation**:
```swift
let sortedLatencies = latencies.sorted() // Ascending order
let p90Index = Int(Double(sortedLatencies.count) * 0.9)
let p90Latency = sortedLatencies[p90Index]
```

**Measurement**:
1. For each golden dataset image:
   ```swift
   let startTime = Date()
   let items = try await detector.detectHouseholdItems(in: image)
   let endTime = Date()
   let latency = endTime.timeIntervalSince(startTime)
   ```
2. Collect all latencies
3. Sort ascending
4. Calculate p50, p90, p95, p99, max
5. Export distribution to CSV

---

## Cost Metrics

### Layer 1 Cost Model

**Definition**: Cloud API cost per item processed by Layer 1

**Formula**:
```
Layer 1 Cost = $0.00 per item
```

**Rationale**:
- On-device processing (Vision Framework, Core ML, Apple Neural Engine)
- No cloud API calls
- Zero marginal cost

**Validation**:
- Verify no network requests during Layer 1 execution
- Monitor Cloud Functions logs (should be zero calls)

**Comparison** (from DESIGN-004):
| Layer | Cost per Item | Latency |
|-------|---------------|---------|
| Layer 1 (on-device) | **$0.00** | 300-500ms |
| Layer 2a (Gemini) | $0.000249 | 30-50ms |
| Layer 2b (SerpAPI) | $0.015000 | 5-7s |
| Layer 3 (Claude Sonnet) | $0.002027 | 1-2s |

**Free Tier Sustainability**:
- 85% of users (free tier) use Layer 1 only → $0 cost
- Enables sustainable freemium business model

---

## Baseline Comparisons

### Baseline: YOLOv3-Tiny on COCO Dataset

**Metric** | **COCO Baseline** | **Abundance Target** | **Change**
---|---|---|---
mAP (Mean Average Precision) | 33.1% | 60% (category accuracy) | +81% (due to filtering)
Latency (iPhone 15 Pro) | 300-500ms | < 500ms (p90) | Same
Model Size | 34 MB | 34 MB | Same
Classes | 80 | 18 (filtered) | -77%

**Filtering Benefit**:
- Removing 62 irrelevant classes (person, car, dog, etc.) reduces false positives
- Category-level accuracy improves when search space narrows
- Example: "backpack" detection more reliable when "person" is filtered out

---

## Results Export Format

### 1. Accuracy Results CSV

**File**: `layer1_accuracy_results.csv`

**Schema**:
```csv
id,image_path,predicted_label,predicted_category,expected_category,confidence,correct,notes
camping-001,GoldenDataset/camping/coleman-triton-stove.jpg,backpack,camping,camping,0.85,true,
camping-002,GoldenDataset/camping/rei-half-dome-tent.jpg,suitcase,camping,camping,0.75,true,
kitchen-001,GoldenDataset/kitchen/cuisinart-blender.jpg,bottle,kitchen,kitchen,0.90,true,
kitchen-002,GoldenDataset/kitchen/stainless-steel-fork.jpg,spoon,kitchen,kitchen,0.65,true,mislabeled but correct category
tools-001,GoldenDataset/tools/dewalt-drill.jpg,person,unknown,tools,0.55,false,filtered to irrelevant class
...
```

---

### 2. Latency Distribution CSV

**File**: `layer1_latency_distribution.csv`

**Schema**:
```csv
image_index,id,latency_ms,percentile
0,camping-001,320,p5
1,camping-002,450,p15
...
89,electronics-019,485,p90
...
99,clothing-010,620,p99
```

---

### 3. Benchmark Summary JSON

**File**: `layer1_benchmark_summary.json`

**Schema**:
```json
{
  "dataset": "golden_dataset_v1",
  "total_items": 100,
  "test_date": "2025-11-12T10:30:00Z",
  "device": "iPhone 15 Pro (A17 Pro)",
  "metrics": {
    "accuracy": {
      "household_item_detection": {
        "correct": 65,
        "total": 100,
        "percentage": 65.0,
        "threshold": 60.0,
        "pass": true
      },
      "barcode_detection": {
        "correct": 48,
        "total": 50,
        "percentage": 96.0,
        "threshold": 95.0,
        "pass": true
      }
    },
    "latency": {
      "p50_ms": 380,
      "p90_ms": 485,
      "p95_ms": 520,
      "p99_ms": 620,
      "max_ms": 680,
      "threshold_p90_ms": 500,
      "pass": true
    },
    "cost": {
      "per_item_usd": 0.0,
      "total_usd": 0.0
    }
  }
}
```

---

## Acceptance Criteria

- [x] ✅ Golden dataset specification documented (100 items, 6 categories)
- [x] ✅ Accuracy measurement methodology defined
- [x] ✅ Latency percentile calculation specified
- [x] ✅ Cost model verified ($0 per item)
- [x] ✅ Baseline comparisons documented (COCO dataset)
- [x] ✅ Results export formats defined (CSV, JSON)

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-12 | 1.0 | Initial benchmark methodology | iOS Architecture Expert + Computer Vision & ML Engineer |

---

**Status**: ✅ **BENCHMARK METHODOLOGY COMPLETE** — Ready for test execution
