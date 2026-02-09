---
date: 2026-02-07
status: Open
priority: P2
type: bug
component: ios
source: manual
related-files:
  - Sources/CollectionFeature/CollectionView.swift
  - Sources/CollectionFeature/ItemCard.swift
screenshots:
  - 020726-catalog-view-overlap.png
  - 020726-catalog-list-view-001.png
axiom-agent: null
branch: null
design-doc: null
---

## Summary

Right card in first grid row overlaps left card in the Collection view.

## Description

In the Collection view, the item card at row 1, position 2 (right side) consistently overlaps the item card at row 1, position 1 (left side). The right card's left edge visually bleeds over the left card's right edge, creating an overlapping appearance.

## Expected Behavior

Both cards in every grid row should be fully contained within their respective column, with consistent 16pt spacing between them and no visual overlap.

## Actual Behavior

The right card in the first row overlaps the left card. The card edges collide or overlap rather than maintaining proper spacing.

## Technical Context

**Grid layout** (`CollectionView.swift`):
- `LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16)`
- `.padding()` on the grid (16pt all sides)

**Card decorations** (`ItemCard.swift`):
- Shadow: `.shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)` — extends ~8pt in all directions
- Border overlay: `outerShape.stroke(Color.peach, lineWidth: 1-2)`
- Selection overlay: `outerShape.stroke(Color.accentPrimary, lineWidth: 3)` when selected
- Press scale: `.scaleEffect(isPressed ? 0.98 : 1.0)`

**Probable root causes:**

1. **Shadow bleed:** The 8pt shadow radius extends horizontally beyond the card's layout bounds. With 16pt column spacing, each card's shadow extends 8pt into the gap, consuming the full inter-column space and overlapping the adjacent card.

2. **No `.clipped()` on card container:** The outer `ZStack` in `ItemCard` does not clip its shadow/overlay decorations to its bounds. The `.background()` and `.overlay()` modifiers with rounded rectangles define visual bounds but don't clip the shadow.

3. **`.flexible()` columns without minimum spacing:** `GridItem(.flexible())` doesn't enforce a minimum gap — the spacing is purely the 16pt from the grid, but decorations that extend beyond layout bounds can visually overlap.

## Proposed Solution

1. **Add `.clipShape()` or `.contentShape()` to the card container** to clip shadow bleed to card bounds.
2. **Or reduce shadow radius** from 8pt to 4pt so it fits within the 16pt column gap (4pt per side = 8pt total, within the 16pt gap).
3. **Or increase grid spacing** to accommodate the shadow radius (e.g., `spacing: 24`).
