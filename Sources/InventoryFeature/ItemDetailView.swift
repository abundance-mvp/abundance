import SwiftUI
import Core
import Persistence

public struct ItemDetailView: View {
    public let item: Item
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var scrollOffset: CGFloat = 0
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
                                    .offset(y: scrollOffset * 0.5) // Parallax effect
                                    .clipped()
                            case .failure:
                                Rectangle()
                                    .fill(.gray.opacity(0.3))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .overlay {
                                        Image(systemName: "photo")
                                            .font(.system(size: 80))
                                            .foregroundStyle(.tertiary)
                                    }
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .clipped()
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

                // Metadata Card with Liquid Glass
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(item.category ?? "Uncategorized")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Spacer()

                        Button {
                            showEditSheet = true
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 20))
                                .foregroundStyle(.primary)
                        }
                        .accessibilityLabel("Edit item")
                    }

                    // Category Badge
                    if let category = item.category {
                        Text(category)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background {
                                Capsule()
                                    .fill(Color.orange.opacity(0.2))
                            }
                    }

                    Divider()

                    // Estimated Value
                    if let value = item.estimatedValue {
                        HStack {
                            Text("Est. Value:")
                                .font(.system(size: 15, design: .rounded))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("$\(value, specifier: "%.2f")")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(.green)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Estimated value: $\(value, specifier: "%.2f")")
                    }

                    // Metadata Rows
                    MetadataRow(label: "Color", value: item.color)
                    MetadataRow(label: "Material", value: item.material)
                    MetadataRow(label: "Condition", value: item.condition)

                    // Confidence Score with Icon and Label
                    if let confidence = item.confidence {
                        HStack {
                            Image(systemName: confidenceIcon(confidence))
                                .foregroundStyle(confidenceColor(confidence))
                            Text("AI Confidence")
                                .font(.system(size: 15, design: .rounded))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(confidenceLevel(confidence)) (\(Int(confidence * 100))%)")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(confidenceColor(confidence))
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("AI Confidence: \(confidenceLevel(confidence)), \(Int(confidence * 100)) percent")
                    }
                }
                .padding(24)
                .background {
                    if #available(iOS 26.0, macOS 26.0, *) {
                        if !reduceTransparency {
                            Color.clear
                                .glassEffect(in: metadataCardShape)
                        } else {
                            Color.backgroundDefault
                                .clipShape(metadataCardShape)
                        }
                    } else {
                        Color.clear
                            .background(.ultraThickMaterial, in: metadataCardShape)
                    }
                }
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
            .sheet(isPresented: $showEditSheet) {
                Text("Edit sheet placeholder")
                    .presentationDetents([.large])
            }
        }
    }

    // MARK: - Computed Properties

    private var metadataCardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 24)
    }

    // MARK: - Confidence Helper Functions

    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.80 {
            return .green
        } else if confidence >= 0.60 {
            return .orange
        } else {
            return .red
        }
    }

    private func confidenceLevel(_ confidence: Double) -> String {
        if confidence >= 0.80 { return "High" }
        else if confidence >= 0.60 { return "Medium" }
        else { return "Low" }
    }

    private func confidenceIcon(_ confidence: Double) -> String {
        if confidence >= 0.80 { return "checkmark.circle.fill" }
        else if confidence >= 0.60 { return "exclamationmark.triangle.fill" }
        else { return "questionmark.circle.fill" }
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

private struct MetadataRow: View {
    let label: String
    let value: String?

    var body: some View {
        if let value = value {
            HStack {
                Text(label)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }
        }
    }
}
