import SwiftUI
import Core

// MARK: - Capture Overlay Views

/// Overlay shown during photo capture with count indicator
struct CaptureOverlay: View {
    let photoCount: Int
    let isLongPress: Bool

    var body: some View {
        VStack {
            Spacer()

            if isLongPress && photoCount > 0 {
                Text("\(photoCount) photos")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
            }

            Spacer()
        }
    }
}

/// Overlay shown during photo upload with progress indicator
struct UploadingOverlay: View {
    let progress: Double

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        VStack(spacing: 16) {
            ProgressView(value: progress)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)

            Text("Uploading...")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)

            Text("\(Int(progress * 100))%")
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(32)
        .background {
            if reduceTransparency {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.85))
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            }
        }
    }
}

/// Overlay shown during server-side object detection
struct AnalyzingOverlay: View {
    @State private var animationPhase: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        VStack(spacing: 16) {
            // Pulsing scan lines animation (disabled with Reduce Motion)
            ZStack {
                if reduceMotion {
                    // Static indicator for Reduce Motion users
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                } else {
                    ForEach(0..<3, id: \.self) { index in
                        Rectangle()
                            .fill(.white.opacity(0.3))
                            .frame(height: 2)
                            .offset(y: CGFloat(index - 1) * 30)
                            .opacity(scanLineOpacity(for: index))
                    }
                }
            }
            .frame(width: 100, height: 100)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                value: animationPhase
            )

            Text("Analyzing...")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)

            Text("Detecting objects")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(32)
        .background {
            if reduceTransparency {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.85))
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            }
        }
        .onAppear {
            if !reduceMotion {
                animationPhase = 1
            }
        }
    }

    private func scanLineOpacity(for index: Int) -> Double {
        let offset = Double(index) * 0.3
        return 0.3 + 0.7 * sin((animationPhase + offset) * .pi)
    }
}

/// Overlay shown when an error occurs during capture flow
/// Enhanced with Liquid Glass styling for iOS 26+ and automatic retry logic
struct ErrorOverlay: View {
    let error: CaptureError
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var isRetrying = false

    var body: some View {
        VStack(spacing: 20) {
            // Error icon with category-based styling
            errorIcon

            // Error message
            VStack(spacing: 8) {
                Text(errorTitle)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)

                Text(error.localizedDescription)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }

            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            // Retry button with loading state
            if error.isRetryable {
                retryButton
            } else {
                dismissButton
            }
        }
        .padding(32)
        .frame(maxWidth: 320)
        .background(overlayBackground)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(error.localizedDescription)")
    }

    private var errorIcon: some View {
        ZStack {
            Circle()
                .fill(iconColor.opacity(0.2))
                .frame(width: 72, height: 72)

            Image(systemName: iconName)
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(iconColor)
        }
    }

    private var iconName: String {
        switch error {
        case .notAuthenticated, .authenticationExpired:
            return "person.crop.circle.badge.exclamationmark"
        case .networkTimeout, .uploadFailed:
            return "wifi.exclamationmark"
        case .detectionTimeout, .detectionFailed, .invalidResponse:
            return "server.rack"
        default:
            return "exclamationmark.triangle.fill"
        }
    }

    private var iconColor: Color {
        switch error {
        case .networkTimeout, .uploadFailed:
            return .orange
        case .notAuthenticated, .authenticationExpired:
            return .blue
        case .detectionTimeout, .detectionFailed, .invalidResponse:
            return .red
        default:
            return .yellow
        }
    }

    private var errorTitle: String {
        switch error {
        case .notAuthenticated, .authenticationExpired:
            return "Sign In Required"
        case .networkTimeout, .uploadFailed:
            return "Connection Problem"
        case .detectionTimeout, .detectionFailed, .invalidResponse:
            return "Analysis Failed"
        case .captureFailure, .invalidImageData, .burstCaptureTooShort:
            return "Capture Issue"
        default:
            return "Something Went Wrong"
        }
    }

    private var retryButton: some View {
        Button {
            isRetrying = true
            // Add slight delay for visual feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onDismiss()
            }
        } label: {
            HStack(spacing: 8) {
                if isRetrying {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
                Text(isRetrying ? "Retrying..." : "Try Again")
            }
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.white, in: RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isRetrying)
        .padding(.top, 8)
    }

    private var dismissButton: some View {
        Button {
            onDismiss()
        } label: {
            Text("Dismiss")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var overlayBackground: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            if !reduceTransparency {
                Color.clear
                    .glassEffect(in: RoundedRectangle(cornerRadius: 24))
            } else {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.85))
            }
        } else {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThickMaterial)
        }
    }
}

/// Button style for capture flow actions
struct CaptureButtonStyle: ButtonStyle {
    let isPrimary: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(isPrimary ? .black : .white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isPrimary ? .white : .white.opacity(0.2))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}
