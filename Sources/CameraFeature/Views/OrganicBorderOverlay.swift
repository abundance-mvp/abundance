import SwiftUI
import VisionCore

/// Displays organic border around detected object with color-coded catalog mode
/// - Mint green: Automatic catalog (high confidence + quality)
/// - Grey: Manual catalog (requires double-tap)
public struct OrganicBorderOverlay: View {

    let object: DetectedObject
    @State private var isAnimating = false

    public nonisolated init(object: DetectedObject) {
        self.object = object
    }

    /// Border color based on catalog mode
    private var borderColor: Color {
        object.borderColor
    }

    /// Glow radius based on catalog mode
    private var glowRadius: CGFloat {
        object.catalogMode == .automatic ? 16 : 12
    }

    /// Glow opacity based on catalog mode
    private var glowOpacity: Double {
        object.catalogMode == .automatic ? 0.8 : 0.6
    }

    public var body: some View {
        // Organic shape from mask
        OrganicBorderShape(mask: object.mask)
            .stroke(borderColor, lineWidth: 3)
            .shadow(
                color: borderColor.opacity(glowOpacity),
                radius: glowRadius,
                x: 0,
                y: 0
            )
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .overlay(alignment: .top) {
                confidenceBadge
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
            .onDisappear {
                isAnimating = false
            }
    }

    /// Confidence badge with label
    private var confidenceBadge: some View {
        HStack(spacing: 4) {
            Text("\(Int(object.confidence * 100))%")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(object.label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThickMaterial, in: Capsule())
        .offset(y: -8)
    }
}

// MARK: - Preview

#Preview("Automatic Mode") {
    ZStack {
        Color.black.ignoresSafeArea()

        OrganicBorderOverlay(object: DetectedObject(
            label: "backpack",
            confidence: 0.92,
            boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.5),
            qualityScore: 0.85,
            catalogMode: .automatic,
            mask: nil,
            fingerprint: "preview-fingerprint"
        ))
        .frame(width: 200, height: 300)
    }
}

#Preview("Manual Mode") {
    ZStack {
        Color.black.ignoresSafeArea()

        OrganicBorderOverlay(object: DetectedObject(
            label: "bottle",
            confidence: 0.55,
            boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
            qualityScore: 0.50,
            catalogMode: .manual,
            mask: nil,
            fingerprint: "preview-fingerprint"
        ))
        .frame(width: 150, height: 200)
    }
}
