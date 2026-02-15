---
date: 2026-01-20
status: Fixed
priority: P2
type: bug
component: ios
source: device-tester
related-files:
  - Sources/InventoryFeature/InventoryView.swift
  - Sources/InventoryFeature/ItemCard.swift
screenshots:
  - Screenshot 2026-01-20 at 8.24.07 PM.png
axiom-agent: null
branch: null
fix-date: 2026-01-20
---

## Summary

Tapping items in multi-select mode does not select them - selection fails silently.

## Description

When user taps "Select" button to enter multi-select mode:
1. The button changes to "Done" (mode entered correctly)
2. Selection checkmark circles appear on cards
3. Tapping on cards does NOT toggle selection
4. No visual feedback, no selection state change
5. User cannot select items for bulk delete

## Expected Behavior

- Tapping a card in selection mode should toggle its selected state
- Selected cards should show filled checkmark
- Unselected cards should show empty circle
- Selection should be reflected in the view model

## Actual Behavior

- Tapping cards has no effect
- Selection state never changes
- No haptic feedback
- No error messages

## Technical Context

- Device: w-16e
- iOS: 26.0
- Source: device-tester
- The screenshot shows "Done" button indicating selection mode is active
- Cards show selection circles but none are selected despite tapping

## Possible Causes

1. Gesture conflict between NavigationLink and selection tap
2. The `onTap` closure not being passed when `isSelectionMode` is true
3. State binding issue with `selectedItems` Set
4. Button in ItemCard not receiving tap events

## Resolution

**Root Cause:** The `.contextMenu` modifier was always attached to the card, even in selection mode (just with no content). SwiftUI's context menu gesture recognizer was intercepting tap events, preventing the Button's tap handler from firing.

**Fix:** Created a `SelectionModeContextMenuModifier` that conditionally applies the context menu ONLY when NOT in selection mode. In selection mode, the context menu is completely omitted from the view hierarchy, allowing taps to reach the Button.

**File Changed:** `/Users/w/code/abundance-mvp/Sources/InventoryFeature/ItemCard.swift`

**Changes:**
1. Replaced inline `.contextMenu` with `.modifier(SelectionModeContextMenuModifier(...))`
2. Added `SelectionModeContextMenuModifier` ViewModifier that:
   - Returns content without context menu when `isSelectionMode == true`
   - Returns content with context menu when `isSelectionMode == false`

**Verification:**
- Build succeeds
- All 17 ItemCard tests pass
- Test "Selection mode hides context menu" specifically validates this behavior
