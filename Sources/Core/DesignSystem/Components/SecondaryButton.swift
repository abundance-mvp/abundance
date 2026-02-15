import SwiftUI

public struct SecondaryButton: View {
    // MARK: - Properties
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true

    // MARK: - State
    @State private var isPressed: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Initializer
    public init(title: String, action: @escaping () -> Void, isEnabled: Bool = true) {
        self.title = title
        self.action = action
        self.isEnabled = isEnabled
    }

    // MARK: - Body
    public var body: some View {
        Button(action: handleTap) {
            Text(title)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.salmon)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .frame(minHeight: 44)
                .background(isPressed ? Color.salmon.opacity(0.15) : Color.clear, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(Color.salmon, lineWidth: 1.5)
                }
                .scaleEffect(isPressed ? 0.97 : 1.0)
                .opacity(isEnabled ? 1.0 : 0.5)
        }
        .disabled(!isEnabled)
        .sensoryFeedback(.impact(weight: .light), trigger: isPressed)
        .animation(reduceMotion ? .brandReducedMotion : .brandPress, value: isPressed)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .accessibilityRemoveTraits(isEnabled ? [] : .isButton)
        .accessibilityAddTraits(isEnabled ? [] : .isStaticText)
    }

    // MARK: - Actions
    private func handleTap() {
        isPressed = true
        action()

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.2))
            isPressed = false
        }
    }
}

#Preview("Secondary Button - States") {
    VStack(spacing: 24) {
        SecondaryButton(title: "Cancel", action: {})

        SecondaryButton(title: "Disabled", action: {}, isEnabled: false)
    }
    .padding()
}
