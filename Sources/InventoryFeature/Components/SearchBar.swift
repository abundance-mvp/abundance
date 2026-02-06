// Sources/InventoryFeature/Components/SearchBar.swift
import SwiftUI
import Core

/// Search bar with Liquid Glass styling
/// Design spec: DESIGN-028-catalog-view-specification.md
public struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search items..."

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
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

            TextField(placeholder, text: $text)
                .font(.system(.body, design: .rounded))
                .focused($isFocused)
                .submitLabel(.search)
                .accessibilityIdentifier("inventory.searchField")
                .accessibilityLabel("Search items")
                .accessibilityHint("Search by category, color, material, or condition")

            if !text.isEmpty {
                Button {
                    withAnimation(reduceMotion ? nil : .brandSnappy) {
                        text = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(.body))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("inventory.searchClearButton")
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            if #available(iOS 26.0, macOS 26.0, *) {
                if !reduceTransparency {
                    Color.clear
                        .glassEffect(in: Capsule())
                } else {
                    Color.backgroundDefault
                        .clipShape(Capsule())
                }
            } else {
                Capsule()
                    .fill(.thickMaterial)
            }
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
