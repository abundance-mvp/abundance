# DESIGN-029: Item Detail View Specification

**Created**: 2025-11-10
**Stage**: 2.6 - iOS UI/UX Design & Liquid Glass Integration
**Status**: Approved
**References**:
- docs/plans/PLAN-SUMMARY-stage-2.6.md
- docs/design/DESIGN-026-onboarding-flow-ui-specification.md
- docs/design/DESIGN-028-catalog-view-specification.md
- docs/adr/ADR-010-swiftui-architecture-pattern.md
- shared/abundance-brand/abundance-brand-bible.md

---

## Overview

This document specifies the Item Detail View for the Abundance iOS app, which displays comprehensive metadata for a single cataloged item. The view features a parallax-scrolling hero image, glass metadata cards, AI confidence indicators, and an edit mode sheet. It embodies the Liquid Glass design language with layered depth simulation, spring animations, and accessibility support.

**User Journey**: Catalog View → Tap Item Card → Item Detail View → (Optional) Tap Edit → Edit Sheet → Save → Detail View Updates

**Success Criteria**:
- Detail view loads with < 200ms transition from Catalog
- Parallax scroll effect provides visual depth at 60 FPS
- AI confidence indicator communicates reliability clearly
- Edit mode allows inline metadata updates with validation
- Firestore writes save changes with < 500ms latency

---

## Layout

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                   │
│                    [Hero Image - Parallax Scroll]                │
│                       Top 50% of screen                          │
│                    Cropped object photo                          │
│                    Aspect fill, no letterbox                     │
│                                                                   │
│   [< Back]                          [AI Confidence • Top Right]  │
│                                                                   │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │                                                               │ │
│ │          [Glass Metadata Card - .ultraThickMaterial]         │ │
│ │                  Overlaps hero by 60pt                        │ │
│ │                                                               │ │
│ │  "Camping Tent"                          [Edit - Pencil]     │ │
│ │  28pt, SF Pro Rounded Bold                                    │ │
│ │                                                               │ │
│ │  [Camping Gear - Category Pill Badge]                        │ │
│ │  Coral Orange background, 12pt                                │ │
│ │                                                               │ │
│ │  ─────────────────────────────────────────────────────        │ │
│ │                                                               │ │
│ │  Est. Value:  $89                                             │ │
│ │  20pt, Mint Green, SF Pro Rounded Bold                        │ │
│ │                                                               │ │
│ │  Location:    Garage                                          │ │
│ │  Color:       Green                                           │ │
│ │  Material:    Nylon                                           │ │
│ │  Condition:   Good                                            │ │
│ │                                                               │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Components

### Hero Image

**Purpose**: Display cropped object photo from Layer 1 Vision Framework processing

**Specifications**:
- **Position**: Top 40% of screen (0-40% vertical space)
- **Source**: AsyncImage from Firebase Storage URL
- **Aspect Ratio**: Aspect fill (no letterboxing, full width)
- **Scroll Behavior**: Parallax effect (image scrolls slower than content, 0.5x speed)
- **Placeholder**: ProgressView (spinning indicator) while loading
- **Error State**: SF Symbol "photo" 80pt, .tertiary vibrancy

**Parallax Implementation**:
```swift
struct ParallaxHeroImage: View {
    let imageURL: URL?
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .offset(y: scrollOffset * 0.5) // Parallax: scroll slower than content
                case .failure:
                    Image(systemName: "photo")
                        .font(.system(size: 80))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                @unknown default:
                    EmptyView()
                }
            }
            .clipped()
        }
        .frame(height: UIScreen.main.bounds.height * 0.4)
    }
}
```

**Scroll Tracking**:
```swift
ScrollView {
    GeometryReader { geometry in
        Color.clear
            .preference(key: ScrollOffsetKey.self, value: geometry.frame(in: .named("scroll")).minY)
    }
    .frame(height: 0)

    // Content...
}
.coordinateSpace(name: "scroll")
.onPreferenceChange(ScrollOffsetKey.self) { offset in
    scrollOffset = offset
}
```

