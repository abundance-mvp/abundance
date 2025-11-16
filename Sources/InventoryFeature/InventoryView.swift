import SwiftUI
import Persistence

public struct InventoryView: View {
    @StateObject var viewModel: InventoryViewModel

    public init(viewModel: InventoryViewModel = InventoryViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading items...")
                } else if let error = viewModel.error {
                    ErrorView(message: error, retry: {
                        Task { await viewModel.loadItems() }
                    })
                } else if viewModel.items.isEmpty {
                    EmptyInventoryView()
                } else {
                    ItemGridView(items: viewModel.items)
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
    var body: some View {
        EmptyStateCard(
            iconName: "tray",
            headline: "No Items Yet",
            description: "Capture items with the camera to get started",
            buttonTitle: "Open Camera",
            action: { /* TODO: Switch to camera tab */ }
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

