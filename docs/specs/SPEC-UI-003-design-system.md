# SPEC-UI-003: Design System Implementation

**Status:** Draft
**Created:** 2026-02-06
**References:** Brand Bible v3.0, SPEC-UI-001, SPEC-UI-002
**Code Refs:** Sources/Core/DesignSystem/, Sources/InventoryFeature/,
              Sources/CameraFeature/, Sources/ProfileFeature/, App/

---

## 1. Overview

This spec defines the concrete codebase changes required to align the Abundance iOS app with the Brand Bible v3.0 design system. Each section maps a brand bible rule to specific file changes.

**Scope:** Color palette migration, component restyling, accessibility fallbacks, asset catalog creation. Does NOT cover Liquid Glass navigation adoption (see SPEC-UI-004).

---

## 2. Color Palette Migration

### 2.1 Current State

`Sources/Core/DesignSystem/Extensions/Color+Brand.swift` defines colors from a prior design iteration that do not match the brand bible:

| Current Name | Current Hex | Brand Bible Name | Brand Bible Hex |
|-------------|-------------|-----------------|----------------|
| `brandBrightBlue` | `#4381DF` | *(no equivalent — remove)* | — |
| `brandCoralOrange` | `#FF9A6F` | *(no equivalent — remove)* | — |
| `brandSalmonPink` | `#FFC4B4` | *(similar but wrong)* | Salmon `#E8907A` |
| `brandCreamYellow` | `#FFEDB9` | *(no equivalent — remove)* | — |
| `brandMintGreen` | `#B3FFE1` | MutedSage `#9DC4A8` | different |
| `textBrightBlue` | `#2D5FA3` | *(remove)* | — |
| `textCoralOrange` | `#CC5D3A` | *(remove)* | — |
| `textMintGreen` | `#008057` | *(remove)* | — |
| `textPrimary` | `#3B2E3A` | DeepPlum `#3B2E3A` | **Match** |
| `backgroundDefault` | `#FCFCFF` | WarmWhite `#FAF6F0` | close but wrong |

### 2.2 Target State

Replace `Color+Brand.swift` with brand bible-compliant colors:

