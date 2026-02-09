---
date: 2026-02-08
status: Open
priority: P1
type: bug
component: ios
source: device-tester
related-files:
  - Sources/CameraFeature/Views/DetectionResultsView.swift
  - Sources/CameraFeature/Models/CaptureSession.swift
screenshots:
  - 020726-catalog-select-001.png
axiom-agent: null
branch: null
design-doc: null
---

## Summary

Bounding boxes are still offset to the right of detected objects after previous fix attempt.

## Description

Bounding boxes are still not drawn around the detected objects. They are all offset to the right of their intended target coordinates. This is a regression or incomplete fix from the previous issue (2026-02-07-bounding-boxes-misaligned-from-detected-objects.md, marked as Fixed).

The previous fix addressed aspect-fit letterboxing mapping, but the offset persists on device.

## Expected Behavior

Bounding boxes should tightly surround the detected objects in the image.

## Actual Behavior

All bounding boxes are offset to the right of their intended target coordinates.

## Technical Context

- **Device:** w-16e (iPhone 16e)
- **Screenshot reference:** 020726-catalog-select-001.png
- **Previous issue:** `docs/issues/2026-02-07-bounding-boxes-misaligned-from-detected-objects.md` (marked Fixed)
- **Related to:** Single mode captured photo shift issue (020726-single-001.png) — the photo capture itself may be shifting right, which could compound or cause the bounding box offset

## Proposed Solution

1. Re-investigate the coordinate mapping in `DetectionResultsView.swift`
2. Check if the photo capture shift (see related issue) is causing the bounding box misalignment
3. Test with debug overlay showing both raw coordinates and mapped coordinates
