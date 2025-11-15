# DESIGN-028: Catalog View Specification

**Created**: 2025-11-10
**Stage**: 2.6 - iOS UI/UX Design & Liquid Glass Integration
**Status**: Approved
**References**:
- docs/plans/PLAN-SUMMARY-stage-2.6.md
- docs/design/DESIGN-026-onboarding-flow-ui-specification.md
- docs/adr/ADR-010-swiftui-architecture-pattern.md
- docs/adr/ADR-012-state-management-strategy.md
- shared/abundance-brand/abundance-brand-bible.md

---

## Overview

This document specifies the Catalog View for the Abundance iOS app, which displays the user's collection of cataloged household items in a scrollable grid layout. The view is the primary screen of the app, providing real-time synchronization with Firestore, search functionality, and navigation to item details. It embodies the Liquid Glass design language with glass material cards, floating tab bar, and spring-based animations.

**User Journey**: Sign In → Catalog View (main screen) → Tap Item Card → Item Detail View

**Success Criteria**:
- Grid displays items with < 300ms load time for first 20 items
- Real-time Firestore sync updates catalog without user action
- Search filters items by name, category, or location with < 100ms latency
- Empty state encourages first capture with clear CTA
- Scroll performance maintains 60 FPS with 100+ items

---

## Layout

```
┌─────────────────────────────────────────────────────────────────┐
│                         Status Bar                               │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                  [Search Bar - Capsule]                   │   │
│  │              .thin material, magnifyingglass icon         │   │
│  │                     .secondary vibrancy                    │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌───────────────────┐  ┌───────────────────┐                   │
│  │                   │  │                   │                   │
│  │   [Item Card 1]   │  │   [Item Card 2]   │                   │
│  │   Photo, name,    │  │   Photo, name,    │                   │
│  │   category, value │  │   category, value │                   │
│  │                   │  │                   │                   │
│  └───────────────────┘  └───────────────────┘                   │
│                                                                   │
│  ┌───────────────────┐  ┌───────────────────┐                   │
│  │                   │  │                   │                   │
│  │   [Item Card 3]   │  │   [Item Card 4]   │                   │
│  │   Photo, name,    │  │   Photo, name,    │                   │
│  │   category, value │  │   category, value │                   │
│  │                   │  │                   │                   │
│  └───────────────────┘  └───────────────────┘                   │
│                                                                   │
│                          ...                                     │
│                                                                   │
│                                                                   │
│                                                                   │
│                  [Floating Tab Bar - Pill Shape]                 │
│              Catalog • Camera • Profile                          │
│              .regular material, sensory feedback                 │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Components

### Search Bar

**Purpose**: Filter catalog items by name, category, or location

**Specifications**:
- **Shape**: Capsule
- **Material**: .thinMaterial
- **Height**: 44pt (minimum tap target)
- **Padding**: 16pt horizontal from screen edges
- **Icon**: SF Symbol "magnifyingglass", 16pt, .secondary vibrancy
- **Placeholder**: "Search items..." (.tertiary vibrancy)
- **Text**: 17pt SF Pro Rounded Regular (Dynamic Type Body)
- **Clear Button**: SF Symbol "xmark.circle.fill", appears when text entered

**Position**: Top safe area + 8pt, pinned (doesn't scroll with grid)

**Behavior**:
- Tap → keyboard appears, cursor blinks
- Type → filter items in real-time (no search button, live filtering)
- Clear button → clears text, shows all items
- Dismiss keyboard → tap outside search bar or scroll grid

**SwiftUI Implementation**:
```swift
struct SearchBar: View {
    @Binding var searchText: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)

            TextField("Search items...", text: $searchText)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.primary)
                .focused($isFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.thinMaterial, in: Capsule())
        .padding(.horizontal, 16)
        .animation(.brandSnappy, value: searchText.isEmpty)
    }
}
```

**Accessibility**:
- VoiceOver: "Search items. Search field. Search by name, category, or location."
- Dynamic Type: Text scales, height adjusts to maintain tap target
- Reduce Transparency: Replace .thinMaterial with opaque `backgroundDefault` with 5% black tint

---

### Item Card (Grid Cell)

**Purpose**: Display individual catalog item with photo, metadata, and navigation to detail view

**Specifications**:
- **Shape**: ConcentricRectangle(cornerRadius: 16, inset: 0) [iOS 26+]
- **Fallback**: RoundedRectangle(cornerRadius: 16) [iOS 25]
- **Material**: .thickMaterial
- **Shadow**: Soft shadow (radius 8, y offset 4, opacity 0.1)
- **Size**:
  - iPhone (Portrait): 2 columns, equal width with 12pt spacing
  - iPhone (Landscape): 3 columns
  - iPad (Portrait): 3 columns
  - iPad (Landscape): 4 columns
- **Aspect Ratio**: 3:4 (portrait card)

**Layout**:
1. **Hero Image** (top 60%):
   - AsyncImage from Firebase Storage URL
   - Aspect fill, cropped to fit
   - Corner radius: 12pt (inner corners concentric)
   - Placeholder: ProgressView while loading
   - Error state: SF Symbol "photo" with .tertiary color

2. **Metadata Section** (bottom 40%):
   - **Item Name**: 15pt SF Pro Rounded Semibold, .primary vibrancy, 2 lines max
   - **Category Badge**: Capsule pill, Coral Orange (#FF9A6F) glow, 10pt SF Pro Rounded Medium
   - **Estimated Value**: 13pt SF Pro Rounded Bold, Mint Green (#B3FFE1), bottom-right

3. **AI Confidence Indicator** (top-right overlay):
   - Circle, 24pt diameter, .ultraThickMaterial
   - High (>80%): Green checkmark
   - Medium (60-80%): Yellow warning
   - Low (<60%): Red question mark
   - Hidden if no AI metadata yet

**SwiftUI Implementation**:
```swift
struct ItemCard: View {
    let item: CatalogItem
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero Image
            AsyncImage(url: item.imageURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 200)
            .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: 12,
                topTrailingRadius: 12
            ))
            .overlay(alignment: .topTrailing) {
                if let confidence = item.aiConfidence {
                    ConfidenceIndicator(confidence: confidence)
                        .padding(8)
                }
            }

            // Metadata Section
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack {
                    Text(item.category)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background {
                            Capsule()
                                .fill(Color.brandCoralOrange.opacity(0.2))
                                .shadow(color: Color.brandCoralOrange.opacity(0.3), radius: 4)
                        }

                    Spacer()

                    if let value = item.estimatedValue {
                        Text("$\(value, specifier: "%.0f")")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.brandMintGreen)
                    }
                }
            }
            .padding(12)
        }
        .background {
            if reduceTransparency {
                Color.backgroundDefault
            } else {
                if #available(iOS 26, *) {
                    ConcentricRectangle(cornerRadius: 16, inset: 0)
                        .fill(.thickMaterial)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.thickMaterial)
                }
            }
        }
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name), \(item.category), \(item.estimatedValue.map { "$\($0, specifier: "%.0f")" } ?? "no price")")
        .accessibilityAddTraits(.isButton)
    }
}

