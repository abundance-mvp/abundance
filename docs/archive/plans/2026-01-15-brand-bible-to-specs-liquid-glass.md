# Abundance Brand Bible to Specs: Liquid Glass Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Translate the Abundance Brand Bible (iOS 26 Liquid Glass design system) into actionable specification documents that guide implementation of the app's visual identity and UX patterns.

**Architecture:** Create a layered specification system: Design System Spec (atomic components) → Feature UI Specs (screen-level) → Integration Specs (cross-feature patterns). Each spec contains SwiftUI code, acceptance criteria, and accessibility requirements verified against iOS 26 APIs.

**Tech Stack:** SwiftUI 26, Liquid Glass APIs (`.glassEffect()`, `.glassBackgroundEffect()`), Vision Framework, Core ML, Foundation Models, Swift 6.0 strict concurrency

---

## Overview

This plan creates **8 specification documents** from the Brand Bible:

| Spec | Purpose | Brand Bible Section |
|------|---------|---------------------|
| SPEC-UI-001 | Design System Foundation | Parts I & II |
| SPEC-UI-002 | Material & Vibrancy Matrix | Section 2.4 |
| SPEC-UI-003 | Component Library | Section 2.1-2.3 |
| SPEC-UI-004 | Navigation & Layout | Section 3.2 |
| SPEC-UI-005 | Scanner Experience | Section 3.3 |
| SPEC-UI-006 | Catalog & Cards | Section 3.4 |
| SPEC-UI-007 | On-Device ML Integration | Part IV |
| SPEC-UI-008 | Accessibility Requirements | Part V |

---

## Task 1: Design System Foundation Spec

**Files:**
- Create: `docs/specs/SPEC-UI-001-design-system-foundation.md`

**Step 1: Write the spec document**

```markdown
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
```

**Step 2: Verify spec file created**

Run: `ls -la docs/specs/SPEC-UI-001-design-system-foundation.md`
Expected: File exists with correct content

**Step 3: Commit**

```bash
git add docs/specs/SPEC-UI-001-design-system-foundation.md
git commit -m "docs: add SPEC-UI-001 design system foundation from Brand Bible"
```

---

## Task 2: Material & Vibrancy Matrix Spec

**Files:**
- Create: `docs/specs/SPEC-UI-002-material-vibrancy-matrix.md`

**Step 1: Write the spec document**

```markdown
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
// ✅ CORRECT: Tinted glass button (brand as light)
Button("Start Scanning") { }
    .buttonStyle(.borderedProminent)
    .tint(.abundance.blue)
    .glassEffect()

// ❌ WRONG: Solid fill (breaks Liquid Glass)
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
```

**Step 2: Verify and commit**

```bash
git add docs/specs/SPEC-UI-002-material-vibrancy-matrix.md
git commit -m "docs: add SPEC-UI-002 material vibrancy matrix from Brand Bible"
```

---

## Task 3: Component Library Spec

**Files:**
- Create: `docs/specs/SPEC-UI-003-component-library.md`

**Step 1: Write the spec document**

```markdown
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
```

**Step 2: Commit**

```bash
git add docs/specs/SPEC-UI-003-component-library.md
git commit -m "docs: add SPEC-UI-003 component library from Brand Bible"
```

---

## Task 4: Navigation & Layout Spec

**Files:**
- Create: `docs/specs/SPEC-UI-004-navigation-layout.md`

**Step 1: Write the spec document**

```markdown
# SPEC-UI-004: Navigation & Layout

**Document ID:** SPEC-UI-004
**Date:** 2026-01-15
**Status:** DRAFT
**Related Documents:**
- Brand Bible: Section 3.2 (Navigating the Abundance Space)
- SPEC-UI-002 (Material & Vibrancy Matrix)
- iOS 26 SwiftUI Layout Reference (axiom-swiftui-layout-ref)

---

## Executive Summary

This specification defines **navigation patterns** and **layout structures** for Abundance, leveraging iOS 26 floating tab bars, contextual menus, and fluid search.

---

## 1. Tab Bar Navigation

### 1.1 Structure

Per Brand Bible 3.2 and iOS 26 patterns:

```swift
struct AbundanceTabView: View {
    @State private var selectedTab: AbundanceTab = .catalog

