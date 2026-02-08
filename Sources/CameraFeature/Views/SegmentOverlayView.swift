import SwiftUI
import Core
import EdgeTAMFeature

/// Renders segment masks as translucent overlays on the camera preview.
///
/// Visual states per SPEC-PIPE-004-A Section 4:
/// - Unselected: translucent white (20% opacity), thin white border, subtle pulse
/// - Selected: translucent salmon (30% opacity), solid salmon border, checkmark badge
struct SegmentOverlayView: View {
    let segment: SegmentedObject
    let isSelected: Bool
    let geometrySize: CGSize
    let onTap: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        let frame = segmentFrame(in: geometrySize)

        ZStack(alignment: .topTrailing) {
            // Segment overlay
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(overlayFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(
                            isSelected ? Color.salmon : Color.white.opacity(0.6),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .frame(width: frame.width, height: frame.height)

            // Checkmark badge for selected segments
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(.white, Color.salmon)
                    .padding(4)
            }
        }
        .position(x: frame.midX, y: frame.midY)
        .onTapGesture {
            onTap()
        }
        .accessibilityLabel(isSelected ? "Selected object" : "Detected object")
        .accessibilityHint(isSelected ? "Double tap to deselect" : "Double tap to select for cataloging")
        .accessibilityAddTraits(.isButton)
    }

    /// Overlay fill, adjusted for Reduce Transparency
    private var overlayFill: Color {
        if reduceTransparency {
            return isSelected ? Color.salmon.opacity(0.5) : Color.white.opacity(0.4)
        } else {
            return isSelected ? Color.salmon.opacity(0.3) : Color.white.opacity(0.2)
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
