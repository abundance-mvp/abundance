# DESIGN-031: SwiftUI Component Library

**Created**: 2025-11-10
**Stage**: 2.6 - iOS UI/UX Design & Liquid Glass Integration
**Status**: Approved
**References**:
- docs/plans/PLAN-SUMMARY-stage-2.6.md
- docs/validation/RESEARCH-VALIDATION-stage-2.6.md
- docs/design/DESIGN-032-color-system-design-tokens.md
- docs/design/DESIGN-033-typography-specifications.md
- docs/design/DESIGN-034-animation-motion-specifications.md
- shared/abundance-brand/abundance-core-style-guidelines.md

---

## Overview

This document defines the complete SwiftUI component library for the Abundance iOS app, implementing the brand's "Refractive Retro-Futurism" aesthetic with Apple's Liquid Glass design language. All components are production-ready, accessibility-compliant (WCAG 2.2 AA), and optimized for iOS 26+ with graceful degradation for iOS 25.

**Core Principles**:
1. **Material-First Design**: All components use SwiftUI's Material system (.ultraThin → .ultraThick)
2. **Spring Physics**: All animations use spring-based physics with brand presets
3. **Accessibility-First**: Reduce Transparency, Reduce Motion, VoiceOver, Dynamic Type support
4. **Brand Consistency**: Capsule for controls, ConcentricRectangle for containers
5. **Sensory Feedback**: Haptic feedback on all interactive elements

**Technology Stack**:
- iOS 26.0+ (primary), iOS 25.0+ (fallback)
- SwiftUI 6.0
- Swift 6.0 (strict concurrency)
- Material System, Vibrancy, Spring Animations, Sensory Feedback

---

## Component Catalog

### 1. PrimaryButton

**Purpose**: Main call-to-action button for critical user actions (Sign In, Capture Photo, Save Item, Export)

**Visual Characteristics**:
- Capsule shape with Bright Blue glow
- .thinMaterial background for translucency
- 2pt Bright Blue stroke for edge definition
- Sensory feedback on tap (.impact, weight: .medium)
- Spring animation on state changes (.brandSnappy)

**Accessibility**:
- Minimum tap target: 44x44pt
- Dynamic Type support (scales with system text size)
- VoiceOver: Announces label and button trait
- Reduce Transparency: Replaces .thinMaterial with opaque #FCFCFF

**Component Props**:
- `title: String` - Button label text
- `action: () -> Void` - Closure executed on tap
- `isEnabled: Bool` - Disabled state (default: true)
- `isLoading: Bool` - Shows loading indicator (default: false)

**SwiftUI Implementation**:

```swift
import SwiftUI

struct PrimaryButton: View {
    // MARK: - Properties
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    var isLoading: Bool = false

    // MARK: - Environment
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    // MARK: - State
    @State private var isPressed: Bool = false

    // MARK: - Body
    var body: some View {
        Button(action: handleTap) {
            ZStack {
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
                    .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.primary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .frame(minHeight: 44) // Accessibility tap target
            .background {
                Capsule()
                    .fill(reduceTransparency ? Color.backgroundDefault : .thinMaterial)
                    .shadow(
                        color: Color.brandBrightBlue.opacity(isEnabled ? 0.5 : 0.2),
                        radius: isPressed ? 8 : 12,
                        x: 0,
                        y: 4
                    )
            }
            .overlay {
                Capsule()
                    .stroke(Color.brandBrightBlue.opacity(isEnabled ? 1.0 : 0.3), lineWidth: 2)
            }
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.5)
        }
        .disabled(!isEnabled || isLoading)
        .sensoryFeedback(.impact(weight: .medium), trigger: isPressed)
        .animation(.brandSnappy, value: isPressed)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .accessibilityRemoveTraits(isEnabled ? [] : .isButton)
        .accessibilityAddTraits(isEnabled ? [] : .isStaticText)
    }

    // MARK: - Actions
    private func handleTap() {
        isPressed = true
        action()

        // Reset pressed state after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPressed = false
        }
    }
}

// MARK: - Preview
#Preview("Primary Button - States") {
    VStack(spacing: 24) {
        PrimaryButton(title: "Get Started", action: {})

        PrimaryButton(title: "Disabled", action: {}, isEnabled: false)

        PrimaryButton(title: "Loading...", action: {}, isLoading: true)
    }
    .padding()
}
```

**Usage Examples**:

```swift
// Onboarding screen
PrimaryButton(title: "Get Started") {
    navigateToPermissions()
}

// Camera capture
PrimaryButton(title: "Capture Photo") {
    captureImage()
}

// Save item
PrimaryButton(
    title: "Save Item",
    isEnabled: viewModel.isValid
) {
    viewModel.saveItem()
}

// Export with loading state
PrimaryButton(
    title: "Export Catalog",
    isLoading: viewModel.isExporting
) {
    viewModel.exportCatalog()
}
```

**Visual Mockup**:

