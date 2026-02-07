# View Spec: ItemCard

**Source:** `Sources/InventoryFeature/ItemCard.swift`
**Module:** InventoryFeature
**Priority:** P0 (core grid component)
**Last updated:** 2026-02-06

---

## 1. Palette

| Element | Token | Hex | Usage |
|---------|-------|-----|-------|
| Card background | `cream` | `#F0DCC0` | `.background(Color.cream, in: outerShape)` |
| Card stroke | `peach` | `#EDBE9E` | `.stroke(Color.peach, lineWidth: 1)` (2 in increased contrast) |
| Card shadow | `black.opacity(0.1)` | — | Drop shadow |
| Selected stroke | `accentPrimary` | `#E8907A` | `.stroke(Color.accentPrimary, lineWidth: 3)` |
| Selection circle (selected) | `accentPrimary` | `#E8907A` | Circle fill |
| Selection circle (unselected) | `.white.opacity(0.8)` | — | Circle fill |
| Checkmark icon | `.white` | — | `xmark` on selected circle |
| Item name text | `.primary` | — | System primary |
| Brand/color text | `.secondary` | — | System secondary |
| Separator text | `.tertiary` | — | "-" separator |
| Condition badge (new/likeNew) | `mutedSage` | `#9DC4A8` | ConditionBadge |
| Condition badge (good) | `softTeal` | `#8ECAC0` | ConditionBadge |
| Condition badge (fair) | `peach` | `#EDBE9E` | ConditionBadge |
| Condition badge (poor) | `salmon` | `#E8907A` | ConditionBadge |
| Status badge (processing) | `peach` | `#EDBE9E` | StatusBadge |
| Status badge (complete) | `mutedSage` | `#9DC4A8` | StatusBadge |
| Status badge (failed) | `salmon` | `#E8907A` | StatusBadge |
| Photo loading/error bg | via `ItemImage` | — | Delegated to ItemImage component |

**Known violations:** None — all colors use brand tokens.

## 2. Accessibility

| Element | Label | Trait | Min Target | Dynamic Type |
|---------|-------|-------|------------|--------------|
| Card (root) | "{name}, {brand}, {color}, {condition}, {status}" | `.isButton`, `.combine` | — | Body/Footnote |
| Photo image | "Photo of {displayName}" | — | — | — |
| Selection indicator | (part of combined card) | — | 44x44pt circle | — |
| Context menu (Edit) | "Edit" | `.isButton` | System | System |
| Context menu (Re-catalog) | "Re-catalog" | `.isButton` | System | System |
| Context menu (Delete) | "Delete" | `.isButton`, `.destructive` | System | System |

**Notes:**
- Card uses `.accessibilityElement(children: .combine)` with full description
- Selection state announced as "selected"/"not selected" in label
- Image height adapts for Dynamic Type: 160pt default, 120pt at xxxLarge+

## 3. Liquid Glass

| Element | Treatment | Tint | Fallback (< iOS 26) |
|---------|-----------|------|---------------------|
| Card background | None — solid `cream` | — | Cream stays |
| Selection circle | None — solid fill | — | — |

**Opportunities:**
- Card background could use `adaptiveGlass(cornerRadius: 16)` for glass-on-scroll

## 4. Layout

| Element | Constraint | Value |
|---------|-----------|-------|
| Outer corner radius | continuous | 16pt |
| Inner corner radius (image) | continuous | 12pt |
| Image height | adaptive | 160pt (120pt at xxxLarge+) |
| Metadata h-padding | horizontal | 12pt |
| Metadata b-padding | bottom | 12pt |
| VStack spacing | between items | 12pt (card), 4pt (metadata) |
| Selection circle | size | 44x44pt |
| Selection circle | padding from edge | 8pt |
| Card stroke | width | 1pt (2pt in increased contrast) |
| Condition badge h-padding | horizontal | 6pt |
| Status badge h-padding | horizontal | 8pt |
| Badge v-padding | vertical | 2pt |
| Press scale | effect | 0.98x |

## 5. Animations & Haptics

| Trigger | Animation | Haptic | Duration |
|---------|-----------|--------|----------|
| Card press | `.brandPress` | None | 300ms spring |
| Selection toggle | `.brandPress` | None | 300ms spring |
| Press release | `.brandPress` (after 150ms delay) | None | 300ms spring |

**Notes:**
- All animations respect `@Environment(\.accessibilityReduceMotion)` — no animation when enabled
- Press animation uses `Task.sleep(150ms)` for tactile feel before releasing
- Context menu only shown when NOT in selection mode (avoids gesture conflict)
