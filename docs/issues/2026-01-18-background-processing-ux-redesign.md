---
date: 2026-01-18
status: open
priority: P2
type: ux
component: ios
source: manual
related-files:
  - Sources/CameraFeature/Views/CaptureView.swift
  - Sources/CameraFeature/ViewModels/CaptureSessionViewModel.swift
  - Sources/CameraFeature/Views/DetectionResultsView.swift
  - docs/plans/2026-01-16-gemini-layer1-capture-redesign.md
screenshots:
  - Screenshot 2026-01-18 at 7.13.50 PM.png
axiom-agent: null
branch: null
design-doc: null
implementation-plan: null
---

## Summary

Redesign capture flow to move Layer 1 processing to background with immediate catalog navigation

## Description

The current capture UX blocks the user in the camera view while Layer 1 (Gemini 3 Flash) detection runs, showing "Scanning...", "Uploading...", and "Analyzing..." overlays. This creates a poor user experience with 3-8 seconds of waiting.

The proposed UX change:

1. **Capture Phase (Camera View)**
   - User double-taps or long-presses to capture
   - Brief haptic feedback confirms capture
   - Photo uploads to GCS in background
   - User is immediately navigated to Catalog view (or can continue capturing)

2. **Catalog View (New Experience)**
   - Shows pending items with "Processing..." indicator
   - When Layer 1 completes: cropped objects appear with details from Gemini 3 Flash
   - Each object card shows:
     - Cropped image thumbnail
     - Label from Layer 1 detection
     - Category and basic attributes
   - Action buttons per object:
     - **Delete**: Remove the detected object
     - **Update**: Edit the object details
     - **Catalog**: Kicks off Layer 2 (Gemini 3 Pro) for detailed cataloging

3. **Layer 2 Processing**
   - Only triggered when user taps "Catalog" button
   - Runs Gemini 3 Pro with tool calling (Lens, barcode, web search)
   - Updates item with full catalog data (brand, model, value, etc.)

This approach:
- Eliminates blocking wait times during capture
- Gives user control over which objects to fully catalog (cost optimization)
- Allows batch review of detected objects
- Separates "detection" from "cataloging" in the UI

## Expected Behavior

1. User captures photo(s)
2. App immediately returns to normal state or navigates to Catalog
3. Processing happens invisibly in background
4. Catalog view shows cropped objects when Layer 1 completes
5. User explicitly triggers Layer 2 cataloging per object

## Actual Behavior

1. User captures photo(s)
2. Camera view shows blocking overlays: "Uploading...", "Analyzing..."
3. User must wait 3-8 seconds before seeing results
4. Results appear in camera view (not catalog view)
5. Layer 2 triggered automatically on "Catalog" tap in camera view

## Technical Context

- Related plan: `docs/plans/2026-01-16-gemini-layer1-capture-redesign.md`
- Current implementation follows the plan's UX but user requests different flow
- Source: manual

## Proposed Solution

1. Modify `CaptureView` to dismiss/return after capture confirmation
2. Add "pending sessions" state to Catalog view
3. Create Firestore listener for session status updates in Catalog
4. Add detected objects to Catalog with "detected" status (not yet cataloged)
5. Add explicit "Catalog" CTA button per object to trigger Layer 2
6. Consider optimistic UI showing placeholder during Layer 1 processing