    var body: some View {
        TabView(selection: $selectedTab) {
            ScannerView()
                .tabItem {
                    Label(AbundanceTab.scan.title, systemImage: AbundanceTab.scan.systemImage)
                }
                .tag(AbundanceTab.scan)

            CatalogView()
                .tabItem {
                    Label(AbundanceTab.catalog.title, systemImage: AbundanceTab.catalog.systemImage)
                }
                .tag(AbundanceTab.catalog)

            ShareView()
                .tabItem {
                    Label(AbundanceTab.share.title, systemImage: AbundanceTab.share.systemImage)
                }
                .tag(AbundanceTab.share)

            TradeView()
                .tabItem {
                    Label(AbundanceTab.trade.title, systemImage: AbundanceTab.trade.systemImage)
                }
                .tag(AbundanceTab.trade)

            ProfileView()
                .tabItem {
                    Label(AbundanceTab.profile.title, systemImage: AbundanceTab.profile.systemImage)
                }
                .tag(AbundanceTab.profile)
        }
        .tint(.abundance.blue)
    }
}
```

### 1.2 Tab Bar Minimization (iOS 26)

For content-focused screens:

```swift
.tabBarMinimizationBehavior(.onScrollDown)
```

---

## 2. Navigation Stack

### 2.1 Catalog Navigation

```swift
struct CatalogView: View {
    @State private var navigationPath = NavigationPath()
    @State private var searchText = ""

    var body: some View {
        NavigationStack(path: $navigationPath) {
            CatalogListView()
                .navigationTitle("My Items")
                .navigationDestination(for: InventoryItem.ID.self) { itemID in
                    ItemDetailView(itemID: itemID)
                }
                .searchable(text: $searchText, placement: .navigationBarDrawer)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        SortMenuButton()
                        FilterMenuButton()

                        Spacer(.fixed)

                        Button {
                            // Add item
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.abundance.blue)
                    }
                }
        }
    }
}
```

### 2.2 Bottom-Aligned Search (iPhone)

iOS 26 automatically positions search at bottom on iPhone for ergonomics:

```swift
NavigationSplitView {
    List { /* sidebar */ }
        .searchable(text: $searchText)
} detail: {
    DetailView()
}
// Search appears bottom-aligned on iPhone, top-trailing on iPad
```

---

## 3. Contextual Menus

### 3.1 Item Card Context Menu

Per Brand Bible 3.2 ("springing menus"):

```swift
ItemCard(item: item)
    .contextMenu {
        Button {
            editItem(item)
        } label: {
            Label("Edit", systemImage: "pencil")
        }

        Button {
            shareItem(item)
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }

        Button {
            listForSale(item)
        } label: {
            Label("List for Sale", systemImage: "tag")
        }

        Divider()

        Button(role: .destructive) {
            deleteItem(item)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
```

---

## 4. Modal Sheets

### 4.1 Item Detail Sheet

```swift
struct ItemDetailSheet: View {
    let item: InventoryItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                ItemDetailContent(item: item)
            }
            .navigationTitle(item.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThickMaterial)
    }
}
```

---

## 5. Layout Patterns

### 5.1 Adaptive Grid

```swift
struct AdaptiveCatalogGrid: View {
    let items: [InventoryItem]

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: AbundanceSpacing.md)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: AbundanceSpacing.md) {
                ForEach(items) { item in
                    ItemCard(item: item)
                }
            }
            .safeAreaPadding(.horizontal, AbundanceSpacing.md)
            .safeAreaPadding(.vertical, AbundanceSpacing.sm)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
    }
}
```

### 5.2 Safe Area Handling

Per iOS 26 best practices:

```swift
// Edge-to-edge content with proper insets
ZStack {
    // Background extends full screen
    TerrazzaBackground()
        .ignoresSafeArea()

    // Content respects safe areas + custom padding
    VStack {
        content
    }
    .safeAreaPadding(.all, AbundanceSpacing.md)
}
```

---

## 6. Acceptance Criteria

- [ ] Tab bar uses floating Liquid Glass style (iOS 26 default)
- [ ] Search is bottom-aligned on iPhone
- [ ] Context menus "spring" from touch point
- [ ] Sheets use `.ultraThickMaterial` for focus
- [ ] Scroll edge effects applied to all scrollable views
- [ ] Safe area padding used for edge-to-edge content

---

## 7. Test Plan

```swift
func testNavigationAccessibility() {
    let app = XCUIApplication()
    app.launch()

    // Verify all tabs are accessible
    for tab in AbundanceTab.allCases {
        XCTAssertTrue(app.tabBars.buttons[tab.title].exists)
    }
}
```
```

**Step 2: Commit**

```bash
git add docs/specs/SPEC-UI-004-navigation-layout.md
git commit -m "docs: add SPEC-UI-004 navigation layout from Brand Bible"
```

---

## Task 5: Scanner Experience Spec

