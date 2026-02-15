---
date: 2026-02-08
status: Open
priority: P1
type: bug
component: ios
source: code-review
related-files:
  - Sources/CameraFeature/Services/CameraService.swift
  - Sources/CameraFeature/Views/CaptureView.swift
screenshots: []
axiom-agent: axiom:camera-auditor
branch: null
design-doc: null
---

## Summary

Camera session interruption recovery has no error handling and UI never shows interruption state.

## Description

Two related issues in camera interruption handling:

1. `sessionInterruptionEnded()` (CameraService.swift:108-125) assumes `startRunning()` always succeeds with no error handling. If restart fails (e.g., after phone call), camera silently freezes.

2. `CaptureView` never subscribes to `cameraService.sessionState` publisher. Interruption events fire but the UI ignores them — user sees frozen camera with no error message.

## Expected Behavior

1. Interruption restart should report failures to the UI via session state publisher.
2. CaptureView should show an error overlay when camera is interrupted.

## Actual Behavior

1. Restart failure is silent — user sees frozen camera.
2. No UI feedback for camera interruption (phone calls, background transitions).

## Technical Context

- Found by: `axiom:camera-auditor` during code review
- Common scenario: phone call ends, camera never resumes
- `sessionStateSubject` exists but CaptureView doesn't subscribe

## Proposed Solution

1. Add error handling to `sessionInterruptionEnded()` with timeout
2. Subscribe CaptureView to `cameraService.sessionState` via `.task { for await state in... }`
