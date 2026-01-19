---
date: 2026-01-18
status: fixed
priority: P0
type: bug
component: ios
source: device-tester
related-files:
  - Sources/CatalogFeature/Views/DetectedObjectRow.swift
  - Sources/CatalogFeature/ViewModels/DetectionViewModel.swift
  - Sources/CatalogFeature/ViewModels/CatalogViewModel.swift
screenshots:
  - Screenshot 2026-01-18 at 10.22.59 PM.png
  - Screenshot 2026-01-18 at 10.26.34 PM.png
axiom-agent: axiom:swiftui-architecture-auditor
branch: fix/catalog-button-duplicate-items
design-doc: null
implementation-plan: null
---

## Summary

Catalog button shows spinner briefly then reappears, causing users to tap multiple times and create duplicate failed items.

## Description

When tapping the "Catalog" button to initiate Layer 2 processing:

1. A spinning indicator appears for a few seconds
2. The spinner disappears and the "Catalog" button reappears
3. User thinks action didn't complete and taps again
4. Multiple catalog requests are sent for the same item
5. Results in duplicate items in inventory, most showing "Failed" status

This is a critical UX issue that creates data pollution and confuses users about processing state.

## Expected Behavior

1. Catalog button should remain disabled/hidden while processing
2. Clear visual feedback that processing is ongoing (even if it takes time)
3. Prevent duplicate submissions for the same detected object
4. Single item should appear in inventory regardless of tap count

## Actual Behavior

- Spinner shows briefly then Catalog button returns
- No indication that background processing is still happening
- Multiple taps create multiple inventory items
- Inventory shows duplicates with "Failed" and "Processing" statuses
- Screenshot 10.26.34 PM shows 4 duplicate "Unknown Item" entries

## Technical Context

- Device: w-16e (iPhone 16e)
- iOS: 18.x
- Source: device-tester session 2026-01-18
- Affects: Layer 2 cataloging workflow

### Root Cause Analysis

1. Button state not properly bound to async operation
2. No debouncing or duplicate submission prevention
3. Backend may be creating new documents for each request
4. No idempotency key to prevent duplicate processing

## Reproduction Steps

1. Capture image and wait for detection
2. Tap "Catalog" button on a detected object
3. When button reappears, tap it again 2-3 times
4. Navigate to Inventory view
5. Observe multiple duplicate items with Failed/Processing status

## Proposed Solution

### Immediate (P0)
1. Disable Catalog button immediately on tap, keep disabled until completion/failure
2. Add idempotency check - if item already submitted, prevent resubmission
3. Show persistent "Processing..." state on the row

### Follow-up
1. Add optimistic UI update showing item in inventory immediately
2. Implement proper loading states per SPEC-UI-002
3. Consider toast/banner for "Cataloging in progress..."