**Files:**
- Create: `docs/specs/SPEC-UI-005-scanner-experience.md`

**Step 1: Write the spec document**

```markdown
# SPEC-UI-005: Scanner Experience

**Document ID:** SPEC-UI-005
**Date:** 2026-01-15
**Status:** DRAFT
**Related Documents:**
- Brand Bible: Section 3.3 (The Intelligent Scanner)
- DESIGN-004 (Computer Vision Pipeline)
- ADR-013 (Vision Framework Strategy)

---

## Executive Summary

This specification defines the **scanning UX** for Abundance, including viewfinder design, recognition feedback, and success/error states optimized for Liquid Glass.

---

## 1. Viewfinder Design

### 1.1 Overlay Elements

Per Brand Bible 3.3 (soft glowing glass elements, not chrome brackets):

```swift
struct ScannerOverlay: View {
    @Binding var isScanning: Bool

    var body: some View {
        ZStack {
            // Scanning guide corners (soft glass, not hard chrome)
            ScannerCorners()

            // Active scanning indicator
            if isScanning {
                ScanningPulse()
            }

            // Bottom action area
            VStack {
                Spacer()
                ScannerControls()
            }
            .safeAreaPadding(.bottom, AbundanceSpacing.lg)
        }
    }
}

struct ScannerCorners: View {
    var body: some View {
        GeometryReader { geo in
            let cornerLength: CGFloat = 40
            let padding: CGFloat = 40

            // Top-left
            CornerShape(corner: .topLeading)
                .stroke(Color.abundance.blue.opacity(0.6), lineWidth: 3)
                .frame(width: cornerLength, height: cornerLength)
                .position(x: padding + cornerLength/2, y: padding + cornerLength/2)

            // Top-right
            CornerShape(corner: .topTrailing)
                .stroke(Color.abundance.blue.opacity(0.6), lineWidth: 3)
                .frame(width: cornerLength, height: cornerLength)
                .position(x: geo.size.width - padding - cornerLength/2, y: padding + cornerLength/2)

            // Bottom-left
            CornerShape(corner: .bottomLeading)
                .stroke(Color.abundance.blue.opacity(0.6), lineWidth: 3)
                .frame(width: cornerLength, height: cornerLength)
                .position(x: padding + cornerLength/2, y: geo.size.height - padding - cornerLength/2)

            // Bottom-right
            CornerShape(corner: .bottomTrailing)
                .stroke(Color.abundance.blue.opacity(0.6), lineWidth: 3)
                .frame(width: cornerLength, height: cornerLength)
                .position(x: geo.size.width - padding - cornerLength/2, y: geo.size.height - padding - cornerLength/2)
        }
    }
}
```

### 1.2 Active Scanning Indicator

```swift
struct ScanningPulse: View {
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .stroke(Color.abundance.blue.opacity(0.3), lineWidth: 2)
            .frame(width: 200, height: 200)
            .scaleEffect(isPulsing ? 1.2 : 1.0)
            .opacity(isPulsing ? 0 : 1)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    isPulsing = true
                }
            }
    }
}
```

---

## 2. Object Detection Feedback

### 2.1 Detected Object Highlight

Per Brand Bible 3.3 ("refractive glass frame"):

```swift
struct DetectedObjectOverlay: View {
    let boundingBox: CGRect
    let confidence: Float

    var body: some View {
        RoundedRectangle(cornerRadius: AbundanceRadius.medium)
            .stroke(
                Color.abundance.blue,
                lineWidth: confidence > 0.8 ? 3 : 2
            )
            .frame(width: boundingBox.width, height: boundingBox.height)
            .position(
                x: boundingBox.midX,
                y: boundingBox.midY
            )
            // Subtle glass effect on border
            .shadow(color: .abundance.blue.opacity(0.5), radius: 8)
    }
}
```

### 2.2 Confidence Indicator

```swift
struct ConfidenceIndicator: View {
    let confidence: Float

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: confidenceIcon)
            Text("\(Int(confidence * 100))%")
                .font(.caption.bold())
        }
        .foregroundStyle(confidenceColor)
        .padding(.horizontal, AbundanceSpacing.sm)
        .padding(.vertical, AbundanceSpacing.xxs)
        .background(
            .thinMaterial,
            in: Capsule()
        )
    }

    private var confidenceIcon: String {
        confidence > 0.8 ? "checkmark.circle.fill" :
        confidence > 0.5 ? "circle.dashed" : "questionmark.circle"
    }

    private var confidenceColor: Color {
        confidence > 0.8 ? .abundance.mint :
        confidence > 0.5 ? .abundance.cream : .abundance.coral
    }
}
```

---

## 3. Success State

### 3.1 Recognition Success Animation

Per Brand Bible 3.3 ("glassy confetti-like particles"):

```swift
struct ScanSuccessView: View {
    let recognizedItem: RecognizedItem
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            // Glass frame around item
            RoundedRectangle(cornerRadius: AbundanceRadius.large)
                .stroke(Color.abundance.mint, lineWidth: 4)
                .frame(width: 200, height: 200)
                .shadow(color: .abundance.mint.opacity(0.5), radius: 12)

