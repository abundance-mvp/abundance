import SwiftUI
import Core
import Persistence

public struct InventoryView: View {
    // Plain var for @Observable type - SwiftUI tracks changes automatically
    var viewModel: InventoryViewModel
    @State private var searchText = ""
    @State private var isSelectionMode = false
    @State private var selectedItemIds: Set<String> = []
    @State private var itemToDelete: Item?
    @State private var showDeleteConfirmation = false
    @State private var showBulkDeleteConfirmation = false
    @State private var showDeleteErrorAlert = false
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
                        ItemGridView(
                            items: filteredItems,
                            isSelectionMode: isSelectionMode,
                            selectedItemIds: $selectedItemIds,
                            onEdit: { _ in
                                // TODO: Stage 3.3 - wire to rescan edit flow
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
                            withAnimation(.brandSnappy) {
                                isSelectionMode.toggle()
                                if !isSelectionMode {
                                    selectedItemIds.removeAll()
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.accentPrimary)
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
                let name = item.category ?? "this item"
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
                    withAnimation(.brandSnappy) {
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

            Spacer()

            Button(role: .destructive) {
                showBulkDeleteConfirmation = true
            } label: {
                Label("Delete (\(selectedItemIds.count))", systemImage: "trash")
            }
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
    let onEdit: (Item) -> Void
    let onDelete: (Item) -> Void

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(items) { item in
                    if isSelectionMode {
                        // In selection mode, tap toggles selection
                        ItemCard(
                            item: item,
                            onTap: {
                                withAnimation(.brandSnappy) {
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
                            ItemDetailView(item: item)
                        } label: {
                            ItemCard(
                                item: item,
                                onEdit: { onEdit(item) },
                                onDelete: { onDelete(item) }
                            )
                        }
                        .buttonStyle(.plain)
                    }
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
