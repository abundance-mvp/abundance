# View Spec: DetectionResultsView

**Source:** `Sources/CameraFeature/Views/DetectionResultsView.swift`
**Module:** CameraFeature
**Priority:** P1
**Last updated:** 2026-02-08

---

## 1. Palette

| Element | Token | Hex | Usage |
|---------|-------|-----|-------|
| Image area background | `Color.black` | `#000000` | Camera image backdrop (viewfinder exempt) |
| Retake overlay text | `.white` | — | Icon + label on image overlay button |
| Retake overlay bg | `.glassEffect(.regular.interactive(), in: Capsule())` | — | iOS 26+ glass; fallback `black.opacity(0.5)` capsule fill |
| Bounding box (checked) | `.white.opacity(0.8)` | — | Checked, uncataloged object border |
| Bounding box (unchecked) | `.white.opacity(0.6)` | — | Unchecked, uncataloged object border |
| Bounding box (selected) | `Color.accentPrimary` | `#E8907A` (salmon) | Selected object border |
| Bounding box (cataloging) | `Color.cream` | — | In-progress cataloging border |
| Bounding box (cataloged) | `Color.successColor` | `#9DC4A8` (mutedSage) | Successfully cataloged border |
| Label badge text | `.white` | — | Object label text on bounding box |
| Label badge bg | `borderColor` | — | Matches dynamic border color |
| Object list bg | `Color(.systemBackground)` | — | System adaptive background |
| Bottom action bar bg (glass) | `.ultraThinMaterial` | — | Material when transparency allowed |
| Bottom action bar bg (opaque) | `Color(.systemBackground)` | — | Reduce-transparency fallback |
| Object card bg (default) | `Color(.secondarySystemBackground)` | — | Unselected card fill |
| Object card bg (selected) | `Color.accentPrimary.opacity(0.1)` | `#E8907A` @ 10% | Selected card highlight |
| Object card border (selected) | `Color.accentPrimary` | `#E8907A` (salmon) | Selected card stroke |
| Object card border (default) | `Color.clear` | — | No visible border |
| Thumbnail border (selected) | `Color.accentPrimary` | `#E8907A` (salmon) | Selected thumbnail stroke |
| Thumbnail placeholder bg | `Color(.secondarySystemFill)` | — | Missing thumbnail fill |
| Object label text | (default) | — | Uses default `.body` foreground |
| Object category text | `.secondary` | — | Muted category label |
| Attribute chip bg | `Color.secondary.opacity(0.2)` | — | Attribute capsule fill |
| Select All button | `Color.accentPrimary` | `#E8907A` (salmon) | Header action text |
| Catalog Selected button | `.borderedProminent` | — | System tinted button (bottom bar) |
| Toggle check (per object) | `Color.accentPrimary` / `.secondary` | — | Checked/unchecked toggle per card |
| Cataloged checkmark | `Color.successColor` | `#9DC4A8` (mutedSage) | Completion indicator |
| Header text | (default) | — | Uses default `.headline` foreground |
| Empty state icon | `.secondary` | — | Viewfinder icon |
| Empty state heading | (default) | — | Uses default `.headline` foreground |
| Empty state body | `.secondary` | — | Muted instructions |
| No-objects icon | `.secondary` | — | Large viewfinder circle icon |
| No-objects heading | (default) | — | Uses default `.title2` foreground |
| No-objects body | `.secondary` | — | Reasoning text |
| Tips bg | `Color.secondary.opacity(0.1)` | — | Tips card fill |
| Tip icons | `Color.accentPrimary` | `#E8907A` (salmon) | Tip row SF Symbol color |
| Retake Photo button | `.borderedProminent` | — | System tinted button |

**Known violations:**

- **VIOLATION:** `Color(.systemBackground)` used at lines 163, 173 (object list bg) and line 323 (`secondarySystemBackground` in card bg) -- these are UIKit system colors, not brand tokens. Should use `Color.backgroundDefault` (warmWhite `#FAF6F0`) or a semantic surface token.
- **VIOLATION:** `Color(.secondarySystemFill)` at line 378 (thumbnail placeholder) -- UIKit system color. Should use brand token or design-system fill.
- **FIXED:** Cataloging bounding box now uses `Color.cream` instead of `.yellow`.
- `.white` and `Color.black` are used intentionally for the image overlay layer (viewfinder exemption applies). The retake overlay capsule now uses `.glassEffect(.regular.interactive(), in: Capsule())` on iOS 26+ with `black.opacity(0.5)` fallback.
- **VIOLATION:** `Color.secondary.opacity(0.2)` at line 408 (attribute chip bg) and `Color.secondary.opacity(0.1)` at line 471 (tips bg) -- raw opacity on system color. Should use brand surface tokens.

## 2. Accessibility