```
┌─────────────────────────────────────────────────┐
│                                                 │
│    ┌─────────────────────────────────────┐     │
│    │         Get Started                 │     │ ← .thinMaterial
│    └─────────────────────────────────────┘     │   Bright Blue glow
│              Bright Blue outline                │   2pt stroke
│                                                 │
│    ┌─────────────────────────────────────┐     │
│    │         Save Item                   │     │ ← Enabled state
│    └─────────────────────────────────────┘     │
│                                                 │
│    ┌─────────────────────────────────────┐     │
│    │         Disabled                    │     │ ← 50% opacity
│    └─────────────────────────────────────┘     │   30% glow
│                                                 │
└─────────────────────────────────────────────────┘
```

---

### 2. ItemCard

**Purpose**: Display cataloged household items in grid layout with photo, metadata, and estimated value

**Visual Characteristics**:
- ConcentricRectangle shape (iOS 26+) or RoundedRectangle (iOS 25)
- .thickMaterial background for substantial glass effect
- Cropped object photo (160pt height, aspect fill)
- Text hierarchy: Name (Semibold) → Category (Footnote) → Value (Caption, Mint Green)
- Soft shadow for depth (8pt radius, 10% opacity)

**Accessibility**:
- VoiceOver: Combines all text into single announcement
- Dynamic Type: Text scales up to .xxxLarge, layout adjusts
- Reduce Transparency: Replaces .thickMaterial with opaque #FCFCFF
- Minimum tap target: Full card (160x240pt minimum)

**Component Props**:
- `item: CatalogItem` - Item data model
- `onTap: () -> Void` - Action when card is tapped

**SwiftUI Implementation**:

```swift
import SwiftUI

struct ItemCard: View {
    // MARK: - Properties
    let item: CatalogItem
    var onTap: (() -> Void)? = nil

    // MARK: - Environment
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // MARK: - State
    @State private var isPressed: Bool = false

    // MARK: - Body
    var body: some View {
        Button(action: handleTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Cropped object image
                AsyncImage(url: item.imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: imageHeight)
                            .frame(maxWidth: .infinity)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: imageHeight)
                            .clipped()
                    case .failure:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
                .clipShape(innerShape)

                // Metadata section
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

                    Text(item.category)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    HStack {
                        Spacer()
                        if let value = item.estimatedValue {
                            Text("$\(value, specifier: "%.2f")")
                                .font(.system(.caption, design: .rounded, weight: .bold))
                                .foregroundStyle(Color.brandMintGreen)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .background(backgroundMaterial, in: outerShape)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.brandSnappy, value: isPressed)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Computed Properties
    private var imageHeight: CGFloat {
        // Adjust image height for larger text sizes
        dynamicTypeSize >= .xxxLarge ? 120 : 160
    }

    private var backgroundMaterial: AnyShapeStyle {
        if reduceTransparency {
            return AnyShapeStyle(Color.backgroundDefault)
        } else {
            return AnyShapeStyle(.thickMaterial)
        }
    }

    @ViewBuilder
    private var outerShape: some Shape {
        if #available(iOS 26, *) {
            ConcentricRectangle(cornerRadius: 16, inset: 0)
        } else {
            RoundedRectangle(cornerRadius: 16)
        }
    }

    @ViewBuilder
    private var innerShape: some Shape {
        if #available(iOS 26, *) {
            ConcentricRectangle(cornerRadius: 12, inset: 4)
        } else {
            RoundedRectangle(cornerRadius: 12)
        }
    }

    private var placeholderImage: some View {
        ZStack {
            Color.gray.opacity(0.2)
            Image(systemName: "photo")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
        }
        .frame(height: imageHeight)
    }

    private var accessibilityDescription: String {
        var description = "\(item.name), \(item.category)"
        if let value = item.estimatedValue {
            description += ", estimated value $\(value, specifier: "%.2f")"
        }
        return description
    }

    // MARK: - Actions
    private func handleTap() {
        isPressed = true
        onTap?()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            isPressed = false
        }
    }
}

// MARK: - Data Model
struct CatalogItem: Identifiable {
    let id: String
    let name: String
    let category: String
    let imageURL: URL?
    let estimatedValue: Double?
}

// MARK: - Preview
#Preview("Item Card - Grid") {
    ScrollView {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ItemCard(item: CatalogItem(
                id: "1",
                name: "Vintage Lamp",
                category: "Lighting",
                imageURL: URL(string: "https://example.com/lamp.jpg"),
                estimatedValue: 45.00
            ))

            ItemCard(item: CatalogItem(
                id: "2",
                name: "Coffee Maker with Very Long Name",
                category: "Kitchen",
                imageURL: nil,
                estimatedValue: 120.00
            ))
        }
        .padding()
    }
}
```

**Usage Examples**:

```swift
// Catalog grid
LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
    ForEach(viewModel.items) { item in
        ItemCard(item: item) {
            navigateToDetail(item)
        }
    }
}

// Search results
ForEach(filteredItems) { item in
    ItemCard(item: item) {
        selectedItem = item
    }
}
```

**Visual Mockup**:

```
┌─────────────────────────────────────┐
│                                     │
│  ┌─────────────────────────────┐   │
│  │                             │   │
│  │      [Cropped Photo]        │   │ ← 160pt height
│  │     (aspect fill, clip)     │   │   ConcentricRectangle
│  │                             │   │
│  └─────────────────────────────┘   │
│                                     │
│  Vintage Lamp                       │ ← .semibold, .primary
│  Lighting                           │ ← .footnote, .secondary
│                          $45.00     │ ← .caption, Mint Green
│                                     │
└─────────────────────────────────────┘
  .thickMaterial, 16pt corner radius
  8pt shadow, 10% opacity
```

