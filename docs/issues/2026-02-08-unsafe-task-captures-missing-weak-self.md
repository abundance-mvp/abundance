---
date: 2026-02-08
status: Open
priority: P1
type: bug
component: ios
source: code-review
related-files:
  - Sources/CollectionFeature/ItemCard.swift
  - Sources/CameraFeature/Views/CaptureView.swift
screenshots: []
axiom-agent: axiom:concurrency-auditor
branch: null
design-doc: null
---

## Summary

Stored Tasks in `ItemCard` and `CaptureView` capture `self` implicitly without `[weak self]`, risking retain cycles.

## Description

Two locations with unsafe Task captures:

1. **ItemCard.swift** (line 231-237): `pressAnimationTask` captures `self` implicitly via `isPressed` state mutation. If the view is deallocated during `Task.sleep`, this creates a retain cycle.

2. **CaptureView.swift** (line 587-611): `captureAndProcess()` Task captures `self` via multiple `@State` properties (`isCaptureInProgress`, `frozenFrame`, `frozenFrameImage`). No `[weak self]` capture.

## Expected Behavior

All stored Tasks should use `[weak self]` capture lists to prevent retain cycles during async operations.

## Actual Behavior

Tasks capture `self` strongly, potentially keeping views alive beyond their intended lifecycle.

## Technical Context

- Found by: `axiom:concurrency-auditor` during code review
- SwiftUI views are value types but `@State` creates reference-type storage
- Tasks with `Task.sleep` are especially prone to outliving their parent view

## Proposed Solution

Add `[weak self]` to both Task closures and guard against nil self at the top.
