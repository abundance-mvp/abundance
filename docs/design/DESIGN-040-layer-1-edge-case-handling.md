# DESIGN-040: Layer 1 Edge Case Handling

**Created**: 2025-11-11
**Stage**: 3.3 - Layer 1 On-Device ML Implementation Research  
**Status**: Complete
**References**: docs/plans/PLAN-SUMMARY-stage-3.3.md, CODE-EXAMPLE-009

---

## Overview

Edge case handling patterns for household item detection: low light, motion blur, overlapping objects, no objects detected, too many objects.

---

## 1. Low Light Detection

**Detection**: brightness < 50 (0-255 scale)
**Mitigation**: User feedback, boost exposure (future)

```swift
if brightness < 50 {
    warning = "Image is too dark. Try using flash or better lighting."
}
```

---

## 2. Motion Blur Detection

**Detection**: Laplacian variance < 100
**Mitigation**: Prompt retake

```swift
if blurScore < 100 {
    warning = "Image is blurry. Hold camera steady and retake."
}
```

---

## 3. Overlapping Objects (NMS)

**Detection**: IoU > 0.5  
**Resolution**: Non-Maximum Suppression (keep highest confidence)

```swift
func applyNMS(_ detections: [DetectedObject], iouThreshold: Float = 0.5) -> [DetectedObject] {
    // Sort by confidence, remove overlaps
}
```

---

## 4. No Objects Detected

**Cause**: Wrong angle, out of focus, no household items
**Mitigation**: User feedback, allow manual creation

```swift
if householdItems.isEmpty {
    errorMessage = "No items detected. Try different angle."
}
```

---

## 5. Too Many Objects (>10)

**Cause**: Cluttered scene
**Resolution**: Show top 10 by confidence, pagination

```swift
if householdItems.count > 10 {
    householdItems = Array(householdItems.prefix(10))
    warning = "Multiple items detected. Showing top 10."
}
```

---

## Acceptance Criteria

- [x] ✅ Low light detection (<50 brightness)
- [x] ✅ Motion blur detection (<100 Laplacian variance)
- [x] ✅ NMS for overlapping objects (IoU >0.5)
- [x] ✅ No objects handling with user feedback
- [x] ✅ Too many objects pagination (top 10)

---

**Status**: ✅ COMPLETE
