import SwiftUI
import Core
import Persistence

/// Before/After comparison sheet showing original vs rescan results
public struct RescanComparisonSheet: View {
    @Bindable var viewModel: EditItemViewModel
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: EditItemViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 32))
                            .foregroundStyle(.orange)

                        Text("Compare Results")
                            .font(.system(size: 24, weight: .bold, design: .rounded))

                        Text("Review the updated analysis from your new photo")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 16)

                    // Comparison cards
                    HStack(spacing: 16) {
                        ComparisonCard(
                            title: "Before",
                            item: viewModel.originalItem,
                            imageUrl: viewModel.originalItem.imageUrl
                        )

                        if case .comparing(let newItem) = viewModel.state {
                            ComparisonCard(
                                title: "After",
                                item: newItem,
                                imageUrl: newItem.imageUrl,
                                isHighlighted: true
                            )
                        }
                    }
                    .padding(.horizontal, 16)

                    // Field changes summary
                    if case .comparing(let newItem) = viewModel.state {
                        FieldChangesSummary(
                            original: viewModel.originalItem,
                            updated: newItem
                        )
                        .padding(.horizontal, 16)
                    }

                    Spacer(minLength: 100)
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        Task {
                            await viewModel.acceptRescanResult()
                            dismiss()
                        }
                    } label: {
                        Text("Looks Good")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)

                    Button {
                        viewModel.unlockManualEdit()
                    } label: {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                            Text("Still Incorrect?")
                        }
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancelFlow()
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled()
        .onChange(of: viewModel.state) { _, newState in
            if case .editing = newState {
                dismiss()
            }
        }
    }
}

// MARK: - Comparison Card

private struct ComparisonCard: View {
    let title: String
    let item: Item
    let imageUrl: String
    var isHighlighted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title badge
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(isHighlighted ? .white : .secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background {
                    Capsule()
                        .fill(isHighlighted ? Color.green : Color.secondary.opacity(0.2))
                }

            // Image thumbnail
            AsyncImage(url: URL(string: imageUrl)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 100)
                        .clipped()
                case .failure:
                    Rectangle()
                        .fill(.gray.opacity(0.2))
                        .frame(height: 100)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                default:
                    Rectangle()
                        .fill(.gray.opacity(0.1))
                        .frame(height: 100)
                        .overlay { ProgressView() }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Key fields
            VStack(alignment: .leading, spacing: 6) {
                if let name = item.name {
                    CompactFieldRow(label: "Name", value: name)
                }
                if let category = item.category {
                    CompactFieldRow(label: "Category", value: category)
                }
                if let brand = item.brand {
                    CompactFieldRow(label: "Brand", value: brand)
                }
                if let value = item.estimatedValue {
                    CompactFieldRow(label: "Value", value: "$\(String(format: "%.2f", value))")
                }
            }
        }
        .padding(12)
        .adaptiveGlass(cornerRadius: 16)
        .overlay {
            if isHighlighted {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.green, lineWidth: 2)
            }
        }
    }
}

private struct CompactFieldRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .lineLimit(1)
        }
    }
}

// MARK: - Field Change Model

private struct FieldChange: Identifiable {
    let id: String
    let field: String
    let from: String?
    let to: String?

    init(field: String, from: String?, to: String?) {
        self.id = field
        self.field = field
        self.from = from
        self.to = to
    }
}

// MARK: - Field Changes Summary

private struct FieldChangesSummary: View {
    let original: Item
    let updated: Item

    private var changes: [FieldChange] {
        var result: [FieldChange] = []

        if original.name != updated.name {
            result.append(FieldChange(field: "Name", from: original.name, to: updated.name))
        }
        if original.category != updated.category {
            result.append(FieldChange(field: "Category", from: original.category, to: updated.category))
        }
        if original.brand != updated.brand {
            result.append(FieldChange(field: "Brand", from: original.brand, to: updated.brand))
        }
        if original.model != updated.model {
            result.append(FieldChange(field: "Model", from: original.model, to: updated.model))
        }
        if original.color != updated.color {
            result.append(FieldChange(field: "Color", from: original.color, to: updated.color))
        }
        if original.estimatedValue != updated.estimatedValue {
            let fromValue = original.estimatedValue.map { "$\(String(format: "%.2f", $0))" }
            let toValue = updated.estimatedValue.map { "$\(String(format: "%.2f", $0))" }
            result.append(FieldChange(field: "Est. Value", from: fromValue, to: toValue))
        }

        return result
    }

    var body: some View {
        if !changes.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Changes Detected")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)

                VStack(spacing: 8) {
                    ForEach(changes) { change in
                        HStack {
                            Text(change.field)
                                .font(.system(size: 14, design: .rounded))
                            Spacer()
                            HStack(spacing: 4) {
                                Text(change.from ?? "--")
                                    .strikethrough()
                                    .foregroundStyle(.secondary)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.tertiary)
                                Text(change.to ?? "--")
                                    .foregroundStyle(.green)
                            }
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                        }
                    }
                }
                .padding(12)
                .adaptiveGlass(cornerRadius: 12)
            }
        }
    }
}