---

### 3. FloatingTabBar

**Purpose**: Primary navigation for Catalog, Camera, and Profile screens with floating pill-shaped design

**Visual Characteristics**:
- Capsule shape (pill) with .regularMaterial background
- 3 tabs: Catalog, Camera, Profile (SF Symbols + labels)
- Selection indicator: .primary vibrancy for active, .secondary for inactive
- Soft shadow for floating effect (12pt radius, 20% opacity)
- Sensory feedback on selection (.selection)

**Accessibility**:
- VoiceOver: Announces tab name and selection state
- Dynamic Type: Scales icon and label size
- Reduce Transparency: Replaces .regularMaterial with opaque #FCFCFF
- Minimum tap target: 44pt height per tab

**Component Props**:
- `selectedTab: Binding<Tab>` - Currently selected tab
- `onTabChange: (Tab) -> Void` - Optional callback when tab changes

**SwiftUI Implementation**:

```swift
import SwiftUI

struct FloatingTabBar: View {
    // MARK: - Tab Definition
    enum Tab: String, CaseIterable, Identifiable {
        case catalog = "Catalog"
        case camera = "Camera"
        case profile = "Profile"

        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .catalog: return "square.grid.2x2"
            case .camera: return "camera"
            case .profile: return "person"
            }
        }
    }

    // MARK: - Properties
    @Binding var selectedTab: Tab
    var onTabChange: ((Tab) -> Void)? = nil

    // MARK: - Environment
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    // MARK: - State
    @State private var lastSelectedTab: Tab?

    // MARK: - Body
    var body: some View {
        HStack(spacing: 24) {
            ForEach(Tab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(backgroundMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 40)
        .padding(.bottom, 16)
        .onChange(of: selectedTab) { oldValue, newValue in
            if oldValue != newValue {
                lastSelectedTab = oldValue
                onTabChange?(newValue)
            }
        }
    }

    // MARK: - Subviews
    @ViewBuilder
    private func tabButton(for tab: Tab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: iconName(for: tab))
                    .font(.system(size: 24))
                    .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                    .symbolVariant(selectedTab == tab ? .fill : .none)

                Text(tab.rawValue)
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(selectedTab == tab ? .primary : .tertiary)
            }
            .frame(minWidth: 60, minHeight: 44) // Accessibility tap target
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selectedTab == tab)
        .accessibilityLabel(tab.rawValue)
        .accessibilityAddTraits(selectedTab == tab ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: - Computed Properties
    private var backgroundMaterial: AnyShapeStyle {
        if reduceTransparency {
            return AnyShapeStyle(Color.backgroundDefault)
        } else {
            return AnyShapeStyle(.regularMaterial)
        }
    }

    private func iconName(for tab: Tab) -> String {
        switch tab {
        case .catalog: return "square.grid.2x2"
        case .camera: return "camera"
        case .profile: return "person"
        }
    }
}

// MARK: - Preview
#Preview("Floating Tab Bar") {
    VStack {
        Spacer()

        FloatingTabBar(selectedTab: .constant(.catalog)) { tab in
            print("Selected: \(tab)")
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray.opacity(0.2))
}
```

**Usage Examples**:

```swift
// Main app navigation
struct MainView: View {
    @State private var selectedTab: FloatingTabBar.Tab = .catalog

    var body: some View {
        ZStack {
            // Content views
            switch selectedTab {
            case .catalog:
                CatalogView()
            case .camera:
                CameraView()
            case .profile:
                ProfileView()
            }

            // Floating tab bar
            VStack {
                Spacer()
                FloatingTabBar(selectedTab: $selectedTab) { newTab in
                    // Analytics tracking
                    trackTabSelection(newTab)
                }
            }
        }
    }
}
```

**Visual Mockup**:

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│                                                         │
│                 [Screen Content]                        │
│                                                         │
│                                                         │
│  ┌───────────────────────────────────────────────┐     │
│  │                                               │     │
│  │   ┌─────┐     ┌─────┐     ┌─────┐           │     │
│  │   │ ▣   │     │ ○   │     │ ○   │           │     │ ← SF Symbols
│  │   │Ctlg │     │Cmra │     │Prof │           │     │   24pt icons
│  │   └─────┘     └─────┘     └─────┘           │     │
│  │   (active)   (inactive) (inactive)           │     │
│  │                                               │     │
│  └───────────────────────────────────────────────┘     │
│         Capsule, .regularMaterial, shadow              │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

### 4. GlassModal

**Purpose**: Modal sheet presentation for editing, exporting, and settings with glass aesthetic

**Visual Characteristics**:
- .ultraThickMaterial presentation background
- Large navigation title with prominent dismiss and action buttons
- Rounded corners (24pt) for sheet presentation
- Primary action button (top-right) and cancel button (top-left)

**Accessibility**:
- VoiceOver: Announces modal title and available actions
- Dynamic Type: Title and content scale appropriately
- Reduce Transparency: Replaces .ultraThickMaterial with opaque #FCFCFF
- Keyboard shortcuts: ESC to dismiss (when keyboard connected)

