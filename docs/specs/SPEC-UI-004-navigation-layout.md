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
