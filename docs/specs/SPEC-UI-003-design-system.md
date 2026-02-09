# SPEC-UI-003: Design System Implementation

**Status:** Draft
**Created:** 2026-02-06
**References:** Brand Bible v3.0, SPEC-UI-001, SPEC-UI-002
**Code Refs:** Sources/Core/DesignSystem/, Sources/CollectionFeature/,
              Sources/CameraFeature/, Sources/ProfileFeature/, App/

---

## 1. Overview

This spec defines the concrete codebase changes required to align the Abundance iOS app with the Brand Bible v3.0 design system. Each section maps a brand bible rule to specific file changes.

**Scope:** Color palette migration, component restyling, accessibility fallbacks, asset catalog creation. Does NOT cover Liquid Glass navigation adoption (see SPEC-UI-004).

---

## 2. Color Palette Migration

### 2.1 Current State (Completed)

`Sources/Core/DesignSystem/Extensions/Color+Brand.swift` has been migrated to match the brand bible. The old color names (`brandBrightBlue`, `brandCoralOrange`, `brandSalmonPink`, `brandCreamYellow`, `brandMintGreen`, `textBrightBlue`, `textCoralOrange`, `textMintGreen`) have been removed and replaced with the brand palette.

### 2.2 Implemented Colors

```swift
// Sources/Core/DesignSystem/Extensions/Color+Brand.swift
import SwiftUI

public extension Color {
    // MARK: - Hex Initializer
    init(hex: String) { /* hex parsing implementation */ }

    // MARK: - Primary Brand Colors
    static let salmon = Color(hex: "E8907A")       // Primary accent, CTA buttons, active states
    static let peach = Color(hex: "EDBE9E")         // Secondary accent, borders, card strokes
    static let cream = Color(hex: "F0DCC0")         // Card backgrounds, content surfaces
    static let softTeal = Color(hex: "8ECAC0")      // Decorative accent, leaf icon
    static let mutedSage = Color(hex: "9DC4A8")     // Success states, positive feedback

    // MARK: - Text Colors
    static let deepPlum = Color(hex: "3B2E3A")      // Primary body text
    static let darkPlum = Color(hex: "2D2226")       // High-emphasis text
    static let ultraDarkPlum = Color(hex: "1A1218")  // Maximum contrast text

    // MARK: - Background Colors
    static let backgroundTeal = Color(hex: "5BB8C9") // Decorative background accent
    static let warmWhite = Color(hex: "FAF6F0")      // Default screen background

    // MARK: - Behind-Glass Pre-Saturated Variants
    static let salmonBehindGlass = Color(hex: "E87A60")
    static let peachBehindGlass = Color(hex: "EDB085")
    static let tealBehindGlass = Color(hex: "7AC4B8")

    // MARK: - Increase Contrast Variants
    static let salmonHighContrast = Color(hex: "C0705A")
    static let deepPlumHighContrast = Color.ultraDarkPlum

    // MARK: - Semantic Aliases
    static let accentPrimary = Color.salmon
    static let accentSecondary = Color.peach
    static let textPrimary = Color.deepPlum
    static let successColor = Color.mutedSage
    static let errorColor = Color.salmon
    static let backgroundDefault = Color.warmWhite
}
```

### 2.3 Migration Status

The color palette migration is **complete**. All old color names have been removed from the codebase. The following files now use brand colors:

| File | Brand Colors Used |
|------|-------------------|
| `PrimaryButton.swift` | `.salmon` fill, `.deepPlum` text |
| `SecondaryButton.swift` | `.salmon` stroke and text |
| `ItemCard.swift` | `.cream` background, `.peach` border, `.deepPlum` badge text |
| `ItemDetailView.swift` | `.peach`/`.softTeal` category badges, `.mutedSage` value, `.deepPlum` badge text |
| `EditItemSheet.swift` | `.successColor` save tint, `.errorColor` validation |
| `CollectionView.swift` | `.accentPrimary` select button, `.errorColor` error icon |
| `SearchBar.swift` | `.adaptiveGlass` styling |
| `CaptureOverlays.swift` | White text (camera dark context) |

---

## 3. Component Restyling

### 3.1 PrimaryButton (Completed)

**File:** `Sources/Core/DesignSystem/Components/PrimaryButton.swift`

**Implementation:** Opaque Salmon capsule, DeepPlum text, no glow, press scale 0.97

```swift
public var body: some View {
    Button(action: handleTap) {
        ZStack {
            Text(title)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.deepPlum)
                .opacity(isLoading ? 0 : 1)

            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color.deepPlum)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .frame(minHeight: 44) // Accessibility tap target
        .background(Color.salmon.opacity(isEnabled ? 1.0 : 0.4), in: Capsule())
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .opacity(isEnabled ? 1.0 : 0.5)
    }
    .disabled(!isEnabled || isLoading)
    .sensoryFeedback(.impact(weight: .medium), trigger: isPressed)
    .animation(reduceMotion ? .brandReducedMotion : .brandPress, value: isPressed)
    .accessibilityLabel(title)
    .accessibilityAddTraits(.isButton)
    .accessibilityRemoveTraits(isEnabled ? [] : .isButton)
    .accessibilityAddTraits(isEnabled ? [] : .isStaticText)
}
```

