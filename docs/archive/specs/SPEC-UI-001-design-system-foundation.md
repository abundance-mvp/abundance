# SPEC-UI-001: Abundance Design System Foundation

**Document ID:** SPEC-UI-001
**Date:** 2026-01-15
**Status:** DRAFT
**Related Documents:**
- Brand Bible: Parts I & II (Strategic Foundation, Design System)
- ADR-010 (SwiftUI-Only Architecture)
- DESIGN-002 (iOS Client Architecture)

---

## Executive Summary

This specification defines the **foundational design tokens** for the Abundance iOS app, translating the retro-futuristic vaporwave brand identity into iOS 26 Liquid Glass patterns. All values are verified against iOS 26 SwiftUI APIs.

---

## 1. Color Palette

### 1.1 Brand Colors (Verified Against iOS 26)

| Token | Hex | SwiftUI Definition | Usage |
|-------|-----|-------------------|-------|
| `brandBlue` | #4381DF | `Color(hex: "4381DF")` | Primary accent, internal glows, active states |
| `brandCoral` | #FF9A6F | `Color(hex: "FF9A6F")` | Secondary accent, category lighting |
| `brandSalmon` | #FF8A80 | `Color(hex: "FF8A80")` | Tertiary accent, highlights |
| `brandCream` | #FFF8E1 | `Color(hex: "FFF8E1")` | Warm backgrounds, text on dark |
| `brandMint` | #A5D6A7 | `Color(hex: "A5D6A7")` | Success states, positive feedback |

### 1.2 SwiftUI Implementation

```swift
import SwiftUI

extension Color {
    static let abundance = AbundanceColors()

    struct AbundanceColors {
        let blue = Color(hex: "4381DF")
        let coral = Color(hex: "FF9A6F")
        let salmon = Color(hex: "FF8A80")
        let cream = Color(hex: "FFF8E1")
        let mint = Color(hex: "A5D6A7")
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255.0,
            green: Double((rgb >> 8) & 0xFF) / 255.0,
            blue: Double(rgb & 0xFF) / 255.0
        )
    }
}
```

### 1.3 Vibrancy Integration

Per Brand Bible Section 1.2 and iOS 26 Liquid Glass skill:

```swift
// Primary vibrancy - saturated colors for primary actions
Text("Primary Action")
    .foregroundStyle(.primary)
    .tint(.abundance.blue)

// Secondary vibrancy - muted for supplementary info
Text("Supporting text")
    .foregroundStyle(.secondary)
```

---

## 2. Shape System (Concentric Geometry)

### 2.1 Shape Types (Per Brand Bible 2.1 & iOS 26 API)

| Shape | Usage | SwiftUI API |
|-------|-------|-------------|
| Capsule | Primary buttons, sliders, toggles | `Capsule()` |
| Concentric | Item cards, category cards, sheets | `.containerRelativeShape()` |
| Fixed Radius | Specific non-adaptive elements | `RoundedRectangle(cornerRadius: X)` |

### 2.2 Corner Radius Tokens

```swift
enum AbundanceRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 20
    static let extraLarge: CGFloat = 28
}
```

### 2.3 Concentric Shape Implementation

Per iOS 26 `containerRelativeShape()` API:

```swift
// Outer container
RoundedRectangle(cornerRadius: AbundanceRadius.large)
    .fill(.thickMaterial)
    .overlay {
        // Inner element uses relative shape
        Button("Action") { }
            .containerRelativeShape(.roundedRectangle)
            .glassEffect()
    }
```

---

## 3. Typography Scale

### 3.1 Font Tokens (Per Brand Bible 2.3 & iOS 26 HIG)

| Token | Style | Usage |
|-------|-------|-------|
| `headline` | .headline.bold() | Section titles, navigation |
| `title` | .title2.bold() | Screen titles |
| `body` | .body | Primary content |
| `caption` | .caption | Metadata, timestamps |

### 3.2 Contrast Requirements (WCAG 2.2)

- **Body text**: Minimum 4.5:1 contrast ratio
- **Large text**: Minimum 3:1 contrast ratio
- **UI components**: Minimum 3:1 contrast ratio

---

## 4. Spacing System

```swift
enum AbundanceSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}
```

---

## 5. Acceptance Criteria

- [ ] All brand colors defined in `Sources/Core/Theme/AbundanceColors.swift`
- [ ] Shape tokens defined in `Sources/Core/Theme/AbundanceShapes.swift`
- [ ] Typography tokens defined in `Sources/Core/Theme/AbundanceTypography.swift`
- [ ] Spacing tokens defined in `Sources/Core/Theme/AbundanceSpacing.swift`
- [ ] All tokens compile with iOS 26 SDK (Xcode 26+)
- [ ] WCAG 2.2 contrast ratios verified via Accessibility Inspector

---

## 6. Test Plan

```swift
func testBrandColorsAccessibility() {
    // Verify contrast ratios
    let blueOnWhite = calculateContrastRatio(.abundance.blue, .white)
    XCTAssertGreaterThanOrEqual(blueOnWhite, 4.5)
}
```
