---
date: 2026-01-20
status: in-progress
priority: P1
type: bug
component: ios
source: manual
related-files:
  - Sources/CameraFeature/Views/CaptureView.swift
  - Sources/CameraFeature/Services/CameraService.swift
  - Sources/CameraFeature/Services/CameraSessionActor.swift
  - App/MainTabView.swift
  - App/CameraTabView.swift
screenshots:
  - Screenshot 2026-01-20 at 7.43.37 PM.png
axiom-agent: axiom:camera-auditor
branch: null
design-doc: null
implementation-plan: null
---

## Summary

Camera stops working after navigating away from Camera tab and returning.

## Description

When the user captures a photo in the Camera tab, views the detection results, then navigates to the Catalog or Profile tab and returns to the Camera tab, the camera preview does not resume. The camera appears frozen or black.

Initial fix attempt added `onAppear` handler to call `restartCameraIfNeeded()` but this did not resolve the issue.

## Expected Behavior

When returning to the Camera tab after navigating away:
1. Camera preview should resume showing live feed
2. User should be able to capture new photos
3. Camera session should restart automatically

## Actual Behavior

When returning to the Camera tab:
1. Camera preview shows black/frozen screen
2. Cannot capture new photos
3. Camera session does not restart properly

## Technical Context

- Device: w-16e (iPhone 16e)
- iOS: 18.x
- Source: manual testing
- SwiftUI TabView with 3 tabs: Catalog, Camera, Profile

### Current Lifecycle Flow

1. `CaptureView` uses `.task` for initial camera authorization
2. `.onDisappear` calls `teardownCamera()` which stops the session
3. `.onAppear` was added to call `restartCameraIfNeeded()` but doesn't work

### Suspected Issues

1. **SwiftUI TabView behavior**: TabView may not properly call `onAppear` when returning to a tab that was never fully removed from the view hierarchy
2. **AVCaptureSession state**: Session may be in an invalid state after stop/start cycle
3. **CameraService singleton**: The `CameraService` instance created in `CaptureView.init` may not persist properly across tab switches
4. **State management**: `captureSession` state variable may be stale when returning to tab

### Code Locations

- `CaptureView.swift:80-92` - onAppear/task/onDisappear handlers
- `CaptureView.swift:441-450` - restartCameraIfNeeded() function
- `CameraService.swift:143-166` - startSession/stopSession
- `MainTabView.swift:16-38` - TabView structure

## Proposed Solution

Requires deep investigation using `axiom:camera-auditor` agent to:
1. Audit AVCaptureSession lifecycle management
2. Check for proper interruption handling
3. Verify session state transitions
4. Consider using `scenePhase` environment value instead of onAppear/onDisappear
5. Consider keeping camera session alive but pausing/resuming instead of full stop/start