**Implemented features:**
- Opaque Salmon capsule background (no glass)
- DeepPlum text with rounded font design
- 0.97 scale press effect
- `.brandPress` / `.brandReducedMotion` animation presets
- `.sensoryFeedback` for haptics
- Accessibility traits for disabled state

### 3.2 SecondaryButton (Completed)

**File:** `Sources/Core/DesignSystem/Components/SecondaryButton.swift`

Salmon stroke outline, clear fill, Salmon text.

```swift
public var body: some View {
    Button(action: handleTap) {
        Text(title)
            .font(.system(.body, design: .rounded, weight: .semibold))
            .foregroundStyle(Color.salmon)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .frame(minHeight: 44)
            .background(isPressed ? Color.salmon.opacity(0.15) : Color.clear, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(Color.salmon, lineWidth: 1.5)
            }
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.5)
    }
    .disabled(!isEnabled)
    .sensoryFeedback(.impact(weight: .light), trigger: isPressed)
    .animation(reduceMotion ? .brandReducedMotion : .brandPress, value: isPressed)
    .accessibilityLabel(title)
    .accessibilityAddTraits(.isButton)
}
```

### 3.3 ItemCard Restyling (Completed)

**File:** `Sources/CollectionFeature/ItemCard.swift`

**Implementation:** Opaque Cream background, Peach border, brand colors throughout.

The card follows Content Layer rules:
- Background: `Color.cream` in `RoundedRectangle(cornerRadius: 16, style: .continuous)`
- Border: `Color.peach` 1px stroke (2px with increased contrast via `colorSchemeContrast`)
- Shadow: Black 8% opacity, 4pt radius, 2pt y-offset
- Title: `.body` weight with `.rounded` design, `.primary` foreground
- Brand/Color: `.footnote` with `.rounded` design, `.secondary` foreground
- Pressed state: `scaleEffect(0.98)` with `.brandPress` animation
- Selection: `Color.accentPrimary` 3pt border, `.cream.opacity(0.8)` unselected indicator
- Condition badge: Brand color backgrounds (`.mutedSage`, `.softTeal`, `.peach`, `.salmon`) with `.deepPlum` text
- Status badge: Brand color backgrounds (`.peach` processing, `.mutedSage` complete, `.salmon` failed) with `.deepPlum` text

### 3.4 AbundanceCard Container (Completed)

**File:** `Sources/Core/DesignSystem/Components/AbundanceCard.swift`

Reusable card container and modifier matching brand bible Section 4.2:

```swift
public struct AbundanceCard<Content: View>: View {
    let cornerRadius: CGFloat
    @ViewBuilder let content: () -> Content
    @Environment(\.colorSchemeContrast) private var contrast

    public var body: some View {
        content()
            .background(
                Color.cream,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.peach, lineWidth: contrast == .increased ? 2 : 1)
            )
    }
}
```

Also provides a `View.abundanceCardStyle(cornerRadius:)` modifier for convenience:

```swift
view.abundanceCardStyle()            // Default 16pt radius
view.abundanceCardStyle(cornerRadius: 24)  // Custom radius
```

**Usage in codebase:** ItemDetailView metadata card, CollectionView selection toolbar, EditItemSheet saving overlay.

### 3.5 Toast/Snackbar Styles

Brand bible defines:
- Success: MutedSage capsule, DeepPlum text, checkmark icon
- Error: Salmon capsule, DeepPlum text, warning icon

These don't exist in the codebase yet. Create when toast functionality is needed.

---

## 4. Animation Alignment

### 4.1 Current State (Completed)

`Sources/Core/DesignSystem/Extensions/Animation+Brand.swift` has been updated to match the brand bible:

| Name | Response | Damping | Usage |
|------|----------|---------|-------|
| `brandPress` | 0.3 | 0.6 | Button taps, toggles, press effects |
| `brandDefault` | 0.5 | 0.6 | Screen transitions, card entrance, modal presentation |
| `brandReducedMotion` | 0.2s easeInOut | N/A | Fallback when `accessibilityReduceMotion` is enabled |

```swift
public extension Animation {
    static let brandPress = Animation.spring(response: 0.3, dampingFraction: 0.6)
    static let brandDefault = Animation.spring(response: 0.5, dampingFraction: 0.6)
    static let brandReducedMotion = Animation.easeInOut(duration: 0.2)
}
```

Old presets (`brandSnappy`, `brandBouncy`, `brandGentle`) have been removed.

---

## 5. Accessibility Implementation

### 5.1 Current State