**Accessibility**:
- VoiceOver: "[Item name] photo. Image. Swipe to scroll for details."
- Reduce Motion: Disable parallax, use static image

---

### Glass Metadata Card

**Purpose**: Primary container for item metadata, overlaps hero image for depth effect

**Specifications**:
- **Shape**: ConcentricRectangle(cornerRadius: 24, inset: 0) [iOS 26+]
- **Fallback**: RoundedRectangle(cornerRadius: 24) [iOS 25]
- **Material**: .ultraThickMaterial
- **Position**: Overlaps hero image by 40pt (creates layered depth)
- **Padding**: 24pt all sides (internal content padding)
- **Shadow**: Soft shadow (radius 16, y offset -8, opacity 0.15)
- **Margin**: 16pt from screen edges (left/right)

**Layout**:
1. **Item Name** (top):
   - 28pt SF Pro Rounded Bold (Dynamic Type Large Title)
   - .primary vibrancy
   - 2 lines max with truncation

2. **AI Confidence Badge** (below name, 8pt spacing):
   - Capsule pill shape
   - Color-coded: Green (high), Yellow (medium), Red (low)
   - Icon + percentage text

3. **Metadata Rows** (vertical stack, 12pt spacing):
   - Label: 15pt SF Pro Rounded Regular, .secondary vibrancy
   - Value: 15pt SF Pro Rounded Semibold, .primary vibrancy
   - Divider: 1pt, .tertiary color, between rows

4. **AI Reasoning Accordion** (bottom, collapsible):
   - Chevron icon (right/down states)
   - 15pt SF Pro Rounded Regular, .secondary vibrancy
   - Expandable content with spring animation

**SwiftUI Implementation**:
```swift
struct GlassMetadataCard: View {
    let item: CatalogItem
    @State private var isReasoningExpanded = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Item Name
            Text(item.name)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(2)

            // AI Confidence Badge
            if let confidence = item.aiConfidence {
                ConfidenceBadge(confidence: confidence)
            }

            Divider()
                .background(.tertiary)

            // Metadata Rows
            MetadataRow(label: "Category", value: item.category)
            if let location = item.location {
                MetadataRow(label: "Location", value: location)
            }
            if let value = item.estimatedValue {
                MetadataRow(label: "Est. Value", value: "$\(value, specifier: "%.2f")")
            }
            if let color = item.color {
                MetadataRow(label: "Color", value: color)
            }
            if let material = item.material {
                MetadataRow(label: "Material", value: material)
            }
            if let condition = item.condition {
                MetadataRow(label: "Condition", value: condition)
            }

            Divider()
                .background(.tertiary)

            // AI Reasoning Accordion
            if let reasoning = item.aiReasoning {
                DisclosureGroup(
                    isExpanded: $isReasoningExpanded,
                    content: {
                        Text(reasoning)
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    },
                    label: {
                        Text("AI Reasoning")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                )
                .animation(.brandSnappy, value: isReasoningExpanded)
            }
        }
        .padding(24)
        .background {
            if reduceTransparency {
                Color.backgroundDefault
            } else {
                if #available(iOS 26, *) {
                    ConcentricRectangle(cornerRadius: 24, inset: 0)
                        .fill(.ultraThickMaterial)
                } else {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThickMaterial)
                }
            }
        }
        .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: -8)
        .padding(.horizontal, 16)
        .offset(y: -40) // Overlap hero image
    }
}

struct MetadataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
        }
    }
}
```

---

### AI Confidence Indicator

**Purpose**: Communicate reliability of AI-generated metadata to user

