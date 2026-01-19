# Code Quality Remediation Plan
**Date**: 2026-01-17  
**Status**: Ready for Execution  
**Target**: Zero P0/P1 issues, production-ready codebase  

## Overview

Comprehensive plan to address all critical code quality issues identified in iOS code review. Focuses on Swift 6 concurrency safety, error handling, accessibility, and performance optimization.

## Phase 1: Critical Fixes (P0) - Days 1-7
**Priority**: Immediate | **Risk**: High | **Timeline**: 5-7 days

### Task 1.1: Swift 6 Concurrency Safety (2-3 days)
**Files**: `Sources/CameraFeature/Services/CameraService.swift:11-27`

**Problem**: Multiple `nonisolated(unsafe)` declarations creating potential data races
```swift
// Current unsafe pattern
nonisolated(unsafe) private let captureSession = AVCaptureSession()
```

**Solution**: Create isolated actor for camera operations
```swift
private actor CameraSessionActor {
    let captureSession = AVCaptureSession()
    let videoOutput = AVCaptureVideoDataOutput()
    
    func configure() -> Bool {
        // Isolated configuration logic
    }
}
```

**Deliverables**:
- [ ] Create `CameraSessionActor` with proper isolation
- [ ] Update `CameraService` to use actor boundaries
- [ ] Remove all `nonisolated(unsafe)` declarations
- [ ] Add concurrency stress tests
- [ ] Validate with Thread Sanitizer

**Testing Strategy**:
- Run with Thread Sanitizer enabled
- Stress test with rapid camera start/stop cycles
- Verify no data race warnings

### Task 1.2: Remove Deprecated YOLO Detection (1-2 days)
**Files**: `Sources/VisionCore/Services/HouseholdItemDetector.swift`, `Sources/CameraFeature/Views/CameraDetectionView.swift`

**Problem**: Deprecated local YOLO detection still active, creating confusion and maintenance burden

**Solution**: Complete server-side Gemini migration
- Remove `HouseholdItemDetector` and YOLO model files
- Update `CameraDetectionView` to use server-side detection only
- Clean up deprecated imports and dependencies

**Deliverables**:
- [ ] Remove `yolo11n.mlmodelc` and related files
- [ ] Delete `HouseholdItemDetector.swift`
- [ ] Update camera detection flow to server-side only
- [ ] Remove deprecated test files
- [ ] Add feature flag for emergency local fallback

**Risk Mitigation**:
- Keep feature flag for rollback capability
- Test server-side detection thoroughly before removal
- Monitor detection latency and accuracy

### Task 1.3: Fix Pixel Buffer Race Conditions (1-2 days)
**Files**: `Sources/CameraFeature/ViewModels/CameraDetectionViewModel.swift:277-285`

**Problem**: Unsafe CVPixelBuffer copying leading to potential corruption

**Solution**: Implement proper buffer locking and atomic operations
```swift
private func copyPixelBufferSafely(_ pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
    CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
    
    // Safe copying with proper synchronization
    return copyBuffer(pixelBuffer)
}
```

**Deliverables**:
- [ ] Add proper CVPixelBuffer locking
- [ ] Implement atomic operations for buffer access
- [ ] Add frame corruption detection
- [ ] Test under high frame rate conditions
- [ ] Validate with Memory Debugger

## Phase 2: Important Fixes (P1) - Days 8-17
**Priority**: High | **Risk**: Medium | **Timeline**: 7-10 days

### Task 2.1: Error Recovery & Resilience (2-3 days)
**Files**: `Sources/CameraFeature/Views/CameraDetectionView.swift`, `Sources/OnboardingFeature/SignInView.swift`

**Problem**: No error recovery UI when camera fails or network issues occur

**Solution**: Comprehensive error handling with user-friendly recovery
```swift
@State private var cameraError: CameraError?
@State private var showingErrorRecovery = false

// Error recovery UI
if let error = cameraError {
    ErrorRecoveryView(error: error) {
        Task { await retryCamera() }
    }
}
```

**Deliverables**:
- [ ] Add `ErrorRecoveryView` component
- [ ] Implement camera permission denied flow
- [ ] Add network error handling with retry logic
- [ ] Create offline mode with sync when available
- [ ] Add user-friendly error messages

### Task 2.2: Accessibility Compliance (3-4 days)
**Files**: All UI files, focus on `Sources/OnboardingFeature/SignInView.swift:67,83-85`

**Problem**: Insufficient VoiceOver support, decorative elements not hidden

**Solution**: WCAG AA compliance with comprehensive accessibility
```swift
.accessibilityLabel("Sign in with Apple")
.accessibilityHint("Authenticates using your Apple ID")
.accessibilityAddTraits(.isButton)
```

**Deliverables**:
- [ ] Complete VoiceOver audit using Accessibility Inspector
- [ ] Add proper labels, hints, and traits to all interactive elements
- [ ] Implement Dynamic Type support (Large Accessibility sizes)
- [ ] Hide decorative elements with `.accessibilityHidden(true)`
- [ ] Add color contrast validation
- [ ] Test with real accessibility tools

### Task 2.3: Configuration & Testing (2-3 days)
**Files**: `Sources/CameraFeature/Services/CameraService.swift:14-15,161,183`

**Problem**: Hard-coded settings, insufficient test coverage for critical components

**Solution**: Configurable settings with comprehensive test suite
```swift
struct CameraConfiguration {
    let qualityPreset: AVCaptureSession.Preset
    let frameRate: Int32
    let queueName: String
}
```

**Deliverables**:
- [ ] Create `CameraConfiguration` struct
- [ ] Extract hard-coded values to configuration files
- [ ] Add device-specific camera settings
- [ ] Write comprehensive tests for `ImageQualityAssessor`
- [ ] Add integration tests for camera-to-detection flow
- [ ] Achieve 80%+ test coverage for critical components