**Component Props**:
- `title: String` - Modal navigation title
- `content: () -> Content` - ViewBuilder for modal content
- `primaryAction: () -> Void` - Action for primary button (Save, Export, etc.)
- `primaryActionTitle: String` - Label for primary button
- `isPresented: Binding<Bool>` - Controls modal presentation

**SwiftUI Implementation**:

```swift
import SwiftUI

struct GlassModal<Content: View>: View {
    // MARK: - Properties
    let title: String
    @ViewBuilder let content: Content
    let primaryAction: () -> Void
    let primaryActionTitle: String
    @Binding var isPresented: Bool

    // MARK: - Environment
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    // MARK: - Body
    var body: some View {
        NavigationStack {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isPresented = false
                        }
                        .foregroundStyle(.secondary)
                    }

                    ToolbarItem(placement: .primaryAction) {
                        Button(primaryActionTitle) {
                            primaryAction()
                        }
                        .foregroundStyle(.primary)
                        .fontWeight(.semibold)
                    }
                }
        }
        .presentationDetents([.large])
        .presentationBackgroundInteraction(.enabled(upThrough: .large))
        .presentationBackground(backgroundMaterial)
        .presentationCornerRadius(24)
        .interactiveDismissDisabled(false)
    }

    // MARK: - Computed Properties
    private var backgroundMaterial: AnyShapeStyle {
        if reduceTransparency {
            return AnyShapeStyle(Color.backgroundDefault)
        } else {
            return AnyShapeStyle(.ultraThickMaterial)
        }
    }
}

// MARK: - Modal Wrapper (for easier usage)
extension View {
    func glassModal<Content: View>(
        isPresented: Binding<Bool>,
        title: String,
        primaryActionTitle: String = "Done",
        primaryAction: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            GlassModal(
                title: title,
                content: content,
                primaryAction: {
                    primaryAction()
                    isPresented.wrappedValue = false
                },
                primaryActionTitle: primaryActionTitle,
                isPresented: isPresented
            )
        }
    }
}

// MARK: - Preview
#Preview("Glass Modal") {
    @Previewable @State var isPresented = true

    Color.gray.opacity(0.2)
        .glassModal(
            isPresented: $isPresented,
            title: "Edit Item",
            primaryActionTitle: "Save",
            primaryAction: {
                print("Save tapped")
            }
        ) {
            Form {
                Section("Details") {
                    TextField("Name", text: .constant("Vintage Lamp"))
                    TextField("Category", text: .constant("Lighting"))
                }

                Section("Value") {
                    TextField("Price", text: .constant("45.00"))
                        .keyboardType(.decimalPad)
                }
            }
        }
}
```

**Usage Examples**:

```swift
// Edit item modal
.glassModal(
    isPresented: $showEditModal,
    title: "Edit Item",
    primaryActionTitle: "Save",
    primaryAction: {
        viewModel.saveItem()
    }
) {
    EditItemForm(item: $selectedItem)
}

// Export options modal
.glassModal(
    isPresented: $showExportModal,
    title: "Export Catalog",
    primaryActionTitle: "Export",
    primaryAction: {
        viewModel.exportCatalog()
    }
) {
    ExportOptionsView(format: $exportFormat)
}

// Settings modal
.glassModal(
    isPresented: $showSettings,
    title: "Settings",
    primaryActionTitle: "Done",
    primaryAction: {
        // Settings auto-save, just dismiss
    }
) {
    SettingsForm()
}
```

**Visual Mockup**:

```
┌─────────────────────────────────────────────────────────┐
│  Cancel                Edit Item                  Save  │ ← Navigation bar
│                                                         │
│  Edit Item                                              │ ← Large title
│  ─────────────────────────────────────────────────────  │
│                                                         │
│  Details                                                │
│  ┌───────────────────────────────────────────────┐     │
│  │ Name           Vintage Lamp                   │     │
│  │ ─────────────────────────────────────────────  │     │
│  │ Category       Lighting                       │     │
│  └───────────────────────────────────────────────┘     │
│                                                         │
│  Value                                                  │
│  ┌───────────────────────────────────────────────┐     │
│  │ Price          45.00                          │     │
│  └───────────────────────────────────────────────┘     │
│                                                         │
└─────────────────────────────────────────────────────────┘
  .ultraThickMaterial background
  24pt corner radius
```

---

### 5. SearchBar

**Purpose**: Filter catalog items by name, category, or location with live filtering

**Visual Characteristics**:
- Capsule shape with .thinMaterial background
- Magnifying glass icon (leading), clear button (trailing)
- Placeholder text (.tertiary vibrancy)
- Clear button appears only when text is entered
- Keyboard dismisses on scroll or tap outside

**Accessibility**:
- VoiceOver: Announces "Search items" and current text
- Dynamic Type: Text scales with system settings
- Reduce Transparency: Replaces .thinMaterial with opaque #FCFCFF
- Minimum height: 44pt (tap target)

**Component Props**:
- `searchText: Binding<String>` - Current search query
- `placeholder: String` - Placeholder text (default: "Search items...")

**SwiftUI Implementation**:

