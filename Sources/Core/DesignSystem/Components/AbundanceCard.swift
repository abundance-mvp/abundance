import SwiftUI

/// Generic card container with cream background and peach border
/// Used as the standard content surface throughout the app
public struct AbundanceCard<Content: View>: View {
    let cornerRadius: CGFloat
    @ViewBuilder let content: () -> Content

    @Environment(\.colorSchemeContrast) private var contrast

    public init(cornerRadius: CGFloat = 16, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content
    }

    public var body: some View {
        content()
            .background(
                Color.cream,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.peach, lineWidth: contrast == .increased ? 2 : 1)
            )
    }
}

#Preview("AbundanceCard") {
    VStack(spacing: 16) {
        AbundanceCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Card Title")
                    .font(.headline)
                Text("Card content goes here")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }

        AbundanceCard(cornerRadius: 24) {
            Text("Large corner radius card")
                .padding(24)
        }
    }
    .padding()
}
