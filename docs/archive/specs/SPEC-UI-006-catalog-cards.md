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
