---
date: 2026-02-08
status: Open
priority: P2
type: feature
component: ios
source: device-tester
related-files:
  - Sources/CameraFeature/Views/CameraView.swift
  - Sources/CameraFeature/Views/CaptureView.swift
screenshots:
  - 020826-camera-view-001.png
axiom-agent: null
branch: null
design-doc: null
---

## Summary

Add "triple tap to enter sweep mode" hint text to camera view.

## Description

In the main camera view (screenshots/020826-camera-view-001.png, red box area), add a second row of hint text that reads: "triple tap to enter sweep mode". This helps users discover the sweep mode gesture.

## Expected Behavior

Camera view shows a hint on a second row: "triple tap to enter sweep mode"

## Actual Behavior

No hint about sweep mode activation gesture is displayed in the camera view.

## Technical Context

- **Device:** w-16e (iPhone 16e)
- **Screenshot reference:** 020826-camera-view-001.png (red box annotation)
- The hint should be placed below existing camera view text/controls

## Proposed Solution

Add a secondary `Text("triple tap to enter sweep mode")` below the existing camera hint text in `CameraView.swift` or `CaptureView.swift`, styled as a subtle hint (small font, reduced opacity).
