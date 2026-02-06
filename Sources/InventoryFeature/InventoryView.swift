import SwiftUI
import Core
import Persistence

public struct InventoryView: View {
    // Plain var for @Observable type - SwiftUI tracks changes automatically
    @Bindable var viewModel: InventoryViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isSelectionMode = false
    @State private var selectedItemIds: Set<String> = []
    @State private var itemToDelete: Item?
    @State private var showDeleteConfirmation = false
    @State private var showBulkDeleteConfirmation = false
    @State private var showDeleteErrorAlert = false
    @State private var showRecatalogErrorAlert = false
    var onOpenCamera: (() -> Void)?

    public init(
        viewModel: InventoryViewModel = InventoryViewModel(),
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
                            .accessibilityIdentifier("inventory.loading")
                    } else if let error = viewModel.error {
                        ErrorView(message: error, retry: {
                            Task { await viewModel.loadItems() }
                        })
                    } else if viewModel.items.isEmpty {
                        EmptyInventoryView(onOpenCamera: onOpenCamera)
                            .accessibilityIdentifier("inventory.emptyState")
                    } else if viewModel.filteredItems.isEmpty {
                        // No search results
                        ContentUnavailableView.search(text: viewModel.searchText)
                    } else {
                        ItemGridView(
                            items: viewModel.filteredItems,
                            isSelectionMode: isSelectionMode,
                            selectedItemIds: $selectedItemIds,
                            onRecatalog: { item in
                                Task { await viewModel.recatalogItem(item) }
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
            .navigationTitle("Inventory")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if !viewModel.items.isEmpty && !viewModel.isLoading {
                        Button(isSelectionMode ? "Done" : "Select") {
                            withAnimation(reduceMotion ? nil : .brandSnappy) {
                                isSelectionMode.toggle()
                                if !isSelectionMode {
                                    selectedItemIds.removeAll()
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(Color.accentPrimary)
                        .accessibilityIdentifier("inventory.selectButton")
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
                let name = item.name ?? item.category ?? "this item"
                Text("Are you sure you want to delete \"\(name)\"? This action cannot be undone.")
            }
            // Bulk delete confirmation
            .confirmationDialog(
                "Delete \(selectedItemIds.count) Items",
                isPresented: $showBulkDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete All", role: .destructive) {
                    let idsToDelete = selectedItemIds
                    // Clear selection state immediately with animation (before async work)
                    withAnimation(reduceMotion ? nil : .brandSnappy) {
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
            // Re-catalog error alert
            .alert("Re-catalog Failed", isPresented: $showRecatalogErrorAlert) {
                Button("OK") {
                    viewModel.recatalogError = nil
                }
            } message: {
                Text(viewModel.recatalogError ?? "An error occurred")
            }
            .onChange(of: viewModel.recatalogError) { _, newValue in
                showRecatalogErrorAlert = newValue != nil
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
            }
            .accessibilityIdentifier("inventory.deselectAllButton")

            Spacer()

            Button(role: .destructive) {
                showBulkDeleteConfirmation = true
            } label: {
                Label("Delete (\(selectedItemIds.count))", systemImage: "trash")
            }
            .accessibilityIdentifier("inventory.bulkDeleteButton")
            .disabled(selectedItemIds.isEmpty)
        }
        .padding()
        .adaptiveGlass(cornerRadius: 16)
    }
}

// MARK: - Subviews

private struct ItemGridView: View {
    let items: [Item]
    let isSelectionMode: Bool
    @Binding var selectedItemIds: Set<String>
    let onRecatalog: (Item) -> Void
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
                                withAnimation(reduceMotion ? nil : .brandSnappy) {
                                    if selectedItemIds.contains(item.id) {
                                        selectedItemIds.remove(item.id)
                                    } else {
                                        selectedItemIds.insert(item.id)
                                    }
                                }
                            },
                            isSelectionMode: true,
                            isSelected: selectedItemIds.contains(item.id)
                        )
                    } else {
                        // Normal mode with navigation
                        NavigationLink {
                            ItemDetailView(
                                item: item,
                                onRecatalog: { onRecatalog(item) }
                            )
                        } label: {
                            ItemCard(
                                item: item,
                                onRecatalog: { onRecatalog(item) },
                                onDelete: { onDelete(item) }
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("inventory.item.\(item.id)")
                    }
                }
            }
            .padding()
        }
        .accessibilityIdentifier("inventory.grid")
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
    @ScaledMetric(relativeTo: .largeTitle) private var errorIconSize: CGFloat = 60

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: errorIconSize))
                .foregroundStyle(.red)
            Text("Error Loading Items")
                .font(.title2)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry", action: retry)
                .buttonStyle(.bordered)
                .accessibilityIdentifier("inventory.retryButton")
        }
        .padding()
    }
}
