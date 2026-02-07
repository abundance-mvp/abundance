import SwiftUI
import Core

/// Capture mode picker: Photo / Burst / Sweep
///
/// Only shows Sweep option on eligible devices (iPhone 15 Pro+).
/// Visible at bottom of camera UI.
struct SweepModeToggle: View {
    @Binding var selectedMode: CaptureMode
    let isSweepAvailable: Bool

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
            Capsule()
                .adaptiveGlass(in: Capsule())
        }
    }

    @ViewBuilder
    private func modeButton(_ mode: CaptureMode, label: String, icon: String) -> some View {
        Button {
            selectedMode = mode
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.body.weight(selectedMode == mode ? .bold : .regular))
                Text(label)
                    .font(.caption2.weight(selectedMode == mode ? .bold : .regular))
            }
            .foregroundStyle(selectedMode == mode ? .blue : .white)
        }
        .accessibilityLabel("\(label) mode")
        .accessibilityAddTraits(selectedMode == mode ? .isSelected : [])
    }
}
