---
date: 2026-02-08
status: Fixed
priority: P1
type: bug
component: ios
source: device-tester
related-files:
  - Sources/CameraFeature/ViewModels/CaptureSessionViewModel.swift
  - Sources/CameraFeature/Views/CaptureView.swift
  - Tests/CameraFeatureTests/ViewModels/CaptureSessionViewModelTests.swift
screenshots:
  - 020726-burst-002.png
axiom-agent: null
branch: claude/pedantic-bhabha
design-doc: null
---

## Summary

Burst mode always produces an error when capture completes, regardless of number of images captured.

## Description

When using burst mode, every capture session ends with an error upon completion. The number of images captured does not affect the outcome — whether 1 image or many, the result is always an error when the capture finishes.

## Expected Behavior

Burst mode capture should complete successfully and transition to the detection/review screen with all captured images.

## Actual Behavior

An error is displayed when burst capture completes, regardless of the number of images captured. The error shown was: "The operation couldn't be completed. (Swift.CancellationError error 1.)"

## Root Cause

Two-part bug:

1. **Gesture removal during burst** (`CaptureView.swift:151-159`): `gesturesEnabled` returned `false` when `uiState` changed from `.idle` to `.capturing`, removing the `DragGesture` recognizer. The user's finger-lift never triggered `endBurstCapture()` via the normal gesture path.

2. **Self-cancellation in auto-end path** (`CaptureSessionViewModel.swift:182`): Because the gesture path never fired, bursts always terminated via auto-end (max duration 4s or max 8 photos) from within the burst task itself. `endBurstCapture()` called `burstTask?.cancel()` which cancelled the **current** task, then `processCapture()` ran in the cancelled context. Any `try await` call (Firestore, Storage) threw `Swift.CancellationError`, wrapped as `.unknownError`.

## Fix Applied

1. **`CaptureView.swift`**: `gesturesEnabled` now returns `true` for both `.idle` and `.capturing` states, keeping the `DragGesture` active during burst capture so finger-lift correctly ends the burst.

2. **`CaptureSessionViewModel.swift`**: `endBurstCapture()` runs `processCapture()` in a fresh `Task { @MainActor }` (unstructured task that does not inherit cancellation from the burst task).

3. **`CaptureSessionViewModel.swift`**: Injected `getUserId` closure replacing direct `Auth.auth().currentUser?.uid` calls, making the ViewModel testable without Firebase configuration.

4. **Tests**: Fixed pre-existing test crashes (process crashed at `Auth.auth()` in unconfigured test env) and assertion races. All 27 `CaptureSessionViewModelTests` now pass.
