# View Spec: ItemDetailView

**Source:** `Sources/InventoryFeature/ItemDetailView.swift`
**Module:** InventoryFeature
**Priority:** P0
**Last updated:** 2026-02-06

---

## 1. Palette

| Element | Token | Hex | Usage |
|---------|-------|-----|-------|
| Hero image bg | (black fallback) | — | Via `ItemImage` component |
| Item name | `.primary` | — | System primary text |
| Brand/model text | `.secondary` / `.tertiary` | — | System secondary text |
| Category badge (category) | `peach` | `#EDBE9E` | `CategoryBadge(color: .peach)` |
| Category badge (sub) | `softTeal` | `#8ECAC0` | `CategoryBadge(color: .softTeal)` |
| Processing banner bg | `.ultraThinMaterial` | — | Material background |
| Estimated value | `mutedSage` | `#9DC4A8` | `.foregroundStyle(Color.mutedSage)` |
| Metadata card | `cream` / `peach` | — | `.abundanceCardStyle(cornerRadius: 24)` |
| Card shadow | `black.opacity(0.15)` | — | Drop shadow |
| Deep scan icon | `softTeal` | `#8ECAC0` | `Color.softTeal` for deep scan feature |
| Confidence high | `mutedSage` | `#9DC4A8` | ConfidenceRow |
| Confidence medium | `peach` | `#EDBE9E` | ConfidenceRow |
| Confidence low | `salmon` | `#E8907A` | ConfidenceRow |
| Delete photo icon | `deepPlum.opacity(0.8)` | — | PhotoCarouselView overlay |

**Known violations:** None — `.purple` violations previously fixed to `Color.softTeal`.

## 2. Accessibility

| Element | Label | Trait | Min Target | Dynamic Type |
|---------|-------|-------|------------|--------------|
| Hero image (single) | "Detail photo of {displayName}" | — | — | — |
| Hero image (multi) | "Photos of {displayName}, N photos" | — | — | — |
| Item name | `detail.itemName` | `.isHeader` | — | Title bold |
| Re-catalog button | "Re-catalog item" / "Re-cataloging in progress" | `.isButton` | 44×44pt | — |
| Deep scan button | "Deep scan item" / "Deep scan in progress" | `.isButton` | 44×44pt | — |
| Edit button | "Edit item" | `.isButton` | 44×44pt | — |
| Estimated value | "Estimated value: $X.XX" | `.combine` | — | Title3 bold |
| AI Confidence | "AI Confidence: {level}" | `.combine` | — | Subheadline |
| Processing banner | `detail.processingBanner` | — | — | Subheadline |

**Notes:**
- All action buttons have 44×44pt frames via `.frame(minWidth: 44, minHeight: 44)`
- Value uses `.accessibilityElement(children: .combine)` for VoiceOver grouping

## 3. Liquid Glass

| Element | Treatment | Tint | Fallback (< iOS 26) |
|---------|-----------|------|---------------------|
| Navigation bar | System inline | — | System |
| Processing banner | `.ultraThinMaterial` | — | Material stays |
| Metadata card | `.abundanceCardStyle()` | — | Cream + peach stroke |
| Page indicator (carousel) | `.ultraThinMaterial` in `Capsule()` | — | Material stays |

**Opportunities:**
- Metadata card could use `adaptiveGlass(radius: .large)` for glass-on-scroll effect
- Processing banner could use `adaptiveGlass()` instead of raw material

## 4. Layout

| Element | Constraint | Value |
|---------|-----------|-------|
| Hero image height | relative | `outerGeometry.size.height * 0.5` |
| Metadata card padding | inner | 24pt |
| Metadata card corner | radius | 24pt |
| Metadata card overlap | offset y | -60pt (overlaps hero) |
| Metadata card | horizontal margin | 16pt |
| Metadata grid | 2 columns flexible | `GridItem(.flexible()) × 2` |
| Metadata grid | spacing | 12pt |
| Deep scan grid | 2 columns flexible | Same as metadata |

## 5. Animations & Haptics

| Trigger | Animation | Haptic | Duration |
|---------|-----------|--------|----------|
| Parallax scroll | `scrollOffset * 0.5` | None | Continuous |
| Processing banner | `.opacity + .move(edge: .top)` | None | System |
| Status change | `.onChange(of: item.status)` | None | — |

**Note:** Parallax respects `@Environment(\.accessibilityReduceMotion)` — offset is 0 when enabled.

---

## Subviews (private)

### CategoryBadge
- Capsule with `color.opacity(0.2)` background
- Caption weight medium text

### MetadataCell
- Two-line layout: label (caption2, tertiary) + value (footnote, primary)

### ConfidenceRow
- Icon + label + value with brand-mapped colors per confidence level

### ScrollOffsetPreferenceKey
- Tracks scroll position for parallax effect
