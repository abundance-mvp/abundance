import SwiftUI
import Core
import EdgeTAMFeature

/// Bottom tray showing thumbnails of selected segments.
///
/// Thumbnails slide in/out as segments are selected/deselected.
/// Tapping a thumbnail's remove button deselects that segment.
struct SegmentSelectionTray: View {
    let selectedSegments: [SegmentedObject]
    let onDeselectSegment: (UUID) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(selectedSegments) { segment in
                    segmentThumbnail(segment)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: selectedSegments.isEmpty ? 0 : 72)
        .animation(reduceMotion ? .brandReducedMotion : .brandDefault, value: selectedSegments.count)
    }

    @ViewBuilder
    private func segmentThumbnail(_ segment: SegmentedObject) -> some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.2))
                .frame(width: 56, height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue, lineWidth: 1.5)
                )

            // Remove button
            Button {
                onDeselectSegment(segment.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.white, .red)
            }
            .offset(x: 4, y: -4)
            .accessibilityLabel("Remove from selection")
        }
        .transition(.scale.combined(with: .opacity))
    }
}
