import SwiftUI
import Core
import EdgeTAMFeature

/// Main sweep capture mode view with segment overlays and selection tray.
///
/// Renders on top of the camera preview when sweep mode is active.
/// Shows detected segments as tappable overlays, a selection tray at bottom,
/// and a "Catalog" action button when items are selected.
public struct SweepCaptureView: View {
    @Bindable var viewModel: SweepCaptureViewModel
    let onCatalog: () -> Void
    let onCancel: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    /// Dynamic Type-scaled padding values
    @ScaledMetric(relativeTo: .body) private var horizontalPadding: CGFloat = 16
    @ScaledMetric(relativeTo: .body) private var verticalPadding: CGFloat = 8
    @ScaledMetric(relativeTo: .body) private var bottomPadding: CGFloat = 16
    @ScaledMetric(relativeTo: .largeTitle) private var errorIconSize: CGFloat = 40

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
                // Error state overlay
                if case .error(let error) = viewModel.sweepState {
                    sweepErrorOverlay(error: error)
                } else {
                    // Segment overlays
                    ForEach(viewModel.segments) { segment in
                        SegmentOverlayView(
                            segment: segment,
                            isSelected: viewModel.selectedSegmentIds.contains(segment.id),
                            isDuplicate: viewModel.duplicateSegmentIds.contains(segment.id),
                            geometrySize: geometry.size,
                            onTap: {
                                viewModel.toggleSelection(segment.id)
                            }
                        )
                    }
                }

                // Tap-to-scan fallback for low-FPS devices
                if viewModel.performanceTier == .fallback,
                   case .scanning = viewModel.sweepState {
                    VStack {
                        Spacer()
                        Text("Tap to scan")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(.ultraThinMaterial))
                        Spacer()
                    }
                    .allowsHitTesting(false)
                }

                // Top center: status indicator (reduced opacity)
                VStack {
                    if case .error = viewModel.sweepState {
                        EmptyView()
                    } else {
                        sweepStatusBar
                            .opacity(0.75)
                            .padding(.top, 60)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .center)

                // Bottom panel: selection tray + actions
                VStack(spacing: 0) {
                    Spacer()

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
        .onAppear {
            viewModel.start()
        }
    }

    // MARK: - Error Overlay

    private func sweepErrorOverlay(error: SweepError) -> some View {
        VStack(spacing: 16) {
            if case .modelsNotBundled = error {
                Image(systemName: "sparkles")
                    .font(.system(size: errorIconSize))
                    .foregroundStyle(Color.softTeal)

                Text("Sweep Mode Coming Soon")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("This feature is under development")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: errorIconSize))
                    .foregroundStyle(.secondary)

                Text(error.errorDescription ?? "Sweep mode unavailable")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Use Photo or Burst mode instead")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(32)
    }

    // MARK: - Status Bar

    private var sweepStatusBar: some View {
        Group {
            switch viewModel.sweepState {
            case .loading:
                HStack {
                    ProgressView()
                        .tint(.white)
                    Text("Loading...")
                }
            case .ready:
                Text("Sweep Ready")
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
                        .tint(Color.salmon)
                    Text("Uploading...")
                }
            case .processing:
                HStack {
                    ProgressView()
                        .tint(.white)
                    Text("Analyzing...")
                }
            case .complete(let count):
                Label("\(count) items cataloged", systemImage: "checkmark.circle")
            default:
                EmptyView()
            }
        }
        .font(.system(.subheadline, design: .rounded, weight: .medium))
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
        .accessibilityLabel(sweepStatusAccessibilityLabel)
    }

    /// Accessibility label for the sweep status bar
    private var sweepStatusAccessibilityLabel: String {
        switch viewModel.sweepState {
        case .loading:
            return "Loading sweep mode"
        case .ready:
            return "Sweep ready"
        case .scanning(let count):
            return "Scanning, \(count) objects found"
        case .reviewing(let selected, let total):
            return "Reviewing, \(selected) of \(total) selected"
        case .uploading(let progress):
            return "Uploading, \(Int(progress * 100)) percent complete"
        case .processing:
            return "Analyzing items"
        case .complete(let count):
            return "\(count) items cataloged"
        default:
            return "Sweep mode"
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 20) {
            Button("Cancel") {
                onCancel()
            }
            .font(.system(.body, design: .rounded, weight: .medium))
            .buttonStyle(.bordered)
            .tint(.white)
            .accessibilityLabel("Cancel sweep")
            .accessibilityHint("Double tap to cancel and return to camera")

            Button {
                onCatalog()
            } label: {
                Label("Catalog \(viewModel.selectedSegments.count)", systemImage: "checkmark.circle")
                    .font(.system(.body, design: .rounded, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.salmon)
            .disabled(!viewModel.canCatalog)
            .accessibilityLabel("Catalog \(viewModel.selectedSegments.count) items")
            .accessibilityHint(viewModel.canCatalog ? "Double tap to catalog selected items" : "Select items first")
        }
        .padding(.horizontal, horizontalPadding)
    }

}