            // Confetti particles
            if showConfetti {
                ConfettiView(colors: [
                    .abundance.blue,
                    .abundance.coral,
                    .abundance.mint
                ])
            }

            // Success checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.abundance.mint)
                .offset(y: -120)
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                showConfetti = true
            }
            // Haptic feedback
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
}
```

---

## 4. Error States

### 4.1 No Object Detected

```swift
struct NoObjectDetectedView: View {
    var body: some View {
        VStack(spacing: AbundanceSpacing.md) {
            Image(systemName: "viewfinder")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .symbolEffect(.pulse)

            Text("No object detected")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("Position an item within the frame")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(AbundanceSpacing.xl)
        .background(
            .thickMaterial,
            in: RoundedRectangle(cornerRadius: AbundanceRadius.large)
        )
    }
}
```

### 4.2 Camera Permission Denied

```swift
struct CameraPermissionView: View {
    var body: some View {
        VStack(spacing: AbundanceSpacing.lg) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)

            Text("Camera Access Required")
                .font(.title2.bold())
                .foregroundStyle(.primary)

            Text("Abundance needs camera access to scan your items")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            AbundancePrimaryButton(title: "Open Settings", icon: "gear") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        }
        .padding(AbundanceSpacing.xxl)
    }
}
```

### 4.3 Lens Smudge Warning (iOS 26)

Per Brand Bible 3.3 (DetectLensSmudgeRequest):

```swift
struct LensSmudgeWarning: View {
    var body: some View {
        HStack(spacing: AbundanceSpacing.sm) {
            Image(systemName: "camera.aperture")
                .foregroundStyle(.abundance.coral)

            Text("Clean camera lens for better results")
                .font(.caption)
                .foregroundStyle(.primary)
        }
        .padding(AbundanceSpacing.sm)
        .background(
            .thinMaterial,
            in: Capsule()
        )
    }
}
```

---

## 5. Vision Framework Integration Points

### 5.1 Detection Request Types

| Request | Purpose | Brand Bible Reference |
|---------|---------|----------------------|
| `VNRecognizeTextRequest` | Read text on objects | Section 3.3 |
| `VNDetectBarcodesRequest` | Scan QR/barcodes | Section 3.3 |
| `VNCoreMLRequest` | Object classification | Section 3.3 |
| `DetectLensSmudgeRequest` | Camera quality check | Section 3.3 (iOS 26) |
| `DetectDocumentSegmentationRequest` | Document isolation | Section 3.3 (iOS 26) |

---

## 6. Acceptance Criteria

- [ ] Viewfinder uses soft glowing corners (not hard chrome brackets)
- [ ] Active scanning shows pulsing indicator
- [ ] Detected objects highlighted with glass frame effect
- [ ] Success state shows confetti animation with haptic
- [ ] Error states show pulsating icons (not static)
- [ ] Lens smudge detection implemented (iOS 26)
- [ ] All states accessible with VoiceOver

---

## 7. Test Plan

```swift
func testScannerAccessibility() {
    let app = XCUIApplication()
    app.launch()
    app.tabBars.buttons["Scan"].tap()

    // Verify scanner controls are accessible
    XCTAssertTrue(app.buttons["Capture"].exists)
    XCTAssertTrue(app.buttons["Capture"].isHittable)
}
```
```

**Step 2: Commit**

```bash
git add docs/specs/SPEC-UI-005-scanner-experience.md
git commit -m "docs: add SPEC-UI-005 scanner experience from Brand Bible"
```

---

## Task 6: Catalog & Cards Spec

**Files:**
- Create: `docs/specs/SPEC-UI-006-catalog-cards.md`

**Step 1: Write the spec document**

