---
date: 2026-02-07
status: Fixed
priority: P1
type: bug
component: shared
source: manual
related-files:
  - Sources/CameraFeature/Views/DetectionResultsView.swift
  - Sources/CameraFeature/Models/CaptureSession.swift
  - Sources/VisionCore/Utilities/PixelBufferCropper.swift
  - functions/src/ai-pipeline/layer1/schemas/detection-result.ts
screenshots:
  - Screenshot 2026-02-07 at 10.05.20 AM.png
  - Catalog-failure-bounding-box_020726.png
axiom-agent: null
branch: feature/brand-design-system
design-doc: null
---

## Summary

Bounding boxes are not aligned with detected objects, causing wrong regions to be displayed and cropped for cataloging.

## Description

When the detection results screen shows the captured image with bounding box overlays, the boxes are visibly misaligned from the actual objects. In the screenshot, two objects (Kose Sekkisei Emulsion and Clear pump bottle) are detected with correct labels, but the bounding boxes are drawn in the wrong location — shifted away from the objects, overlaying empty floor instead.

This has two consequences:
1. **UX confusion:** Users see bounding boxes that don't match the objects, reducing trust in the detection.
2. **Catalog pipeline corruption:** The crop region sent to Layer 2 cataloging is based on the same misaligned coordinates, so the AI catalogs the contents of the bounding box (floor/background) instead of the actual object.

## Expected Behavior

Bounding boxes should tightly surround the detected objects in the image, and the crop coordinates should extract the correct object region for cataloging.

## Actual Behavior

Bounding boxes are offset from the detected objects. The boxes appear over empty floor/background areas rather than the objects themselves.

## Technical Context

**Root cause (iOS rendering):** The `BoundingBoxOverlay` maps normalized coordinates (0-1) to the full `GeometryReader` container size. However, the image is displayed with `.aspectRatio(contentMode: .fit)`, which may letterbox the image (black bars on sides or top/bottom). The bounding box coordinates are relative to the *image* dimensions, not the *container* dimensions, causing a mismatch.

Relevant code in `DetectionResultsView.swift`:
```swift
// Image displayed with .fit (may not fill container)
Image(uiImage: uiImage)
    .resizable()
    .aspectRatio(contentMode: .fit)

// Bounding boxes mapped to CONTAINER size, not image display size
GeometryReader { geometry in
    let frame = CGRect(
        x: rect.minX * geometry.size.width,   // Should account for letterboxing offset
        y: rect.minY * geometry.size.height,
        width: rect.width * geometry.size.width,
        height: rect.height * geometry.size.height
    )
}
```

**Backend coordinate format:** Gemini returns `box_2d` as `[ymin, xmin, ymax, xmax]` normalized 0-1000. The Swift model converts this correctly in `BoundingBoxInfo.normalizedRect`. The coordinate conversion itself appears correct — the issue is in how the normalized rect is projected onto the displayed image.

**Cropping impact (CONFIRMED):** The crop sent to Layer 2 cataloging is also wrong. Second screenshot shows the catalog result is "Light Maple Wood Grain Laminate Flooring" (the floor) with low AI confidence — confirming the crop region contained floor, not the actual object. This is an end-to-end bug affecting both rendering AND the catalog pipeline.

## Proposed Solution

Calculate the actual displayed image frame within the container (accounting for aspect-fit letterboxing) and map bounding box coordinates to that frame:

1. Compute the displayed image rect from the image's intrinsic aspect ratio and the container size
2. Offset and scale bounding box coordinates to the displayed image rect instead of the full container
3. Verify that `PixelBufferCropper` crops are unaffected (they should work in image pixel space)
