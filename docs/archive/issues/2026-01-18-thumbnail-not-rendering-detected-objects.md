---
date: 2026-01-18
status: fixed
priority: P1
type: bug
component: ios
source: device-tester
related-files:
  - Sources/CatalogFeature/Views/DetectedObjectRow.swift
  - Sources/CatalogFeature/ViewModels/DetectionViewModel.swift
screenshots:
  - Screenshot 2026-01-18 at 10.11.10 PM.png
  - Screenshot 2026-01-18 at 10.22.59 PM.png
axiom-agent: general-purpose
branch: fix/thumbnail-not-rendering
design-doc: null
implementation-plan: null
---

## Summary

Thumbnail image not rendering for detected objects - shows placeholder icon instead of cropped image.

## Description

After Layer 1 detection completes, the detected objects list shows placeholder icons instead of actual thumbnail images for some items. In the screenshots, the "Carhartt beanie" item displays a placeholder image icon while "striped towel" correctly shows its thumbnail.

This suggests the thumbnail URL or image data is not being properly loaded or cached for certain detected objects.

## Expected Behavior

All detected objects should display their cropped thumbnail images in the detection results list.

## Actual Behavior

Some detected objects show a placeholder image icon (broken image symbol) instead of the actual thumbnail. The "Carhartt beanie" consistently shows placeholder while other items like "striped towel" render correctly.

## Technical Context

- Device: w-16e (iPhone 16e)
- iOS: 18.x
- Source: device-tester session 2026-01-18
- Related to Layer 1 detection crop URLs

### Possible Causes

1. Crop URL not being generated/saved for this object
2. AsyncImage loading failure without proper fallback
3. Race condition between detection completion and URL availability
4. Firebase Storage download URL token issue for specific crops

## Reproduction Steps

1. Open camera and capture image with multiple objects
2. Wait for Layer 1 detection to complete
3. Observe detected objects list - some thumbnails show placeholder

## Proposed Solution

1. Verify crop URLs are being generated for all detected objects in Layer 1
2. Add error logging to AsyncImage loading to identify failures
3. Check if the issue correlates with specific object types or detection order
