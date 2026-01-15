import SwiftUI
import Core
import Persistence

/// Display cataloged household items in grid layout
/// **Design Spec:** DESIGN-031-swiftui-component-library.md (ItemCard)
struct ItemCard: View {
    let item: Item
    var onTap: (() -> Void)?
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    /// Whether the card is in multi-select mode
    var isSelectionMode: Bool = false

    /// Whether this card is currently selected (for multi-select)
    var isSelected: Bool = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize: DynamicTypeSize
    @State private var isPressed: Bool = false

    var body: some View {
        Button(action: handleTap) {
            ZStack(alignment: .topTrailing) {
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

                // Selection checkmark overlay (multi-select mode)
                if isSelectionMode {
                    selectionIndicator
                }
            }
            .adaptiveGlass(in: outerShape)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .overlay {
                if isSelected {
                    outerShape
                        .stroke(Color.accentColor, lineWidth: 3)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.brandSnappy, value: isPressed)
        .animation(.brandSnappy, value: isSelected)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(.isButton)
        .contextMenu {
            // Only show context menu when not in selection mode
            if !isSelectionMode {
                Button {
                    onEdit?()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    onDelete?()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    // MARK: - Selection Indicator

    @ViewBuilder
    private var selectionIndicator: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.accentColor : Color.white.opacity(0.8))
                .frame(width: 28, height: 28)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .padding(8)
    }

    // MARK: - Computed Properties

    private var imageHeight: CGFloat {
        dynamicTypeSize >= .xxxLarge ? 120 : 160
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
        var desc: String = "\(item.category ?? "Unknown item")"
        if let color: String = item.color {
            desc += ", \(color)"
        }
        desc += ", \(statusText(for: item.status))"
        if isSelectionMode {
            desc += isSelected ? ", selected" : ", not selected"
        }
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
        withAnimation(.brandSnappy) {
            isPressed = true
        }
        onTap?()

        // Use DispatchQueue for delayed reset (avoids Task capture issues
        // if view is removed mid-animation)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.brandSnappy) {
                isPressed = false
            }
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
