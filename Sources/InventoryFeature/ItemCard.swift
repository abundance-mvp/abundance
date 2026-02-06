import SwiftUI
import Core
import Persistence

/// Display cataloged household items in grid layout
/// **Design Spec:** DESIGN-031-swiftui-component-library.md (ItemCard)
struct ItemCard: View {
    let item: Item
    var onTap: (() -> Void)?
    var onEdit: (() -> Void)?
    var onRecatalog: (() -> Void)?
    var onDelete: (() -> Void)?

    /// Whether the card is in multi-select mode
    var isSelectionMode: Bool = false

    /// Whether this card is currently selected (for multi-select)
    var isSelected: Bool = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize: DynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed: Bool = false

    var body: some View {
        cardContent
            .animation(reduceMotion ? nil : .brandSnappy, value: isPressed)
            .animation(reduceMotion ? nil : .brandSnappy, value: isSelected)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityDescription)
            .accessibilityAddTraits(.isButton)
            .modifier(SelectionModeContextMenuModifier(
                isSelectionMode: isSelectionMode,
                onEdit: onEdit,
                onRecatalog: onRecatalog,
                onDelete: onDelete
            ))
    }

    // MARK: - Card Content

    /// Card visual content - wrapped in Button only when onTap is provided
    /// This allows NavigationLink to work when ItemCard is used as its label
    @ViewBuilder
    private var cardContent: some View {
        if onTap != nil {
            // Selection mode or explicit tap handler - use Button
            // handleTap() delegates to onTap?() internally
            Button(action: {
                handleTap()
            }) {
                cardVisual
            }
            .buttonStyle(.plain)
        } else {
            // No tap handler - don't wrap in Button (allows NavigationLink to work)
            cardVisual
        }
    }

    /// The actual visual content of the card
    @ViewBuilder
    private var cardVisual: some View {
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
                            .frame(maxWidth: .infinity)
                            .frame(height: imageHeight)
                            .clipped()
                    case .failure:
                        placeholderImage
                            .onAppear {
                                AppLogger.log(.imageLoadFailed(
                                    url: item.imageUrl,
                                    itemId: item.id,
                                    context: "ItemCard.thumbnail"
                                ))
                            }
                    @unknown default:
                        placeholderImage
                    }
                }
                .clipShape(innerShape)
                .accessibilityLabel("Photo of \(item.name ?? item.category ?? "item")")

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

    // MARK: - Selection Indicator

    @ViewBuilder
    private var selectionIndicator: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.accentColor : Color.white.opacity(0.8))
                .frame(width: 44, height: 44)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.footnote.weight(.bold))
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
                .font(.title)
                .foregroundStyle(.secondary)
        }
        .frame(height: imageHeight)
        .accessibilityLabel("Image not available")
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
        if reduceMotion {
            // Skip animation for Reduce Motion users
            onTap?()
        } else {
            withAnimation(.brandSnappy) {
                isPressed = true
            }
            onTap?()

            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(150))
                withAnimation(.brandSnappy) {
                    isPressed = false
                }
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
            .background(conditionColor.opacity(0.3))
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
            .background(statusColor.opacity(0.3))
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

// MARK: - Context Menu Modifier

/// Conditionally applies context menu only when NOT in selection mode.
/// This avoids gesture conflicts where the context menu intercepts taps in selection mode.
private struct SelectionModeContextMenuModifier: ViewModifier {
    let isSelectionMode: Bool
    let onEdit: (() -> Void)?
    let onRecatalog: (() -> Void)?
    let onDelete: (() -> Void)?

    func body(content: Content) -> some View {
        if isSelectionMode {
            // No context menu in selection mode - allows taps to work
            content
        } else {
            content.contextMenu {
                // Only show Edit when functionality is implemented (Stage 3.3+)
                if let onEdit = onEdit {
                    Button {
                        onEdit()
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }

                if let onRecatalog = onRecatalog {
                    Button {
                        onRecatalog()
                    } label: {
                        Label("Re-catalog", systemImage: "arrow.triangle.2.circlepath")
                    }
                }

                Button(role: .destructive) {
                    onDelete?()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}
