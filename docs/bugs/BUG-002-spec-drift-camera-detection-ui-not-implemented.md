# BUG-002: Spec Drift - Real-Time Camera Detection UI Not Implemented

**Status**: ✅ Resolved
**Resolved Date**: 2025-11-17
**Implementation**: docs/implementation/2025-11-17-camera-detection-ui-implementation.md
**Severity**: High
**Type**: Spec Drift (Major Implementation Gap)
**Created**: 2025-11-17
**Issue Reference**: .debug/issues/triaged/issue-002.md

---

## Description

The Camera View currently displays a traditional single-photo capture UI (white button at bottom) instead of the specified real-time continuous detection experience with organic borders, automatic/manual cataloging modes, and sparkle animations.

The backend detection pipeline (`CameraDetectionViewModel`) has been fully implemented according to DESIGN-027 v2.0, but the UI layer (`CameraView`) was never updated from the old v1.0 specification.

---

## Specification vs Implementation

### Specification (DESIGN-027 v2.0, Updated 2025-11-15)

**User Journey**: Catalog View → Tap Camera Tab → Camera Opens → **Continuous 2 FPS Detection** → Organic Borders Appear → **Automatic Catalog (Mint Green)** OR **Double-Tap Manual Catalog (Grey)** → Sparkle Animation → Cropped Objects Uploaded → AI Processing → Continue Scanning

**Key Features**:
- ✅ Real-time object detection at 2 FPS (CameraDetectionViewModel)
- ❌ Organic borders using VNInstanceMaskObservation (NOT IMPLEMENTED IN UI)
- ❌ Mint green borders for high-confidence automatic catalog (NOT IMPLEMENTED)
- ❌ Grey borders for medium-confidence manual catalog (NOT IMPLEMENTED)
- ❌ Sparkle animation on automatic catalog (NOT IMPLEMENTED)
- ❌ Double-tap gesture for manual cataloging (NOT IMPLEMENTED)
- ❌ Continuous scanning experience (NOT IMPLEMENTED)
- ❌ No capture button (UI STILL HAS BUTTON)

### Current Implementation (CameraView.swift)

**User Journey**: Catalog View → Tap Camera Tab → Camera Opens → **User Taps Capture Button** → Photo Captured → Upload Fails (BUG-001)

**Features Implemented**:
- ✅ Camera preview with AVFoundation
- ✅ Single white capture button (DEPRECATED)
- ✅ Loading indicator
- ✅ Error banner
- ❌ No real-time detection display
- ❌ No organic borders
- ❌ No automatic/manual catalog modes
- ❌ No continuous scanning

---

## Root Cause

**Architecture Mismatch**: The backend detection pipeline was refactored to support continuous 2 FPS detection (CameraDetectionViewModel implemented), but the frontend UI layer was never updated to consume and display this data.

**Evidence**:

1. **CameraDetectionViewModel.swift** (Lines 10-240):
   - Fully implements real-time detection pipeline
   - Processes frames at 2 FPS
   - Generates DetectedObject with catalogMode, mask, confidence
   - Has handleDoubleTap() for manual catalog gesture
   - Published property `detectedObjects: [DetectedObject]`

2. **CameraView.swift** (Lines 1-92):
   - Still uses deprecated `CameraViewModel.capturePhoto()` (marked @deprecated on line 72)
   - Has capture button UI (lines 64-81)
   - Does NOT use CameraDetectionViewModel
   - Does NOT display detectedObjects
   - Does NOT render organic borders
   - Does NOT have double-tap gesture handler

3. **Deprecation Warning** (CameraViewModel.swift:68-71):
   ```swift
   // DEPRECATED: Single-photo capture replaced with real-time detection
   // See: CameraDetectionViewModel.processFrame() for new API
   @available(*, deprecated, message: "Use CameraDetectionViewModel.processFrame() for real-time detection pipeline")
   ```

---

## Affected Files

### UI Layer (Needs Implementation)
- `Sources/CameraFeature/Views/CameraView.swift` - Main view needs complete refactor
- Missing: `Sources/CameraFeature/Views/OrganicBorderOverlay.swift` - Organic border rendering
- Missing: `Sources/CameraFeature/Views/SparkleAnimation.swift` - Sparkle effect on auto-catalog
- Missing: `Sources/CameraFeature/Views/CameraDetectionView.swift` - New main view

### ViewModel Layer (Already Implemented)
- ✅ `Sources/CameraFeature/ViewModels/CameraDetectionViewModel.swift` - Detection pipeline complete
- ⚠️ `Sources/CameraFeature/ViewModels/CameraViewModel.swift` - Deprecated, still in use

### Data Models (Already Implemented)
- ✅ `Sources/VisionCore/Models/DetectedObject.swift` - Complete with catalogMode, mask
- ✅ `Sources/VisionCore/Models/CatalogMode.swift` - Automatic/Manual/Ignore

---

## Required Implementation

### Phase 1: Create New UI Components

1. **OrganicBorderOverlay.swift**
   - Render organic shape from VNInstanceMaskObservation
   - Display mint green for automatic mode
   - Display grey for manual mode
   - Pulsing glow animation
   - Confidence badge and label

2. **SparkleAnimation.swift**
   - Particle emitter for mint green sparkles
   - Triggered on automatic catalog
   - 0.5s duration, radial expansion

