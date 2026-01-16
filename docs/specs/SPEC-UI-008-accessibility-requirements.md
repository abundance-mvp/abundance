# SPEC-UI-008: Accessibility Requirements

**Document ID:** SPEC-UI-008
**Date:** 2026-01-15
**Status:** DRAFT
**Related Documents:**
- Brand Bible: Part V (Implementation & Accessibility)
- SPEC-UI-001 through SPEC-UI-007 (All UI Specs)
- iOS 26 Liquid Glass Accessibility (axiom-liquid-glass)

---

## Executive Summary

This specification defines the **mandatory accessibility requirements** for Abundance, ensuring the app is fully usable with VoiceOver, Dynamic Type, Reduce Motion, and Reduce Transparency.

---

## 1. System Setting Support

### 1.1 Reduce Transparency

Per Brand Bible 5.1:

```swift
struct AccessibilityAwareView<Content: View>: View {
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    let content: Content

    var body: some View {
        if reduceTransparency {
            content
                .background(Color.abundance.background) // Solid color
        } else {
            content
                .background(.thickMaterial) // Glass effect
        }
    }
}
```

### 1.2 Reduce Motion

Per Brand Bible 5.1:

```swift
struct AnimatedSuccessView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var showSuccess = false

    var body: some View {
        if reduceMotion {
            // Simple cross-fade
            SuccessIcon()
                .opacity(showSuccess ? 1 : 0)
        } else {
            // Full animation
            SuccessIcon()
                .scaleEffect(showSuccess ? 1 : 0.5)
                .opacity(showSuccess ? 1 : 0)
        }
    }
}
```

### 1.3 Dynamic Type Support

```swift
// All text must scale
Text("Item Title")
    .font(.headline) // System font scales automatically

// Fixed frame sizes must adapt
@ScaledMetric var iconSize: CGFloat = 24

Image(systemName: "star")
    .frame(width: iconSize, height: iconSize)
```

---

## 2. VoiceOver Support

### 2.1 Item Card Accessibility

```swift
struct ItemCard: View {
    let item: InventoryItem

    var body: some View {
        cardContent
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint("Double tap to view details")
            .accessibilityAddTraits(.isButton)
    }

    private var accessibilityLabel: String {
        var label = item.title
        if let value = item.estimatedValue {
            label += ", valued at \(value.formatted(.currency(code: "USD")))"
        }
        label += ", category \(item.category.displayName)"
        return label
    }
}
```

### 2.2 Scanner Accessibility

```swift
struct ScannerView: View {
    @State private var scanStatus: ScanStatus = .idle

    var body: some View {
        cameraPreview
            .accessibilityLabel("Camera viewfinder")
            .accessibilityValue(scanStatusDescription)
            .accessibilityHint("Point camera at item to scan")
    }

    private var scanStatusDescription: String {
        switch scanStatus {
        case .idle: return "Ready to scan"
        case .scanning: return "Scanning in progress"
        case .success(let item): return "Found \(item.title)"
        case .error: return "Scan failed, try again"
        }
    }
}
```

### 2.3 Custom Actions

```swift
ItemCard(item: item)
    .accessibilityAction(named: "Edit") {
        editItem(item)
    }
    .accessibilityAction(named: "Share") {
        shareItem(item)
    }
    .accessibilityAction(named: "Delete") {
        deleteItem(item)
    }
```

---

## 3. Contrast Requirements

### 3.1 WCAG 2.2 Ratios

| Element Type | Minimum Ratio | Verification Method |
|--------------|---------------|---------------------|
| Body text | 4.5:1 | Accessibility Inspector |
| Large text (>= 18pt bold) | 3:1 | Accessibility Inspector |
| UI components | 3:1 | Accessibility Inspector |
| Focus indicators | 3:1 | Accessibility Inspector |

### 3.2 Color Testing Matrix

```swift
func testColorContrast() {
    let combinations = [
        (Color.abundance.blue, Color.white, "Primary on light"),
        (Color.abundance.blue, Color.black, "Primary on dark"),
        (Color.abundance.coral, Color.white, "Secondary on light"),
    ]

    for (foreground, background, description) in combinations {
        let ratio = calculateContrastRatio(foreground, background)
        XCTAssertGreaterThanOrEqual(ratio, 4.5, "\(description) failed contrast check")
    }
}
```

---

## 4. Focus Management

### 4.1 Keyboard Navigation

```swift
struct CatalogView: View {
    @FocusState private var focusedItem: InventoryItem.ID?

    var body: some View {
        LazyVGrid(columns: columns) {
            ForEach(items) { item in
                ItemCard(item: item)
                    .focused($focusedItem, equals: item.id)
                    .onKeyPress(.return) {
                        selectItem(item)
                        return .handled
                    }
            }
        }
    }
}
```

### 4.2 Focus Indicators

```swift
struct FocusableCard: View {
    @FocusState private var isFocused: Bool

    var body: some View {
        cardContent
            .overlay(
                RoundedRectangle(cornerRadius: AbundanceRadius.large)
                    .stroke(
                        isFocused ? Color.abundance.blue : .clear,
                        lineWidth: 3
                    )
            )
            .focused($isFocused)
    }
}
```

---

## 5. Testing Requirements

### 5.1 Automated Tests

```swift
final class AccessibilityTests: XCTestCase {
    let app = XCUIApplication()

    func testVoiceOverLabels() {
        app.launch()

        // Verify all main elements have accessibility labels
        XCTAssertFalse(app.buttons.matching(
            NSPredicate(format: "label == ''")
        ).count > 0, "Found buttons without accessibility labels")
    }

    func testReducedMotion() {
        app.launchArguments += ["-UIAccessibilityIsReduceMotionEnabled", "1"]
        app.launch()

        // Verify animations are simplified
        // (Manual verification required)
    }

    func testReducedTransparency() {
        app.launchArguments += ["-UIAccessibilityIsReduceTransparencyEnabled", "1"]
        app.launch()

        // Verify glass effects replaced with solid backgrounds
        // (Manual verification required)
    }

    func testDynamicType() {
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge"]
        app.launch()

        // Verify layout doesn't break at largest type size
        XCTAssertTrue(app.staticTexts["Item Title"].exists)
    }
}
```

### 5.2 Manual Testing Checklist

- [ ] VoiceOver: Navigate entire app without sight
- [ ] VoiceOver: Complete scan flow with eyes closed
- [ ] Switch Control: Navigate and interact with all elements
- [ ] Reduce Motion: Verify no vestibular-triggering animations
- [ ] Reduce Transparency: Verify all text legible
- [ ] Dynamic Type (XXL): Verify layout integrity
- [ ] Dynamic Type (Accessibility sizes): Verify all text visible
- [ ] Color Blind: Test with simulator filters

---

## 6. Acceptance Criteria

- [ ] All interactive elements have accessibility labels
- [ ] All images have accessibility descriptions
- [ ] Reduce Transparency replaces glass with solid colors
- [ ] Reduce Motion replaces animations with cross-fades
- [ ] All text scales with Dynamic Type
- [ ] WCAG 2.2 4.5:1 contrast for body text
- [ ] VoiceOver can navigate entire app
- [ ] Focus indicators visible for keyboard navigation

---

## 7. Accessibility Audit Schedule

| Audit Type | Frequency | Owner |
|------------|-----------|-------|
| Automated tests | Every PR | CI/CD |
| VoiceOver testing | Weekly | QA |
| Contrast audit | Monthly | Design |
| Full accessibility review | Before release | External auditor |
