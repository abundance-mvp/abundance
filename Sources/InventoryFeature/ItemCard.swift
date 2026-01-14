import SwiftUI
import Core
import Persistence

/// Display cataloged household items in grid layout
/// **Design Spec:** DESIGN-031-swiftui-component-library.md (ItemCard)
struct ItemCard: View {
    let item: Item
    var onTap: (() -> Void)? = nil

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isPressed: Bool = false

    var body: some View {
        Button(action: handleTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Cropped object image
                AsyncImage(url: URL(string: item.imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(height: imageHeight)
                            .frame(maxWidth: .infinity)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: imageHeight)
                            .clipped()
                    case .failure:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
                .clipShape(innerShape)

                // Metadata section
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.category ?? "Unknown Item")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    if let color = item.color {
                        Text(color)
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    HStack {
                        Spacer()
                        StatusBadge(status: item.status)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .background(backgroundMaterial, in: outerShape)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.brandSnappy, value: isPressed)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Computed Properties

    private var imageHeight: CGFloat {
        dynamicTypeSize >= .xxxLarge ? 120 : 160
    }

    private var backgroundMaterial: AnyShapeStyle {
        reduceTransparency ? AnyShapeStyle(Color.backgroundDefault) : AnyShapeStyle(.thickMaterial)
    }

    private var outerShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 16)
    }

    private var innerShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 12)
    }

    private var placeholderImage: some View {
        ZStack {
            Color.gray.opacity(0.2)
            Image(systemName: "photo")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
        }
        .frame(height: imageHeight)
    }

    private var accessibilityDescription: String {
        var desc = "\(item.category ?? "Unknown item")"
        if let color = item.color {
            desc += ", \(color)"
        }
        desc += ", \(statusText(for: item.status))"
        return desc
    }

    private func statusText(for status: ItemStatus) -> String {
        switch status {
        case .pending: return "Processing"
        case .layer2aComplete: return "Analyzed"
        case .complete: return "Complete"
        case .failed, .failedLayer2a, .failedLayer2b: return "Failed"
        default: return status.rawValue
        }
    }

    private func handleTap() {
        isPressed = true
        onTap?()
        Task {
            try? await Task.sleep(for: .seconds(0.15))
            isPressed = false
        }
    }
}

// MARK: - Status Badge

private struct StatusBadge: View {
    let status: ItemStatus

    var body: some View {
        Text(statusText)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.2))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
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
        case .layer2aComplete, .complete: return .green
        case .failed, .failedLayer2a, .failedLayer2b: return .red
        default: return .gray
        }
    }
}