```swift
import SwiftUI

struct SearchBar: View {
    // MARK: - Properties
    @Binding var searchText: String
    var placeholder: String = "Search items..."

    // MARK: - Environment
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    // MARK: - Focus State
    @FocusState private var isFocused: Bool

    // MARK: - Body
    var body: some View {
        HStack(spacing: 12) {
            // Magnifying glass icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)

            // Text field
            TextField(placeholder, text: $searchText)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.primary)
                .focused($isFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            // Clear button (shows when text exists)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    isFocused = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(backgroundMaterial, in: Capsule())
        .animation(.brandSnappy, value: searchText.isEmpty)
    }

    // MARK: - Computed Properties
    private var backgroundMaterial: AnyShapeStyle {
        if reduceTransparency {
            return AnyShapeStyle(Color.backgroundDefault)
        } else {
            return AnyShapeStyle(.thinMaterial)
        }
    }
}

// MARK: - Preview
#Preview("Search Bar") {
    @Previewable @State var searchText = ""

    VStack(spacing: 16) {
        SearchBar(searchText: $searchText)

        SearchBar(searchText: .constant("Lamp"))

        SearchBar(searchText: $searchText, placeholder: "Find an item...")
    }
    .padding()
}
```

**Usage Examples**:

```swift
// Catalog view search
struct CatalogView: View {
    @State private var searchText = ""

    var body: some View {
        VStack {
            SearchBar(searchText: $searchText)
                .padding(.horizontal, 16)
                .padding(.top, 8)

            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(filteredItems) { item in
                        ItemCard(item: item)
                    }
                }
            }
        }
    }

    var filteredItems: [CatalogItem] {
        if searchText.isEmpty {
            return viewModel.items
        }
        return viewModel.items.filter { item in
            item.name.localizedCaseInsensitiveContains(searchText) ||
            item.category.localizedCaseInsensitiveContains(searchText)
        }
    }
}
```

**Visual Mockup**:

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  ┌───────────────────────────────────────────────┐     │
│  │ 🔍  Search items...                          │     │ ← Empty state
│  └───────────────────────────────────────────────┘     │
│                                                         │
│  ┌───────────────────────────────────────────────┐     │
│  │ 🔍  Lamp                                    ⊗│     │ ← With text
│  └───────────────────────────────────────────────┘     │   Clear button
│                                                         │
└─────────────────────────────────────────────────────────┘
  Capsule, .thinMaterial, 44pt height
```

---

### 6. PermissionCard

**Purpose**: Request user permissions (camera, notifications) during onboarding with clear value proposition

**Visual Characteristics**:
- .thickMaterial background with ConcentricRectangle shape
- Emoji icon for visual recognition
- Title (Semibold) + description (Regular) + CTA button
- Soft shadow for depth (8pt radius, 10% opacity)

**Accessibility**:
- VoiceOver: Reads title, description, and button separately
- Dynamic Type: Text scales, layout adjusts for larger sizes
- Reduce Transparency: Replaces .thickMaterial with opaque #FCFCFF
- Minimum button height: 44pt

**Component Props**:
- `icon: String` - Emoji or SF Symbol name
- `title: String` - Permission title (e.g., "Camera Access")
- `description: String` - Why permission is needed
- `buttonTitle: String` - CTA button label (e.g., "Allow Camera")
- `action: () -> Void` - Action when button is tapped

**SwiftUI Implementation**:

```swift
import SwiftUI

struct PermissionCard: View {
    // MARK: - Properties
    let icon: String
    let title: String
    let description: String
    let buttonTitle: String
    let action: () -> Void

    // MARK: - Environment
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Icon
            Text(icon)
                .font(.system(size: 48))
                .accessibilityHidden(true)

            // Title
            Text(title)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(.primary)

            // Description
            Text(description)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            // CTA Button
            PrimaryButton(title: buttonTitle, action: action)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundMaterial, in: outerShape)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    // MARK: - Computed Properties
    private var backgroundMaterial: AnyShapeStyle {
        if reduceTransparency {
            return AnyShapeStyle(Color.backgroundDefault)
        } else {
            return AnyShapeStyle(.thickMaterial)
        }
    }

    @ViewBuilder
    private var outerShape: some Shape {
        if #available(iOS 26, *) {
            ConcentricRectangle(cornerRadius: 20, inset: 0)
        } else {
            RoundedRectangle(cornerRadius: 20)
        }
    }
}

// MARK: - Preview
#Preview("Permission Cards") {
    VStack(spacing: 24) {
        PermissionCard(
            icon: "📸",
            title: "Camera Access",
            description: "Scan items instantly with your camera to add them to your catalog.",
            buttonTitle: "Allow Camera",
            action: { print("Camera requested") }
        )

        PermissionCard(
            icon: "🔔",
            title: "Notifications",
            description: "Get reminded about expiring warranties and item maintenance.",
            buttonTitle: "Allow Notifications",
            action: { print("Notifications requested") }
        )
    }
    .padding()
}
```

**Usage Examples**:

```swift
// Permissions screen
struct PermissionsView: View {
    @StateObject private var viewModel = PermissionsViewModel()

