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

// MARK: - AbundanceCard Modifier

/// ViewModifier that applies cream background + peach stroke card styling
/// Complements AbundanceCard wrapper — use when you need modifier syntax
struct AbundanceCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content
            .background(Color.cream, in: shape)
            .overlay(shape.stroke(Color.peach, lineWidth: contrast == .increased ? 2 : 1))
    }
}

extension View {
    /// Apply standard Abundance card styling (cream background, peach stroke)
    public func abundanceCardStyle(cornerRadius: CGFloat = 16) -> some View {
        modifier(AbundanceCardModifier(cornerRadius: cornerRadius))
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
