# View Spec: PhotoCarouselView

**Source:** `Sources/CollectionFeature/Components/PhotoCarouselView.swift`
**Module:** CollectionFeature
**Priority:** P1
**Last updated:** 2026-02-06

---

## 1. Palette

| Element | Token | Hex | Usage |
|---------|-------|-----|-------|
| Photo loading bg | `gray.opacity(0.1)` | — | Via `ItemImage` loading placeholder |
| Photo error bg | `gray.opacity(0.2)` | — | Via `ItemImage` error placeholder |
| Delete button icon fg | `.white` | `#FFFFFF` | `xmark.circle.fill` primary layer |
| Delete button icon bg | `deepPlum.opacity(0.8)` | `#3B2E3A` | `xmark.circle.fill` secondary layer |
| Page dot (active) | `.white` | `#FFFFFF` | Overlay on photo content |
| Page dot (inactive) | `.white.opacity(0.5)` | `#FFFFFF` @ 50% | Overlay on photo content |
| Page indicator capsule bg | `.ultraThinMaterial` | — | Material background |

**Known violations:**
- `ItemImage` placeholders use `Color.gray` — tracked in ItemImage component scope
- `.white` on page dots is intentional for overlay-on-photo contrast

## 2. Accessibility

| Element | Label | Trait | Min Target | Dynamic Type |
|---------|-------|-------|------------|--------------|
| Root container | "Photo {N} of {total}" | `.contain` | — | — |
| Delete button | "Delete photo {N}" (1-indexed) | `.isButton` | 44x44pt | — |
| Confirmation dialog | "Delete Photo" | System dialog | System | System |
| Delete action | "Delete" | `.isButton`, `.destructive` | System | System |
| Cancel action | "Cancel" | `.isButton`, `.cancel` | System | System |
| Page indicator dots | (none — decorative) | — | — | — |

**Notes:**
- Root view uses `.accessibilityElement(children: .contain)` with position label
- Delete button has explicit `.frame(minWidth: 44, minHeight: 44)`
- Delete button only appears on non-primary photos (`index > 0`)
- Missing: `.accessibilityAdjustableAction` for VoiceOver increment/decrement

## 3. Liquid Glass

| Element | Treatment | Tint | Fallback (< iOS 26) |
|---------|-----------|------|---------------------|
| Page indicator capsule | `.ultraThinMaterial` in `Capsule()` | — | Material stays |

**Opportunities:**
- Page indicator could use `adaptiveGlass(in: Capsule())` for iOS 26+ glass

## 4. Layout

| Element | Constraint | Value |
|---------|-----------|-------|
| Root | structure | `ZStack(alignment: .bottom)` |
| TabView | style | `.page(indexDisplayMode: .never)` |
| Delete button | min target | 44x44pt |
| Delete button | padding from edge | 8pt |
| Delete button | alignment | `.topTrailing` |
| Page dot diameter | size | 7pt |
| Page dot spacing | HStack spacing | 6pt |
| Page indicator | padding h/v | 12pt / 6pt |
| Page indicator | bottom margin | 12pt |
| Page indicator | shape | `Capsule()` |

**Notes:**
- View has no intrinsic height — parent supplies it
- Page dots are 7pt (decorative, non-interactive)

## 5. Animations & Haptics

| Trigger | Animation | Haptic | Duration |
|---------|-----------|--------|----------|
| Page swipe | System `TabView` page transition | None | System |
| Delete confirmation | System `.confirmationDialog` | None | System |
| Photo load retry | `ItemImage` loadId swap | None | 1s delay |

**Known gaps:**
- No haptic feedback on page swipe — consider `.sensoryFeedback(.selection, trigger: selectedIndex)`
- No animation on page dot state change — consider `.animation(.brandPress, value: selectedIndex)`
- `TabView` page animation is system-managed and respects `accessibilityReduceMotion` automatically

---

## Dependencies

### ItemImage (Core)
- Async image loading with retry logic (2 retries, 1s delay)
- Uses `Color.gray` placeholders — tracked separately

### Color+Brand (Core)
- Only `deepPlum` used directly (delete button icon background)
