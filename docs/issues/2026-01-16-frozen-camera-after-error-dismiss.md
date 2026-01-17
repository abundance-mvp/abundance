# Bug: Camera View Frozen After Error Dismiss

**Date:** 2026-01-16
**Status:** Fixed
**Priority:** P1
**Component:** CameraFeature/CaptureView
**Fixed:** 2026-01-16

## Summary

When an error occurs during the capture/catalog flow and the user dismisses the error dialog (via "Try Again" button), the camera preview becomes frozen. The user must force-quit and reopen the app to restore camera functionality.

## Steps to Reproduce

1. Open Abundance app
2. Navigate to Camera tab (CaptureView)
3. Double-tap to trigger capture
4. Wait for an error to occur (e.g., permission error, upload failure, detection timeout)
5. Tap "Try Again" to dismiss the error
6. Camera preview is now frozen
7. Navigating away (to Inventory/Profile) and back does not restore camera

## Expected Behavior

After dismissing the error:
1. Camera preview should resume live feed
2. UI should return to idle state ready for new capture
3. All camera resources should be properly restarted

## Actual Behavior

- Camera preview shows last frozen frame
- Cannot capture new photos
- Requires app restart to restore functionality

## Technical Analysis

### Suspected Root Cause

In `CaptureView.swift`, the `dismissError()` function in `CaptureSessionViewModel` sets `uiState = .idle` but:
1. The `frozenFrame` state variable may not be cleared
2. The `CameraService` session may not be restarted
3. The camera preview layer may not be refreshed

### Relevant Code

**CaptureSessionViewModel.swift:381-386**
```swift
public func dismissError() {
    if case .error = uiState {
        cleanupCapture()
        uiState = .idle
    }
}
```

**CaptureView.swift** - `frozenFrame` state:
```swift
@State private var frozenFrame: Data?
```

The `frozenFrame` is set during capture but may not be cleared when error is dismissed.

### Files to Investigate

- `Sources/CameraFeature/Views/CaptureView.swift`
- `Sources/CameraFeature/ViewModels/CaptureSessionViewModel.swift`
- `Sources/CameraFeature/Services/CameraService.swift`

## Proposed Fix

1. Clear `frozenFrame` when dismissing error
2. Ensure `CameraService.startSession()` is called if needed
3. Add `onAppear` logic to restart camera when returning to view

## Workaround

Force-quit and reopen the app.

## Resolution

### Root Cause Confirmed

The Camera Auditor identified 3 critical issues:

1. **frozenFrame not cleared on error dismiss** - The `frozenFrame` state variable was set during capture but never cleared when dismissing errors. Since the frozen frame overlay has higher z-order than the live preview, it blocked the camera feed.

2. **Camera session not restarted** - `dismissError()` set `uiState = .idle` but never called `setupCamera()` to restart the AVCaptureSession.

3. **Missing session interruption handlers** - CameraService had no handlers for `AVCaptureSession.wasInterruptedNotification`, meaning phone calls or app switching could freeze the camera with no recovery mechanism.

### Changes Made

**CaptureView.swift:175-182** - Error dismissal now clears frozen frame and restarts camera:
```swift
case .error(let error):
    ErrorOverlay(error: error) {
        // Clear frozen frame first to unblock preview
        frozenFrame = nil
        viewModel.dismissError()
        // Restart camera session to resume live feed
        setupCamera()
    }
```

**CameraSessionState.swift** - Added `interrupted(reasonRawValue:)` case to track session interruptions.

**CameraService.swift** - Added session interruption notification handlers:
- `sessionWasInterrupted(_:)` - Publishes `.interrupted` state when phone call/other app takes camera
- `sessionInterruptionEnded(_:)` - Automatically restarts session when interruption ends

### Verification

- Build: ✅ Passed
- Manual test: Dismiss error → camera resumes live feed

## Related

- Session: 2026-01-16 iOS debugging session
- Fixed in same session: Gesture blocking on error overlay (gestures now disabled during error state)
- Axiom agent: camera-auditor (a531af9)
