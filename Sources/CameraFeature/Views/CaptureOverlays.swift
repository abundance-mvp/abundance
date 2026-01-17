import SwiftUI

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
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

/// Overlay shown during server-side object detection
struct AnalyzingOverlay: View {
    @State private var animationPhase: Double = 0

    var body: some View {
        VStack(spacing: 16) {
            // Pulsing scan lines animation
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Rectangle()
                        .fill(.white.opacity(0.3))
                        .frame(height: 2)
                        .offset(y: CGFloat(index - 1) * 30)
                        .opacity(scanLineOpacity(for: index))
                }
            }
            .frame(width: 100, height: 100)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animationPhase)

            Text("Analyzing...")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)

            Text("Detecting objects")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .onAppear {
            animationPhase = 1
        }
    }

    private func scanLineOpacity(for index: Int) -> Double {
        let offset = Double(index) * 0.3
        return 0.3 + 0.7 * sin((animationPhase + offset) * .pi)
    }
}

/// Overlay shown when an error occurs during capture flow
struct ErrorOverlay: View {
    let error: CaptureError
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow)

            Text(error.localizedDescription)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }

            Button("Try Again") {
                onDismiss()
            }
            .buttonStyle(CaptureButtonStyle(isPrimary: true))
            .padding(.top, 8)
        }
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
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
