import SwiftUI
import Core
import Persistence

/// Display cataloged household items in grid layout
/// **Design Spec:** DESIGN-031-swiftui-component-library.md (ItemCard)
struct ItemCard: View {
    let item: Item
    var onTap: (() -> Void)?
    var onEdit: (() -> Void)?
    var onRefresh: (() -> Void)?
    var onDelete: (() -> Void)?

    /// Whether the card is in multi-select mode
    var isSelectionMode: Bool = false

    /// Whether this card is currently selected (for multi-select)
    var isSelected: Bool = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize: DynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @State private var isPressed: Bool = false
    @State private var pressAnimationTask: Task<Void, Never>?

    var body: some View {
        cardContent
            .animation(reduceMotion ? nil : .brandPress, value: isPressed)
            .animation(reduceMotion ? nil : .brandPress, value: isSelected)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityDescription)
            .accessibilityAddTraits(.isButton)
            .onDisappear {
                pressAnimationTask?.cancel()
            }
            .modifier(SelectionModeContextMenuModifier(
                isSelectionMode: isSelectionMode,
                onEdit: onEdit,
                onRefresh: onRefresh,
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
                // Cropped object image (with automatic retry on failure)
                ItemImage(
                    url: item.imageUrl,
                    itemId: item.id,
                    context: "ItemCard.thumbnail"
                )
                .frame(maxWidth: .infinity)
                .frame(height: imageHeight)
                .clipped()
                .clipShape(innerShape)
                .accessibilityLabel("Photo of \(item.displayName)")

                // Metadata section
                VStack(alignment: .leading, spacing: 4) {
                    // Primary: Item name with full fallback chain
                    Text(item.displayName)
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
        .background(Color.cream, in: outerShape)
        .overlay(outerShape.stroke(Color.peach, lineWidth: contrast == .increased ? 2 : 1))
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .overlay {
            if isSelected {
                outerShape
                    .stroke(Color.accentPrimary, lineWidth: 3)
            }
        }
    }

    // MARK: - Selection Indicator

    @ViewBuilder
    private var selectionIndicator: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.accentPrimary : Color.cream.opacity(0.8))
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .stroke(Color.secondary.opacity(0.4), lineWidth: isSelected ? 0 : 1.5)
                )
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Color.warmWhite)
            }
        }
        .padding(8)
    }

    // MARK: - Computed Properties

    private var imageHeight: CGFloat {
        dynamicTypeSize >= .xxxLarge ? 120 : 160
    }

    private var outerShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
    }

    private var innerShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
    }

    private var accessibilityDescription: String {
        var desc = "\(item.displayName)"
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
        case .processing: return "Processing"
        case .complete: return "Complete"
        case .failed: return "Failed"
        }
    }

    private func handleTap() {
        if reduceMotion {
            // Skip animation for Reduce Motion users
            onTap?()
        } else {
            withAnimation(.brandPress) {
                isPressed = true
            }
            onTap?()

            pressAnimationTask?.cancel()
            pressAnimationTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(150))
                guard !Task.isCancelled else { return }
                withAnimation(.brandPress) {
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
            .foregroundStyle(Color.deepPlum)
            .clipShape(Capsule())
    }

    private var conditionColor: Color {
        switch condition {
        case .new, .likeNew: return .mutedSage
        case .good: return .softTeal
        case .fair: return .peach
        case .poor: return .salmon
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
            .foregroundStyle(Color.deepPlum)
            .clipShape(Capsule())
    }

    private var statusText: String {
        switch status {
        case .processing: return "Processing"
        case .complete: return "Complete"
        case .failed: return "Failed"
        }
    }

    private var statusColor: Color {
        switch status {
        case .processing: return .peach
        case .complete: return .mutedSage
        case .failed: return .salmon
        }
    }
}

// MARK: - Context Menu Modifier

/// Conditionally applies context menu only when NOT in selection mode.
/// This avoids gesture conflicts where the context menu intercepts taps in selection mode.
private struct SelectionModeContextMenuModifier: ViewModifier {
    let isSelectionMode: Bool
    let onEdit: (() -> Void)?
    let onRefresh: (() -> Void)?
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

                if let onRefresh = onRefresh {
                    Button {
                        onRefresh()
                    } label: {
                        Label("Refresh", systemImage: "arrow.triangle.2.circlepath")
                    }
                }

                if let onDelete = onDelete {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }
}
