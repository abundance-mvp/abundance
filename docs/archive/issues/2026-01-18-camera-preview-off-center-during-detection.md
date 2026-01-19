---
date: 2026-01-18
status: open
priority: P1
type: bug
component: ios
source: manual
related-files:
  - Sources/CameraFeature/Views/CaptureView.swift
  - Sources/CameraFeature/Views/CameraPreviewView.swift
screenshots:
  - Screenshot 2026-01-18 at 7.13.50 PM.png
axiom-agent: null
branch: null
design-doc: null
implementation-plan: null
---

## Summary

Camera preview appears off-center/shifted when error overlay or detection results are displayed

## Description

When the camera is in an error state or showing detection results, the underlying camera preview appears to be shifted off-center. In the screenshot, the camera feed is visible behind the error dialog and appears shifted toward the upper-left corner of the screen, with black bars visible on the right and bottom edges.

This creates a jarring visual effect and suggests the camera preview layer is not properly constrained when overlays are displayed.

## Expected Behavior

- Camera preview should remain full-screen and centered at all times
- Preview should fill the entire screen edge-to-edge
- Overlays (error dialogs, detection results) should appear on top of the centered preview
- No black bars or offset should be visible

## Actual Behavior

- Camera preview shifts toward upper-left
- Black/empty space visible on right and bottom edges
- Preview appears cropped or incorrectly positioned
- Issue visible when error overlay is displayed (see screenshot)

## Technical Context

- Device: iPhone 16e (w-16e)
- iOS: 26
- Source: manual
- Screenshot shows "Analysis Failed" error dialog with misaligned preview behind it

Possible causes:
1. `CameraPreviewView` frame not properly constrained with `.ignoresSafeArea()`
2. Layout changes when `frozenFrame` or error overlay is shown
3. AVCaptureVideoPreviewLayer gravity or frame misconfiguration
4. GeometryReader interaction with overlay transitions

## Proposed Solution

1. Review `CameraPreviewView` constraints and ensure it fills parent
2. Check if preview layer's `videoGravity` is set to `.resizeAspectFill`
3. Verify `ZStack` layering doesn't affect preview positioning
4. Test with `background(Color.red)` on preview to visualize bounds
5. Ensure frozen frame image uses same sizing as live preview