```swift
// Sources/Core/DesignSystem/Extensions/Color+Brand.swift

import SwiftUI

public extension Color {
    // MARK: - Hex Initializer
    init(hex: String) {
        // [keep existing hex initializer unchanged]
    }

    // MARK: - Primary Brand Colors
    static let salmon = Color(hex: "E8907A")
    static let peach = Color(hex: "EDBE9E")
    static let cream = Color(hex: "F0DCC0")
    static let softTeal = Color(hex: "8ECAC0")
    static let mutedSage = Color(hex: "9DC4A8")

    // MARK: - Text Colors
    static let deepPlum = Color(hex: "3B2E3A")
    static let darkPlum = Color(hex: "2D2226")
    static let ultraDarkPlum = Color(hex: "1A1218")

    // MARK: - Background Colors
    static let backgroundTeal = Color(hex: "5BB8C9")
    static let warmWhite = Color(hex: "FAF6F0")

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

### 2.3 Migration Checklist

Every file using the old color names must be updated:

| File | Old Reference | New Reference |
|------|--------------|---------------|
| `Sources/Core/DesignSystem/Components/PrimaryButton.swift` | `brandBrightBlue` (glow, stroke) | Remove glow; use `.salmon` fill |
| `Sources/InventoryFeature/ItemCard.swift` | `.adaptiveGlass()` background | `.cream` opaque fill, `.peach` stroke |
| `Sources/InventoryFeature/SearchBar.swift` | Check for blue references | `.salmon` cursor, glass search styling |
| `Sources/InventoryFeature/EmptyStateCard.swift` | Check color usage | `.salmon` CTA, `.deepPlum` text |
| `Sources/InventoryFeature/ItemDetailView.swift` | Check color usage | `.deepPlum` text, `.cream` metadata bg |
| `Sources/CameraFeature/Views/DetectionResultsView.swift` | `.blue` on catalog button | `.salmon` accent |
| `Sources/CameraFeature/Views/CaptureOverlays.swift` | `.white` text | Keep (camera is dark context) |
| `Sources/ProfileFeature/ProfileView.swift` | Check color usage | `.deepPlum` text, `.warmWhite` bg |
| `Sources/ProfileFeature/Components/UserInfoCard.swift` | Check color usage | `.cream` card, `.peach` border |
| `App/DebugMainTabView.swift` | Check tab styling | `.salmon` tint |

**Rule:** Search codebase for all instances of: `brandBrightBlue`, `brandCoralOrange`, `brandSalmonPink`, `brandCreamYellow`, `brandMintGreen`, `textBrightBlue`, `textCoralOrange`, `textMintGreen`, `accentPrimary`, `accentSecondary`, `successColor`, `warningColor`, `errorColor`, `backgroundDefault`, `successGlow`, `textLink`. Each must be remapped to the new palette.

---

## 3. Component Restyling

### 3.1 PrimaryButton

**File:** `Sources/Core/DesignSystem/Components/PrimaryButton.swift`

**Current:** Glass capsule with blue glow and blue stroke
**Target:** Opaque Salmon capsule, DeepPlum text, no glow, press scale 0.97

```swift
public var body: some View {
    Button(action: handleTap) {
        ZStack {
            Text(title)
                .font(.headline)
                .foregroundColor(Color.deepPlum)
                .opacity(isLoading ? 0 : 1)

            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color.deepPlum)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
    .background(
        Color.salmon.opacity(isEnabled ? 1.0 : 0.4),
        in: Capsule()
    )
    .foregroundColor(
        Color.deepPlum.opacity(isEnabled ? 1.0 : 0.5)
    )
    .scaleEffect(isPressed ? 0.97 : 1.0)
    .animation(
        reduceMotion
            ? .easeInOut(duration: 0.1)
            : .spring(response: 0.3, dampingFraction: 0.6),
        value: isPressed
    )
    .disabled(!isEnabled || isLoading)
    .sensoryFeedback(.impact(weight: .medium), trigger: isPressed)
    .accessibilityLabel(title)
    .accessibilityAddTraits(.isButton)
}
```

**Key changes:**
- Remove `.adaptiveGlass(in: Capsule())` — buttons are content layer (opaque)
- Remove `.shadow(color: .brandBrightBlue...)` — no glow in brand bible
- Remove `.overlay { Capsule().stroke(.brandBrightBlue...) }` — no blue stroke
- Add `Color.salmon` background in Capsule
- Add `Color.deepPlum` foreground
- Add `@Environment(\.accessibilityReduceMotion)` check
- Scale: 0.97 (not 0.96)

### 3.2 SecondaryButton (NEW)

**File:** Create `Sources/Core/DesignSystem/Components/SecondaryButton.swift`

Brand bible defines a secondary button: Salmon stroke outline, clear fill, Salmon text.

```swift
public struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false

    public init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color.salmon)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .background(
            isPressed ? Color.salmon.opacity(0.15) : Color.clear,
            in: Capsule()
        )
        .overlay(Capsule().stroke(Color.salmon, lineWidth: 1))
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(
            reduceMotion
                ? .easeInOut(duration: 0.1)
                : .spring(response: 0.3, dampingFraction: 0.6),
            value: isPressed
        )
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}
```

### 3.3 ItemCard Restyling

**File:** `Sources/InventoryFeature/ItemCard.swift`

**Current:** Uses `.adaptiveGlass()` (glass material background)
**Target:** Opaque Cream background, Peach 1px border, DeepPlum text

The card must follow the Content Layer rules:
- Background: `Color.cream` in `RoundedRectangle(cornerRadius: 16, style: .continuous)`
- Border: `Color.peach` 1px stroke
- Title: `.headline` weight, `Color.deepPlum`
- Description: `.subheadline`, `Color.deepPlum.opacity(0.6)`
- Price: `.headline`, `Color.salmon`
- Pressed state: Background becomes `Color.peach`, `scaleEffect(0.98)`

### 3.4 AbundanceCard Container (NEW)

**File:** Create `Sources/Core/DesignSystem/Components/AbundanceCard.swift`

Reusable card container matching brand bible Section 4.2:

```swift
public struct AbundanceCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 16

    @Environment(\.colorSchemeContrast) private var contrast

    public init(
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: some View {
        content
            .padding(12)
            .background(
                Color.cream,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        Color.peach,
                        lineWidth: contrast == .increased ? 2 : 1
                    )
            )
    }
}
```

### 3.5 Toast/Snackbar Styles

Brand bible defines:
- Success: MutedSage capsule, DeepPlum text, checkmark icon
- Error: Salmon capsule, DeepPlum text, warning icon

These don't exist in the codebase yet. Create when toast functionality is needed.

---

## 4. Animation Alignment

### 4.1 Current State

`Sources/Core/DesignSystem/Extensions/Animation+Brand.swift` defines:

| Current | Response | Damping | Brand Bible Equivalent |
|---------|----------|---------|----------------------|
| `brandSnappy` | 0.3 | 0.6 | Button press (matches) |
| `brandDefault` | 0.4 | 0.7 | *(no equivalent)* |
| `brandBouncy` | 0.5 | 0.5 | *(close to success: 0.5/0.6)* |
| `brandGentle` | 0.6 | 0.8 | *(no equivalent)* |

### 4.2 Target State

```swift
public extension Animation {
    /// Default brand animation (most transitions)
    /// Brand Bible: .spring(response: 0.5, dampingFraction: 0.6)
    static let brandDefault = Animation.spring(response: 0.5, dampingFraction: 0.6)

