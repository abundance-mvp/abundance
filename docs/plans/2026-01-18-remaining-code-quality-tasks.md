# Remaining Code Quality Tasks

**Date**: 2026-01-18
**Status**: Ready for Execution
**Parent Plan**: `2026-01-17-code-quality-remediation-plan.md`
**Progress**: ~75% Complete (P0/P1 done, P2 remaining)

---

## Executive Summary

The Code Quality Remediation Plan is substantially complete. All P0 (Critical) and most P1 (Important) tasks have been implemented. This document captures the remaining P2 tasks and any deferred P1 items for future work.

### Completed Summary

| Phase | Status | Key Deliverables |
|-------|--------|------------------|
| **Phase 1 (P0)** | ✅ Complete | Swift 6 concurrency, YOLO removal, buffer safety |
| **Phase 2 (P1)** | ✅ ~90% Complete | Error recovery, Dynamic Type, accessibility labels, configuration |
| **Phase 3 (P2)** | ⏳ 33% Complete | ItemRepository split done; design system + performance pending |

---

## Remaining Tasks

### Task 1: Comprehensive Test Coverage (P1 - Deferred)

**Priority**: P1 | **Effort**: 2-3 days | **Risk**: Medium

**Problem**: Test coverage for critical components needs improvement. Specifically:
- `ImageQualityAssessor` lacks comprehensive tests
- Camera-to-detection integration flow has no end-to-end tests
- Target is 80%+ coverage on critical components

**Files**:
- `Sources/CameraFeature/Services/ImageQualityAssessor.swift`
- `Tests/CameraFeatureTests/` (new files needed)

**Deliverables**:
- [ ] Add unit tests for `ImageQualityAssessor`
  - [ ] Test quality threshold calculations
  - [ ] Test edge cases (blurry images, low light, etc.)
  - [ ] Test different image sizes and formats
- [ ] Add integration tests for camera-to-detection flow
  - [ ] Mock camera input → detection → item creation
  - [ ] Test error handling at each stage
- [ ] Achieve 80%+ coverage on CameraFeature module
- [ ] Add performance benchmarks for frame processing

**Testing Strategy**:
```swift
// Example test structure
@Test func qualityAssessorDetectsBlurryImage() async throws {
    let assessor = ImageQualityAssessor()
    let blurryImage = TestAssets.blurryImage
    let score = assessor.assess(blurryImage)
    #expect(score < 0.5)
}
```

---

### Task 2: Design System Completion - Liquid Glass Audit (P2)

**Priority**: P2 | **Effort**: 2-3 days | **Risk**: Low

**Problem**: Liquid Glass implementation varies across views. Need consistent application of glass effects per iOS 26+ design guidelines.

**Files to Audit**:
- `Sources/InventoryFeature/InventoryView.swift`
- `Sources/ProfileFeature/ProfileView.swift`
- `Sources/CameraFeature/Views/CaptureView.swift`
- `Sources/CameraFeature/Views/DetectionResultsView.swift`
- `Sources/Core/DesignSystem/Extensions/LiquidGlassHelpers.swift`

**Deliverables**:
- [ ] Audit all views for Liquid Glass usage patterns
  - [ ] Identify views using `.ultraThinMaterial` that should use `.glassEffect()`
  - [ ] Identify views using custom blur that should use adaptive glass
  - [ ] Check `.adaptiveGlass()` usage is consistent
- [ ] Document glass variant guidelines
  - [ ] When to use `.glassEffect()` (iOS 26+)
  - [ ] When to use `.adaptiveGlass()` (iOS 26+ with fallback)
  - [ ] When to use `.ultraThinMaterial` (backward compatible)
- [ ] Create design token system
  - [ ] `GlassIntensity.light`, `.medium`, `.heavy`
  - [ ] `GlassCornerRadius.small`, `.medium`, `.large`
- [ ] Add `@Environment(\.accessibilityReduceTransparency)` checks to all glass views
- [ ] Update component library documentation

**Validation**:
```bash
# Search for inconsistent patterns
rg "\.ultraThinMaterial|\.thinMaterial|\.regularMaterial" Sources/
rg "\.blur\(radius:" Sources/
rg "\.glassEffect|\.adaptiveGlass" Sources/
```

**Design Guidelines Reference**:
See `docs/brand/abundance-brand-bible_090125.md` for brand colors and design principles.

---

### Task 3: Performance Optimization - Parallel Frame Processing (P2)

**Priority**: P2 | **Effort**: 3-4 days | **Risk**: Medium

