import SwiftUI

/// Item detail view with parallax hero image and glass metadata cards
/// **Design Spec:** DESIGN-029-item-detail-view-specification.md
struct ItemDetailView: View {
    let itemId: String

    @StateObject private var observer: ItemObserver
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var scrollOffset: CGFloat = 0

    // MARK: - Initialization

    init(item: Item) {
        self.itemId = item.id
        _observer = StateObject(wrappedValue: ItemObserver())
    }

    init(itemId: String, itemRepository: ItemRepository = ItemService()) {
        self.itemId = itemId
        _observer = StateObject(wrappedValue: ItemObserver(itemRepository: itemRepository))
    }

    // MARK: - Body

    var body: some View {
        Group {
            if observer.isLoading {
                loadingView
            } else if let error = observer.error {
                errorView(error: error)
            } else if let item = observer.item {
                detailContent(for: item)
            } else {
                errorView(error: "Item not found")
            }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            observer.observe(itemId: itemId)
        }
        .onDisappear {
            observer.stopObserving()
        }
    }

    // MARK: - Content Views

    @ViewBuilder
    private func detailContent(for item: Item) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Image with Parallax
                heroImage(item: item)

                // Glass Metadata Card
                metadataCard(item: item)
                    .padding(.bottom, 24)
            }
        }
        .background(Color.backgroundDefault.ignoresSafeArea())
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetKey.self) { offset in
            if !reduceMotion {
                scrollOffset = offset
            }
        }
    }

    @ViewBuilder
    private func heroImage(item: Item) -> some View {
        GeometryReader { geometry in
            ZStack {
                // Track scroll offset
                Color.clear
                    .preference(key: ScrollOffsetKey.self, value: geometry.frame(in: .named("scroll")).minY)

                // Image with parallax effect
                AsyncImage(url: URL(string: item.imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.gray.opacity(0.1))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .offset(y: reduceMotion ? 0 : scrollOffset * 0.5)
                    case .failure:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
                .clipped()
            }
        }
        .frame(height: heroImageHeight)
    }

    private var placeholderImage: some View {
        ZStack {
            Color.gray.opacity(0.2)
            Image(systemName: "photo")
                .font(.system(size: 80))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func metadataCard(item: Item) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Item Name (Category as title)
            Text(item.category ?? "Unknown Item")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(2)

            // AI Confidence Badge
            if let confidence = item.confidence {
                ConfidenceBadge(confidence: confidence)
            }

            Divider()
                .background(.tertiary)

            // Metadata Rows
            VStack(spacing: 12) {
                if let category = item.category {
                    MetadataRow(label: "Category", value: category)
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
            }

            Divider()
                .background(.tertiary)

            // Status Section
            statusSection(item: item)
        }
        .padding(24)
        .background {
            if reduceTransparency {
                Color.backgroundDefault
            } else {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThickMaterial)
            }
        }
        .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: -8)
        .padding(.horizontal, 16)
        .offset(y: -40) // Overlap hero image
    }

    @ViewBuilder
    private func statusSection(item: Item) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Processing Status")
                .font(.system(.footnote, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)

            HStack {
                StatusBadge(status: item.status)
                Spacer()
                Text(statusDescription(for: item.status))
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    // MARK: - Loading & Error States

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
            Text("Loading item...")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func errorView(error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundStyle(Color.errorColor)
            Text("Error Loading Item")
                .font(.system(.title2, design: .rounded, weight: .bold))
            Text(error)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            PrimaryButton(title: "Go Back") {
                dismiss()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Computed Properties

    /// Hero image height - 40% of typical screen height
    /// Uses fixed value to avoid UIKit dependency (ADR-010)
    private var heroImageHeight: CGFloat {
        300
    }

    private func statusDescription(for status: ItemStatus) -> String {
        switch status {
        case .pending:
            return "Processing - Layer 2a extraction in progress..."
        case .layer2aComplete:
            return "Analysis complete - attributes extracted"
        case .complete:
            return "Fully cataloged"
        case .failed, .failedLayer2a:
            return "Processing failed - please try recapturing"
        default:
            return status.rawValue
        }
    }
}

// MARK: - Supporting Views

private struct MetadataRow: View {
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

private struct StatusBadge: View {
    let status: ItemStatus

    var body: some View {
        Text(statusText)
            .font(.system(.caption2, design: .rounded, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
            .accessibilityLabel("Status: \(statusText)")
    }

    private var statusText: String {
        switch status {
        case .pending: return "Processing"
        case .layer2aComplete: return "Analyzed"
        case .complete: return "Complete"
        case .failed, .failedLayer2a, .failedLayer2b: return "Failed"
        default: return status.rawValue
        }
    }

    private var statusColor: Color {
        switch status {
        case .pending: return .blue
        case .layer2aComplete, .complete: return Color.successColor
        case .failed, .failedLayer2a, .failedLayer2b: return Color.errorColor
        default: return .gray
        }
    }
}

// MARK: - Scroll Offset Preference Key

private struct ScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview

#Preview("Item Detail - Complete") {
    NavigationStack {
        ItemDetailView(
            item: Item(
                id: "preview-1",
                userId: "user-1",
                imageUrl: "https://picsum.photos/400/300",
                status: .layer2aComplete,
                category: "Camping Tent",
                color: "Green",
                material: "Nylon",
                condition: "Good",
                confidence: 0.87
            )
        )
    }
}

#Preview("Item Detail - Pending") {
    NavigationStack {
        ItemDetailView(
            item: Item(
                id: "preview-2",
                userId: "user-1",
                imageUrl: "https://picsum.photos/400/300",
                status: .pending,
                category: nil,
                color: nil,
                material: nil,
                condition: nil,
                confidence: nil
            )
        )
    }
}