## Phase 3: Architecture & Performance (P2) - Days 18-27
**Priority**: Medium | **Risk**: Low | **Timeline**: 8-10 days

### Task 3.1: Architecture Refactoring (3-4 days)
**Files**: `Sources/Persistence/Firebase/ItemService.swift:38-93`

**Problem**: Large protocols violating Interface Segregation Principle

**Solution**: Split into focused, cohesive interfaces
```swift
protocol ItemReadRepository {
    func getItem(id: String) async throws -> Item?
    func getItems(userId: String) async throws -> [Item]
}

protocol ItemWriteRepository {
    func createItem(_ item: Item) async throws -> String
    func updateItem(_ item: Item) async throws
}

protocol ItemObservableRepository {
    func observeItems(userId: String) -> AnyPublisher<[Item], Never>
}
```

**Deliverables**:
- [ ] Split `ItemRepository` into focused protocols
- [ ] Create `ItemService` composition implementing all interfaces
- [ ] Refactor large ViewModels into composable components
- [ ] Implement proper dependency injection container
- [ ] Update all callers to use appropriate interface

### Task 3.2: Design System Completion (2-3 days)
**Files**: All UI files, `Sources/Core/DesignSystem/Extensions/LiquidGlassHelpers.swift`

**Problem**: Inconsistent Liquid Glass implementation across views

**Solution**: Complete design system with consistent patterns
```swift
// Standardized glass modifier usage
.modifier(AdaptiveGlassModifier(
    variant: .regular,
    intensity: .medium
))
```

**Deliverables**:
- [ ] Audit all views for Liquid Glass compliance
- [ ] Create design token system for consistent styling
- [ ] Document when to use each glass variant (regular vs clear)
- [ ] Add automated design system validation
- [ ] Create comprehensive component library documentation

### Task 3.3: Performance Optimization (3-4 days)
**Files**: `Sources/CameraFeature/ViewModels/CameraDetectionViewModel.swift:98-103`

**Problem**: Sequential frame processing limiting performance

**Solution**: Parallel processing with proper isolation
```swift
await withTaskGroup(of: DetectedObject?.self) { group in
    for yoloResult in yoloResults {
        group.addTask { [self] in
            await self.processObject(yoloResult, in: pixelBuffer)
        }
    }
    
    var processedObjects: [DetectedObject] = []
    for await object in group {
        if let object = object {
            processedObjects.append(object)
        }
    }
    return processedObjects
}
```

**Deliverables**:
- [ ] Implement parallel frame processing with TaskGroup
- [ ] Add zero-copy operations using IOSurface where possible
- [ ] Optimize memory usage in image processing pipeline
- [ ] Add performance monitoring and metrics collection
- [ ] Target <16ms frame processing time

## Implementation Strategy

### Development Workflow
1. **Branch Strategy**: Feature branch per task (`fix/p0-concurrency`, `fix/p1-accessibility`, etc.)
2. **Testing Approach**: TDD - write failing tests before implementing fixes
3. **Validation**: Use `/device-tester` for each fix on physical device w-16e
4. **Code Review**: Peer review required for all P0/P1 fixes

### Risk Mitigation
- **Feature Flags**: All major changes behind feature toggles for rollback
- **Gradual Migration**: Backward compatibility during transitions
- **Performance Benchmarks**: Before/after measurements for optimizations
- **Automated Testing**: CI pipeline runs all tests on every commit

### Success Metrics

#### Phase 1 Success Criteria
- [ ] Zero Thread Sanitizer warnings
- [ ] No deprecated code references in codebase
- [ ] Zero buffer corruption under stress testing
- [ ] All critical paths covered by tests

#### Phase 2 Success Criteria
- [ ] Camera error recovery in <2 seconds
- [ ] WCAG AA compliance (contrast, VoiceOver, Dynamic Type)
- [ ] 80%+ test coverage on critical components
- [ ] Zero hard-coded configuration values

#### Phase 3 Success Criteria
- [ ] Protocol interfaces follow SOLID principles
- [ ] Consistent Liquid Glass usage across all views
- [ ] <16ms average frame processing time
- [ ] Memory usage stable under extended operation

### Monitoring & Validation

#### Daily Checks
- [ ] Build passes with Thread Sanitizer enabled
- [ ] All tests passing on CI
- [ ] No new accessibility violations
- [ ] Performance benchmarks within targets

#### Weekly Reviews
- [ ] Code review sessions for architectural changes
- [ ] Accessibility testing with real users
- [ ] Performance profiling on physical devices
- [ ] Crash analytics review for regressions

## Timeline Summary

| Phase | Duration | Key Deliverables | Success Criteria |
|-------|----------|------------------|------------------|
| **Phase 1 (P0)** | 5-7 days | Concurrency safety, deprecated code removal, buffer safety | Zero data races, no deprecated code |
| **Phase 2 (P1)** | 7-10 days | Error recovery, accessibility, comprehensive testing | <2s recovery, WCAG AA, 80%+ coverage |
| **Phase 3 (P2)** | 8-10 days | Architecture refactor, design system, performance | SOLID principles, consistent UI, <16ms frames |
| **Total** | **20-27 days** | **Production-ready codebase** | **Zero critical issues** |

## Execution Notes

This plan is designed for execution with `/ios-superpowers execute` command. Each task includes:
- **Clear file references** for targeted changes
- **Before/after code examples** for implementation guidance
- **Specific deliverables** with checkboxes for progress tracking
- **Testing strategies** for validation
- **Success criteria** for completion verification

The plan prioritizes safety (P0) → stability (P1) → optimization (P2), ensuring each phase builds on the previous for steady progress toward production readiness.