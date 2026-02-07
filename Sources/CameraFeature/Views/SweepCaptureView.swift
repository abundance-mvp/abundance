import SwiftUI
import Core
import EdgeTAMFeature

/// Main sweep capture mode view with segment overlays and selection tray.
///
/// Renders on top of the camera preview when sweep mode is active.
/// Shows detected segments as tappable overlays, a selection tray at bottom,
/// and a "Catalog" action button when items are selected.
public struct SweepCaptureView: View {
    @ObservedObject var viewModel: SweepCaptureViewModel
    let onCatalog: () -> Void
    let onCancel: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    /// Throttle to prevent haptic spam when many segments appear at once
    @State private var lastSegmentHapticTime: Date = .distantPast

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
                            #if os(iOS)
                            let style: UIImpactFeedbackGenerator.FeedbackStyle =
                                viewModel.selectedSegmentIds.contains(segment.id) ? .medium : .light
                            UIImpactFeedbackGenerator(style: style).impactOccurred()
                            #endif
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
                        .padding(.bottom, 16)
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
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background {
            if reduceTransparency {
                Capsule().fill(Color.black.opacity(0.7))
            } else {
                Capsule().adaptiveGlass(in: Capsule())
            }
        }
        .padding(.bottom, 8)
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
        .padding(.horizontal, 16)
    }

    // MARK: - Haptics

    /// Trigger throttled haptic for new segment detection (max 1 per 500ms)
    private func triggerNewSegmentHaptic() {
        #if os(iOS)
        let now = Date()
        guard now.timeIntervalSince(lastSegmentHapticTime) >= 0.5 else { return }
        lastSegmentHapticTime = now
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }
}
