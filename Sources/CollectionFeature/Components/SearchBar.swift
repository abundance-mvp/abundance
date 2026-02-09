// Sources/InventoryFeature/Components/SearchBar.swift
import SwiftUI
import Core

/// Search bar with Liquid Glass styling
/// Design spec: DESIGN-028-catalog-view-specification.md
public struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search items..."

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isFocused: Bool

    public init(text: Binding<String>, placeholder: String = "Search items...") {
        self._text = text
        self.placeholder = placeholder
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(.body, weight: .medium))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField(placeholder, text: $text)
                .font(.system(.body, design: .rounded))
                .focused($isFocused)
                .submitLabel(.search)
                .accessibilityIdentifier("inventory.searchField")
                .accessibilityLabel("Search items")
                .accessibilityHint("Search by category, color, material, or condition")

            if !text.isEmpty {
                Button {
                    withAnimation(reduceMotion ? nil : .brandPress) {
                        text = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(.body))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Circle())
                .accessibilityIdentifier("inventory.searchClearButton")
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            Color.clear
                .adaptiveGlass(in: Capsule())
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("inventory.searchBar")
    }
}

#Preview {
    @Previewable @State var text = ""
    SearchBar(text: $text)
        .padding()
}
