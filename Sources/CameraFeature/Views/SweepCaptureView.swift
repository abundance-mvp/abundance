import SwiftUI
import Core
import EdgeTAMFeature

/// Main sweep capture mode view with segment overlays and selection tray.
///
/// Renders on top of the camera preview when sweep mode is active.
/// Shows detected segments as tappable overlays, a selection tray at bottom,
/// and a "Catalog" action button when items are selected.
public struct SweepCaptureView: View {
    var viewModel: SweepCaptureViewModel
    let onCatalog: () -> Void
    let onCancel: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    /// Dynamic Type-scaled padding values
    @ScaledMetric(relativeTo: .body) private var horizontalPadding: CGFloat = 16
    @ScaledMetric(relativeTo: .body) private var verticalPadding: CGFloat = 8
    @ScaledMetric(relativeTo: .body) private var bottomPadding: CGFloat = 16

    public init(
        viewModel: SweepCaptureViewModel,
        onCatalog: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onCatalog = onCatalog
        self.onCancel = onCancel
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Segment overlays
                ForEach(viewModel.segments) { segment in
                    SegmentOverlayView(
                        segment: segment,
                        isSelected: viewModel.selectedSegmentIds.contains(segment.id),
                        geometrySize: geometry.size,
                        onTap: {
                            viewModel.toggleSelection(segment.id)
                        }
                    )
                }

                // Bottom panel: selection tray + actions
                VStack(spacing: 0) {
                    Spacer()

                    // Status indicator
                    sweepStatusBar

                    // Selection tray
                    SegmentSelectionTray(
                        selectedSegments: viewModel.selectedSegments,
                        onDeselectSegment: { segmentId in
                            viewModel.toggleSelection(segmentId)
                        }
                    )

                    // Action buttons
                    actionButtons
                        .padding(.bottom, bottomPadding)
                }
            }
        }
    }

    // MARK: - Status Bar

    private var sweepStatusBar: some View {
        Group {
            switch viewModel.sweepState {
            case .scanning(let count):
                HStack {
                    ProgressView()
                        .tint(.white)
                    Text("Scanning... \(count) objects found")
                }
            case .reviewing(let selected, let total):
                Text("Selected \(selected) of \(total)")
            case .uploading(let progress):
                HStack {
                    ProgressView(value: progress)
                        .frame(width: 100)
                    Text("Uploading...")
                }
            case .processing:
                HStack {
                    ProgressView()
                        .tint(.white)
                    Text("Analyzing...")
                }
            default:
                Text("Pan across items to detect")
            }
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.white)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background {
            if reduceTransparency {
                Capsule().fill(Color.black.opacity(0.7))
            } else {
                Capsule().adaptiveGlass(in: Capsule())
            }
        }
        .padding(.bottom, verticalPadding)
        .accessibilityAddTraits(.updatesFrequently)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 20) {
            Button("Cancel") {
                onCancel()
            }
            .buttonStyle(.bordered)
            .tint(.white)

            Button {
                onCatalog()
            } label: {
                Label("Catalog \(viewModel.selectedSegments.count)", systemImage: "checkmark.circle")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canCatalog)
        }
        .padding(.horizontal, horizontalPadding)
    }

}