struct ConfidenceIndicator: View {
    let confidence: Float

    var iconName: String {
        if confidence >= 0.8 { return "checkmark.circle.fill" }
        else if confidence >= 0.6 { return "exclamationmark.triangle.fill" }
        else { return "questionmark.circle.fill" }
    }

    var color: Color {
        if confidence >= 0.8 { return .green }
        else if confidence >= 0.6 { return .yellow }
        else { return .red }
    }

    var body: some View {
        Circle()
            .fill(.ultraThickMaterial)
            .frame(width: 24, height: 24)
            .overlay {
                Image(systemName: iconName)
                    .font(.system(size: 12))
                    .foregroundStyle(color)
            }
            .accessibilityLabel("AI confidence: \(Int(confidence * 100))%")
    }
}
```

**Interaction**:
- **Tap**: Navigate to ItemDetailView (push navigation)
- **Long Press**: Context menu (Edit, Share, Delete)
- **Swipe**: Swipe to delete (red .ultraThickMaterial overlay, trash icon)

**Context Menu**:
```swift
.contextMenu {
    Button {
        // Navigate to edit sheet
    } label: {
        Label("Edit", systemImage: "pencil")
    }

    Button {
        // Share item via UIActivityViewController
    } label: {
        Label("Share", systemImage: "square.and.arrow.up")
    }

    Divider()

    Button(role: .destructive) {
        // Delete item with confirmation alert
    } label: {
        Label("Delete", systemImage: "trash")
    }
}
```

---

### Grid Layout

**Purpose**: Display items in responsive grid with optimal column count per device size

**Specifications**:
- **Type**: LazyVGrid (lazy loading for performance)
- **Columns**:
  - iPhone (Portrait): 2 columns, flexible width
  - iPhone (Landscape): 3 columns
  - iPad (Portrait): 3 columns
  - iPad (Landscape): 4 columns
- **Spacing**: 12pt horizontal and vertical
- **Padding**: 16pt from screen edges
- **Scroll**: Vertical scroll with bounce effect

**SwiftUI Implementation**:
```swift
struct CatalogGridView: View {
    let items: [CatalogItem]
    @Environment(\.horizontalSizeClass) private var sizeClass

