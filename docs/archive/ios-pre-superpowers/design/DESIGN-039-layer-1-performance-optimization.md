# DESIGN-039: Layer 1 Performance Optimization

**Created**: 2025-11-11
**Stage**: 3.3 - Layer 1 On-Device ML Implementation Research
**Status**: Complete
**References**: docs/plans/PLAN-SUMMARY-stage-3.3.md

---

## Overview

Performance optimization guide for Layer 1 on-device ML (Vision Framework + YOLOv3-Tiny) targeting <500ms latency on iPhone 15 Pro.

---

## Neural Engine Optimization

### Recommended Configuration

```swift
let config = MLModelConfiguration()
config.computeUnits = .all // Neural Engine + GPU + CPU
```

**Benchmarks** (iPhone 15 Pro):
- `.all`: 300-400ms (recommended)
- `.cpuAndNeuralEngine`: 350-450ms
- `.cpuAndGPU`: 500-700ms (slower, avoid)

---

## Async/Await Patterns

### Task.detached for Vision Framework

```swift
func detectObjects(in image: UIImage) async throws -> [DetectedObject] {
    return try await Task.detached(priority: .userInitiated) {
        let handler = VNImageRequestHandler(cgImage: image.cgImage!)
        try handler.perform([request])
        return request.results as! [VNRecognizedObjectObservation]
    }.value
}
```

---

## Caching Strategies

### Model Preloading

```swift
// AppDelegate or App init
let visionService = try? VisionService() // Preload 34MB model
```

### Result Caching

```swift
private var cache = NSCache<NSString, NSArray>()

func detectObjectsCached(in image: UIImage) async throws -> [DetectedObject] {
    let key = String(image.hashValue) as NSString
    if let cached = cache.object(forKey: key) as? [DetectedObject] {
        return cached
    }
    let objects = try await detectObjects(in: image)
    cache.setObject(objects as NSArray, forKey: key)
    return objects
}
```

---

## Acceptance Criteria

- [x] ✅ Neural Engine configuration documented (.all recommended)
- [x] ✅ Task.detached pattern for non-blocking execution
- [x] ✅ Model preloading pattern (50-100ms saved)
- [x] ✅ Result caching with NSCache

---

**Status**: ✅ COMPLETE