| Element | Label | Trait | Min Target | Dynamic Type |
|---------|-------|-------|------------|--------------|
| Bounding box overlay | "Detected: {label}" | `.isButton` | Tap region = normalized bbox | — |
| Bounding box overlay hint | "Double tap to select" / "Double tap to deselect" | — | — | — |
| Retake overlay button | "Retake photo" | `.isButton` | Capsule padded 12pt | Caption2 / Caption semibold |
| Retake overlay identifier | `detection.retakeOverlayButton` | — | — | — |
| Object card (combined) | "{label}, {category}" | `.isButton` | Card area (~full width x ~84pt) | Body / Caption |
| Object card identifier | `detection.object.{groupId}` | — | — | — |
| Object card hint | "Double tap to select this object" | — | — | — |
| Select All button | (text: "Select All" / "Deselect All") | `.isButton` | Text-only | Caption semibold |
| Select All identifier | `detection.selectAllButton` | — | — | — |
| Toggle check (per card) | "Selected for cataloging" / "Not selected" | `.isButton` | `.title2` icon | — |
| Toggle check identifier | `detection.toggleCheck.{groupId}` | — | — | — |
| Toggle check hint | "Double tap to select/deselect this item" | — | — | — |
| Cataloged checkmark | "Cataloged" | (image) | 44x44pt (`.title2`) | — |
| Retake bottom button | (text: "Retake") with icon | `.isButton` | `.bordered` default | Body |
| Retake bottom identifier | `detection.retakeButton` | — | — | — |
| Catalog Selected button | "Catalog N items" | `.isButton` | `.borderedProminent` | Body semibold |
| Catalog Selected identifier | `detection.catalogSelectedButton` | — | — | — |
| Done bottom button | (text: "Done") | `.isButton` | `.borderedProminent` default | Body semibold |
| Done bottom identifier | `detection.doneButton` | — | — | — |
| Done bottom hint | "Saves results and returns to catalog view" | — | — | — |
| Empty state icon | (decorative) | — | — | `@ScaledMetric` (48pt base) |
| No-objects icon | (decorative) | — | — | `@ScaledMetric` (64pt base) |
| No-objects retake button | (text: "Retake Photo") | `.isButton` | `.controlSize(.large)` | Body |
| Reduce transparency | Checks `accessibilityReduceTransparency` | — | — | — |

**Concerns:**

- **FIXED:** Cataloged checkmark now has `.accessibilityLabel("Cataloged")`.
- **FIXED:** Cataloging `ProgressView` now has `.accessibilityLabel("Cataloging in progress")`.
- **FIXED:** `accessibilityReduceMotion` IS now checked -- animations use `.brandPress` with `nil` fallback when reduce-motion is enabled.
- **CONCERN:** Retake overlay capsule has padding of only 12pt from edges, with `caption2`/`caption` text size, resulting in a small visual target. The actual hit area may be under 44x44pt. Should verify with a frame of at least 44x44pt.
- **CONCERN:** The `NoObjectsDetectedView` tip rows have no individual accessibility identifiers or grouping. Consider `.accessibilityElement(children: .combine)` on the tips container.
- **GOOD:** `@ScaledMetric` is used for empty-state and no-objects icon sizes, properly supporting Dynamic Type.
- **GOOD:** `accessibilityReduceTransparency` is respected for the bottom action bar background.
- **GOOD:** Toggle check buttons have descriptive labels ("Selected for cataloging" / "Not selected") and hints.

## 3. Liquid Glass

| Element | Treatment | Tint | Fallback (< iOS 26) |
|---------|-----------|------|---------------------|
| Bottom action bar | `.adaptiveGlass(in: Rectangle())` | None | Adaptive glass with material fallback |
| Object list background | `Color(.systemBackground)` | None | System background |
| Retake overlay capsule | `.glassEffect(.regular.interactive(), in: Capsule())` | None | `black.opacity(0.5)` capsule fill fallback (< iOS 26) |
| Object cards | Opaque fill | None | N/A |

**Notes:**

- Bottom action bar now uses `.adaptiveGlass(in: Rectangle())` for iOS 26+ glass treatment.
- Retake overlay capsule uses `.glassEffect(.regular.interactive(), in: Capsule())` on iOS 26+.
- **RECOMMENDATION:** Object cards could adopt `adaptiveGlass(cornerRadius: 12)` for the selected state instead of raw opacity fill.

## 4. Layout

