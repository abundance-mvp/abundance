import SwiftUI
import Core

/// Capture mode picker: Photo / Burst / Sweep
///
/// Only shows Sweep option on eligible devices (iPhone 15 Pro+).
/// Visible at bottom of camera UI.
struct SweepModeToggle: View {
    @Binding var selectedMode: CaptureMode
    let isSweepAvailable: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        HStack(spacing: 24) {
            modeButton(.single, label: "Photo", icon: "camera")
            modeButton(.burst, label: "Burst", icon: "rectangle.stack")

            if isSweepAvailable {
                modeButton(.sweep, label: "Sweep", icon: "viewfinder")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background {
            if reduceTransparency {
                Capsule().fill(Color.black.opacity(0.7))
            } else {
                Capsule().adaptiveGlass(in: Capsule())
            }
        }
    }

    @ViewBuilder
    private func modeButton(_ mode: CaptureMode, label: String, icon: String) -> some View {
        Button {
            withAnimation(reduceMotion ? .brandReducedMotion : .brandPress) {
                selectedMode = mode
            }
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(.body, design: .rounded, weight: selectedMode == mode ? .bold : .regular))
                Text(label)
                    .font(.system(.caption2, design: .rounded, weight: selectedMode == mode ? .bold : .regular))
            }
            .foregroundStyle(selectedMode == mode ? Color.salmon : .white)
            .scaleEffect(selectedMode == mode ? 1.0 : 0.95)
            .animation(reduceMotion ? .brandReducedMotion : .brandPress, value: selectedMode)
        }
        .accessibilityLabel("\(label) mode")
        .accessibilityHint(selectedMode == mode ? "Currently selected" : "Double tap to switch to \(label) mode")
        .accessibilityAddTraits(selectedMode == mode ? .isSelected : [])
    }
}