- `reduceTransparency` is checked in: CaptureView (mode indicator, instruction label), CaptureOverlays, ErrorRecoveryView, LiquidGlassHelpers (AdaptiveGlassModifier)
- `reduceMotion` is checked in: CaptureView, CaptureOverlays, CollectionView, ItemCard, ItemDetailView, PrimaryButton, SecondaryButton
- `colorSchemeContrast` is checked in: ItemCard (border width), AbundanceCard/AbundanceCardModifier (border width)
- `dynamicTypeSize` is checked in: ItemCard (image height: 160px normal, 120px at xxxLarge)

### 5.2 Required Changes

**Every view that uses brand colors or animation must check:**

```swift
@Environment(\.accessibilityReduceTransparency) private var reduceTransparency
@Environment(\.accessibilityReduceMotion) private var reduceMotion
@Environment(\.colorSchemeContrast) private var contrast
```

**Increase Contrast rules (not yet implemented):**
- `Color.deepPlum` → `Color.ultraDarkPlum` when `contrast == .increased`
- Border widths: 1px → 2px when `contrast == .increased`
- `Color.salmon` → `Color.salmonHighContrast` when `contrast == .increased`

**Files requiring Increase Contrast support:**
- `PrimaryButton.swift` — darken salmon, use ultraDarkPlum text
- `ItemCard.swift` — 2px border, darker colors
- `ItemDetailView.swift` — darker text
- Any view using brand colors for interactive elements

---

## 6. Asset Catalog (Deferred)

The brand bible specifies 15+ color sets in an xcassets catalog with light/dark mode variants. This is deferred because:

1. The app currently uses an SPM package structure without an xcassets bundle
2. Color+Brand.swift with hex values works for MVP
3. Dark mode design is explicitly noted as "requires design validation"

**When to implement:** When dark mode support is prioritized. Track in a separate issue/spec.

---

## 7. LiquidGlassHelpers.swift Updates

### 7.1 Current State

The `AdaptiveGlassModifier` now correctly falls back to `Color.backgroundDefault` (which maps to `Color.warmWhite` at `#FAF6F0`) for Reduce Transparency.

The modifier provides three convenience methods:
- `adaptiveGlass(cornerRadius:tint:)` - Rounded rectangle shape
- `adaptiveGlass(in:tint:)` - Custom shape (e.g., Capsule)
- `adaptiveGlass(radius:tint:)` - Design token enum (`GlassCornerRadius`)

Additionally, iOS 26+ specific `brandGlass()` methods provide direct glass effect access without the fallback layer.

### 7.2 Usage Audit

`adaptiveGlass` is currently used in navigation-layer elements only:
- `SearchBar.swift` - Search capsule
- `FloatingTabBar.swift` - Tab bar background and tab items
- `PhotoCarouselView.swift` - Photo counter capsule
- `EditItemSheet.swift` - Primary photo label
- `RescanCameraView.swift` - Camera UI elements
- `AddPhotoCameraView.swift` - Camera UI elements
- `SweepCaptureView.swift` - Sweep UI controls
- `SweepModeToggle.swift` - Mode selector

Content-layer components (ItemCard, AbundanceCard, ItemDetailView) use opaque brand fills (`Color.cream` background, `Color.peach` borders) via `AbundanceCard`/`.abundanceCardStyle()`, not glass effects.

---

## 8. Testing Requirements

### 8.1 Visual Regression

For each restyled component, verify in Xcode Preview:
- [ ] Default state matches brand bible specification
- [ ] Pressed/focused state matches brand bible specification
- [ ] Reduce Transparency: glass → opaque fallback works
- [ ] Reduce Motion: spring → easeInOut fallback works
- [ ] Increase Contrast: colors darken, borders thicken
- [ ] Dynamic Type at AX3: layout doesn't break

### 8.2 Automated Tests

Add unit tests for Color+Brand.swift to verify hex values match brand bible:

```swift
func testSalmonColor() {
    let salmon = Color.salmon
    // Verify components match #E8907A
}
```

Add snapshot tests for PrimaryButton, SecondaryButton, and AbundanceCard in all accessibility states if snapshot testing is set up.

---

## 9. Implementation Status

| Step | Item | Status |
|------|------|--------|
| 1 | **Color+Brand.swift** — Brand palette | Completed |
| 2 | **Animation+Brand.swift** — Updated presets | Completed |
| 3 | **PrimaryButton.swift** — Opaque Salmon | Completed |
| 4 | **SecondaryButton.swift** — New component | Completed |
| 5 | **AbundanceCard.swift** — New container + modifier | Completed |
| 6 | **ItemCard.swift** — Opaque Cream/Peach | Completed |
| 7 | **Remaining views** — Color references | Completed |
| 8 | **Accessibility** — Increase Contrast support | Partial (ItemCard, AbundanceCard have contrast checks; not all views) |
| 9 | **LiquidGlassHelpers.swift** — Fallback colors | Completed |
