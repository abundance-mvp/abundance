import SwiftUI
import EdgeTAMFeature

/// Renders segment masks as translucent overlays on the camera preview.
///
/// Visual states per SPEC-PIPE-004-A Section 4:
/// - Unselected: translucent white (20% opacity), thin white border, subtle pulse
/// - Selected: translucent blue (30% opacity), solid blue border, checkmark badge
struct SegmentOverlayView: View {
    let segment: SegmentedObject
    let isSelected: Bool
    let geometrySize: CGSize
    let onTap: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let frame = segmentFrame(in: geometrySize)

        ZStack(alignment: .topTrailing) {
            // Segment overlay
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.3) : Color.white.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected ? Color.blue : Color.white.opacity(0.6),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
                .frame(width: frame.width, height: frame.height)

            // Checkmark badge for selected segments
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white, .blue)
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
