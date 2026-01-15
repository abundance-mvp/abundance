import SwiftUI
import Core
import Persistence

/// Display cataloged household items in grid layout
/// **Design Spec:** DESIGN-031-swiftui-component-library.md (ItemCard)
struct ItemCard: View {
    let item: Item
    var onTap: (() -> Void)?

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
                    // Primary: Item name (fallback to category)
                    Text(item.name ?? item.category ?? "Unknown Item")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    // Secondary: Brand + Color
                    if let brand = item.brand {
                        HStack(spacing: 4) {
                            Text(brand)
                                .font(.system(.footnote, design: .rounded, weight: .medium))
                                .foregroundStyle(.secondary)
                            if let color = item.color {
                                Text("-")
                                    .foregroundStyle(.tertiary)
                                Text(color)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(.system(.footnote, design: .rounded))
                        .lineLimit(1)
                    } else if let color = item.color {
                        Text(color)
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    HStack {
                        // Condition badge (if available)
                        if let condition = item.condition {
                            ConditionBadge(condition: condition)
                        }
                        Spacer()
                        StatusBadge(status: item.status)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .adaptiveGlass(in: outerShape)
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
        var desc = "\(item.name ?? item.category ?? "Unknown item")"
        if let brand = item.brand {
            desc += ", \(brand)"
        }
        if let color = item.color {
            desc += ", \(color)"
        }
        if let condition = item.condition {
            desc += ", \(condition.displayName)"
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

// MARK: - Condition Badge

private struct ConditionBadge: View {
    let condition: ItemCondition

    var body: some View {
        Text(condition.displayName)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(conditionColor.opacity(0.2))
            .foregroundStyle(conditionColor)
            .clipShape(Capsule())
    }

    private var conditionColor: Color {
        switch condition {
        case .new, .likeNew: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
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