    var columns: [GridItem] {
        let count: Int
        if UIDevice.current.userInterfaceIdiom == .pad {
            count = sizeClass == .compact ? 3 : 4
        } else {
            count = sizeClass == .compact ? 2 : 3
        }
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(items) { item in
                    NavigationLink(value: item) {
                        ItemCard(item: item)
                    }
                    .buttonStyle(.plain) // Prevent default button highlighting
                }
            }
            .padding(16)
        }
        .refreshable {
            // Pull-to-refresh action
        }
    }
}
```

**Performance**:
- LazyVGrid only renders visible cells (memory efficient)
- AsyncImage caches via URLSession (reduces network calls)
- Firestore listener provides incremental updates (no full reload)

---

### Empty State

**Purpose**: Encourage first capture when catalog is empty

**Specifications**:
- **Background**: .regularMaterial card, ConcentricRectangle, 280pt width
- **Icon**: SF Symbol "tray", 80pt, .tertiary vibrancy
- **Headline**: "Your catalog is empty" (20pt SF Pro Rounded Bold, .primary vibrancy)
- **Body**: "Scan your first item to start cataloging" (15pt SF Pro Rounded Regular, .secondary vibrancy)
- **CTA Button**: "Capture Item" (PrimaryButton, Bright Blue glow)

**Position**: Center of screen (vertically and horizontally)

**SwiftUI Implementation**:
```swift
struct CatalogEmptyState: View {
    let onCapture: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "tray")
                .font(.system(size: 80))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Your catalog is empty")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("Scan your first item to start cataloging")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            PrimaryButton(title: "Capture Item", action: onCapture)
                .padding(.top, 16)
        }
        .padding(32)
        .frame(width: 280)
        .background(.regularMaterial, in: ConcentricRectangle(cornerRadius: 20, inset: 0))
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
    }
}
```

**Accessibility**:
- VoiceOver: "Your catalog is empty. Scan your first item to start cataloging. Capture Item, button."
- Reduce Transparency: Replace .regularMaterial with opaque `backgroundDefault`

---

### Floating Tab Bar

**Purpose**: Primary navigation between Catalog, Camera, and Profile screens

**Specifications**:
- **Shape**: Capsule (pill shape)
- **Material**: .regularMaterial
- **Position**: Bottom safe area + 16pt, centered horizontally
- **Width**: Fits content with 24pt horizontal padding
- **Height**: 60pt
- **Shadow**: Soft shadow (radius 12, y offset 4, opacity 0.2)

**Tabs**:
1. **Catalog**: SF Symbol "square.grid.2x2", "Catalog" label
2. **Camera**: SF Symbol "camera", "Camera" label (center, larger)
3. **Profile**: SF Symbol "person", "Profile" label

**States**:
- **Selected**: .primary vibrancy, 24pt icon
- **Unselected**: .secondary vibrancy, 20pt icon

**SwiftUI Implementation**:
```swift
struct FloatingTabBar: View {
    @Binding var selectedTab: Tab

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

    var body: some View {
        HStack(spacing: 40) {
            ForEach(Tab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: selectedTab == tab ? 24 : 20))
                            .foregroundStyle(selectedTab == tab ? .primary : .secondary)

                        Text(tab.rawValue)
                            .font(.system(.caption2, design: .rounded, weight: .medium))
                            .foregroundStyle(selectedTab == tab ? .primary : .tertiary)
                    }
                }
                .sensoryFeedback(.selection, trigger: selectedTab == tab)
                .accessibilityLabel(tab.rawValue)
                .accessibilityAddTraits(selectedTab == tab ? [.isSelected] : [])
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
        .padding(.bottom, 16)
        .animation(.brandSnappy, value: selectedTab)
    }
}
```

**Accessibility**:
- VoiceOver: "Catalog, tab, 1 of 3, selected" (announces tab role and position)
- Reduce Transparency: Replace .regularMaterial with opaque `backgroundDefault` with 10% black tint
- Reduce Motion: Disable spring animation, use instant selection feedback

---

### Loading State

**Purpose**: Display skeleton cards while Firestore loads initial data

**Specifications**:
- **Skeleton Cards**: Same size as ItemCard, .regularMaterial, no content
- **Animation**: Shimmer effect (gradient sweeps left to right, brandGentle spring)
- **Count**: 6 skeleton cards (fills typical screen)

**SwiftUI Implementation**:
```swift
struct SkeletonItemCard: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Skeleton image
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .frame(height: 200)
                .shimmer(isAnimating: isAnimating)

            VStack(alignment: .leading, spacing: 6) {
                // Skeleton name
                RoundedRectangle(cornerRadius: 4)
                    .fill(.regularMaterial)
                    .frame(height: 16)
                    .shimmer(isAnimating: isAnimating)

                HStack {
                    // Skeleton category
                    Capsule()
                        .fill(.regularMaterial)
                        .frame(width: 60, height: 20)

                    Spacer()

                    // Skeleton value
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.regularMaterial)
                        .frame(width: 40, height: 16)
                }
            }
            .padding(12)
        }
        .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 16))
        .onAppear {
            isAnimating = true
        }
    }
}

