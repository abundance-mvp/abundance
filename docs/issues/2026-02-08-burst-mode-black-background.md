---
date: 2026-02-08
status: Open
priority: P2
type: ux
component: ios
source: device-tester
related-files:
  - Sources/CameraFeature/Views/CaptureView.swift
  - Sources/CameraFeature/Views/CameraPreviewView.swift
screenshots:
  - 020726-burst-001.png
axiom-agent: null
branch: null
design-doc: null
---

## Summary

Background goes black during burst mode capture, creating a poor user experience.

## Description

During burst mode capture, the background turns completely black. This is visually jarring and provides a poor user experience — the user loses visual context of what they're capturing.

## Expected Behavior

The camera preview should remain visible (possibly dimmed or with an overlay) during burst capture so users maintain spatial awareness of their scene.

## Actual Behavior

The background goes fully black during burst mode.

## Technical Context

- **Device:** w-16e (iPhone 16e)
- **Screenshot reference:** 020726-burst-001.png (black background during capture)
- **Possible cause:** Camera preview layer is stopped or hidden during burst photo processing

## Proposed Solution

1. Keep the camera preview layer visible during burst capture
2. If preview must pause, freeze the last preview frame as a static background instead of black
3. Add a subtle overlay (e.g., semi-transparent dark) with capture progress indicator