    /// Button press animation
    /// Brand Bible: .spring(response: 0.3, dampingFraction: 0.6)
    static let brandPress = Animation.spring(response: 0.3, dampingFraction: 0.6)

    /// Reduce Motion fallback
    /// Brand Bible: .easeInOut(duration: 0.2)
    static let brandReducedMotion = Animation.easeInOut(duration: 0.2)
}
```

**Changes:** Rename `brandSnappy` to `brandPress`, update `brandDefault` to match brand bible values (0.5/0.6 instead of 0.4/0.7), remove `brandBouncy` and `brandGentle` (YAGNI — not specified in brand bible).

---

## 5. Accessibility Implementation

### 5.1 Current State

- `reduceTransparency` is checked in: DetectionResultsView, CaptureOverlays, LiquidGlassHelpers (AdaptiveGlassModifier)
- `reduceMotion` is checked in: CaptureOverlays (AnalyzingOverlay)
- `colorSchemeContrast` is NOT checked anywhere
- `dynamicTypeSize` is NOT checked for layout reflow

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

### 7.1 Changes

The `AdaptiveGlassModifier` currently falls back to `Color.backgroundDefault` (wrong hex `#FCFCFF`) for Reduce Transparency. After the color migration in Section 2, `backgroundDefault` will map to `Color.warmWhite` (`#FAF6F0`), fixing this automatically.

For navigation glass Reduce Transparency fallback: use `Color.cream` (brand bible Section 2.5).

### 7.2 Cleanup

After content-layer elements are migrated to opaque fills, `AdaptiveGlassModifier` is only needed for navigation-layer elements. Content components should NOT use `.adaptiveGlass()` — they should use `AbundanceCard` or direct opaque fills.

Remove any `.adaptiveGlass()` calls on content-layer views (cards, buttons, text fields) during the component migration.

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

## 9. Implementation Order

1. **Color+Brand.swift** — Replace palette (everything depends on this)
2. **Animation+Brand.swift** — Update presets
3. **PrimaryButton.swift** — Restyle to opaque Salmon
4. **Create SecondaryButton.swift** — New component
5. **Create AbundanceCard.swift** — New container
6. **ItemCard.swift** — Migrate from glass to opaque Cream/Peach
7. **Remaining views** — Update color references across all features
8. **Accessibility** — Add Increase Contrast support
9. **LiquidGlassHelpers.swift** — Clean up, update fallback colors
