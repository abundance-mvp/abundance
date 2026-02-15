---
date: 2026-02-08
status: Open
priority: P1
type: bug
component: ios
source: device-tester
related-files:
  - Sources/CameraFeature/Services/CameraService.swift
  - Sources/CameraFeature/Services/CameraSessionActor.swift
  - Sources/CameraFeature/Views/CameraPreviewView.swift
  - Sources/CameraFeature/Views/DetectionResultsView.swift
screenshots:
  - 020726-single-001.png
  - 020726-catalog-select-001.png
axiom-agent: null
branch: null
design-doc: null
---

## Summary

Captured photo in single mode always shifts to the right of center.

## Description

When capturing a photo in single mode, the resulting image is shifted to the right compared to what was shown in the camera preview. This misalignment between preview and capture could be the root cause of the bounding box offset issue (see related issue: single-mode-bounding-boxes-still-offset-right).

Two possibilities need investigation:
1. **Camera preview vs capture misalignment:** The preview layer shows a different crop/position than what `AVCapturePhotoOutput` captures
2. **Purely UX issue:** The shift is cosmetic but compounds the bounding box coordinate mapping

## Expected Behavior

The captured photo should match the camera preview — objects centered in the preview should be centered in the captured image.

## Actual Behavior

The captured photo is consistently shifted to the right of what the camera preview showed.

## Technical Context

- **Device:** w-16e (iPhone 16e)
- **Screenshot references:** 020726-single-001.png (shifted capture), 020726-catalog-select-001.png (bounding box offset)
- **Possible causes:**
  - `AVCaptureVideoPreviewLayer` gravity vs photo output resolution mismatch
  - Preview uses `.resizeAspectFill` but captured photo has different aspect ratio
  - Connection video orientation not matching preview orientation

## Proposed Solution

1. Compare preview layer's `videoGravity` setting with the actual capture output dimensions
2. Log the captured photo dimensions vs preview frame dimensions
3. Ensure `AVCaptureConnection.videoOrientation` matches the UI orientation
4. If the shift is consistent, apply a compensating offset to bounding box mapping as a temporary fix
