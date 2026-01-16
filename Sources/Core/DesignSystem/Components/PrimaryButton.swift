import SwiftUI

public struct PrimaryButton: View {
    // MARK: - Properties
    let title: String
    let action: () -> Void
    var isEnabled: Bool = true
    var isLoading: Bool = false

    // MARK: - State
    @State private var isPressed: Bool = false

    // MARK: - Initializer
    public init(title: String, action: @escaping () -> Void, isEnabled: Bool = true, isLoading: Bool = false) {
        self.title = title
        self.action = action
        self.isEnabled = isEnabled
        self.isLoading = isLoading
    }

    // MARK: - Body
    public var body: some View {
        Button(action: handleTap) {
            ZStack {
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
                    .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.primary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .frame(minHeight: 44) // Accessibility tap target
            .adaptiveGlass(in: Capsule())
            .shadow(
                color: Color.brandBrightBlue.opacity(isEnabled ? 0.5 : 0.2),
                radius: isPressed ? 8 : 12,
                x: 0,
                y: 4
            )
            .overlay {
                Capsule()
                    .stroke(Color.brandBrightBlue.opacity(isEnabled ? 1.0 : 0.3), lineWidth: 2)
            }
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.5)
        }
        .disabled(!isEnabled || isLoading)
        .sensoryFeedback(.impact(weight: .medium), trigger: isPressed)
        .animation(.brandSnappy, value: isPressed)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .accessibilityRemoveTraits(isEnabled ? [] : .isButton)
        .accessibilityAddTraits(isEnabled ? [] : .isStaticText)
    }

    // MARK: - Actions
    private func handleTap() {
        isPressed = true
        action()

        // Reset pressed state after animation
        Task {
            try? await Task.sleep(for: .seconds(0.2))
            isPressed = false
        }
    }
}

#Preview("Primary Button - States") {
    VStack(spacing: 24) {
        PrimaryButton(title: "Get Started", action: {})

        PrimaryButton(title: "Disabled", action: {}, isEnabled: false)

        PrimaryButton(title: "Loading...", action: {}, isLoading: true)
    }
    .padding()
}
