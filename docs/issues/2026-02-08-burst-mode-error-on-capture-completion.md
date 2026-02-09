---
date: 2026-02-08
status: Open
priority: P1
type: bug
component: ios
source: device-tester
related-files:
  - Sources/CameraFeature/ViewModels/CaptureSessionViewModel.swift
  - Sources/CameraFeature/Models/CaptureSession.swift
  - Sources/CameraFeature/Services/CameraService.swift
screenshots:
  - 020726-burst-002.png
axiom-agent: null
branch: null
design-doc: null
---

## Summary

Burst mode always produces an error when capture completes, regardless of number of images captured.

## Description

When using burst mode, every capture session ends with an error upon completion. The number of images captured does not affect the outcome — whether 1 image or many, the result is always an error when the capture finishes.

## Expected Behavior

Burst mode capture should complete successfully and transition to the detection/review screen with all captured images.

## Actual Behavior

An error is displayed when burst capture completes, regardless of the number of images captured.

## Technical Context

- **Device:** w-16e (iPhone 16e)
- **Screenshot reference:** 020726-burst-002.png (error state after capture)
- **Likely location:** Error handling in `CaptureSessionViewModel.swift` or `CaptureSession.swift` burst completion logic

## Proposed Solution

1. Review burst capture completion handler for error conditions
2. Check if the error is a timeout, memory, or processing pipeline issue
3. Add detailed error logging for burst mode to identify the specific failure