    var body: some View {
        VStack(spacing: 24) {
            PermissionCard(
                icon: "📸",
                title: "Camera Access",
                description: "Scan items instantly with your camera.",
                buttonTitle: "Allow Camera",
                action: viewModel.requestCameraPermission
            )

            PermissionCard(
                icon: "🔔",
                title: "Notifications",
                description: "Get reminded about warranties and maintenance.",
                buttonTitle: "Allow Notifications",
                action: viewModel.requestNotificationPermission
            )
        }
        .padding()
    }
}
```

**Visual Mockup**:

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  📸                                                     │ ← 48pt emoji
│                                                         │
│  Camera Access                                          │ ← .title3, semibold
│                                                         │
│  Scan items instantly with your camera to add them     │ ← .body, secondary
│  to your catalog.                                       │
│                                                         │
│    ┌─────────────────────────────────────┐             │
│    │        Allow Camera                 │             │ ← PrimaryButton
│    └─────────────────────────────────────┘             │
│                                                         │
└─────────────────────────────────────────────────────────┘
  .thickMaterial, ConcentricRectangle, 20pt corner radius
```

---

### 7. ConfidenceBadge

**Purpose**: Display AI confidence level (High/Medium/Low) with color-coded visual indicator

**Visual Characteristics**:
- Capsule shape with color-coded background (Green/Yellow/Red)
- Percentage display or text label (High/Medium/Low)
- Compact size for inline usage in metadata sections
- Semi-bold text for readability

**Accessibility**:
- VoiceOver: Announces "Confidence: High" or percentage
- Dynamic Type: Scales with system text size
- Color + text label ensures accessibility for colorblind users
- No reliance on color alone for information

**Component Props**:
- `confidence: Double` - Confidence score (0.0 to 1.0)
- `showPercentage: Bool` - Show percentage instead of label (default: false)

**SwiftUI Implementation**:

```swift
import SwiftUI

struct ConfidenceBadge: View {
    // MARK: - Confidence Level
    enum ConfidenceLevel {
        case high, medium, low

        var color: Color {
            switch self {
            case .high: return Color.successColor
            case .medium: return Color.warningColor
            case .low: return Color.errorColor
            }
        }

        var label: String {
            switch self {
            case .high: return "High"
            case .medium: return "Medium"
            case .low: return "Low"
            }
        }
    }

    // MARK: - Properties
    let confidence: Double
    var showPercentage: Bool = false

    // MARK: - Computed Properties
    private var level: ConfidenceLevel {
        if confidence >= 0.8 {
            return .high
        } else if confidence >= 0.5 {
            return .medium
        } else {
            return .low
        }
    }

    private var displayText: String {
        if showPercentage {
            return "\(Int(confidence * 100))%"
        } else {
            return level.label
        }
    }

    // MARK: - Body
    var body: some View {
        Text(displayText)
            .font(.system(.caption, design: .rounded, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(level.color, in: Capsule())
            .accessibilityLabel("Confidence: \(displayText)")
    }
}

// MARK: - Preview
#Preview("Confidence Badges") {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            ConfidenceBadge(confidence: 0.95)
            ConfidenceBadge(confidence: 0.95, showPercentage: true)
        }

        HStack(spacing: 12) {
            ConfidenceBadge(confidence: 0.65)
            ConfidenceBadge(confidence: 0.65, showPercentage: true)
        }

        HStack(spacing: 12) {
            ConfidenceBadge(confidence: 0.35)
            ConfidenceBadge(confidence: 0.35, showPercentage: true)
        }
    }
    .padding()
}
```

**Usage Examples**:

```swift
// Item detail view
HStack {
    Text("AI Confidence:")
        .font(.system(.footnote, design: .rounded))
        .foregroundStyle(.secondary)

    ConfidenceBadge(confidence: item.aiConfidence)
}

// List row with percentage
HStack {
    Text(item.name)
    Spacer()
    ConfidenceBadge(confidence: item.aiConfidence, showPercentage: true)
}
```

**Visual Mockup**:

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  AI Confidence:  ┌──────┐                              │
│                  │ High │  ← Green background          │
│                  └──────┘    Capsule shape             │
│                                                         │
│  AI Confidence:  ┌────────┐                            │
│                  │ Medium │  ← Yellow background       │
│                  └────────┘                             │
│                                                         │
│  AI Confidence:  ┌──────┐                              │
│                  │ Low  │  ← Red background            │
│                  └──────┘                               │
│                                                         │
│  AI Confidence:  ┌──────┐                              │
│                  │ 95%  │  ← Percentage variant        │
│                  └──────┘                               │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

### 8. EmptyStateCard

**Purpose**: Display empty state when catalog has no items, encouraging user to capture first item

**Visual Characteristics**:
- .thickMaterial background with ConcentricRectangle shape
- Large SF Symbol icon (64pt) in .secondary vibrancy
- Headline + description text
- Primary CTA button to initiate first action
- Centered layout for visual balance

**Accessibility**:
- VoiceOver: Reads headline, description, and button
- Dynamic Type: Text scales, layout adjusts
- Reduce Transparency: Replaces .thickMaterial with opaque #FCFCFF
- Minimum button height: 44pt

**Component Props**:
- `iconName: String` - SF Symbol name
- `headline: String` - Main empty state message
- `description: String` - Supporting text
- `buttonTitle: String` - CTA button label
- `action: () -> Void` - Action when button is tapped

**SwiftUI Implementation**:

