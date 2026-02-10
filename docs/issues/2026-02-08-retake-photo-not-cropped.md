---
date: 2026-02-08
status: Fixed
priority: P1
type: bug
component: ios
source: device-tester
related-files:
  - Sources/CollectionFeature/EditFlow/RescanCameraView.swift
  - Sources/CollectionFeature/EditFlow/EditItemSheet.swift
  - Sources/CollectionFeature/EditFlow/EditItemViewModel.swift
screenshots:
  - 020726-retake-photo-001.png
axiom-agent: null
branch: null
design-doc: null
---

## Summary

Retake photo (Item Detail > Edit Item) does not appear to be cropped, exposing surrounding items.

## Description

When using the "Retake photo" flow from Item Detail > Edit Item, the photo used does not appear to be cropped to the individual item. The uncropped photo shows surrounding items and context, which has two implications:

1. **Privacy:** Other items in the user's environment are visible in the item photo, which could be shared or synced
2. **Analysis accuracy:** The AI cataloging pipeline may receive a full scene image instead of a cropped individual item, reducing classification accuracy

## Expected Behavior

The retake photo should be cropped to focus on the specific item being edited, similar to how initial capture crops items via bounding box detection.

## Actual Behavior

The retake photo appears to be the full uncropped capture, showing the item along with surrounding objects and environment.

## Technical Context

- **Device:** w-16e (iPhone 16e)
- **Screenshot reference:** 020726-retake-photo-001.png
- **Flow:** Item Detail → Edit Item → Retake photo
- **Related files:** `RescanCameraView.swift` handles the retake camera, `EditItemViewModel.swift` processes the result

## Proposed Solution

1. Apply the same bounding box cropping logic used in initial capture to the retake flow
2. If no bounding box detection is run on retake, add a manual crop step or run detection on the retake image
3. Ensure the cropped image is what gets uploaded and sent to the AI pipeline
