---
date: 2026-02-07
status: Open
priority: P1
type: bug
component: ios
source: manual
related-files:
  - Sources/CameraFeature/Views/CaptureView.swift
  - Sources/CameraFeature/Views/CameraPreviewView.swift
  - Sources/CameraFeature/Services/CameraService.swift
  - Sources/CameraFeature/Services/CameraSessionActor.swift
  - App/CameraTabView.swift
screenshots:
  - Camera-view-post-process_020726.png
axiom-agent: null
branch: null
design-doc: null
---

## Summary

Camera freezes with zoomed-in offset of last captured photo after navigating away and back to camera tab.

## Description

After the camera captures a photo and the user navigates to another tab (Catalog or Profile) and then returns to the Camera tab, the live camera preview does not resume. Instead, it displays a frozen, zoomed-in, offset crop of the last captured photo. The camera is completely non-functional until the app is force-quit.

## Expected Behavior

When returning to the Camera tab after capturing a photo and navigating away, the live camera preview should resume with a full-frame, correctly-scaled feed from the device camera.

## Actual Behavior

The camera view shows a frozen, zoomed-in, offset image of the last captured photo. The live preview does not restart. The camera is unusable.

## Technical Context

**Device:** Physical device (screenshot from device)
**Lifecycle flow:** CaptureView uses `onAppear` → `restartCameraIfNeeded()` and `onDisappear` → `teardownCamera()`

**Probable root causes (from code analysis):**

1. **`frozenFrame` not cleared on return:** `CaptureView` stores captured photo data in `@State var frozenFrame: Data?` to freeze the preview during upload. This state may persist across tab switches since `CameraTabView` uses `@StateObject` to persist the camera service. If `frozenFrame` is not nil when the view reappears, the frozen overlay remains visible instead of the live preview.

2. **Preview layer frame stale after session restart:** `CameraPreviewView` (UIViewRepresentable) sets the `AVCaptureVideoPreviewLayer` frame in `layoutSubviews()`. After `teardownCamera()` stops the session and `restartCameraIfNeeded()` reconfigures it, the preview layer may not trigger a layout pass, leaving it with stale bounds (zoomed/offset appearance).

3. **Session restart race:** `teardownCamera()` is async and runs on `sessionQueue`. If the user navigates away and back quickly, `restartCameraIfNeeded()` may fire before teardown completes, leading to a misconfigured or stuck session.

## Proposed Solution

1. **Clear `frozenFrame` in `onAppear`:** Ensure `frozenFrame = nil` when the camera tab reappears so the live preview layer is always visible.

2. **Force layout update on session restart:** After restarting the session in `restartCameraIfNeeded()`, trigger `setNeedsLayout()` on the preview UIView to ensure the preview layer frame matches current bounds.

3. **Guard against restart-before-teardown:** Add a serialization mechanism (e.g., await teardown completion) in `restartCameraIfNeeded()` before starting a new session.
