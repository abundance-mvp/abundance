---
date: 2026-01-20
status: Resolved
priority: P1
type: bug
component: backend
source: device-tester
related-files:
  - functions/src/ai-pipeline/layer1/layer1-service.ts
  - Sources/InventoryFeature/ItemCard.swift
screenshots:
  - Screenshot 2026-01-20 at 8.22.26 PM.png
axiom-agent: null
branch: null
resolved: 2026-01-20
---

## Summary

Cropped image thumbnails display with incorrect orientation/sizing, breaking the inventory grid layout.

## Description

The ItemCard thumbnails are rendering with:
1. Incorrect rotation (images appear sideways/rotated 90 degrees)
2. Images overflowing their container bounds
3. Cards overlapping each other in the grid
4. Severe layout breakage making the UI unusable

## Expected Behavior

- Thumbnails should display with correct orientation (upright)
- Images should be clipped to fit within their card bounds
- Grid layout should maintain proper spacing between cards

## Actual Behavior

- Images rotated 90 degrees (sideways)
- Images extend beyond card boundaries
- Cards overlap each other
- Grid layout completely broken

## Technical Context

- Device: w-16e
- iOS: 26.0
- Source: device-tester
- This appears to be an EXIF orientation issue - the cropped images may have EXIF rotation metadata that AsyncImage isn't respecting, or the crops are being saved without proper orientation normalization
- The backend sharp library should normalize orientation when cropping

## Proposed Solution

1. Backend: Ensure sharp normalizes EXIF orientation when cropping (`.rotate()` with no args auto-rotates based on EXIF)
2. iOS: Ensure AsyncImage or the image loading respects EXIF orientation

## Resolution

**Root Cause:** The backend `layer1-service.ts` was cropping images without normalizing EXIF orientation first. When a phone takes a portrait photo, the image data is often stored in landscape orientation with EXIF metadata indicating how to rotate it for display. The cropping code was:
1. Reading image dimensions from the original (un-rotated) buffer
2. Extracting the crop region without applying EXIF rotation
3. Saving images with incorrect orientation baked in

**Fix Applied:** Modified `functions/src/ai-pipeline/layer1/layer1-service.ts` in `cropAndUploadObjects()`:
1. Apply `.rotate()` FIRST to normalize EXIF orientation to actual pixels
2. Get metadata from the rotated buffer (correct dimensions)
3. Extract crop region from the already-rotated image

```typescript
// Before (broken):
const metadata = await sharpLib(imageBuffer).metadata();
const croppedBuffer = await sharpLib(imageBuffer)
  .extract({...})
  .jpeg({ quality: 85 })
  .toBuffer();

// After (fixed):
const rotatedBuffer = await sharpLib(imageBuffer)
  .rotate()  // Normalize EXIF orientation first
  .toBuffer();
const metadata = await sharpLib(rotatedBuffer).metadata();
const croppedBuffer = await sharpLib(rotatedBuffer)
  .extract({...})
  .jpeg({ quality: 85 })
  .toBuffer();
```

**Deployed:** `firebase deploy --only functions:onSessionCreated` completed successfully.

**Note:** Existing items with broken thumbnails will need to be re-processed to get correct orientation. New items captured after this deploy will have correct orientation.