```markdown
# SPEC-UI-006: Catalog & Cards

**Document ID:** SPEC-UI-006
**Date:** 2026-01-15
**Status:** DRAFT
**Related Documents:**
- Brand Bible: Section 3.4 (The Living Catalog)
- SPEC-UI-003 (Component Library)
- SPEC-UI-004 (Navigation & Layout)

---

## Executive Summary

This specification defines the **catalog views** and **card presentations** for inventory items, including grid layouts, detail views, and empty states optimized for Liquid Glass.

---

## 1. Catalog Grid View

### 1.1 Main Grid Layout

```swift
struct CatalogGridView: View {
    @ObservedObject var viewModel: CatalogViewModel

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: AbundanceSpacing.md)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: AbundanceSpacing.md) {
                ForEach(viewModel.items) { item in
                    NavigationLink(value: item.id) {
                        ItemCard(item: item)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        ItemContextMenu(item: item)
                    }
                }
            }
            .safeAreaPadding(.horizontal, AbundanceSpacing.md)
            .safeAreaPadding(.top, AbundanceSpacing.sm)
            .safeAreaPadding(.bottom, AbundanceSpacing.xxl) // Space for tab bar
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .scrollEdgeEffectStyle(.soft, for: .bottom)
        .background {
            // Terrazzo texture visible through glass cards
            TerrazzaBackground()
                .ignoresSafeArea()
        }
    }
}
```

### 1.2 List View Alternative

```swift
struct CatalogListView: View {
    @ObservedObject var viewModel: CatalogViewModel

    var body: some View {
        List(viewModel.items) { item in
            NavigationLink(value: item.id) {
                ItemListRow(item: item)
            }
            .listRowBackground(
                RoundedRectangle(cornerRadius: AbundanceRadius.medium)
                    .fill(.thickMaterial)
            )
            .listRowSeparator(.hidden)
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    viewModel.delete(item)
                } label: {
                    Label("Delete", systemImage: "trash")
                }

                Button {
                    viewModel.edit(item)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.abundance.blue)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background {
            TerrazzaBackground()
                .ignoresSafeArea()
        }
    }
}
```

---

## 2. Item Card Variants

### 2.1 Grid Card (Compact)

```swift
struct ItemGridCard: View {
    let item: InventoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: AbundanceSpacing.sm) {
            // Thumbnail
            AsyncImage(url: item.thumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                case .failure:
                    ImagePlaceholder(systemImage: "photo")
                case .empty:
                    ProgressView()
                @unknown default:
                    ImagePlaceholder(systemImage: "photo")
                }
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: AbundanceRadius.medium))

            // Title
            Text(item.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)

            // Value
            if let value = item.estimatedValue {
                Text(value, format: .currency(code: "USD"))
                    .font(.subheadline.bold())
                    .foregroundStyle(.abundance.blue)
            }

            // Category badge
            CategoryBadge(category: item.category)
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

### 2.2 List Row (Horizontal)

```swift
struct ItemListRow: View {
    let item: InventoryItem

    var body: some View {
        HStack(spacing: AbundanceSpacing.md) {
            // Thumbnail
            AsyncImage(url: item.thumbnailURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.secondary.opacity(0.1)
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: AbundanceRadius.medium))

            // Content
            VStack(alignment: .leading, spacing: AbundanceSpacing.xxs) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(item.category.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let value = item.estimatedValue {
                    Text(value, format: .currency(code: "USD"))
                        .font(.subheadline.bold())
                        .foregroundStyle(.abundance.blue)
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(AbundanceSpacing.sm)
    }
}
```

---

## 3. Category Badge

```swift
struct CategoryBadge: View {
    let category: ItemCategory

    var body: some View {
        HStack(spacing: AbundanceSpacing.xxs) {
            Image(systemName: category.systemImage)
                .font(.caption2)
            Text(category.displayName)
                .font(.caption2)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, AbundanceSpacing.xs)
        .padding(.vertical, AbundanceSpacing.xxs)
        .background(
            .thinMaterial,
            in: Capsule()
        )
    }
}
```

---

## 4. Empty States

### 4.1 New User Empty State

Per Brand Bible 3.4 ("dynamic and inviting"):

