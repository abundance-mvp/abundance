# View Spec: CollectionView

**Source:** `Sources/CollectionFeature/CollectionView.swift`
**Module:** CollectionFeature
**Priority:** P0
**Last updated:** 2026-02-06

---

## 1. Palette

| Element | Token | Hex | Usage |
|---------|-------|-----|-------|
| View background | (system default) | — | NavigationStack default |
| Select button tint | `accentPrimary` | `#E8907A` | `.tint(Color.accentPrimary)` |
| Selection toolbar bg | `cream` | `#F0DCC0` | `.abundanceCardStyle()` |
| Error icon | `errorColor` | `#E8907A` | Error state icon |
| Grid item cards | `cream` / `peach` | `#F0DCC0` / `#EDBE9E` | Via `ItemCard` |
| Empty state card | — | — | Via `EmptyStateCard` component |

**Known violations:** None

## 2. Accessibility

| Element | Label | Trait | Min Target | Dynamic Type |
|---------|-------|-------|------------|--------------|
| Select/Done button | "Enter/Exit selection mode" | `.isButton` | 44×44pt (`.controlSize(.large)`) | Body |
| Search bar | "Search items" | `.isSearchField` | — | Body |
| Loading indicator | "Loading items..." | `.updatesFrequently` | — | — |
| Empty state CTA | "Open Camera" | `.isButton` | 44×44pt | Body |
| Retry button | "Retry" | `.isButton` | 44×44pt | Body |
| Item grid | `collection.grid` | — | — | — |
| Item card | Combined a11y element | `.isButton` | — | Body/Footnote |
| Deselect All button | `collection.deselectAllButton` | `.isButton` | 44×44pt | Body |
| Bulk Delete button | `collection.bulkDeleteButton` | `.isButton` | 44×44pt | Body |

**Notes:**
- `ErrorView` error icon uses `@ScaledMetric(relativeTo: .largeTitle)` with `.font(.system(size:))` — Dynamic Type compliant

## 3. Liquid Glass

| Element | Treatment | Tint | Fallback (< iOS 26) |
|---------|-----------|------|---------------------|
| Navigation bar | System default | — | System default |
| Selection toolbar | `.abundanceCardStyle()` | — | Cream + peach stroke |
| Search bar background | None currently | — | — |

**Opportunities:**
- Selection toolbar could use `adaptiveGlass()` instead of solid cream
- Search bar could benefit from glass background

## 4. Layout

| Element | Constraint | Value |
|---------|-----------|-------|
| Search bar padding | horizontal | 16pt (`.padding(.horizontal)`) |
| Search bar padding | vertical | 8pt |
| Grid columns | 2 flexible | `[GridItem(.flexible()), GridItem(.flexible())]` |
| Grid spacing | between items | 16pt |
| Grid padding | all edges | 16pt (`.padding()`) |
| Selection toolbar | padding | 16pt (`.padding()`) |
| Empty state | padding | 16pt (`.padding()`) |

## 5. Animations & Haptics

| Trigger | Animation | Haptic | Duration |
|---------|-----------|--------|----------|
| Selection toggle | `.brandPress` | None | 300ms spring |
| Item tap (selection mode) | `.brandPress` | None | 300ms spring |
| Bulk delete clear | `.brandPress` | None | 300ms spring |

**Note:** All animations respect `@Environment(\.accessibilityReduceMotion)`.

---

## Subviews

### ItemGridView (private)
- Renders `LazyVGrid` of `ItemCard` components
- Selection mode toggles between `Button` tap and `NavigationLink`
- Respects `reduceMotion`

### EmptyCollectionView (private)
- Uses `EmptyStateCard` component
- "Open Camera" CTA delegates to parent

### ErrorView (private)
- `@ScaledMetric` for icon size (Dynamic Type compliant)
- Uses `Color.errorColor` (brand token)
