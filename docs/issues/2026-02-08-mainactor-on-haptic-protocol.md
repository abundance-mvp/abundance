---
date: 2026-02-08
status: Open
priority: P0
type: bug
component: ios
source: code-review
related-files:
  - Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift
  - Sources/CameraFeature/ViewModels/CaptureSessionViewModel.swift
screenshots: []
axiom-agent: axiom:concurrency-auditor
branch: null
design-doc: null
---

## Summary

`@MainActor` on `HapticFeedbackProviding` protocol forces all conformers to be MainActor-isolated; UIKit haptics called directly in ViewModels violate ADR-010.

## Description

Two related concurrency/architecture issues:

1. `HapticFeedbackProviding` protocol is marked `@MainActor`, which is overly restrictive. Per ADR-010, protocols should not force isolation — individual conformances should isolate as needed.

2. `CaptureSessionViewModel` calls `UIImpactFeedbackGenerator` directly (lines 404-409, 599, 227), violating ADR-010's "no UIKit in ViewModels" constraint.

## Expected Behavior

1. Protocol should declare `@MainActor` on individual methods, not the protocol itself.
2. Haptic feedback should be abstracted through a service/protocol, not called directly with UIKit in ViewModels.

## Actual Behavior

1. Protocol forces all conformers to be `@MainActor` classes.
2. ViewModels import UIKit directly for haptic calls.

## Technical Context

- Found by: `axiom:concurrency-auditor` during code review
- ADR-010: SwiftUI-only — `import UIKit` in Views/ViewModels is a P0 violation (infrastructure OK)
- Affects Swift 6 strict concurrency migration

## Proposed Solution

1. Remove `@MainActor` from protocol, add to individual method declarations
2. Create `HapticService` that conforms to `HapticFeedbackProviding` and wraps UIKit calls
3. Inject `HapticService` into ViewModels via constructor injection