```swift
struct EmptyInventoryView: View {
    let onScanTapped: () -> Void
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: AbundanceSpacing.xl) {
            // Animated glass display cases
            HStack(spacing: AbundanceSpacing.md) {
                ForEach(0..<3, id: \.self) { index in
                    EmptyDisplayCase()
                        .opacity(isAnimating ? 1 : 0.5)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever()
                            .delay(Double(index) * 0.3),
                            value: isAnimating
                        )
                }
            }

            VStack(spacing: AbundanceSpacing.sm) {
                Text("Your collection awaits")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)

                Text("Scan your first item to start cataloging")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            AbundancePrimaryButton(title: "Start Scanning", icon: "viewfinder") {
                onScanTapped()
            }
        }
        .padding(AbundanceSpacing.xxl)
        .onAppear {
            isAnimating = true
        }
    }
}

struct EmptyDisplayCase: View {
    var body: some View {
        RoundedRectangle(cornerRadius: AbundanceRadius.medium)
            .fill(.thickMaterial)
            .frame(width: 80, height: 100)
            .overlay(
                RoundedRectangle(cornerRadius: AbundanceRadius.medium)
                    .stroke(Color.abundance.blue.opacity(0.3), lineWidth: 1)
            )
            .overlay {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundStyle(.abundance.blue.opacity(0.5))
            }
    }
}
```

### 4.2 Search No Results

```swift
struct SearchEmptyView: View {
    let searchText: String

    var body: some View {
        VStack(spacing: AbundanceSpacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("No results for \"\(searchText)\"")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(AbundanceSpacing.xxl)
    }
}
```

---

## 5. Terrazza Background

Per Brand Bible 1.1 ("used sparingly, visible through glass"):

```swift
struct TerrazzaBackground: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                // Generate terrazzo-like pattern
                let colors: [Color] = [
                    .abundance.blue.opacity(0.1),
                    .abundance.coral.opacity(0.1),
                    .abundance.mint.opacity(0.1),
                    .abundance.salmon.opacity(0.1)
                ]

                // Seeded random for consistency
                var rng = SeededRandomNumberGenerator(seed: 12345)

                for _ in 0..<50 {
                    let x = CGFloat.random(in: 0...size.width, using: &rng)
                    let y = CGFloat.random(in: 0...size.height, using: &rng)
                    let radius = CGFloat.random(in: 10...30, using: &rng)
                    let color = colors.randomElement(using: &rng) ?? .gray

                    let path = Circle().path(in: CGRect(
                        x: x - radius,
                        y: y - radius,
                        width: radius * 2,
                        height: radius * 2
                    ))
                    context.fill(path, with: .color(color))
                }
            }
        }
        .background(Color(UIColor.systemBackground))
    }
}
```

---

## 6. Acceptance Criteria

- [ ] Grid view uses adaptive columns (min 160, max 200)
- [ ] Cards use `.thickMaterial` with 1px border
- [ ] Terrazzo background visible through glass cards
- [ ] Empty states animate with pulsing elements
- [ ] Scroll edge effects on all scrollable content
- [ ] Context menus spring from touch point
- [ ] All cards support Dynamic Type

---

## 7. Test Plan

```swift
func testCatalogGridAccessibility() {
    let app = XCUIApplication()
    app.launch()
    app.tabBars.buttons["Catalog"].tap()

    // Verify grid items are accessible
    let firstCard = app.collectionViews.cells.firstMatch
    XCTAssertTrue(firstCard.isHittable)
}
```
```

**Step 2: Commit**

```bash
git add docs/specs/SPEC-UI-006-catalog-cards.md
git commit -m "docs: add SPEC-UI-006 catalog cards from Brand Bible"
```

---

## Task 7: On-Device ML Integration Spec

**Files:**
- Create: `docs/specs/SPEC-UI-007-on-device-ml.md`

**Step 1: Write the spec document**

```markdown
# SPEC-UI-007: On-Device ML Integration

**Document ID:** SPEC-UI-007
**Date:** 2026-01-15
**Status:** DRAFT
**Related Documents:**
- Brand Bible: Part IV (On-Device Machine Learning)
- DESIGN-004 (Computer Vision Pipeline)
- ADR-013 (Vision Framework Strategy)

---

## Executive Summary

This specification defines the **on-device ML integration** for Abundance, leveraging Vision Framework, Core ML, and Foundation Models for intelligent cataloging without cloud dependency.

---

## 1. Vision Framework Integration

### 1.1 Detection Pipeline

```swift
actor VisionDetectionService {
    private let requestHandler: VNImageRequestHandler

    func detectObjects(in image: CGImage) async throws -> [DetectedObject] {
        // Text recognition
        let textRequest = VNRecognizeTextRequest()
        textRequest.recognitionLevel = .accurate

        // Barcode detection
        let barcodeRequest = VNDetectBarcodesRequest()
        barcodeRequest.symbologies = [.qr, .ean13, .ean8, .upce]

        // Object classification (Core ML)
        let classificationRequest = try VNCoreMLRequest(model: objectClassifier)

        try requestHandler.perform([textRequest, barcodeRequest, classificationRequest])

        // Aggregate results
        return aggregateResults(
            text: textRequest.results ?? [],
            barcodes: barcodeRequest.results ?? [],
            classifications: classificationRequest.results ?? []
        )
    }
}
```