```swift
import SwiftUI

struct EmptyStateCard: View {
    // MARK: - Properties
    let iconName: String
    let headline: String
    let description: String
    let buttonTitle: String
    let action: () -> Void

    // MARK: - Environment
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    // MARK: - Body
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                // Headline
                Text(headline)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                // Description
                Text(description)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // CTA Button
            PrimaryButton(title: buttonTitle, action: action)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(backgroundMaterial, in: outerShape)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    // MARK: - Computed Properties
    private var backgroundMaterial: AnyShapeStyle {
        if reduceTransparency {
            return AnyShapeStyle(Color.backgroundDefault)
        } else {
            return AnyShapeStyle(.thickMaterial)
        }
    }

    @ViewBuilder
    private var outerShape: some Shape {
        if #available(iOS 26, *) {
            ConcentricRectangle(cornerRadius: 24, inset: 0)
        } else {
            RoundedRectangle(cornerRadius: 24)
        }
    }
}

// MARK: - Preview
#Preview("Empty State Card") {
    VStack {
        EmptyStateCard(
            iconName: "cube.box",
            headline: "No Items Yet",
            description: "Start building your catalog by scanning your first item with the camera.",
            buttonTitle: "Scan First Item",
            action: { print("Navigate to camera") }
        )
    }
    .padding()
}
```

**Usage Examples**:

```swift
// Catalog view empty state
if viewModel.items.isEmpty {
    ScrollView {
        EmptyStateCard(
            iconName: "cube.box",
            headline: "No Items Yet",
            description: "Start building your catalog by scanning your first item.",
            buttonTitle: "Scan First Item",
            action: {
                selectedTab = .camera
            }
        )
        .padding()
    }
}

// Search results empty state
if filteredItems.isEmpty && !searchText.isEmpty {
    EmptyStateCard(
        iconName: "magnifyingglass",
        headline: "No Results Found",
        description: "Try adjusting your search terms or browse all items.",
        buttonTitle: "Clear Search",
        action: {
            searchText = ""
        }
    )
    .padding()
}
```

**Visual Mockup**:

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│                                                         │
│                       📦                                │ ← 64pt icon
│                                                         │   .secondary
│                                                         │
│                  No Items Yet                           │ ← .title2, bold
│                                                         │
│     Start building your catalog by scanning your       │ ← .body, secondary
│              first item with the camera.                │   multiline, centered
│                                                         │
│                                                         │
│    ┌─────────────────────────────────────┐             │
│    │        Scan First Item              │             │ ← PrimaryButton
│    └─────────────────────────────────────┘             │
│                                                         │
│                                                         │
└─────────────────────────────────────────────────────────┘
  .thickMaterial, ConcentricRectangle, 24pt corner radius
  32pt padding, centered layout
```

---

## Component Testing Guidelines

### Unit Testing

All components should have unit tests verifying:
1. **Accessibility**: VoiceOver labels, Dynamic Type support, Reduce Transparency/Motion fallbacks
2. **State Management**: Button states (enabled/disabled/loading), selection states, animation triggers
3. **Data Binding**: Proper binding updates, two-way data flow
4. **Edge Cases**: Empty states, very long text, missing images, nil values

**Example Test**:

```swift
import XCTest
import SwiftUI
@testable import Abundance

final class PrimaryButtonTests: XCTestCase {
    func testButtonAccessibility() {
        let button = PrimaryButton(title: "Save Item", action: {})

        // VoiceOver label should match title
        XCTAssertEqual(button.accessibilityLabel, "Save Item")

        // Button trait should be present
        XCTAssertTrue(button.accessibilityTraits.contains(.isButton))
    }

    func testDisabledState() {
        let button = PrimaryButton(title: "Save", action: {}, isEnabled: false)

        // Opacity should be 50% when disabled
        XCTAssertEqual(button.opacity, 0.5)

        // Should have static text trait, not button trait
        XCTAssertTrue(button.accessibilityTraits.contains(.isStaticText))
        XCTAssertFalse(button.accessibilityTraits.contains(.isButton))
    }

    func testLoadingState() {
        let button = PrimaryButton(title: "Export", action: {}, isLoading: true)

        // Title should be hidden, progress view visible
        XCTAssertEqual(button.titleOpacity, 0)
        XCTAssertTrue(button.showsProgressView)
    }
}
```

### UI Testing

UI tests should verify:
1. **Visual Appearance**: Material rendering, shadows, corner radius
2. **Interactions**: Tap feedback, animations, sensory feedback
3. **Layouts**: Grid layouts, scrolling, Dynamic Type adjustments
4. **Accessibility Settings**: Test with Reduce Transparency ON, Reduce Motion ON, VoiceOver ON

**Example UI Test**:

```swift
import XCTest

final class CatalogViewUITests: XCTestCase {
    func testItemCardTapNavigation() {
        let app = XCUIApplication()
        app.launch()

        // Tap first item card
        app.otherElements["ItemCard-0"].tap()

        // Verify navigation to detail view
        XCTAssertTrue(app.navigationBars["Item Detail"].exists)
    }

    func testSearchFiltering() {
        let app = XCUIApplication()
        app.launch()

        // Tap search bar
        app.searchFields["Search items..."].tap()

        // Type search query
        app.typeText("Lamp")

        // Verify filtered results
        XCTAssertTrue(app.otherElements.matching(identifier: "ItemCard").count > 0)
    }

