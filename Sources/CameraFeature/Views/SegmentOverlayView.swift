import SwiftUI
import Core
import EdgeTAMFeature

/// Renders segment masks as translucent overlays on the camera preview.
///
/// Visual states per SPEC-PIPE-004-A Section 4:
/// - Unselected: translucent white (20% opacity), thin white border, subtle pulse
/// - Selected: translucent salmon (30% opacity), solid salmon border, checkmark badge
/// - Duplicate: translucent yellow (20% opacity), "Already selected" badge (Phase 3)
///
/// When `maskData` is available, renders organic contour via `MaskContourShape`.
/// Otherwise falls back to `RoundedRectangle`.
struct SegmentOverlayView: View {
    let segment: SegmentedObject
    let isSelected: Bool
    let isDuplicate: Bool
    let geometrySize: CGSize
    let onTap: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    /// Pulse animation state for unselected segments
    @State private var isPulsing = false

    var body: some View {
        let frame = segmentFrame(in: geometrySize)

        ZStack(alignment: .topTrailing) {
            // Segment overlay — organic mask or rounded rectangle
            segmentShape(frame: frame)

            // Badge: checkmark for selected, "Already scanned" for duplicates
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(.white, Color.salmon)
                    .padding(4)
            } else if isDuplicate {
                Text("Already scanned")
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.cream.opacity(0.9)))
                    .padding(4)
            }
        }
        .frame(width: frame.width, height: frame.height)
        .contentShape(Rectangle())
        .position(x: frame.midX, y: frame.midY)
        .animation(.linear(duration: 0.15), value: segment.boundingBox)
        .onTapGesture {
            onTap()
        }
        .transition(.opacity.animation(.brandReducedMotion))
        .accessibilityLabel(isDuplicate ? "Duplicate object" : isSelected ? "Selected object" : "Detected object")
        .accessibilityHint(isDuplicate ? "Already scanned in this sweep" : isSelected ? "Double tap to deselect" : "Double tap to select for cataloging")
        .accessibilityAddTraits(.isButton)
        .onAppear {
            if !isSelected && !reduceMotion {
                isPulsing = true
            }
        }
        .onChange(of: isSelected) { _, newValue in
            isPulsing = !newValue && !reduceMotion
        }
    }

    // MARK: - Shape Rendering

    @ViewBuilder
    private func segmentShape(frame: CGRect) -> some View {
        if let maskData = segment.maskData, segment.maskWidth > 0, segment.maskHeight > 0 {
            // Organic contour from EdgeTAM mask
            let shape = MaskContourShape(
                maskData: maskData,
                maskWidth: segment.maskWidth,
                maskHeight: segment.maskHeight
            )

            shape
                .fill(overlayFill)
                .overlay(
                    shape.stroke(
                        strokeColor,
                        lineWidth: isSelected ? 2 : 1
                    )
                )
                .frame(width: frame.width, height: frame.height)
                .opacity(pulseOpacity)
                .animation(
                    isPulsing ? .brandPulse : .default,
                    value: isPulsing
                )
        } else {
            // Fallback: rounded rectangle bounding box
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(overlayFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(
                            strokeColor,
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .frame(width: frame.width, height: frame.height)
                .opacity(pulseOpacity)
                .animation(
                    isPulsing ? .brandPulse : .default,
                    value: isPulsing
                )
        }
    }

    /// Pulse opacity for unselected segments (15-25% cycle per spec)
    private var pulseOpacity: Double {
        if isSelected { return 1.0 }
        return isPulsing ? 0.75 : 1.0
    }

    /// Stroke color based on selection/duplicate state
    private var strokeColor: Color {
        if isSelected { return Color.salmon }
        if isDuplicate { return Color.cream.opacity(0.6) }
        return Color.white.opacity(0.6)
    }

    /// Overlay fill, adjusted for Reduce Transparency
    private var overlayFill: Color {
        if reduceTransparency {
            if isSelected { return Color.salmon.opacity(0.5) }
            if isDuplicate { return Color.cream.opacity(0.4) }
            return Color.white.opacity(0.4)
        } else {
            if isSelected { return Color.salmon.opacity(0.3) }
            if isDuplicate { return Color.cream.opacity(0.2) }
            return Color.white.opacity(0.2)
        }
    }

    /// Convert normalized bounding box to pixel coordinates
    /// Note: EdgeTAM bounding boxes are already in SwiftUI coordinate space (top-left origin)
    private func segmentFrame(in size: CGSize) -> CGRect {
        CGRect(
            x: segment.boundingBox.origin.x * size.width,
            y: segment.boundingBox.origin.y * size.height,
            width: segment.boundingBox.width * size.width,
            height: segment.boundingBox.height * size.height
        )
    }
}