### 1.2 iOS 26 New APIs

```swift
// Lens smudge detection (Brand Bible 3.3)
func checkLensQuality(pixelBuffer: CVPixelBuffer) async throws -> LensQuality {
    let request = DetectLensSmudgeRequest()
    let result = try await request.perform(on: pixelBuffer)

    return LensQuality(
        isSmudged: result.confidence > 0.7,
        confidence: result.confidence
    )
}

// Document segmentation (Brand Bible 3.3)
func segmentDocument(in image: CGImage) async throws -> CGRect? {
    let request = DetectDocumentSegmentationRequest()
    try requestHandler.perform([request])

    return request.results?.first?.boundingBox
}
```

---

## 2. Core ML Custom Models

### 2.1 Model Integration

```swift
struct CoreMLModelManager {
    static let shared = CoreMLModelManager()

    // Object classifier (YOLOv3-Tiny or custom)
    lazy var objectClassifier: VNCoreMLModel = {
        guard let model = try? YOLOv3Tiny(configuration: .init()).model,
              let visionModel = try? VNCoreMLModel(for: model) else {
            fatalError("Failed to load object classifier")
        }
        return visionModel
    }()

    // Category-specific classifiers (future)
    // - Sneaker classifier
    // - Electronics classifier
    // - Book classifier
}
```

### 2.2 Model Performance Requirements

| Model | Max Latency | Min Accuracy |
|-------|-------------|--------------|
| Object Detection | 150ms | 85% |
| Text Recognition | 200ms | 95% |
| Barcode Detection | 50ms | 99% |

---

## 3. Foundation Models Integration (iOS 26+)

### 3.1 Intelligent Cataloging

Per Brand Bible 4.1 (Guided Generation):

```swift
import FoundationModels

@Generable
struct CatalogItem: Codable {
    @Guide(description: "A concise, marketable title under 60 characters")
    var title: String

    @Guide(description: "A detailed description for catalog listing, 100-300 words")
    var description: String

    @Guide(description: "The primary category for this item")
    var category: ItemCategory

    @Guide(description: "Estimated market value in USD")
    var estimatedValue: Decimal?

    @Guide(description: "Relevant keywords for search, 5-10 items")
    var keywords: [String]
}

actor IntelligentCatalogingService {
    private let session = LanguageModelSession()

    func generateCatalogItem(from detectionResult: DetectionResult) async throws -> CatalogItem {
        let prompt = """
        Based on the following recognized data, generate a CatalogItem:
        - Object type: \(detectionResult.objectType)
        - Recognized text: \(detectionResult.text.joined(separator: ", "))
        - Barcode: \(detectionResult.barcode ?? "none")
        """

        let result = try await session.generate(
            prompt,
            as: CatalogItem.self
        )

        return result
    }
}
```

### 3.2 Feature Availability

Per Brand Bible 4.1:

| Feature | Minimum Device | iOS Version |
|---------|----------------|-------------|
| Basic Vision | iPhone 11+ | iOS 26 |
| Foundation Models | iPhone 15 Pro+ | iOS 26 + Apple Intelligence |
| Custom Core ML | iPhone 11+ | iOS 26 |

### 3.3 Graceful Degradation

```swift
struct MLCapabilities {
    static var supportsFoundationModels: Bool {
        if #available(iOS 26, *) {
            return LanguageModelSession.isAvailable
        }
        return false
    }

    static var supportsAdvancedVision: Bool {
        // Check for Neural Engine capability
        return ProcessInfo.processInfo.processorCount >= 6
    }
}

// Usage
func catalogItem(_ image: CGImage) async throws -> CatalogItem {
    let detection = try await visionService.detectObjects(in: image)

    if MLCapabilities.supportsFoundationModels {
        // Full intelligent cataloging
        return try await intelligentService.generateCatalogItem(from: detection)
    } else {
        // Fallback to basic detection results
        return CatalogItem(
            title: detection.text.first ?? "Unknown Item",
            description: "",
            category: .other,
            estimatedValue: nil,
            keywords: []
        )
    }
}
```

---

## 4. Tool Calling for Live Data

Per Brand Bible 4.3:

