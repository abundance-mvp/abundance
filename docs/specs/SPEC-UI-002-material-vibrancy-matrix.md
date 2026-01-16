# SPEC-UI-002: Material & Vibrancy Matrix

**Document ID:** SPEC-UI-002
**Date:** 2026-01-15
**Status:** DRAFT
**Related Documents:**
- Brand Bible: Section 2.4 (Material & Vibrancy Matrix)
- SPEC-UI-001 (Design System Foundation)
- iOS 26 Liquid Glass Skill (axiom-liquid-glass)

---

## Executive Summary

This specification defines the **Material thickness** and **Vibrancy levels** for all UI components, ensuring consistent Liquid Glass application across the Abundance app.

---

## 1. Material Thickness Mapping

### 1.1 Material to Component Matrix

| UI Component | State | Material | SwiftUI API |
|--------------|-------|----------|-------------|
| Tab Bar | Active | `.regularMaterial` | `.background(.regularMaterial)` |
| Navigation Bar | Active | `.regularMaterial` | `.toolbarBackground(.regularMaterial)` |
| Primary Button | Default | `.regularMaterial` | `.glassEffect()` |
| Primary Button | Pressed | `.thickMaterial` | `.glassEffect()` + scale animation |
| Primary Button | Disabled | `.ultraThickMaterial` | `.glassEffect()` + `.opacity(0.5)` |
| Item Card | Default | `.thickMaterial` | `.background(.thickMaterial, in: shape)` |
| Category Card | Default | `.thickMaterial` | `.background(.thickMaterial, in: shape)` |
| Modal Sheet | Active | `.ultraThickMaterial` | `.presentationBackground(.ultraThickMaterial)` |
| Search Bar | Active | `.thinMaterial` | `.background(.thinMaterial, in: Capsule())` |
| Pop-out Menu | Active | `.thinMaterial` | Context menu default |

### 1.2 Implementation Pattern

```swift
struct AbundanceMaterials {
    // Transient elements (menus, overlays)
    static let transient: Material = .thinMaterial

    // Persistent surfaces (bars, navigation)
    static let persistent: Material = .regularMaterial

    // Primary surfaces (cards, content containers)
    static let primary: Material = .thickMaterial

    // Focus surfaces (modals, alerts)
    static let focus: Material = .ultraThickMaterial
}
```

---

## 2. Vibrancy Mapping

### 2.1 Vibrancy to Content Matrix

| Content Type | Vibrancy Level | SwiftUI API |
|--------------|----------------|-------------|
| Primary text | `.primary` | `.foregroundStyle(.primary)` |
| Interactive icons | `.primary` | `.foregroundStyle(.primary)` |
| Secondary text | `.secondary` | `.foregroundStyle(.secondary)` |
| Captions, metadata | `.secondary` | `.foregroundStyle(.secondary)` |
| Disabled elements | `.tertiary` | `.foregroundStyle(.tertiary)` |
| Dividers | `.separator` | `Divider()` (automatic) |

### 2.2 Brand Color Tinting

Per Brand Bible: Use brand colors as light sources, not flat fills.

```swift
// CORRECT: Tinted glass button (brand as light)
Button("Start Scanning") { }
    .buttonStyle(.borderedProminent)
    .tint(.abundance.blue)
    .glassEffect()

// WRONG: Solid fill (breaks Liquid Glass)
Button("Start Scanning") { }
    .background(.abundance.blue) // Opaque, breaks glass character
```

---

## 3. Component State Matrix

### 3.1 Primary Button States

```swift
struct AbundancePrimaryButton: View {
    let title: String
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .buttonStyle(.borderedProminent)
        .tint(.abundance.blue)
        .glassEffect(in: Capsule())
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.2), value: isPressed)
    }
}
```

### 3.2 Item Card States

```swift
struct ItemCardMaterial: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AbundanceSpacing.md)
            .background(
                .thickMaterial,
                in: RoundedRectangle(cornerRadius: AbundanceRadius.large)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AbundanceRadius.large)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

extension View {
    func itemCardStyle() -> some View {
        modifier(ItemCardMaterial())
    }
}
```

---

## 4. Scroll Edge Effects

Per Brand Bible 3.4 and iOS 26 APIs:

```swift
ScrollView {
    LazyVStack(spacing: AbundanceSpacing.sm) {
        ForEach(items) { item in
            ItemCard(item: item)
        }
    }
    .safeAreaPadding(.horizontal, AbundanceSpacing.md)
}
.scrollEdgeEffectStyle(.soft, for: .top)
.scrollEdgeEffectStyle(.soft, for: .bottom)
```

---

## 5. Acceptance Criteria

- [ ] Material mappings defined in `Sources/Core/Theme/AbundanceMaterials.swift`
- [ ] Vibrancy patterns documented with code examples
- [ ] All components use `.glassEffect()` for navigation layer only (not content)
- [ ] No glass-on-glass stacking (verified via design review)
- [ ] Scroll edge effects applied to all scrollable content
- [ ] Brand colors used as tints, not solid fills

---

## 6. Test Plan

```swift
func testMaterialAccessibility() {
    // Verify Reduce Transparency support
    let app = XCUIApplication()
    app.launchArguments += ["-UIAccessibilityIsReduceTransparencyEnabled", "1"]
    app.launch()

    // Verify all glass elements still visible and functional
    XCTAssertTrue(app.buttons["Start Scanning"].isHittable)
}
```
