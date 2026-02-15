---
date: 2026-02-08
status: Open
priority: P3
type: ux
component: ios
source: device-tester
related-files:
  - Sources/CameraFeature/Views/SweepCaptureView.swift
screenshots:
  - 020826-sweep-001.png
axiom-agent: null
branch: null
design-doc: null
---

## Summary

Remove "Pan across items to detect" helper text from sweep mode.

## Description

The sweep mode UI currently displays the text "Pan across items to detect" (visible in red box area of 020826-sweep-001.png). This helper text should be removed.

## Expected Behavior

No "Pan across items to detect" text visible in sweep mode.

## Actual Behavior

"Pan across items to detect" text is displayed in sweep mode.

## Technical Context

- **Device:** w-16e (iPhone 16e)
- **Screenshot reference:** 020826-sweep-001.png (red box annotation)
- Text is likely in `SweepCaptureView.swift`

## Proposed Solution

Remove or hide the helper text string from `SweepCaptureView.swift`.
