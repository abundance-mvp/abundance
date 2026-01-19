---
date: 2026-01-18
status: fixed
priority: P2
type: bug
component: ios
source: device-tester
related-files:
  - Sources/CatalogFeature/Views/CatalogItemView.swift
  - Sources/CatalogFeature/Views/InventoryView.swift
  - Sources/CatalogFeature/ViewModels/CatalogViewModel.swift
screenshots:
  - Screenshot 2026-01-18 at 10.26.34 PM.png
axiom-agent: axiom:swiftui-nav-auditor
branch: fix/edit-item-navigation
design-doc: null
implementation-plan: null
---

## Summary

Edit item option in catalog view context menu does not work - fails silently with no feedback.

## Description

In the Inventory/Catalog view, long-pressing on an item correctly shows a context menu with "Edit" and "Delete" options. The Delete function works correctly, but tapping "Edit" produces no response:

- No navigation to edit screen
- No error message
- No visual feedback
- Item remains unchanged

Note: This may be because edit functionality is not yet implemented. If so, the option should either be hidden or show "Coming soon" feedback.

## Expected Behavior

Tapping "Edit" should either:
1. Navigate to an item edit screen, OR
2. Show inline editing UI, OR
3. Display "Feature not yet available" message if unimplemented

## Actual Behavior

- Edit option appears in context menu
- Tapping Edit does nothing
- No feedback or error indication
- Delete option (same menu) works correctly

## Technical Context

- Device: w-16e (iPhone 16e)
- iOS: 18.x
- Source: device-tester session 2026-01-18
- Context menu triggered via long-press on inventory item

### Verification Needed

Check if edit functionality is:
1. Implemented but broken (bug)
2. Not implemented but UI shown (UX issue)
3. Implemented but navigation not wired (integration bug)

## Reproduction Steps

1. Navigate to Inventory view
2. Long-press on any catalog item
3. Context menu appears with Edit and Delete options
4. Tap "Edit"
5. Observe nothing happens

## Proposed Solution

### If not implemented:
1. Hide Edit option until feature is ready, OR
2. Show "Coming soon" toast when tapped

### If implemented but broken:
1. Debug navigation binding in context menu action
2. Verify edit view exists and is properly configured
3. Check state management for edit mode
