import SwiftUI

/// Display empty state with call-to-action
/// **Design Spec:** DESIGN-031-swiftui-component-library.md (EmptyStateCard)
struct EmptyStateCard: View {
    let iconName: String
    let headline: String
    let description: String
    let buttonTitle: String
    let action: () -> Void

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: iconName)
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(headline)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            PrimaryButton(title: buttonTitle, action: action)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(backgroundMaterial, in: outerShape)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    private var backgroundMaterial: AnyShapeStyle {
        reduceTransparency ? AnyShapeStyle(Color.backgroundDefault) : AnyShapeStyle(.thickMaterial)
    }

    private var outerShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 24)
    }
}