**Specifications**:
- **Shape**: Capsule pill
- **Padding**: 8pt horizontal, 6pt vertical
- **Icon**: SF Symbol, 14pt
- **Text**: "[Confidence level] • [Percentage]%" (12pt SF Pro Rounded Semibold)
- **Color-Coding**:
  - **High (80-100%)**: Green (#34C759) background at 0.2 opacity, green icon/text
  - **Medium (60-79%)**: Yellow (#FFD60A) background at 0.2 opacity, yellow icon/text
  - **Low (<60%)**: Red (#FF3B30) background at 0.2 opacity, red icon/text

**Icons**:
- High: "checkmark.circle.fill"
- Medium: "exclamationmark.triangle.fill"
- Low: "questionmark.circle.fill"

**SwiftUI Implementation**:
```swift
struct ConfidenceBadge: View {
    let confidence: Float

    var level: String {
        if confidence >= 0.8 { return "High" }
        else if confidence >= 0.6 { return "Medium" }
        else { return "Low" }
    }

    var color: Color {
        if confidence >= 0.8 { return .green }
        else if confidence >= 0.6 { return .yellow }
        else { return .red }
    }

    var iconName: String {
        if confidence >= 0.8 { return "checkmark.circle.fill" }
        else if confidence >= 0.6 { return "exclamationmark.triangle.fill" }
        else { return "questionmark.circle.fill" }
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.system(size: 14))
                .foregroundStyle(color)

            Text("\(level) • \(Int(confidence * 100))%")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(color.opacity(0.2), in: Capsule())
        .accessibilityLabel("AI confidence: \(level), \(Int(confidence * 100))%")
    }
}
```

---

### Edit Button

**Purpose**: Navigate to edit mode sheet for metadata updates

**Specifications**:
- **Type**: Icon button (SF Symbol "pencil")
- **Position**: Top-right, 16pt from safe area
- **Size**: 24pt icon
- **Color**: .primary vibrancy
- **Background**: Circle, 44pt diameter, .ultraThickMaterial
- **Tap Target**: 44x44pt (iOS HIG)

**SwiftUI Implementation**:
```swift
Button {
    showEditSheet = true
} label: {
    Image(systemName: "pencil")
        .font(.system(size: 24))
        .foregroundStyle(.primary)
        .frame(width: 44, height: 44)
        .background(.ultraThickMaterial, in: Circle())
}
.accessibilityLabel("Edit item")
.accessibilityHint("Opens edit sheet to modify item details")
```

---

### Edit Sheet (Modal)

**Purpose**: Inline editing of item metadata with validation and save/cancel actions

**Specifications**:
- **Presentation**: Sheet with .large detent
- **Background**: .ultraThickMaterial
- **Corner Radius**: 24pt (presentationCornerRadius modifier)
- **Interaction**: Background interaction enabled (can scroll detail view behind sheet)

**Layout**:
- **Navigation Bar**:
  - Title: "Edit Item" (Large Title)
  - Cancel button (leading): Dismisses without saving
  - Save button (trailing): Validates and saves changes

- **Form Sections**:
  1. **Name**: TextField, required, 1-100 characters
  2. **Category**: Picker with predefined categories
  3. **Location**: Picker with user-defined locations
  4. **Estimated Value**: NumberField with currency formatter
  5. **Attributes**: Color, Material, Condition (chips with multi-select)

**SwiftUI Implementation**:
```swift
struct ItemEditSheet: View {
    @Binding var item: CatalogItem
    @Environment(\.dismiss) private var dismiss
    @State private var editedItem: CatalogItem
    @State private var isSaving = false

    init(item: Binding<CatalogItem>) {
        _item = item
        _editedItem = State(initialValue: item.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Name", text: $editedItem.name)
                        .font(.system(.body, design: .rounded))

                    Picker("Category", selection: $editedItem.category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }

                    Picker("Location", selection: $editedItem.location) {
                        ForEach(locations, id: \.self) { location in
                            Text(location).tag(location as String?)
                        }
                    }
                }

                Section("Value") {
                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("Estimated Value", value: $editedItem.estimatedValue, format: .number)
                            .keyboardType(.decimalPad)
                            .font(.system(.body, design: .rounded))
                    }
                }

                Section("Attributes") {
                    TextField("Color", text: Binding(
                        get: { editedItem.color ?? "" },
                        set: { editedItem.color = $0.isEmpty ? nil : $0 }
                    ))

                    TextField("Material", text: Binding(
                        get: { editedItem.material ?? "" },
                        set: { editedItem.material = $0.isEmpty ? nil : $0 }
                    ))

                    Picker("Condition", selection: $editedItem.condition) {
                        Text("Not specified").tag(nil as String?)
                        Text("Excellent").tag("Excellent" as String?)
                        Text("Good").tag("Good" as String?)
                        Text("Fair").tag("Fair" as String?)
                        Text("Poor").tag("Poor" as String?)
                    }
                }
            }
            .scrollContentBackground(.hidden) // Remove default Form background
            .background(.ultraThickMaterial)
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        Task {
                            await saveChanges()
                        }
                    }
                    .foregroundStyle(.primary)
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .overlay {
                if isSaving {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThickMaterial)
                }
            }
        }
        .presentationDetents([.large])
        .presentationBackgroundInteraction(.enabled(upThrough: .large))
        .presentationCornerRadius(24)
    }

    var isValid: Bool {
        !editedItem.name.isEmpty && editedItem.name.count <= 100
    }

    func saveChanges() async {
        isSaving = true
        defer { isSaving = false }

        // Firestore write
        item = editedItem
        dismiss()
    }

    let categories = ["Tools", "Camping Gear", "Kitchen", "Electronics", "Clothing", "Other"]
    let locations = ["Garage", "Kitchen", "Bedroom", "Living Room", "Storage", "Car"]
}
```

**Validation**:
- **Name**: Required, 1-100 characters
- **Estimated Value**: Optional, > 0 if provided
- **Save button**: Disabled until validation passes

**Accessibility**:
- VoiceOver: "Edit Item. Sheet. Cancel button. Save button. Name field. Category picker."
- Dynamic Type: All text scales, Form adjusts row heights
- Reduce Transparency: Replace .ultraThickMaterial with opaque backgroundDefault

---

## State Management

### ItemDetailViewModel

**MVVM Pattern** (ADR-010):

```swift
import SwiftUI
import Combine

@MainActor
class ItemDetailViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var item: CatalogItem
    @Published var isEditing: Bool = false
    @Published var isSaving: Bool = false
    @Published var error: ItemDetailError?

    // MARK: - Dependencies

    private let repository: CatalogRepositoryProtocol

    // MARK: - Initialization

    init(item: CatalogItem, repository: CatalogRepositoryProtocol) {
        self.item = item
        self.repository = repository
    }

    // MARK: - Public Methods

    func saveItem(_ updatedItem: CatalogItem) async {
        isSaving = true
        defer { isSaving = false }

        do {
            try await repository.updateItem(updatedItem)
            item = updatedItem
            isEditing = false
        } catch {
            self.error = .saveFailed(error)
        }
    }

    func deleteItem() async {
        do {
            try await repository.deleteItem(id: item.id)
            // Navigate back to Catalog
        } catch {
            self.error = .deleteFailed(error)
        }
    }
}

enum ItemDetailError: Error, LocalizedError {
    case saveFailed(Error)
    case deleteFailed(Error)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save changes: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete item: \(error.localizedDescription)"
        }
    }
}
```

---

## SwiftUI Implementation Pattern

### ItemDetailView (Main View)

```swift
import SwiftUI

struct ItemDetailView: View {
    @StateObject private var viewModel: ItemDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(item: CatalogItem, repository: CatalogRepositoryProtocol = FirestoreCatalogRepository()) {
        _viewModel = StateObject(wrappedValue: ItemDetailViewModel(item: item, repository: repository))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Image with Parallax
                ParallaxHeroImage(imageURL: viewModel.item.imageURL)

                // Glass Metadata Card
                GlassMetadataCard(item: viewModel.item)
                    .padding(.bottom, 24)
            }
        }
        .background(Color.backgroundDefault.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.isEditing = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 24))
                        .foregroundStyle(.primary)
                }
                .accessibilityLabel("Edit item")
            }
        }
        .sheet(isPresented: $viewModel.isEditing) {
            ItemEditSheet(item: $viewModel.item)
        }
        .alert(error: $viewModel.error)
    }
}
```

---

## Animations

### Hero Image Parallax

- Scroll offset tracked via GeometryReader preference key
- Image offset: `scrollOffset * 0.5` (slower than content)
- Smooth tracking with no lag (60 FPS)

### Metadata Card Entrance

- Slide up from bottom with brandDefault spring (0.4s response)
- Fade in with brandGentle spring (0.3s delay)

### AI Reasoning Accordion

- Expand/collapse with brandSnappy spring (0.3s response)
- Chevron rotation: 0° → 90° (right to down)

### Edit Sheet Presentation

- Sheet slides up with system default animation
- Background blur with brandGentle spring (0.4s)

---

## Accessibility

### VoiceOver

- **Hero image**: "[Item name] photo. Image. Swipe to scroll for details."
- **Item name**: "[Item name]. Heading."
- **AI confidence badge**: "AI confidence: High, 87%."
- **Metadata rows**: "Category, Camping Gear. Location, Garage."
- **AI reasoning**: "AI Reasoning. Disclosure button. Collapsed."
- **Edit button**: "Edit item. Button. Opens edit sheet to modify item details."

### Dynamic Type

- All text scales from `.xSmall` to `.xxxLarge`
- Metadata card height adjusts to fit scaled text
- Hero image height fixed (40% of screen)

### Reduce Transparency

- Replace .ultraThickMaterial with opaque `backgroundDefault` (#FCFCFF)
- Metadata card: Add 10% black tint to differentiate from background

### Reduce Motion

- Disable parallax effect on hero image
- Use static image with fade-in animation
- Accordion expand/collapse uses instant transition

---

## Testing Checklist

### Functional Tests

- [ ] Detail view loads with < 200ms transition from Catalog
- [ ] Hero image displays with parallax scroll at 60 FPS
- [ ] Metadata card overlaps hero image by 40pt
- [ ] AI confidence badge color-coded correctly (green/yellow/red)
- [ ] Edit button navigates to edit sheet
- [ ] Edit sheet validates name (required, 1-100 characters)
- [ ] Save button saves changes to Firestore (< 500ms)
- [ ] Cancel button dismisses sheet without saving
- [ ] AI reasoning accordion expands/collapses with spring animation

### Accessibility Tests

- [ ] VoiceOver announces all elements with descriptive labels
- [ ] All text scales with Dynamic Type (XS to XXXL)
- [ ] Reduce Transparency replaces materials with opaque backgrounds
- [ ] Reduce Motion disables parallax, uses static image
- [ ] Edit button has 44x44pt tap target
- [ ] Form fields in edit sheet are keyboard-navigable

### Brand Compliance

- [ ] Metadata card uses ConcentricRectangle on iOS 26, RoundedRectangle on iOS 25
- [ ] AI confidence badge uses system colors (green, yellow, red) with 0.2 opacity
- [ ] Edit sheet uses .ultraThickMaterial background
- [ ] All animations use brand spring presets (brandSnappy, brandDefault, brandGentle)
- [ ] Typography uses SF Pro Rounded at specified weights

### Performance Tests

- [ ] Parallax scroll maintains 60 FPS
- [ ] Edit sheet presents without lag
- [ ] Firestore write completes in < 500ms
- [ ] Hero image loads progressively (placeholder → image)

---

## References

- **Architecture**: docs/adr/ADR-010-swiftui-architecture-pattern.md (MVVM)
- **Component Library**: docs/design/DESIGN-031-swiftui-component-library.md
- **Color System**: docs/design/DESIGN-032-color-system-design-tokens.md
- **Animation Presets**: docs/design/DESIGN-034-animation-motion-specifications.md
- **Catalog View**: docs/design/DESIGN-028-catalog-view-specification.md

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-10 | 1.0 | Initial item detail view specification | iOS UI/UX Designer |

---

**Status**: ✅ **APPROVED**

**Implementation Ready**: Item detail view specified with parallax hero image, glass metadata card, AI confidence indicator, edit sheet, and complete accessibility support.
