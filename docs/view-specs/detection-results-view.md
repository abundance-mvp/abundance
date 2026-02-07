# View Spec: DetectionResultsView

**Source:** `Sources/CameraFeature/Views/DetectionResultsView.swift`
**Module:** CameraFeature
**Priority:** P1
**Last updated:** 2026-02-06

---

## 1. Palette

| Element | Token | Hex | Usage |
|---------|-------|-----|-------|
| Image area background | `Color.black` | `#000000` | Camera image backdrop (viewfinder exempt) |
| Retake overlay text | `.white` | — | Icon + label on image overlay button |
| Retake overlay bg | `black.opacity(0.5)` | — | Semi-transparent capsule fill |
| Bounding box (default) | `.white.opacity(0.8)` | — | Unselected, uncataloged object border |
| Bounding box (selected) | `Color.accentPrimary` | `#E8907A` (salmon) | Selected object border |
| Bounding box (cataloging) | `.yellow` | — | In-progress cataloging border |
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
| Catalog All button | `Color.accentPrimary` | `#E8907A` (salmon) | Header action text |
| Catalog button (per object) | `.borderedProminent` | — | System tinted button |
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
- **VIOLATION:** `.yellow` at line 279 (cataloging bounding box) -- raw system color, not a brand token. Consider adding a `Color.warningColor` semantic alias or use `Color.peach`.
- **VIOLATION:** `.white` and `Color.black` are used intentionally for the image overlay layer (viewfinder exemption applies), but the retake overlay capsule `black.opacity(0.5)` could use a design-system overlay token for consistency.
- **VIOLATION:** `Color.secondary.opacity(0.2)` at line 408 (attribute chip bg) and `Color.secondary.opacity(0.1)` at line 471 (tips bg) -- raw opacity on system color. Should use brand surface tokens.

## 2. Accessibility

| Element | Label | Trait | Min Target | Dynamic Type |
|---------|-------|-------|------------|--------------|
| Bounding box overlay | "Detected: {label}" | `.isButton` | Tap region = normalized bbox | — |
| Bounding box overlay hint | "Double tap to select/deselect" | — | — | — |
| Retake overlay button | "Retake photo" | `.isButton` | Capsule padded 12pt | Caption2 / Caption semibold |
| Retake overlay identifier | `detection.retakeOverlayButton` | — | — | — |
| Object card (combined) | "{label}, {category}" | `.isButton` | Card area (~full width x ~84pt) | Body / Caption |
| Object card identifier | `detection.object.{groupId}` | — | — | — |
| Object card hint | "Double tap to select this object" | — | — | — |
| Catalog All button | (text: "Catalog All") | (implicit link) | Text-only | Caption semibold |
| Catalog button (per card) | (text: "Catalog") | `.isButton` | `.controlSize(.small)` | Caption semibold |
| Catalog button identifier | `detection.catalogButton.{groupId}` | — | — | — |
| Cataloged checkmark | (none) | (image) | 44x44pt (`.title2`) | — |
| Retake bottom button | (text: "Retake") with icon | `.isButton` | `.bordered` default | Body |
| Retake bottom identifier | `detection.retakeButton` | — | — | — |
| Done bottom button | (text: "Done") | `.isButton` | `.borderedProminent` default | Body semibold |
| Done bottom identifier | `detection.doneButton` | — | — | — |
| Empty state icon | (decorative) | — | — | `@ScaledMetric` (48pt base) |
| No-objects icon | (decorative) | — | — | `@ScaledMetric` (64pt base) |
| No-objects retake button | (text: "Retake Photo") | `.isButton` | `.controlSize(.large)` | Body |
| Reduce transparency | Checks `accessibilityReduceTransparency` | — | — | — |

**Concerns:**

- **VIOLATION:** Cataloged checkmark (`Image(systemName: "checkmark.circle.fill")` at line 418) has no `.accessibilityLabel`. VoiceOver will announce the SF Symbol name. Should add `.accessibilityLabel("Cataloged")`.
- **VIOLATION:** The "Catalog All" button at line 187 has no `.accessibilityLabel` or `.accessibilityHint` -- the text is self-describing, but there is no `.accessibilityAddTraits(.isButton)` explicitly set (it is a `Button` so traits are implicit -- acceptable).
- **CONCERN:** Retake overlay capsule has padding of only 12pt from edges, with `caption2`/`caption` text size, resulting in a small visual target. The actual hit area may be under 44x44pt. Should verify with a frame of at least 44x44pt.
- **CONCERN:** `ProgressView` spinners (lines 292, 362, 422) lack accessibility labels. VoiceOver may announce "In progress" generically. Consider `.accessibilityLabel("Cataloging in progress")`.
- **CONCERN:** The `NoObjectsDetectedView` tip rows have no individual accessibility identifiers or grouping. Consider `.accessibilityElement(children: .combine)` on the tips container.
- **GOOD:** `@ScaledMetric` is used for empty-state and no-objects icon sizes (lines 197, 441), properly supporting Dynamic Type.
- **GOOD:** `accessibilityReduceTransparency` is respected for the bottom action bar background.
- **MISSING:** `accessibilityReduceMotion` is NOT checked -- animations use raw `.easeInOut(duration: 0.2)` regardless of user preference.

