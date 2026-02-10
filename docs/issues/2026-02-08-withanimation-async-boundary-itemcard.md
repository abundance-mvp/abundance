---
date: 2026-02-08
status: Closed
priority: P0
type: bug
component: ios
source: code-review
related-files:
  - Sources/CollectionFeature/ItemCard.swift
screenshots: []
axiom-agent: axiom:swiftui-architecture-auditor
branch: null
design-doc: null
---

## Summary

`withAnimation` wraps state mutation after async `Task.sleep()` boundary in `ItemCard.handleTap()`, causing unpredictable animation timing.

## Description

In `ItemCard.handleTap()` (lines 225-236), the second `withAnimation(.brandPress)` block wraps `isPressed = false` after an `await Task.sleep(for: .milliseconds(150))`. This crosses an async boundary, violating the State-as-Bridge pattern. The animation duration is unpredictable because the Task.sleep is a separate async operation.

## Expected Behavior

State mutations should be synchronous within their own `withAnimation` context, not dependent on async timing.

## Actual Behavior

`withAnimation` wraps a state mutation that occurs after an `await`, causing the animation context to be unpredictable.

## Technical Context

- Found by: `axiom:swiftui-architecture-auditor` during code review
- Pattern: State-as-Bridge violation
- The current code works in practice but is architecturally incorrect and may cause animation glitches

## Proposed Solution

The Task captures should also use `[weak self]` (related concurrency finding). The pattern itself is borderline — the `withAnimation` inside the Task creates its own animation context, which is technically correct but fragile. Add `[weak self]` capture and document the pattern.