```swift
import FoundationModels

// Define tool for market data lookup
struct MarketDataTool: Tool {
    let name = "lookupMarketValue"
    let description = "Look up current market value for an item"

    struct Input: Codable {
        let itemTitle: String
        let category: String
    }

    struct Output: Codable {
        let estimatedValue: Decimal
        let priceRange: ClosedRange<Decimal>
        let recentSales: Int
    }

    func call(with input: Input) async throws -> Output {
        // Call Abundance backend API
        let response = try await abundanceAPI.lookupMarketValue(
            title: input.itemTitle,
            category: input.category
        )
        return Output(
            estimatedValue: response.median,
            priceRange: response.low...response.high,
            recentSales: response.saleCount
        )
    }
}
```

---

## 5. Privacy Architecture

Per Brand Bible 4.1:

```
┌─────────────────────────────────────────────────────┐
│                   USER'S DEVICE                      │
│                                                      │
│  ┌────────────┐     ┌─────────────────────────┐    │
│  │   Camera   │────▶│   Vision Framework      │    │
│  └────────────┘     │   - Text Recognition    │    │
│                     │   - Object Detection    │    │
│                     │   - Barcode Scanning    │    │
│                     └───────────┬─────────────┘    │
│                                 │                   │
│                                 ▼                   │
│                     ┌─────────────────────────┐    │
│                     │  Foundation Models      │    │
│                     │  - Intelligent Catalog  │    │
│                     │  - Runs 100% on-device  │    │
│                     └───────────┬─────────────┘    │
│                                 │                   │
│                                 ▼                   │
│                     ┌─────────────────────────┐    │
│                     │     Firestore           │    │
│                     │  - Catalog metadata     │    │
│                     │  - No original photos   │    │
│                     └─────────────────────────┘    │
│                                                      │
└─────────────────────────────────────────────────────┘
               │
               │ Premium tier only
               ▼
┌─────────────────────────────────────────────────────┐
│                   GCP BACKEND                        │
│  - Cropped thumbnails only (not originals)          │
│  - Market data lookup                               │
│  - SerpAPI Google Lens (optional)                   │
└─────────────────────────────────────────────────────┘
```

---

## 6. Acceptance Criteria

- [ ] Vision detection pipeline runs <200ms total
- [ ] Text recognition accuracy >95%
- [ ] Barcode detection accuracy >99%
- [ ] Foundation Models gracefully degrade on unsupported devices
- [ ] Original photos never leave device
- [ ] All ML processing respects Reduce Motion setting

---

## 7. Test Plan

```swift
func testVisionPipelinePerformance() async throws {
    let testImage = loadTestImage("sample_product.jpg")

    let start = CFAbsoluteTimeGetCurrent()
    let results = try await visionService.detectObjects(in: testImage)
    let elapsed = CFAbsoluteTimeGetCurrent() - start

    XCTAssertLessThan(elapsed, 0.2) // 200ms max
    XCTAssertFalse(results.isEmpty)
}
```
```

**Step 2: Commit**

```bash
git add docs/specs/SPEC-UI-007-on-device-ml.md
git commit -m "docs: add SPEC-UI-007 on-device ML integration from Brand Bible"
```

---

## Task 8: Accessibility Requirements Spec

**Files:**
- Create: `docs/specs/SPEC-UI-008-accessibility-requirements.md`

**Step 1: Write the spec document**

```markdown
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
```

**Step 2: Commit**

```bash
git add docs/specs/SPEC-UI-008-accessibility-requirements.md
git commit -m "docs: add SPEC-UI-008 accessibility requirements from Brand Bible"
```

---

## Summary

This plan creates **8 specification documents** that translate the Abundance Brand Bible into actionable implementation guidance:

| Document | Contents |
|----------|----------|
| SPEC-UI-001 | Color palette, typography, spacing tokens |
| SPEC-UI-002 | Material thickness/vibrancy mappings per component |
| SPEC-UI-003 | Reusable SwiftUI components (buttons, cards, badges) |
| SPEC-UI-004 | Tab bar, navigation stack, modal patterns |
| SPEC-UI-005 | Scanner viewfinder, detection feedback, success/error states |
| SPEC-UI-006 | Grid/list views, item cards, empty states |
| SPEC-UI-007 | Vision Framework, Core ML, Foundation Models integration |
| SPEC-UI-008 | VoiceOver, Dynamic Type, Reduce Motion/Transparency |

All specs are verified against:
- iOS 26 Liquid Glass APIs (`axiom-liquid-glass` skill)
- SwiftUI 26 layout APIs (`axiom-swiftui-26-ref` skill)
- SwiftUI layout best practices (`axiom-swiftui-layout-ref` skill)

---

**Plan complete and saved to `docs/plans/2026-01-15-brand-bible-to-specs-liquid-glass.md`. Two execution options:**

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

**Which approach?**