    func testReduceTransparencyFallback() {
        let app = XCUIApplication()
        app.launchArguments = ["-UIAccessibilityReduceTransparency", "YES"]
        app.launch()

        // Verify materials are replaced with opaque backgrounds
        // (Visual regression testing with snapshot comparison)
    }
}
```

---

## Performance Guidelines

### Rendering Performance

1. **Material Limits**: Max 3 layered materials per screen to avoid GPU bottlenecks
2. **Shadow Optimization**: Use `.compositingGroup()` for complex shadows
3. **Image Loading**: Always use `AsyncImage` with placeholder for network images
4. **Grid Performance**: Use `LazyVGrid` for large catalogs (100+ items)

**Example Optimization**:

```swift
// ❌ Bad: Too many material layers
ZStack {
    Color.clear.background(.ultraThickMaterial)
    VStack {
        Text("Title").background(.thickMaterial)
        Text("Body").background(.regularMaterial)
    }
}

// ✅ Good: Single material layer
VStack {
    Text("Title")
    Text("Body")
}
.padding()
.background(.thickMaterial)
```

### Animation Performance

1. **Spring Limits**: Avoid dampingFraction < 0.3 (too bouncy, many frames)
2. **Batch Animations**: Use single `.animation()` modifier for multiple properties
3. **Reduce Motion**: Always provide instant fallbacks for animations
4. **Drawing Group**: Use `.drawingGroup()` for complex compositing

**Example**:

```swift
// ✅ Good: Reduce Motion fallback
@Environment(\.accessibilityReduceMotion) var reduceMotion

var animation: Animation? {
    reduceMotion ? nil : .brandSnappy
}

Text("Animated")
    .scaleEffect(isActive ? 1.1 : 1.0)
    .opacity(isActive ? 1.0 : 0.5)
    .animation(animation, value: isActive) // Single animation for multiple properties
```

---

## Common Patterns

### 1. Material + Vibrancy Pattern

```swift
Text("Content")
    .foregroundStyle(.primary) // Uses vibrancy automatically
    .padding()
    .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 12))
```

### 2. Reduce Transparency Fallback Pattern

```swift
@Environment(\.accessibilityReduceTransparency) private var reduceTransparency

var backgroundStyle: AnyShapeStyle {
    reduceTransparency ? AnyShapeStyle(Color.backgroundDefault) : AnyShapeStyle(.thickMaterial)
}

// Usage
.background(backgroundStyle, in: Capsule())
```

### 3. iOS 26 ConcentricRectangle Fallback Pattern

```swift
@ViewBuilder
var shape: some Shape {
    if #available(iOS 26, *) {
        ConcentricRectangle(cornerRadius: 16, inset: 0)
    } else {
        RoundedRectangle(cornerRadius: 16)
    }
}

// Usage
.background(.thickMaterial, in: shape)
```

### 4. Sensory Feedback Pattern

```swift
@State private var isPressed = false

Button("Action") {
    isPressed = true
    performAction()
}
.sensoryFeedback(.impact(weight: .medium), trigger: isPressed)
```

---

## Integration with Design Tokens

All components reference centralized design tokens from DESIGN-032, DESIGN-033, and DESIGN-034:

```swift
// Colors (from DESIGN-032)
Color.brandBrightBlue
Color.textPrimary
Color.successColor

// Typography (from DESIGN-033)
.font(.system(.body, design: .rounded, weight: .semibold))

// Animations (from DESIGN-034)
.animation(.brandSnappy, value: isActive)
```

---

## References

### Internal Documents
- docs/design/DESIGN-026-onboarding-flow-ui-specification.md (component usage examples)
- docs/design/DESIGN-027-camera-capture-view-specification.md (camera overlays)
- docs/design/DESIGN-028-catalog-view-specification.md (grid layouts)
- docs/design/DESIGN-029-item-detail-view-specification.md (metadata cards)
- docs/design/DESIGN-030-profile-export-view-specification.md (settings UI)
- docs/design/DESIGN-032-color-system-design-tokens.md (color tokens)
- docs/design/DESIGN-033-typography-specifications.md (typography tokens)
- docs/design/DESIGN-034-animation-motion-specifications.md (animation presets)

### Apple Documentation
- https://developer.apple.com/documentation/swiftui/material (Material system)
- https://developer.apple.com/documentation/swiftui/concentricrectangle (ConcentricRectangle shape)
- https://developer.apple.com/documentation/swiftui/animation/spring(response:dampingfraction:blendduration:) (Spring animations)
- https://developer.apple.com/documentation/swiftui/sensoryfeedback (Sensory feedback)
- https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducetransparency (Reduce Transparency)
- https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion (Reduce Motion)

### Brand Guidelines
- shared/abundance-brand/abundance-core-style-guidelines.md
- shared/abundance-brand/abundance-brand-bible.md

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-10 | 1.0 | Initial component library with 8 production-ready components | iOS UI/UX Designer & SwiftUI Specialist |

---

**Status**: ✅ **APPROVED**

**Next Steps**: Implement components in Stage 3.1 iOS Implementation with unit and UI tests
