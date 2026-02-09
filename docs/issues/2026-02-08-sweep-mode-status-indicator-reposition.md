---
date: 2026-02-08
status: Open
priority: P2
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

Sweep mode status indicator needs lower opacity and repositioning to upper center area.

## Description

The sweep mode status indicator (visible in blue box area of 020826-sweep-001.png) needs two adjustments:
1. **Opacity:** Should be slightly lower opacity than current
2. **Position:** Should be moved to the upper center area of the screen (as indicated by blue arrow in screenshot)

## Expected Behavior

Status indicator is semi-transparent and positioned at the upper center of the camera view.

## Actual Behavior

Status indicator is at full opacity and positioned away from the upper center area.

## Technical Context

- **Device:** w-16e (iPhone 16e)
- **Screenshot reference:** 020826-sweep-001.png (blue box annotation, blue arrow indicates target position)

## Proposed Solution

1. Reduce the opacity of the status indicator background/container
2. Reposition using `.frame(maxWidth: .infinity, alignment: .center)` at the top of the overlay stack
