# Sweep Mode Brand Compliance Polish

**Date:** 2026-02-08
**Status:** In Progress
**Scope:** Audit and fix brand compliance across sweep/EdgeTAM UI views

---

## Overview

Audit all new sweep mode views against the Abundance Brand Bible v3.0 (`docs/brand/abundance-brand-bible-v3-2026-02-06.md`) and the on-device edition (`docs/brand/abundance-brand-bible-ondevice-2026-02-06.md`). Identify and fix brand compliance gaps.

## Files Under Audit

| File | Purpose |
|------|---------|
| `Sources/CameraFeature/Views/SweepCaptureView.swift` | Main sweep capture overlay with status bar and actions |
| `Sources/CameraFeature/Views/SweepModeToggle.swift` | Photo/Burst/Sweep mode picker |
| `Sources/CameraFeature/Views/SegmentOverlayView.swift` | Segment mask overlays on camera preview |
| `Sources/CameraFeature/Views/SegmentSelectionTray.swift` | Bottom tray with selected segment thumbnails |
| `Sources/CameraFeature/Views/OrganicBorderShape.swift` | Custom Shape for organic contour borders |
| `Sources/CameraFeature/ViewModels/SweepCaptureViewModel.swift` | ViewModel (no UI, but verify no UIKit imports) |
| `Sources/InventoryFeature/Components/PhotoCarouselView.swift` | Photo carousel with page indicator |

## Brand Compliance Checklist

### 1. Color Palette (Brand Bible Section 1.2)

- [ ] Replace `Color.blue` / `.blue` with `Color.salmon` or `Color.accentPrimary`
- [ ] Replace `Color.white` used as foreground text on brand colors (violates brand rule)
- [ ] Replace `Color.mint` in previews with brand colors
- [ ] Use `Color.accentPrimary` (salmon) for selected/active states
- [ ] Use `Color.cream` for content backgrounds
- [ ] Use `Color.deepPlum` for text on opaque surfaces
- [ ] Use `Color.peach` for borders/strokes on content elements

**Findings:**
- `SweepModeToggle.swift:43` - Uses `.blue` for selected mode (should be `Color.salmon`)
- `SweepCaptureView.swift:79,93` - Uses `.white` tint for ProgressView (OK: camera overlay context)
- `SweepCaptureView.swift:101,123` - Uses `.white` for button tint (OK on camera dark background per brand bible)
- `OrganicBorderShape.swift:213` - Uses `Color.mint` in preview (should use brand color)

### 2. Typography (Brand Bible Section 2.3)

- [ ] All text fonts should use `.system(.X, design: .rounded)` for brand consistency
- [ ] Font weights should follow brand bible specification

**Findings:**
- `SweepCaptureView.swift:100` - Uses `.subheadline.weight(.medium)` without `.rounded` design
- `SweepModeToggle.swift:39` - Uses `.body.weight()` without `.rounded` design
- `SweepModeToggle.swift:41` - Uses `.caption2.weight()` without `.rounded` design

### 3. Accessibility (Brand Bible Section 2.5)

- [ ] `@Environment(\.accessibilityReduceMotion)` checked and animations gated
- [ ] `@Environment(\.accessibilityReduceTransparency)` checked and glass effects gated
- [ ] `.accessibilityLabel()` on all interactive elements
- [ ] `.accessibilityHint()` on non-obvious interactive elements
- [ ] Dynamic Type support with `@ScaledMetric` or `.dynamicTypeSize` constraints

**Findings:**
- `SweepCaptureView.swift` - Has reduceMotion and reduceTransparency -- PASS
- `SweepModeToggle.swift` - Missing reduceMotion, reduceTransparency -- NEEDS FIX
- `SweepModeToggle.swift` - Has accessibilityLabel -- PASS, missing accessibilityHint -- NEEDS FIX
- `SegmentOverlayView.swift` - Has reduceMotion but missing reduceTransparency -- PARTIAL
- `SegmentSelectionTray.swift` - Has reduceMotion -- PASS, missing reduceTransparency -- NEEDS FIX
- `PhotoCarouselView.swift` - Missing reduceMotion and reduceTransparency -- NEEDS FIX
- `SweepCaptureView.swift:119-131` - Cancel/Catalog buttons missing accessibilityLabel/Hint -- NEEDS FIX

### 4. Liquid Glass (Brand Bible Section 1.7)

- [ ] Glass effects only on navigation-layer elements (per Two-Layer Strategy)
- [ ] Content-layer elements use opaque brand fills
- [ ] Glass effects gated on `@available(iOS 26.0, macOS 26.0, *)` via `adaptiveGlass()`
- [ ] Reduce Transparency fallback provides opaque alternative

**Findings:**
- `SweepCaptureView.swift:108` - Uses `adaptiveGlass(in: Capsule())` on status bar -- appropriate for overlay
- `SweepModeToggle.swift:25` - Uses `adaptiveGlass(in: Capsule())` on mode picker -- appropriate for chrome
- `PhotoCarouselView.swift:58` - Uses `adaptiveGlass(in: Capsule())` on page indicator -- appropriate for overlay
- All glass usages are for navigation/chrome overlays on camera -- PASS

### 5. Animation (Brand Bible Appendix C)

- [ ] Spring animations use `.brandDefault` or `.brandPress`
- [ ] All animations gated on `reduceMotion` with `.brandReducedMotion` fallback

**Findings:**
- `SegmentSelectionTray.swift:25` - Uses brand animations correctly -- PASS
- `SweepModeToggle.swift` - No animation on selection change -- NEEDS FIX (add press feedback)
- `SweepCaptureView.swift` - Missing animation gating on some state transitions

### 6. OrganicBorderShape.swift

- Shape-only file (no UI rendering) -- minimal brand concerns
- Preview uses `Color.mint` -- should use brand color
- No accessibility concerns (utility shape)

## Fixes Required

### P0 (Must Fix)

1. **SweepModeToggle** - Replace `.blue` with `Color.salmon` for selected state
2. **SweepModeToggle** - Add `.font(.system(.body, design: .rounded))` typography
3. **SweepModeToggle** - Add `reduceMotion` and `reduceTransparency` environment support
4. **SweepCaptureView** - Add rounded font design to status bar text
5. **SweepCaptureView** - Add accessibility labels/hints to Cancel and Catalog buttons

### P1 (Should Fix)

6. **SegmentOverlayView** - Add `reduceTransparency` environment and opaque fallback
7. **SegmentSelectionTray** - Add `reduceTransparency` environment
8. **PhotoCarouselView** - Add `reduceMotion` and `reduceTransparency` environment
9. **PhotoCarouselView** - Add rounded font design to page indicator (if any text)
10. **OrganicBorderShape** - Fix preview to use brand colors

### P2 (Nice to Have)

11. **SweepModeToggle** - Add selection animation with brand curves
12. **Dynamic Type** constraints on compact camera overlays