// Shimmer effect modifier
struct ShimmerModifier: ViewModifier {
    @Binding var isAnimating: Bool

    func body(content: Content) -> some View {
        content
            .overlay {
                LinearGradient(
                    colors: [.clear, .white.opacity(0.3), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: isAnimating ? 300 : -300)
                .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
            }
            .clipped()
    }
}

extension View {
    func shimmer(isAnimating: Bool) -> some View {
        modifier(ShimmerModifier(isAnimating: .constant(isAnimating)))
    }
}
```

---

## State Management

### CatalogViewModel

**MVVM Pattern** (ADR-010):

```swift
import SwiftUI
import Combine
import FirebaseFirestore

@MainActor
class CatalogViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var items: [CatalogItem] = []
    @Published var filteredItems: [CatalogItem] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var error: CatalogError?
    @Published var selectedTab: FloatingTabBar.Tab = .catalog

    // MARK: - Dependencies

    private let repository: CatalogRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    private var firestoreListener: ListenerRegistration?

    // MARK: - Computed Properties

    var displayedItems: [CatalogItem] {
        searchText.isEmpty ? items : filteredItems
    }

    var isEmpty: Bool {
        items.isEmpty && !isLoading
    }

    // MARK: - Initialization

    init(repository: CatalogRepositoryProtocol) {
        self.repository = repository
        observeSearchText()
    }

    // MARK: - Public Methods

    func fetchItems() async {
        isLoading = true
        defer { isLoading = false }

        do {
            items = try await repository.fetchItems()
        } catch {
            self.error = .fetchFailed(error)
        }
    }

    func observeItems() {
        // Real-time Firestore listener (Combine-based)
        firestoreListener = repository.observeItems { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let items):
                self.items = items
            case .failure(let error):
                self.error = .syncFailed(error)
            }
        }
    }

    func deleteItem(_ item: CatalogItem) async {
        do {
            try await repository.deleteItem(id: item.id)
            items.removeAll { $0.id == item.id }
        } catch {
            self.error = .deleteFailed(error)
        }
    }

    func refreshItems() async {
        await fetchItems()
    }

    // MARK: - Private Methods

    private func observeSearchText() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.filterItems(query: query)
            }
            .store(in: &cancellables)
    }

    private func filterItems(query: String) {
        guard !query.isEmpty else {
            filteredItems = items
            return
        }

        let lowercased = query.lowercased()
        filteredItems = items.filter { item in
            item.name.lowercased().contains(lowercased) ||
            item.category.lowercased().contains(lowercased) ||
            (item.location?.lowercased().contains(lowercased) ?? false)
        }
    }

    // MARK: - Cleanup

    deinit {
        firestoreListener?.remove()
    }
}

enum CatalogError: Error, LocalizedError {
    case fetchFailed(Error)
    case syncFailed(Error)
    case deleteFailed(Error)

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "Failed to load items: \(error.localizedDescription)"
        case .syncFailed(let error):
            return "Sync failed: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete item: \(error.localizedDescription)"
        }
    }
}
```

---

## SwiftUI Implementation Pattern

### CatalogView (Main View)

```swift
import SwiftUI

struct CatalogView: View {
    @StateObject private var viewModel: CatalogViewModel

    init(repository: CatalogRepositoryProtocol = FirestoreCatalogRepository()) {
        _viewModel = StateObject(wrappedValue: CatalogViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Main Content
                Group {
                    if viewModel.isLoading {
                        // Loading state
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 12) {
                                ForEach(0..<6, id: \.self) { _ in
                                    SkeletonItemCard()
                                }
                            }
                            .padding(16)
                        }
                    } else if viewModel.isEmpty {
                        // Empty state
                        CatalogEmptyState {
                            viewModel.selectedTab = .camera
                        }
                    } else {
                        // Grid of items
                        VStack(spacing: 0) {
                            SearchBar(searchText: $viewModel.searchText)
                                .padding(.top, 8)

                            CatalogGridView(items: viewModel.displayedItems)
                        }
                    }
                }

