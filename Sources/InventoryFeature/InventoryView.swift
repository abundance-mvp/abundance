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

// MARK: - ItemDetailView Placeholder

/// Placeholder for ItemDetailView (will be implemented in Task 3.2)
private struct ItemDetailView: View {
    let item: Item

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero image
                AsyncImage(url: URL(string: item.imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: 300)
                            .frame(maxWidth: .infinity)
                            .background(.gray.opacity(0.1))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 400)
                    case .failure:
                        Rectangle()
                            .fill(.gray.opacity(0.3))
                            .frame(height: 300)
                            .overlay {
                                Image(systemName: "photo")
                                    .font(.system(size: 80))
                                    .foregroundStyle(.tertiary)
                            }
                    @unknown default:
                        EmptyView()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                // Attributes card
                VStack(spacing: 16) {
                    AttributeRow(label: "Category", value: item.category)
                    AttributeRow(label: "Color", value: item.color)
                    AttributeRow(label: "Material", value: item.material)
                    AttributeRow(label: "Condition", value: item.condition)

                    if let confidence = item.confidence {
                        HStack {
                            Text("AI Confidence")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(confidence * 100))%")
                                .font(.headline)
                        }
                    }
                }
                .padding()
                .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                // Status
                VStack(alignment: .leading, spacing: 8) {
                    Text("Status")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(statusDescription)
                        .font(.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(item.category ?? "Item Details")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var statusDescription: String {
        switch item.status {
        case .pending:
            return "Processing - Layer 2a extraction in progress..."
        case .layer2aComplete:
            return "Analysis complete - attributes extracted"
        case .complete:
            return "Fully cataloged"
        case .failed, .failedLayer2a:
            return "Processing failed - please try recapturing"
        default:
            return item.status.rawValue
        }
    }
}

// MARK: - Supporting Views

private struct AttributeRow: View {
    let label: String
    let value: String?

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value ?? "—")
                .font(.headline)
        }
    }
}
