---
date: 2026-02-08
status: Open
priority: P2
type: bug
component: ios
source: device-tester
related-files:
  - Sources/CollectionFeature/CollectionView.swift
  - Sources/CollectionFeature/ItemCard.swift
screenshots:
  - 020726-catalog-list-view-001.png
axiom-agent: null
branch: null
design-doc: null
---

## Summary

Collection view item cards are not uniform size, causing layout inconsistencies.

## Description

In the Collection view grid, item cards are not rendered at a uniform size. Some cards appear taller or wider than others, breaking the visual grid alignment and causing an inconsistent UI appearance.

## Expected Behavior

All item cards in the collection grid should have uniform dimensions (same width and height) regardless of their content (image aspect ratio, text length, etc.).

## Actual Behavior

Item cards have varying sizes, creating an uneven grid layout.

## Technical Context

- **Device:** w-16e (iPhone 16e)
- **Screenshot reference:** 020726-catalog-list-view-001.png (red box annotation)
- **Related issue:** Collection view item overlap (2026-02-07-catalog-grid-first-row-card-overlap.md)
- **Possible causes:**
  - Image aspect ratios not being normalized (some images taller, some wider)
  - Text content (item name, category) causing variable card heights
  - Missing fixed frame on the card container

## Proposed Solution

1. Set a fixed aspect ratio or fixed height on `ItemCard` containers
2. Use `.frame(height: fixedValue)` on the card or image container
3. Ensure images use `.aspectRatio(contentMode: .fill)` with `.clipped()` to normalize display
4. Truncate long text with `.lineLimit()` to prevent height variation
