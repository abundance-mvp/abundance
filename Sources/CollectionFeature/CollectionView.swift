import SwiftUI
import Core
import Persistence

public struct CollectionView: View {
    // Plain var for @Observable type - SwiftUI tracks changes automatically
    @Bindable var viewModel: CollectionViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isSelectionMode = false
    @State private var selectedItemIds: [String: Bool] = [:]
    @State private var itemToDelete: Item?
    @State private var showDeleteConfirmation = false
    @State private var showBulkDeleteConfirmation = false
    @State private var showDeleteErrorAlert = false
    @State private var showRefreshErrorAlert = false
    var onOpenCamera: (() -> Void)?

    public init(
        viewModel: CollectionViewModel = CollectionViewModel(),
        onOpenCamera: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onOpenCamera = onOpenCamera
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar at top when items exist
                if !viewModel.items.isEmpty && !viewModel.isLoading {
                    SearchBar(text: $viewModel.searchText)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                }

                Group {
                    if viewModel.isLoading {
                        ProgressView("Loading items...")
                            .accessibilityIdentifier("collection.loading")
                    } else if let error = viewModel.error {
                        ErrorView(message: error, retry: {
                            Task { await viewModel.loadItems() }
                        })
                    } else if viewModel.items.isEmpty {
                        EmptyCollectionView(onOpenCamera: onOpenCamera)
                            .accessibilityIdentifier("collection.emptyState")
                    } else if viewModel.filteredItems.isEmpty {
                        // No search results
                        ContentUnavailableView.search(text: viewModel.searchText)
                    } else {
                        ItemGridView(
                            items: viewModel.filteredItems,
                            isSelectionMode: isSelectionMode,
                            selectedItemIds: $selectedItemIds,
                            onRefresh: { item in
                                Task { await viewModel.refreshItem(item) }
                            },
                            onDeletePhoto: { item, index in
                                Task { await viewModel.deletePhoto(from: item, at: index) }
                            },
                            onDelete: { item in
                                itemToDelete = item
                                showDeleteConfirmation = true
                            }
                        )
                    }
                }

                // Multi-select toolbar at bottom
                if isSelectionMode && !selectedItemIds.isEmpty {
                    selectionToolbar
                }
            }
            .navigationTitle("Collection")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if !viewModel.items.isEmpty && !viewModel.isLoading {
                        Button(isSelectionMode ? "Done" : "Select") {
                            withAnimation(reduceMotion ? nil : .brandPress) {
                                isSelectionMode.toggle()
                                if !isSelectionMode {
                                    selectedItemIds.removeAll()
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(Color.accentPrimary)
                        .accessibilityIdentifier("collection.selectButton")
                        .accessibilityHint(
                            isSelectionMode
                                ? "Exit selection mode"
                                : "Enter selection mode to select multiple items"
                        )
                    }
                }
            }
            .task {
                await viewModel.loadItems()
            }
            // Single item delete confirmation
            .confirmationDialog(
                "Delete Item",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible,
                presenting: itemToDelete
            ) { item in
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteItem(item)
                    }
                }
                Button("Cancel", role: .cancel) {
                    itemToDelete = nil
                }
            } message: { item in
                let name = item.displayName
                Text("Are you sure you want to delete \"\(name)\"? This action cannot be undone.")
            }
            // Bulk delete confirmation
            .confirmationDialog(
                "Delete \(selectedItemIds.count) Items",
                isPresented: $showBulkDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All", role: .destructive) {
                    let idsToDelete = Set(selectedItemIds.keys)
                    // Clear selection state immediately with animation (before async work)
                    withAnimation(reduceMotion ? nil : .brandPress) {
                        isSelectionMode = false
                        selectedItemIds.removeAll()
                    }
                    Task {
                        await viewModel.deleteItems(ids: idsToDelete)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete \(selectedItemIds.count) items? This action cannot be undone.")
            }
            // Delete error alert
            .alert("Delete Failed", isPresented: $showDeleteErrorAlert) {
                Button("OK") {
                    viewModel.deleteError = nil
                }
            } message: {
                Text(viewModel.deleteError ?? "An error occurred")
            }
            .onChange(of: viewModel.deleteError) { _, newValue in
                showDeleteErrorAlert = newValue != nil
            }
            // Refresh error alert
            .alert("Refresh Failed", isPresented: $showRefreshErrorAlert) {
                Button("OK") {
                    viewModel.refreshError = nil
                }
            } message: {
                Text(viewModel.refreshError ?? "An error occurred")
            }
            .onChange(of: viewModel.refreshError) { _, newValue in
                showRefreshErrorAlert = newValue != nil
            }
        }
    }

    // MARK: - Selection Toolbar

    @ViewBuilder
    private var selectionToolbar: some View {
        HStack {
            Button {
                selectedItemIds.removeAll()
            } label: {
                Text("Deselect All")
                    .frame(minHeight: 44)
            }
            .accessibilityIdentifier("collection.deselectAllButton")

            Spacer()

            Button(role: .destructive) {
                showBulkDeleteConfirmation = true
            } label: {
                Label("Delete (\(selectedItemIds.count))", systemImage: "trash")
                    .frame(minHeight: 44)
            }
            .accessibilityIdentifier("collection.bulkDeleteButton")
            .disabled(selectedItemIds.isEmpty)
        }
        .padding()
        .abundanceCardStyle()
    }
}

// MARK: - Subviews

private struct ItemGridView: View {
    let items: [Item]
    let isSelectionMode: Bool
    @Binding var selectedItemIds: [String: Bool]
    let onRefresh: (Item) -> Void
    let onDeletePhoto: (Item, Int) -> Void
    let onDelete: (Item) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(items) { item in
                    if isSelectionMode {
                        // In selection mode, tap toggles selection
                        ItemCard(
                            item: item,
                            onTap: {
                                withAnimation(reduceMotion ? nil : .brandPress) {
                                    if selectedItemIds[item.id] == true {
                                        selectedItemIds[item.id] = nil
                                    } else {
                                        selectedItemIds[item.id] = true
                                    }
                                }
                            },
                            isSelectionMode: true,
                            isSelected: selectedItemIds[item.id] == true
                        )
                        .accessibilityIdentifier("collection.item.\(item.id)")
                    } else {
                        // Normal mode with navigation
                        NavigationLink {
                            ItemDetailView(
                                item: item,
                                onRefresh: { onRefresh(item) },
                                onDeletePhoto: { index in onDeletePhoto(item, index) }
                            )
                        } label: {
                            ItemCard(
                                item: item,
                                onRefresh: { onRefresh(item) },
                                onDelete: { onDelete(item) }
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("collection.item.\(item.id)")
                    }
                }
            }
            .padding()
            .accessibilityIdentifier("collection.grid")
        }
    }
}

private struct EmptyCollectionView: View {
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
    @ScaledMetric(relativeTo: .largeTitle) private var errorIconSize: CGFloat = 60

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: errorIconSize))
                .foregroundStyle(Color.errorColor)
                .accessibilityHidden(true)
            Text("Error Loading Items")
                .font(.title2)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry", action: retry)
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityIdentifier("collection.retryButton")
        }
        .padding()
    }
}