                // Floating Tab Bar
                FloatingTabBar(selectedTab: $viewModel.selectedTab)
            }
            .background(Color.backgroundDefault.ignoresSafeArea())
            .navigationTitle("Catalog")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.fetchItems()
                viewModel.observeItems()
            }
            .alert(error: $viewModel.error)
        }
    }
}
```

---

## Animations

### Grid Entrance Animation

- Items fade in with brandDefault spring (0.4s response)
- Staggered delay: 0.05s per item (max 1.0s total)

### Search Results Animation

- Filtered items cross-fade with brandSnappy spring (0.3s)
- Empty search results show with brandGentle spring (0.6s)

### Tab Switch Animation

- Selected tab icon scales to 1.1 with brandBouncy spring
- Unselected tabs scale to 1.0 with brandSnappy spring

### Pull-to-Refresh Animation

- Standard iOS pull-to-refresh (system default)
- Success haptic: `.success` on refresh complete

---

## Accessibility

### VoiceOver

- **Search bar**: "Search items. Search field. Search by name, category, or location."
- **Item card**: "[Item name], [category], [price]. Button. Opens item details."
- **Empty state**: "Your catalog is empty. Scan your first item to start cataloging. Capture Item, button."
- **Tab bar**: "Catalog, tab, 1 of 3, selected"

### Dynamic Type

- All text scales from `.xSmall` to `.xxxLarge`
- Item card height adjusts to fit scaled text
- Search bar height maintains minimum 44pt tap target

### Reduce Transparency

- Replace all materials with opaque `backgroundDefault` (#FCFCFF)
- Item cards: Add 5% black tint to differentiate from background
- Tab bar: Add 10% black tint

### Reduce Motion

- Disable staggered entrance animation
- Use instant fade-in for items
- Disable tab icon scale animation

---

## Testing Checklist

### Functional Tests

- [ ] Grid displays items in correct column count per device size
- [ ] Search filters items by name, category, location with < 100ms latency
- [ ] Empty state displays when catalog is empty
- [ ] Loading state displays skeleton cards while fetching data
- [ ] Real-time Firestore listener updates catalog without refresh
- [ ] Pull-to-refresh reloads items from Firestore
- [ ] Tap item card navigates to ItemDetailView
- [ ] Long press shows context menu (Edit, Share, Delete)
- [ ] Swipe to delete removes item with confirmation
- [ ] Tab bar switches between Catalog, Camera, Profile

### Accessibility Tests

- [ ] VoiceOver announces all items with name, category, price
- [ ] All text scales with Dynamic Type (XS to XXXL)
- [ ] Reduce Transparency replaces materials with opaque backgrounds
- [ ] Reduce Motion disables decorative animations
- [ ] Search bar has minimum 44pt tap target
- [ ] Tab bar buttons have accessible labels and traits

### Brand Compliance

- [ ] Item cards use ConcentricRectangle on iOS 26, RoundedRectangle on iOS 25
- [ ] Category badges use Coral Orange (#FF9A6F) with 0.2 opacity fill
- [ ] Estimated value uses Mint Green (#B3FFE1)
- [ ] Tab bar uses .regularMaterial with Capsule shape
- [ ] All animations use brand spring presets (brandSnappy, brandBouncy, brandGentle)
- [ ] Typography uses SF Pro Rounded at specified weights

### Performance Tests

- [ ] Grid maintains 60 FPS with 100+ items
- [ ] LazyVGrid lazy-loads cells (only visible cells rendered)
- [ ] AsyncImage caches images (no duplicate network calls)
- [ ] Search filtering completes in < 100ms
- [ ] Firestore listener updates without blocking UI thread

---

## References

- **Architecture**: docs/adr/ADR-010-swiftui-architecture-pattern.md (MVVM)
- **State Management**: docs/adr/ADR-012-state-management-strategy.md (Combine + async/await)
- **Component Library**: docs/design/DESIGN-031-swiftui-component-library.md
- **Color System**: docs/design/DESIGN-032-color-system-design-tokens.md
- **Animation Presets**: docs/design/DESIGN-034-animation-motion-specifications.md

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-10 | 1.0 | Initial catalog view specification | iOS UI/UX Designer |

---

**Status**: ✅ **APPROVED**

**Implementation Ready**: Catalog view specified with Firestore real-time sync, responsive grid layout, search functionality, and complete accessibility support.