## 3. Liquid Glass

| Element | Treatment | Tint | Fallback (< iOS 26) |
|---------|-----------|------|---------------------|
| Bottom action bar | None (uses `.ultraThinMaterial`) | None | `Color(.systemBackground)` when reduce-transparency |
| Object list background | None | None | `Color(.systemBackground)` |
| Retake overlay capsule | None (uses `black.opacity(0.5)`) | None | Same opaque fill |
| Object cards | None (uses opaque fill) | None | N/A |

**Known violations:**

- **VIOLATION:** No Liquid Glass treatments are applied anywhere in this view. The bottom action bar at line 168 uses `.ultraThinMaterial` directly instead of `adaptiveGlass()` from `LiquidGlassHelpers.swift`. This is inconsistent with the rest of the app (e.g., `CaptureView` uses `.glassEffect`).
- **RECOMMENDATION:** The bottom action bar should use `adaptiveGlass(in: Rectangle())` which provides iOS 26+ glass with automatic fallback to `.thickMaterial` and reduce-transparency support.
- **RECOMMENDATION:** The retake overlay capsule (`black.opacity(0.5)`) could use `adaptiveGlass(in: Capsule())` for iOS 26+ consistency with the capture view's mode indicator.
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
| Bounding box tap (select/deselect) | `withAnimation(.easeInOut(duration: 0.2))` | None | 200ms |
| Object card tap (select) | `withAnimation(.easeInOut(duration: 0.2))` | None | 200ms |
| ProgressView (cataloging spinner) | System default | None | System |
| AsyncImage phase transition | System default | None | System |

**Known violations:**

- **VIOLATION:** Lines 85, 145 use raw `.easeInOut(duration: 0.2)` instead of brand animation tokens. Should use `.brandPress` (300ms spring, dampingFraction 0.6) for tap interactions, which provides more satisfying bounce feedback. If reduced motion is desired, should conditionally use `.brandReducedMotion`.
- **VIOLATION:** `@Environment(\.accessibilityReduceMotion)` is NOT read anywhere in this file. All selection animations will play regardless of the user's Reduce Motion preference. Should gate animations behind a reduce-motion check.
- **MISSING:** No haptic feedback on any interaction. Consider adding:
  - `.impact(.light)` on bounding box selection/deselection
  - `.impact(.light)` on object card selection
  - `.notification(.success)` when an object finishes cataloging (via `isCataloged` state change)
  - `.impact(.medium)` on "Catalog All" tap
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

| # | Severity | Category | Description |
|---|----------|----------|-------------|
| V1 | Medium | Palette | `Color(.systemBackground)` and `Color(.secondarySystemBackground)` used instead of brand tokens |
| V2 | Medium | Palette | `Color(.secondarySystemFill)` used instead of brand surface token |
| V3 | Low | Palette | `.yellow` used for cataloging state -- no brand `warningColor` token |
| V4 | Low | Palette | `Color.secondary.opacity(...)` used for chips and tips bg -- should use brand surface tokens |
| V5 | High | Accessibility | Cataloged checkmark icon missing `.accessibilityLabel` |
| V6 | Medium | Accessibility | ProgressView spinners missing descriptive accessibility labels |
| V7 | High | Animations | Raw `.easeInOut(duration: 0.2)` used instead of `.brandPress` / `.brandReducedMotion` tokens |
| V8 | High | Animations | `accessibilityReduceMotion` not checked -- animations ignore Reduce Motion preference |
| V9 | Medium | Liquid Glass | No glass treatments applied -- should use `adaptiveGlass()` for bottom action bar |
| V10 | Low | Haptics | No haptic feedback on any user interaction |
| V11 | Low | Accessibility | Retake overlay capsule may be under 44x44pt minimum touch target |
