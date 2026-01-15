import SwiftUI
import Core
import Persistence

public struct InventoryView: View {
    // Plain var for @Observable type - SwiftUI tracks changes automatically
    var viewModel: InventoryViewModel
    @State private var searchText: String = ""
    var onOpenCamera: (() -> Void)?

    public init(
        viewModel: InventoryViewModel = InventoryViewModel(),
        onOpenCamera: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onOpenCamera = onOpenCamera
    }

    /// Filters items based on search text matching any searchable text field.
    /// Searches: category, color, material, condition (and name, subCategory, brand, model after Stage 3.1)
    /// Uses case-insensitive, locale-aware matching per Apple best practices.
    private var filteredItems: [Item] {
        guard !searchText.isEmpty else {
            return viewModel.items
        }

        return viewModel.items.filter { item in
            item.matchesSearchQuery(searchText)
        }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar at top when items exist
                if !viewModel.items.isEmpty && !viewModel.isLoading {
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                }

                Group {
                    if viewModel.isLoading {
                        ProgressView("Loading items...")
                    } else if let error = viewModel.error {
                        ErrorView(message: error, retry: {
                            Task { await viewModel.loadItems() }
                        })
                    } else if viewModel.items.isEmpty {
                        EmptyInventoryView(onOpenCamera: onOpenCamera)
                    } else if filteredItems.isEmpty {
                        // No search results
                        ContentUnavailableView.search(text: searchText)
                    } else {
                        ItemGridView(items: filteredItems)
                    }
                }
            }
            .navigationTitle("Inventory")
            .task {
                await viewModel.loadItems()
            }
        }
    }
}

// MARK: - Subviews

private struct ItemGridView: View {
    let items: [Item]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(items) { item in
                    NavigationLink {
                        ItemDetailView(item: item)
                    } label: {
                        ItemCard(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}

private struct EmptyInventoryView: View {
    var onOpenCamera: (() -> Void)?

    var body: some View {
        EmptyStateCard(
            iconName: "tray",
            headline: "No Items Yet",
            description: "Capture items with the camera to get started",
            buttonTitle: "Open Camera",
            action: {
                onOpenCamera?()
            }
        )
        .padding()
    }
}

private struct ErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundStyle(.red)
            Text("Error Loading Items")
                .font(.title2)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry", action: retry)
                .buttonStyle(.bordered)
        }
        .padding()
    }
}
