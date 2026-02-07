import SwiftUI

/// Sparkle particle animation triggered when object is automatically cataloged
/// Displays 12 mint green particles radiating from center over 0.5s
public struct SparkleAnimation: View {

    let center: CGPoint
    @State private var sparkles: [Sparkle] = []

    /// Individual sparkle particle
    struct Sparkle: Identifiable {
        let id = UUID()
        let offset: CGSize
        let size: CGFloat
        let opacity: Double
    }

    public var body: some View {
        ZStack {
            ForEach(sparkles) { sparkle in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.softTeal, // Brand teal
                                Color.white
                            ],
                            startPoint: .center,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: sparkle.size, height: sparkle.size)
                    .offset(sparkle.offset)
                    .opacity(sparkle.opacity)
            }
        }
        .position(center)
        .onAppear {
            generateSparkles()
            animateSparkles()
        }
    }

    /// Generate initial sparkle particles
    private func generateSparkles() {
        sparkles = (0..<12).map { _ in
            let angle = Double.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 10...30)
            return Sparkle(
                offset: CGSize(
                    width: cos(angle) * distance,
                    height: sin(angle) * distance
                ),
                size: CGFloat.random(in: 4...8),
                opacity: 1.0
            )
        }
    }

    /// Animate sparkles outward and fade
    private func animateSparkles() {
        withAnimation(.easeOut(duration: 0.5)) {
            sparkles = sparkles.map { sparkle in
                Sparkle(
                    offset: CGSize(
                        width: sparkle.offset.width * 3,
                        height: sparkle.offset.height * 3
                    ),
                    size: sparkle.size,
                    opacity: 0
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        SparkleAnimation(center: CGPoint(x: 200, y: 300))
    }
}
