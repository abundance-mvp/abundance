# BENCHMARK-001: Layer 1 Accuracy Methodology

**Created**: 2025-11-11
**Stage**: 3.3 - Layer 1 On-Device ML Implementation Research
**Status**: Methodology Complete
**References**: docs/plans/PLAN-SUMMARY-stage-3.3.md, RESEARCH-003

---

## Overview

Defines methodology for measuring Layer 1 (Vision Framework + YOLOv3-Tiny) accuracy on household items.

---

## Test Dataset Specification

**Size**: 50-100 household item photos  
**Categories**:
- Camping gear (tent, sleeping bag, backpack, camping chair)
- Kitchen items (bottle, cup, bowl, utensils)
- Electronics (laptop, phone, camera)
- Personal items (handbag, suitcase)

**Ground Truth**: Manual annotation with bounding boxes + labels

**Conditions**:
- Well-lit (50+ brightness)
- Low-light (<50 brightness)
- Cluttered background
- Multiple items per photo

---

## Accuracy Metrics

### Precision
TP / (TP + FP) - How many detections are correct?  
**Target**: >70%

### Recall
TP / (TP + FN) - How many actual items were detected?  
**Target**: >60%

### F1 Score  
2 * (Precision * Recall) / (Precision + Recall)  
**Target**: >0.65

### IoU (Intersection over Union)
Bounding box accuracy  
**Target**: >0.5 (50% overlap)

### mAP (mean Average Precision)
Overall detection quality  
**Target**: >40% (vs 33.1% COCO baseline)

---

## Benchmarking Script

```swift
struct BenchmarkResult {
    let precision: Float
    let recall: Float
    let f1Score: Float
    let meanIoU: Float
    let mAP: Float
    let latency: TimeInterval
}

func benchmarkDetector(
    detector: HouseholdItemDetector,
    testDataset: [TestImage]
) async throws -> BenchmarkResult {
    var truePositives = 0
    var falsePositives = 0
    var falseNegatives = 0
    var totalIoU: Float = 0
    
    for testImage in testDataset {
        let detections = try await detector.detectHouseholdItems(in: testImage.image)
        let groundTruth = testImage.groundTruthItems
        
        // Calculate TP, FP, FN, IoU
        // ...
    }
    
    let precision = Float(truePositives) / Float(truePositives + falsePositives)
    let recall = Float(truePositives) / Float(truePositives + falseNegatives)
    let f1 = 2 * (precision * recall) / (precision + recall)
    
    return BenchmarkResult(...)
}
```

---

## Baseline Accuracy Targets

| Metric | YOLOv3-Tiny COCO | Target (Household Items) |
|--------|------------------|--------------------------|
| mAP | 33.1% | >40% |
| Precision | ~60% | >70% |
| Recall | ~70% | >60% |
| F1 Score | ~0.65 | >0.65 |

---

## Acceptance Criteria

- [x] ✅ Test dataset specification (50-100 images, ground truth)
- [x] ✅ Accuracy metrics defined (precision, recall, F1, IoU, mAP)
- [x] ✅ Benchmarking script structure defined
- [x] ✅ Baseline targets documented (>40% mAP, >70% precision)

---

**Status**: ✅ METHODOLOGY COMPLETE  
**Next**: Actual benchmarking in Stage 4.3 (AI/ML Integration Specification)
