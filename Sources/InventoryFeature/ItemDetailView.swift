import SwiftUI
import Core
import Persistence

public struct ItemDetailView: View {
    public let item: Item
    public var onRecatalog: (() -> Void)?
    public var onDeepScan: (() -> Void)?
    public var onDeletePhoto: ((Int) -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scrollOffset: CGFloat = 0
    @State private var editViewModel: EditItemViewModel?
    @State private var showRescanPrompt = false
    @State private var showRescanCamera = false
    @State private var showRescanComparison = false
    @State private var showEditSheet = false
    @State private var showRecatalogConfirmation = false
    @State private var showDeepScanConfirmation = false
    @State private var showAddPhotoCamera = false
    @State private var isRecataloging = false
    @State private var isDeepScanning = false

    private var isProcessing: Bool {
        isRecataloging || item.status == .processing
    }

    public init(
        item: Item,
        onRecatalog: (() -> Void)? = nil,
        onDeepScan: (() -> Void)? = nil,
        onDeletePhoto: ((Int) -> Void)? = nil
    ) {
        self.item = item
        self.onRecatalog = onRecatalog
        self.onDeepScan = onDeepScan
        self.onDeletePhoto = onDeletePhoto
    }

    public var body: some View {
        GeometryReader { outerGeometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Image: Carousel for multi-photo, Parallax for single
                    if item.photoCount > 1 {
                        PhotoCarouselView(
                            imageUrls: item.allImageUrls,
                            onDeletePhoto: onDeletePhoto
                        )
                        .frame(height: outerGeometry.size.height * 0.5)
                        .accessibilityLabel("Photos of \(item.displayName), \(item.photoCount) photos")
                    } else {
                        GeometryReader { geometry in
                            ItemImage(
                                url: item.imageUrl,
                                itemId: item.id,
                                context: "ItemDetailView.heroImage",
                                placeholderIcon: "photo"
                            )
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .offset(y: reduceMotion ? 0 : scrollOffset * 0.5)
                            .clipped()
                            .accessibilityLabel("Detail photo of \(item.displayName)")
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
                    }

                    // Expanded Metadata Card with Liquid Glass
                    VStack(alignment: .leading, spacing: 16) {
                        // Header: Name + Edit
                        HStack {
                            Text(item.displayName)
                                .font(.title.weight(.bold))
                                .foregroundStyle(.primary)
                                .accessibilityIdentifier("detail.itemName")

                            Spacer()

                            if onRecatalog != nil {
                                Button {
                                    showRecatalogConfirmation = true
                                } label: {
                                    Group {
                                        if isProcessing {
                                            ProgressView()
                                        } else {
                                            Image(systemName: "arrow.triangle.2.circlepath")
                                        }
                                    }
                                    .font(.title3)
                                    .foregroundStyle(isProcessing ? .secondary : .primary)
                                    .frame(minWidth: 44, minHeight: 44)
                                }
                                .disabled(isProcessing)
                                .accessibilityIdentifier("detail.recatalogButton")
                                .accessibilityLabel(isProcessing ? "Re-cataloging in progress" : "Re-catalog item")
                            }

                            if onDeepScan != nil {
                                Button {
                                    showDeepScanConfirmation = true
                                } label: {
                                    Group {
                                        if isDeepScanning {
                                            ProgressView()
                                        } else {
                                            Image(systemName: "sparkles")
                                        }
                                    }
                                    .font(.title3)
                                    .foregroundStyle(isDeepScanning ? Color.secondary : Color.purple)
                                    .frame(minWidth: 44, minHeight: 44)
                                }
                                .disabled(isDeepScanning || item.deepScanCompletedAt != nil)
                                .accessibilityIdentifier("detail.deepScanButton")
                                .accessibilityLabel(isDeepScanning ? "Deep scan in progress" : "Deep scan item")
                            }

                            Button {
                                startEditFlow()
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.title3)
                                    .foregroundStyle(.primary)
                                    .frame(minWidth: 44, minHeight: 44)
                            }
                            .accessibilityIdentifier("detail.editButton")
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
                                CategoryBadge(text: category, color: .peach)
                            }
                            if let subCategory = item.subCategory {
                                CategoryBadge(text: subCategory, color: .softTeal)
                            }
                        }

                        // Processing banner
                        if isProcessing {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Re-cataloging with AI...")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .accessibilityIdentifier("detail.processingBanner")
                        }

                        Divider()

                        // Estimated Value
                        if let value = item.estimatedValue {
                            HStack {
                                Text("Est. Value:")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(value, format: .currency(code: "USD"))
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(Color.mutedSage)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Estimated value: \(formattedValue(value))")
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

                        // Deep Scan Details
                        if item.deepScanRequested == true || item.deepScanCompletedAt != nil {
                            Divider()
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .foregroundStyle(.purple)
                                    Text("Deep Scan Details")
                                        .font(.subheadline.weight(.semibold))
                                }

                                if item.deepScanCompletedAt != nil {
                                    LazyVGrid(columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ], spacing: 12) {
                                        MetadataCell(label: "UPC Code", value: item.upcCode)
                                        MetadataCell(label: "Market Price", value: item.marketPriceRange)
                                        MetadataCell(
                                            label: "Retail Price",
                                            value: item.originalRetailPrice.map { "$\(String(format: "%.2f", $0))" }
                                        )
                                        MetadataCell(label: "Product URL", value: item.productUrl != nil ? "View" : nil)
                                    }
                                } else if isDeepScanning {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .controlSize(.small)
                                        Text("Scanning...")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                } else {
                                    LazyVGrid(columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ], spacing: 12) {
                                        MetadataCell(label: "UPC Code", value: "--")
                                        MetadataCell(label: "Market Price", value: "--")
                                        MetadataCell(label: "Retail Price", value: "--")
                                        MetadataCell(label: "Product URL", value: "--")
                                    }
                                    .foregroundStyle(.tertiary)
                                }
                            }
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
                    .abundanceCardStyle(cornerRadius: 24)
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
            #if os(iOS)
            .fullScreenCover(isPresented: $showAddPhotoCamera) {
                if let vm = editViewModel {
                    AddPhotoCameraView(viewModel: vm)
                        .onChange(of: vm.state) { _, newState in
                            handleStateChange(newState)
                        }
                }
            }
            #else
            .sheet(isPresented: $showAddPhotoCamera) {
                if let vm = editViewModel {
                    AddPhotoCameraView(viewModel: vm)
                        .onChange(of: vm.state) { _, newState in
                            handleStateChange(newState)
                        }
                }
            }
            #endif
            .confirmationDialog(
                "Re-catalog Item",
                isPresented: $showRecatalogConfirmation,
                titleVisibility: .visible
            ) {
                Button("Re-catalog") {
                    isRecataloging = true
                    onRecatalog?()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will re-process the item through the AI pipeline. Existing metadata will be replaced with new results.")
            }
            .onChange(of: item.status) { _, newStatus in
                if newStatus != .processing {
                    isRecataloging = false
                    isDeepScanning = false
                }
            }
            .confirmationDialog(
                "Deep Scan",
                isPresented: $showDeepScanConfirmation,
                titleVisibility: .visible
            ) {
                Button("Start Deep Scan") {
                    isDeepScanning = true
                    onDeepScan?()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Deep Scan uses advanced AI to find pricing, dimensions, product details, and market value.")
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
            showAddPhotoCamera = false
            showEditSheet = true

        case .addingPhoto:
            showEditSheet = false
            showAddPhotoCamera = true

        case .idle:
            // Reset all sheets
            showRescanPrompt = false
            showRescanCamera = false
            showRescanComparison = false
            showEditSheet = false
            showAddPhotoCamera = false
            editViewModel = nil

        default:
            break // processing, saving, error handled within sheets
        }
    }

    // MARK: - Computed Properties

    private func formattedValue(_ value: Double) -> String {
        value.formatted(.currency(code: "USD"))
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
        case .high: return .mutedSage
        case .medium: return .peach
        case .low: return .salmon
        }
    }
}
