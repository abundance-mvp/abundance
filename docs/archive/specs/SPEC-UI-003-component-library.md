# SPEC-UI-003: Abundance Component Library

**Document ID:** SPEC-UI-003
**Date:** 2026-01-15
**Status:** DRAFT
**Related Documents:**
- Brand Bible: Sections 2.1-2.3 (Shape, Iconography, Typography)
- SPEC-UI-001 (Design System Foundation)
- SPEC-UI-002 (Material & Vibrancy Matrix)

---

## Executive Summary

This specification defines the **reusable UI components** for Abundance, including buttons, cards, icons, and form elements, all designed for iOS 26 Liquid Glass.

---

## 1. Button Components

### 1.1 Primary Action Button

**Usage:** Main CTAs like "Start Scanning", "Save Item"

```swift
struct AbundancePrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AbundanceSpacing.xs) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.headline.bold())
            .foregroundStyle(.primary)
            .padding(.horizontal, AbundanceSpacing.lg)
            .padding(.vertical, AbundanceSpacing.md)
        }
        .buttonStyle(.borderedProminent)
        .tint(.abundance.blue)
        .glassEffect(in: Capsule())
        .buttonSizing(.flexible)
    }
}
```

### 1.2 Secondary Action Button

**Usage:** Secondary actions, cancel, back

```swift
struct AbundanceSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, AbundanceSpacing.md)
                .padding(.vertical, AbundanceSpacing.sm)
        }
        .glassEffect(in: Capsule())
    }
}
```

### 1.3 Icon Button

**Usage:** Toolbar actions, navigation

```swift
struct AbundanceIconButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title2)
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
        }
        .glassEffect(in: Circle())
    }
}
```

---

## 2. Card Components

### 2.1 Item Card

**Usage:** Display inventory items in catalog grid/list

```swift
struct ItemCard: View {
    let item: InventoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: AbundanceSpacing.sm) {
            // Product image
            AsyncImage(url: item.thumbnailURL) { image in
                image
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(.quaternary)
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: AbundanceRadius.medium))

            // Title
            Text(item.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)

            // Price (if available)
            if let price = item.estimatedValue {
                Text(price, format: .currency(code: "USD"))
                    .font(.subheadline.bold())
                    .foregroundStyle(.abundance.blue)
            }

            // Category
            Text(item.category.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
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
```

### 2.2 Category Card

**Usage:** Home screen category navigation with internal glow effect

```swift
struct CategoryCard: View {
    let category: ItemCategory
    let accentColor: Color

    var body: some View {
        VStack(spacing: AbundanceSpacing.sm) {
            // 3D icon placeholder (future: Model3D)
            Image(systemName: category.systemImage)
                .font(.system(size: 40))
                .foregroundStyle(accentColor)
                .frame(height: 80)

            Text(category.displayName)
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(AbundanceSpacing.lg)
        .background(
            .thickMaterial,
            in: RoundedRectangle(cornerRadius: AbundanceRadius.large)
        )
        // Internal glow effect (Brand Bible: accent lighting)
        .overlay(
            RoundedRectangle(cornerRadius: AbundanceRadius.large)
                .stroke(
                    LinearGradient(
                        colors: [accentColor.opacity(0.5), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2
                )
        )
    }
}
```

---

## 3. Navigation Icons

### 3.1 Tab Bar Icons (Per Brand Bible 2.2)

| Tab | System Image | Active Tint |
|-----|--------------|-------------|
| Scan | `viewfinder` | `.abundance.blue` |
| Catalog | `square.grid.2x2` | `.abundance.blue` |
| Share | `square.and.arrow.up` | `.abundance.coral` |
| Trade | `arrow.triangle.2.circlepath` | `.abundance.mint` |
| Profile | `person.circle` | `.abundance.salmon` |

### 3.2 Implementation

```swift
enum AbundanceTab: String, CaseIterable {
    case scan, catalog, share, trade, profile

    var title: String {
        rawValue.capitalized
    }

    var systemImage: String {
        switch self {
        case .scan: "viewfinder"
        case .catalog: "square.grid.2x2"
        case .share: "square.and.arrow.up"
        case .trade: "arrow.triangle.2.circlepath"
        case .profile: "person.circle"
        }
    }

    var tint: Color {
        switch self {
        case .scan, .catalog: .abundance.blue
        case .share: .abundance.coral
        case .trade: .abundance.mint
        case .profile: .abundance.salmon
        }
    }
}
```

---

## 4. Form Components

### 4.1 Search Bar

```swift
struct AbundanceSearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: AbundanceSpacing.xs) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search items...", text: $text)
                .focused($isFocused)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, AbundanceSpacing.md)
        .padding(.vertical, AbundanceSpacing.sm)
        .background(
            .thinMaterial,
            in: Capsule()
        )
        .overlay(
            Capsule()
                .stroke(
                    isFocused ? Color.abundance.blue : .clear,
                    lineWidth: 2
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
```

---

## 5. Feedback Components

### 5.1 Success Animation

**Usage:** Item scanned successfully (Brand Bible 3.3)

```swift
struct ScanSuccessAnimation: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Confetti particles (glass-like)
            ForEach(0..<20, id: \.self) { i in
                Circle()
                    .fill(.abundance.blue.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .offset(
                        x: isAnimating ? CGFloat.random(in: -100...100) : 0,
                        y: isAnimating ? CGFloat.random(in: -150...0) : 0
                    )
                    .opacity(isAnimating ? 0 : 1)
            }

            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.abundance.mint)
                .scaleEffect(isAnimating ? 1.2 : 0.8)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                isAnimating = true
            }
        }
    }
}
```

### 5.2 Error State

**Usage:** Scanning error (Brand Bible 3.3)

```swift
struct ScanErrorView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: AbundanceSpacing.md) {
            // Pulsating question mark
            Image(systemName: "questionmark.circle")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
                .symbolEffect(.pulse)

            Text(message)
                .font(.headline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            AbundancePrimaryButton(title: "Try Again", icon: "arrow.clockwise") {
                retryAction()
            }
        }
        .padding(AbundanceSpacing.xl)
    }
}
```

---

## 6. Acceptance Criteria

- [ ] All components defined in `Sources/Core/Components/`
- [ ] Components use design tokens from SPEC-UI-001
- [ ] Components apply materials from SPEC-UI-002
- [ ] All interactive components have proper accessibility labels
- [ ] All components support Dynamic Type
- [ ] All components support Reduce Motion

---

## 7. Test Plan

```swift
final class ComponentLibraryTests: XCTestCase {
    func testPrimaryButtonAccessibility() {
        let button = AbundancePrimaryButton(title: "Test", icon: nil) { }
        XCTAssertTrue(button.accessibilityLabel == "Test")
    }

    func testItemCardDynamicType() {
        // Verify text scales with accessibility sizes
    }
}
```
