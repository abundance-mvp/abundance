---
date: 2026-01-18
status: fixed
priority: P1
type: bug
component: backend
source: device-tester
related-files:
  - functions/src/ai-pipeline/layer1/layer1-service.ts
  - Sources/CameraFeature/Views/BoundingBoxOverlay.swift
screenshots:
  - Screenshot 2026-01-18 at 10.11.10 PM.png
  - Screenshot 2026-01-18 at 10.22.59 PM.png
axiom-agent: general-purpose
branch: fix/bounding-box-coordinates
design-doc: null
implementation-plan: null
---

## Summary

Bounding box for "power strip" object is positioned incorrectly - appears in bottom left corner instead of actual object location.

## Description

During Layer 1 detection, the Gemini model detected a "power strip" object but returned incorrect bounding box coordinates. The bounding box renders in the bottom left corner of the image preview, far from where any power strip would actually be located in the scene.

This is visible in both screenshots where the "power strip" label and bounding box appear over the striped towel area rather than on an actual power strip.

## Expected Behavior

Bounding boxes should accurately outline the detected objects in their actual positions within the image.

## Actual Behavior

The "power strip" bounding box is positioned in the bottom left corner of the image, not aligned with any visible power strip. The coordinates returned by Gemini Flash appear to be incorrect or misinterpreted.

## Technical Context

- Device: w-16e (iPhone 16e)
- iOS: 18.x
- Source: device-tester session 2026-01-18
- Layer 1 model: Gemini 3 Flash

### Possible Causes

1. Gemini model hallucinating object that doesn't exist
2. Coordinate system mismatch between model output and iOS rendering
3. Bounding box normalization issue (0-1 vs pixel coordinates)
4. Image orientation/rotation not accounted for in coordinate mapping

## Reproduction Steps

1. Capture image of scene with multiple objects
2. Wait for Layer 1 detection
3. Observe bounding box positions - "power strip" box is misaligned

## Proposed Solution

1. Verify coordinate normalization in Layer 1 response parsing
2. Add validation that bounding boxes fall within reasonable image bounds
3. Consider confidence threshold filtering to reject low-confidence detections
4. Log raw Gemini coordinates vs rendered coordinates for debugging