| Element | Constraint | Value |
|---------|-----------|-------|
| Root container | `GeometryReader` | Full available space |
| Image area | height | `geometry.size.height * 0.55` (55%) |
| Object list area | maxHeight | `geometry.size.height * 0.45` (45%) |
| Root VStack | spacing | `0` |
| Retake overlay button | padding (outer) | 12pt all sides from image top-left |
| Retake overlay capsule | padding (horizontal) | 10pt |
| Retake overlay capsule | padding (vertical) | 6pt |
| Retake overlay icon spacing | HStack spacing | 4pt |
| Object list header | padding (horizontal) | 16pt |
| Object list header | padding (vertical) | 12pt |
| Object card ScrollView content | padding (horizontal) | 16pt |
| Object card ScrollView content | padding (vertical) | 12pt |
| Object cards LazyVStack | spacing | 12pt |
| Object card internal | HStack spacing | 12pt |
| Object card internal | padding | 12pt all sides |
| Object card corner radius | RoundedRectangle | 12pt |
| Thumbnail | size | 60 x 60pt |
| Thumbnail corner radius | RoundedRectangle | 8pt |
| Thumbnail border (selected) | lineWidth | 2pt |
| Object info VStack | spacing | 4pt |
| Attribute chips | HStack spacing | 4pt |
| Attribute chip | padding (horizontal) | 6pt |
| Attribute chip | padding (vertical) | 2pt |
| Bottom actions | padding (horizontal) | 16pt |
| Bottom actions | padding (vertical) | 12pt |
| Bottom actions HStack | spacing | 16pt |
| Bounding box | cornerRadius | 4pt |
| Bounding box lineWidth (default) | stroke | 2pt |
| Bounding box lineWidth (selected) | stroke | 3pt |
| Label badge | padding (horizontal) | 6pt |
| Label badge | padding (vertical) | 3pt |
| Label badge offset | position | `frame.midX`, `frame.minY - 14` |
| Label badge shadow | radius | 2pt |
| Empty state VStack | spacing | 16pt |
| Empty state icon | size | `@ScaledMetric` base 48pt |
| No-objects VStack | spacing | 24pt |
| No-objects icon | size | `@ScaledMetric` base 64pt |
| No-objects reasoning | padding (horizontal) | 32pt |
| Tips container | padding | default (16pt) |
| Tips container | cornerRadius | 12pt |
| Tips internal VStack | spacing | 12pt |
| Tip rows VStack | spacing | 8pt |
| Tip row HStack | spacing | 8pt |
| Tip icon frame | width | 20pt |

## 5. Animations & Haptics

| Trigger | Animation | Haptic | Duration |
|---------|-----------|--------|----------|
| Bounding box tap (select/deselect) | `withAnimation(.brandPress)` (nil when reduceMotion) | None | 300ms spring |
| Object card tap (select) | `withAnimation(.brandPress)` (nil when reduceMotion) | None | 300ms spring |
| ProgressView (cataloging spinner) | System default | None | System |
| AsyncImage phase transition | System default | None | System |

**Notes:**

- **FIXED:** Animations now use `.brandPress` brand token instead of raw `.easeInOut`.
- **FIXED:** `@Environment(\.accessibilityReduceMotion)` is now read and respected -- animations pass `nil` when reduce-motion is enabled.
- **MISSING:** No haptic feedback on any interaction. Consider adding:
  - `.impact(.light)` on bounding box selection/deselection
  - `.impact(.light)` on object card selection
  - `.notification(.success)` when an object finishes cataloging (via `isCataloged` state change)
  - `.impact(.medium)` on "Catalog Selected" tap
- **MISSING:** No entrance animation for object cards or bounding boxes. Consider a staggered `.brandDefault` entrance when detection results first appear.
- **MISSING:** No transition animation on the cataloged checkmark appearance. The `checkmark.circle.fill` icon appears instantly when `isCataloged` becomes true. Consider a `.transition(.scale.combined(with: .opacity))` with `.brandPress`.

---

## Subviews (contained)

- `BoundingBoxOverlay` -- Draws normalized bounding box with dynamic color and label badge
- `DetectedObjectCard` -- Object list card with thumbnail, info, attributes, and catalog action
- `NoObjectsDetectedView` -- Standalone empty state with reasoning, tips, and retake CTA

## Subviews (referenced)

- `ServerDetectedObject` -- Data model for detected objects
- `BoundingBoxInfo` -- Bounding box coordinates model

## Summary of Violations

| # | Severity | Category | Status | Description |
|---|----------|----------|--------|-------------|
| V1 | Medium | Palette | Open | `Color(.systemBackground)` and `Color(.secondarySystemBackground)` used instead of brand tokens |
| V2 | Medium | Palette | Open | `Color(.secondarySystemFill)` used instead of brand surface token |
| V3 | Low | Palette | **Fixed** | ~~`.yellow` used for cataloging state~~ Now uses `Color.cream` |
| V4 | Low | Palette | Open | `Color.secondary.opacity(...)` used for chips and tips bg -- should use brand surface tokens |
| V5 | High | Accessibility | **Fixed** | ~~Cataloged checkmark icon missing `.accessibilityLabel`~~ Now has "Cataloged" label |
| V6 | Medium | Accessibility | **Fixed** | ~~ProgressView spinners missing descriptive accessibility labels~~ Now has "Cataloging in progress" label |
| V7 | High | Animations | **Fixed** | ~~Raw `.easeInOut(duration: 0.2)`~~ Now uses `.brandPress` |
| V8 | High | Animations | **Fixed** | ~~`accessibilityReduceMotion` not checked~~ Now reads and respects reduce-motion |
| V9 | Medium | Liquid Glass | **Fixed** | ~~No glass treatments~~ Bottom action bar uses `.adaptiveGlass(in: Rectangle())`, retake overlay uses `.glassEffect` |
| V10 | Low | Haptics | Open | No haptic feedback on any user interaction |
| V11 | Low | Accessibility | Open | Retake overlay capsule may be under 44x44pt minimum touch target |
