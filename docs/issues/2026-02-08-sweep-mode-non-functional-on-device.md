---
date: 2026-02-08
status: Open
priority: P0
type: bug
component: ios
source: device-tester
related-files:
  - Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift
  - Sources/CameraFeature/Views/SweepCaptureView.swift
  - Sources/CameraFeature/Views/SweepModeToggle.swift
  - Sources/CameraFeature/Services/SweepARSessionManager.swift
screenshots:
  - 020826-sweep-001.png
axiom-agent: null
branch: null
design-doc: null
---

## Summary

Sweep mode is completely non-functional on device w-16e — no animation, no detection, no feedback.

## Description

When entering sweep mode on physical device w-16e (iPhone 16e), nothing happens. Multiple interaction methods were attempted:
- Single press
- Double press
- Press and hold
- Press and highlight

None of these produced any visible animation, detection indication, or object recognition. The catalog counter does not appear and no objects are detected.

## Expected Behavior

1. Entering sweep mode should show a clear visual transition/animation
2. Panning across items should trigger real-time object detection
3. The catalog counter should become visible when an item is successfully detected and sent to processing
4. Haptic feedback should confirm detections

## Actual Behavior

Nothing happens. No visual feedback, no detection, no counter, no haptic response. The mode appears completely broken on device.

## Technical Context

- **Device:** w-16e (iPhone 16e)
- **iOS version:** Current
- **Note:** iPhone 16e may have hardware differences (no LiDAR) that affect ARKit-based sweep if the implementation relies on depth sensing. Review `SweepARSessionManager.swift` for device capability checks.
- **Related files:** `SweepCaptureViewModel.swift` handles detection state, `SweepCaptureView.swift` renders the UI, `SweepARSessionManager.swift` manages the AR session.

## Proposed Solution

1. Review `SweepARSessionManager` for device capability requirements (LiDAR, ARKit configuration)
2. Add device eligibility check and fallback for non-LiDAR devices
3. Add logging/diagnostics for sweep mode activation failures
4. Ensure the catalog counter visibility is tied to detection events