3. **CameraDetectionView.swift**
   - Replace CameraView as main entry point
   - Use CameraDetectionViewModel instead of CameraViewModel
   - Display organic border overlays for each detectedObject
   - Add double-tap gesture handler
   - Remove capture button
   - Add mode indicator (Auto/Manual)

### Phase 2: Wire Detection Pipeline to UI

1. **Frame Capture Loop**
   ```swift
   // In CameraDetectionView.swift
   .onReceive(framePublisher.throttle(for: 0.5, scheduler: DispatchQueue.main)) { pixelBuffer in
       Task {
           await viewModel.processFrame(pixelBuffer)
       }
   }
   ```

2. **Display Detected Objects**
   ```swift
   ForEach(viewModel.detectedObjects) { object in
       OrganicBorderOverlay(object: object)
           .onTapGesture(count: 2) {
               Task {
                   await viewModel.handleDoubleTap(at: location)
               }
           }
   }
   ```

3. **Automatic Catalog Trigger**
   ```swift
   .onChange(of: viewModel.detectedObjects) { _, newObjects in
       for object in newObjects where object.catalogMode == .automatic {
           // Trigger sparkle animation
           // Trigger upload to Firebase
           // Play success haptic
       }
   }
   ```

### Phase 3: Deprecate Old UI

1. Rename CameraView → LegacyCameraView
2. Update all call sites to use CameraDetectionView
3. Remove deprecated CameraViewModel.capturePhoto() method
4. Update tests

---

## Test Plan

### Unit Tests

- [ ] Test CameraDetectionView displays borders for all detectedObjects
- [ ] Test mint green borders for automatic catalog mode (confidence > 0.70, quality > 0.65)
- [ ] Test grey borders for manual catalog mode (confidence 0.40-0.69 OR quality < 0.65)
- [ ] Test double-tap gesture calls viewModel.handleDoubleTap()
- [ ] Test sparkle animation triggers on automatic catalog
- [ ] Test no capture button is rendered

### Integration Tests

- [ ] Test frame processing pipeline runs at 2 FPS
- [ ] Test detected objects update UI in real-time
- [ ] Test organic borders match VNInstanceMaskObservation contours
- [ ] Test automatic catalog uploads cropped object to Firebase
- [ ] Test manual catalog waits for double-tap before upload
- [ ] Test continuous scanning (multiple objects over time)

### Manual Tests

- [ ] Open camera view, see continuous detection (no button)
- [ ] Point at high-quality object, see mint green border appear automatically
- [ ] Wait 2 seconds, see sparkle animation and object uploaded
- [ ] Point at low-quality object, see grey border appear
- [ ] Double-tap grey object, see upload triggered
- [ ] Scan multiple objects in sequence without closing camera
- [ ] Verify no capture button exists in UI

### Accessibility Tests

- [ ] VoiceOver announces detected objects ("Backpack detected with 92% confidence")
- [ ] VoiceOver announces catalog mode ("Automatic catalog mode" vs "Manual catalog mode")
- [ ] Reduce Motion disables pulsing glow and sparkle animations
- [ ] High Contrast increases border stroke width and glow opacity

---

## References

- **Spec**: docs/design/DESIGN-027-camera-capture-view-specification.md (v2.0, updated 2025-11-15)
- **Original Issue**: .debug/issues/triaged/issue-002.md
- **Log File**: .debug/logs/session-20251117-055805.log
- **Refactor Plan**: docs/plans/2025-11-15-realtime-object-detection-refactor.md (if exists)
- **Architecture**: ADR-010 (SwiftUI-only, MVVM pattern)

---

## Priority Justification

**High** - This is a major spec drift that fundamentally changes the user experience from manual button-driven capture to automatic continuous detection. The backend is ready but the UI is blocking users from experiencing the new feature.

---

## Estimated Effort

**Large** (3-5 days)
- Create OrganicBorderOverlay component (1 day)
- Create SparkleAnimation component (0.5 day)
- Create CameraDetectionView main view (1 day)
- Wire frame capture loop and detection display (1 day)
- Implement automatic catalog upload trigger (0.5 day)
- Add double-tap gesture handler (0.5 day)
- Write comprehensive tests (1 day)
- Update documentation and deprecate old UI (0.5 day)

---

## Suggested Branch

`feature/camera-detection-ui-implementation`

---

## Acceptance Criteria

- [ ] Camera opens and starts continuous detection at 2 FPS
- [ ] Organic borders appear around detected objects in real-time
- [ ] Mint green borders for high-confidence objects (automatic mode)
- [ ] Grey borders for medium-confidence objects (manual mode)
- [ ] Sparkle animation plays when automatic catalog triggers
- [ ] Double-tap on grey borders triggers manual catalog
- [ ] No capture button exists in UI
- [ ] Mode indicator shows "Auto/Manual" in top-right
- [ ] Instruction label shows "Double-tap grey objects to catalog manually"
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] All accessibility tests pass
- [ ] Code review approved
- [ ] Design review approved (matches DESIGN-027 v2.0 spec exactly)

---

## Notes

This is NOT a bug in the traditional sense - the code doesn't have errors or crashes. This is **spec drift** where the implementation (old v1.0 single-photo UI) significantly diverges from the specification (new v2.0 continuous detection UI).

The backend detection pipeline is fully functional and well-tested. The only missing piece is the frontend UI layer to display and interact with the detection results.

This issue should be treated as a feature implementation rather than a bug fix, despite being classified as spec drift.
