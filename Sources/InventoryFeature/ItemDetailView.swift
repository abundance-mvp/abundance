import SwiftUI
import Core
import Persistence

public struct ItemDetailView: View {
    public let item: Item
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scrollOffset: CGFloat = 0
    @State private var editViewModel: EditItemViewModel?
    @State private var showRescanPrompt = false
    @State private var showRescanCamera = false
    @State private var showRescanComparison = false
    @State private var showEditSheet = false

    public init(item: Item) {
        self.item = item
    }

    public var body: some View {
        GeometryReader { outerGeometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Image with Parallax
                    GeometryReader { geometry in
                        AsyncImage(url: URL(string: item.imageUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(.gray.opacity(0.1))
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .offset(y: reduceMotion ? 0 : scrollOffset * 0.5) // Parallax effect
                                    .clipped()
                            case .failure:
                                Rectangle()
                                    .fill(.gray.opacity(0.3))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .overlay {
                                        Image(systemName: "photo")
                                            .font(.largeTitle)
                                            .foregroundStyle(.tertiary)
                                    }
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .clipped()
                        .accessibilityLabel("Detail photo of \(item.name ?? "item")")
                    }
                    .frame(height: outerGeometry.size.height * 0.5)
                    .background(
                        GeometryReader { scrollGeometry in
                            Color.clear
                                .preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: scrollGeometry.frame(in: .named("scrollView")).minY
                                )
                        }
                    )

                    // Expanded Metadata Card with Liquid Glass
                    VStack(alignment: .leading, spacing: 16) {
                        // Header: Name + Edit
                        HStack {
                            Text(item.name ?? "Unnamed Item")
                                .font(.title.weight(.bold))
                                .foregroundStyle(.primary)

                            Spacer()

                            Button {
                                startEditFlow()
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.title3)
                                    .foregroundStyle(.primary)
                            }
                            .accessibilityLabel("Edit item")
                        }

                        // Brand + Model Row
                        if item.brand != nil || item.model != nil {
                            HStack(spacing: 8) {
                                if let brand = item.brand {
                                    Text(brand)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.secondary)
                                }
                                if let model = item.model {
                                    Text(model)
                                        .font(.footnote)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }

                        // Category Badges
                        HStack(spacing: 8) {
                            if let category = item.category {
                                CategoryBadge(text: category, color: .orange)
                            }
                            if let subCategory = item.subCategory {
                                CategoryBadge(text: subCategory, color: .blue)
                            }
                        }

                        Divider()

                        // Estimated Value
                        if let value = item.estimatedValue {
                            HStack {
                                Text("Est. Value:")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("$\(value, specifier: "%.2f")")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(.green)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Estimated value: $\(value, specifier: "%.2f")")
                        }

                        // Metadata Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            MetadataCell(label: "Color", value: item.color)
                            MetadataCell(label: "Material", value: item.material)
                            MetadataCell(label: "Condition", value: item.condition?.displayName)
                            MetadataCell(label: "Dimensions", value: item.dimensions)
                            MetadataCell(label: "Quantity", value: item.quantity.map { "\($0)" })
                        }

                        Divider()

                        // AI Confidence Section
                        if let confidence = item.confidence {
                            ConfidenceRow(confidence: confidence)
                        }

                        // Processing Notes (if any)
                        if let notes = item.processingNotes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("AI Notes")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.tertiary)
                                Text(notes)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(24)
                    .adaptiveGlass(in: metadataCardShape)
                    .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: -8)
                    .padding(.horizontal, 16)
                    .offset(y: -60) // Overlap hero
                }
            }
            .coordinateSpace(name: "scrollView")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                scrollOffset = offset
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            // Edit flow sheets - chained based on state machine
            .sheet(isPresented: $showRescanPrompt) {
                if let vm = editViewModel {
                    RescanPromptSheet(viewModel: vm)
                        .onChange(of: vm.state) { _, newState in
                            handleStateChange(newState)
                        }
                }
            }
            #if os(iOS)
            .fullScreenCover(isPresented: $showRescanCamera) {
                if let vm = editViewModel {
                    RescanCameraView(viewModel: vm)
                        .onChange(of: vm.state) { _, newState in
                            handleStateChange(newState)
                        }
                }
            }
            #else
            .sheet(isPresented: $showRescanCamera) {
                if let vm = editViewModel {
                    RescanCameraView(viewModel: vm)
                        .onChange(of: vm.state) { _, newState in
                            handleStateChange(newState)
                        }
                }
            }
            #endif
            .sheet(isPresented: $showRescanComparison) {
                if let vm = editViewModel {
                    RescanComparisonSheet(viewModel: vm)
                        .onChange(of: vm.state) { _, newState in
                            handleStateChange(newState)
                        }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                if let vm = editViewModel {
                    EditItemSheet(viewModel: vm)
                        .onChange(of: vm.state) { _, newState in
                            handleStateChange(newState)
                        }
                }
            }
        }
    }

    // MARK: - Edit Flow Control

    private func startEditFlow() {
        let vm = EditItemViewModel(item: item)
        editViewModel = vm
        vm.startEditFlow()
        showRescanPrompt = true
    }

    private func handleStateChange(_ state: EditFlowState) {
        switch state {
        case .promptingRescan:
            showRescanPrompt = true
            showRescanCamera = false
            showRescanComparison = false
            showEditSheet = false

        case .capturing:
            showRescanPrompt = false
            showRescanCamera = true
            showRescanComparison = false
            showEditSheet = false

        case .comparing:
            showRescanPrompt = false
            showRescanCamera = false
            showRescanComparison = true
            showEditSheet = false

        case .editing:
            showRescanPrompt = false
            showRescanCamera = false
            showRescanComparison = false
            showEditSheet = true

        case .idle:
            // Reset all sheets
            showRescanPrompt = false
            showRescanCamera = false
            showRescanComparison = false
            showEditSheet = false
            editViewModel = nil

        default:
            break // processing, saving, error handled within sheets
        }
    }

    // MARK: - Computed Properties

    private var metadataCardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 24)
    }
}

// MARK: - Scroll Offset Tracking

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Supporting Views

private struct CategoryBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .fill(color.opacity(0.2))
            }
    }
}

private struct MetadataCell: View {
    let label: String
    let value: String?

    var body: some View {
        if let value = value {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text(value)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct ConfidenceRow: View {
    let confidence: ItemConfidence

    var body: some View {
        HStack {
            Image(systemName: confidenceIcon)
                .foregroundStyle(confidenceColor)
            Text("AI Confidence")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(confidence.rawValue.capitalized)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(confidenceColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("AI Confidence: \(confidence.rawValue)")
    }

    private var confidenceIcon: String {
        switch confidence {
        case .high: return "checkmark.circle.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .low: return "questionmark.circle.fill"
        }
    }

    private var confidenceColor: Color {
        switch confidence {
        case .high: return .green
        case .medium: return .orange
        case .low: return .red
        }
    }
}