**Problem**: Sequential frame processing limits performance. Current implementation processes detected objects one at a time.

**File**: `Sources/CameraFeature/ViewModels/CameraDetectionViewModel.swift`

**Current Pattern** (Sequential):
```swift
for result in detectionResults {
    let processed = await processObject(result, in: pixelBuffer)
    processedObjects.append(processed)
}
```

**Target Pattern** (Parallel):
```swift
await withTaskGroup(of: DetectedObject?.self) { group in
    for result in detectionResults {
        group.addTask { [self] in
            await self.processObject(result, in: pixelBuffer)
        }
    }

    for await object in group {
        if let object = object {
            processedObjects.append(object)
        }
    }
}
```

**Deliverables**:
- [ ] Implement parallel frame processing with `TaskGroup`
  - [ ] Process multiple detected objects concurrently
  - [ ] Maintain order stability if needed
  - [ ] Add proper cancellation handling
- [ ] Add zero-copy optimizations where possible
  - [ ] Use `IOSurface` for buffer sharing when appropriate
  - [ ] Avoid unnecessary `CVPixelBuffer` copies
- [ ] Optimize memory usage in image processing pipeline
  - [ ] Profile memory with Instruments
  - [ ] Reduce allocations in hot path
- [ ] Add performance metrics collection
  - [ ] Frame processing time (target: <16ms)
  - [ ] Objects processed per frame
  - [ ] Memory high-water mark
- [ ] Create performance benchmarks
  - [ ] Baseline before changes
  - [ ] Measure improvement after changes

**Success Criteria**:
- Frame processing time: <16ms average
- No increase in memory usage
- No regression in detection accuracy
- Thread Sanitizer clean

**Validation Commands**:
```bash
# Run with Thread Sanitizer
swift test --sanitize=thread

# Profile with Instruments (manual)
# Use Time Profiler and Allocations instruments
```

---

### Task 4: Reduce Motion Support (P2 - Accessibility)

**Priority**: P2 | **Effort**: 1 day | **Risk**: Low

**Problem**: Animations don't respect `accessibilityReduceMotion` preference.

**Files**:
- `Sources/CameraFeature/Views/CaptureOverlays.swift`
- `Sources/InventoryFeature/ItemCard.swift`
- `Sources/CameraFeature/Views/CaptureView.swift`

**Deliverables**:
- [ ] Add `@Environment(\.accessibilityReduceMotion)` to animated views
- [ ] Conditionally disable/simplify animations:
  ```swift
  @Environment(\.accessibilityReduceMotion) var reduceMotion

  .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: state)
  ```
- [ ] Test with Settings > Accessibility > Motion > Reduce Motion enabled

---

## Implementation Order

| Order | Task | Dependencies | Effort |
|-------|------|--------------|--------|
| 1 | Design System Audit | None | 2-3 days |
| 2 | Reduce Motion Support | None | 1 day |
| 3 | Performance Optimization | Design System done (UI stability) | 3-4 days |
| 4 | Test Coverage | All other tasks done | 2-3 days |

**Total Estimated Effort**: 8-11 days

---

## Validation Checklist

### Before Marking Complete

- [ ] All tasks have corresponding tests
- [ ] Build passes with zero warnings: `swift build 2>&1 | grep -c warning`
- [ ] All tests pass: `swift test`
- [ ] Thread Sanitizer clean: `swift test --sanitize=thread`
- [ ] Memory profile shows no leaks (manual Instruments check)
- [ ] Accessibility audit passes (VoiceOver + Dynamic Type + Reduce Motion)

### Performance Targets

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| Frame processing time | <16ms | TBD | ⏳ |
| Memory high-water | Stable | TBD | ⏳ |
| Test coverage (CameraFeature) | >80% | TBD | ⏳ |
| Accessibility audit | Pass | ✅ | Done |

---

## Notes

### Why These Tasks are P2

These tasks improve quality but don't block shipping:
- **Design System**: Visual polish, not functional
- **Performance**: Current performance is acceptable, optimization is enhancement
- **Test Coverage**: Existing tests cover critical paths; additional coverage is defensive
- **Reduce Motion**: Affects small subset of users; app is still usable without it

### Risk Mitigation

- **Performance changes**: Benchmark before/after, keep old code path available via feature flag
- **Design changes**: Use `#Preview` extensively, test on multiple device sizes
- **Test additions**: Don't block CI on coverage thresholds initially

---

## Execution Command

```bash
/ios-superpowers execute docs/plans/2026-01-18-remaining-code-quality-tasks.md
```
