import SwiftUI
import AVFoundation

/// Main capture view with double-tap and long-press gestures
/// Replaces CameraDetectionView - no real-time YOLO detection
public struct CaptureView: View {

    @StateObject private var viewModel: CaptureSessionViewModel
    private let cameraService: CameraService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @State private var frozenFrame: Data?
    @State private var longPressActive = false

    public init(
        viewModel: CaptureSessionViewModel = CaptureSessionViewModel(),
        cameraService: CameraService = CameraService()
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.cameraService = cameraService
    }

    public var body: some View {
        GeometryReader { geometry in
            captureContent(geometry: geometry)
                .gesture(gesturesEnabled ? doubleTapGesture : nil)
                .gesture(gesturesEnabled ? longPressGesture : nil)
                .onAppear {
                    setupCamera()
                }
                .onDisappear {
                    teardownCamera()
                }
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
    }

    /// Only enable gestures in idle state to prevent blocking UI elements
    private var gesturesEnabled: Bool {
        if case .idle = viewModel.uiState {
            return true
        }
        return false
    }

    // MARK: - Main Content Layout

    /// Main content switching between capture mode and results
    @ViewBuilder
    private func captureContent(geometry: GeometryProxy) -> some View {
        ZStack {
            if case .results = viewModel.uiState {
                resultsView
            } else {
                captureLayout(geometry: geometry)
            }
        }
    }

    /// Camera capture layout with preview, overlays, and controls
    @ViewBuilder
    private func captureLayout(geometry: GeometryProxy) -> some View {
        // Camera preview or frozen frame
        cameraLayer

        // Overlay based on UI state
        overlayForState(geometry: geometry)

        // Top bar (always visible)
        topBar

        // Bottom bar (mode-dependent)
        bottomBar(geometry: geometry)
    }

    // MARK: - Results View

    private var resultsView: some View {
        Group {
            if viewModel.detectedObjects.isEmpty {
                NoObjectsDetectedView(
                    reasoning: viewModel.currentSession?.reasoning,
                    onRetake: {
                        viewModel.retake()
                        frozenFrame = nil
                    }
                )
            } else {
                DetectionResultsView(
                    capturedImage: viewModel.lastCapturedPhoto,
                    detectedObjects: viewModel.detectedObjects,
                    catalogingObjectIds: viewModel.catalogingObjectIds,
                    catalogedObjectIds: viewModel.catalogedObjectIds,
                    onCatalogObject: { object in
                        Task {
                            await viewModel.catalogObject(object)
                        }
                    },
                    onCatalogAll: {
                        Task {
                            await viewModel.catalogAllObjects()
                        }
                    },
                    onRetake: {
                        viewModel.retake()
                        frozenFrame = nil
                    },
                    onDone: {
                        dismiss()
                    }
                )
            }
        }
    }

    // MARK: - Camera Layer

    private var cameraLayer: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let captureSession = cameraService.getCaptureSession() {
                CameraPreviewView(captureSession: captureSession)
                    .ignoresSafeArea()
                    .opacity(shouldShowPreview ? 1 : 0)
            }

            // Frozen frame during capture/processing
            if let frameData = frozenFrame {
                #if os(iOS)
                if let image = UIImage(data: frameData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                }
                #endif
            }
        }
    }

    private var shouldShowPreview: Bool {
        switch viewModel.uiState {
        case .idle, .capturing:
            return frozenFrame == nil
        default:
            return false
        }
    }

    // MARK: - Overlays

    @ViewBuilder
    private func overlayForState(geometry: GeometryProxy) -> some View {
        switch viewModel.uiState {
        case .idle:
            EmptyView()

        case .capturing(let count):
            CaptureOverlay(photoCount: count, isLongPress: longPressActive)

        case .uploading(let progress):
            UploadingOverlay(progress: progress)

        case .analyzing:
            AnalyzingOverlay()

        case .results:
            // Results view will be shown separately
            EmptyView()

        case .error(let error):
            ErrorOverlay(error: error) {
                // Clear frozen frame first to unblock preview
                frozenFrame = nil
                viewModel.dismissError()
                // Restart camera session to resume live feed
                setupCamera()
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        VStack {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(16)
                }

                Spacer()

                modeIndicator
                    .padding(16)
            }
            Spacer()
        }
    }

    private var modeIndicator: some View {
        let text: String = {
            switch viewModel.uiState {
            case .capturing(let count) where count > 1:
                return "Burst: \(count)"
            case .uploading:
                return "Uploading..."
            case .analyzing:
                return "Analyzing..."
            default:
                return "Ready"
            }
        }()

        return Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background {
                if #available(iOS 26.0, macOS 26.0, *) {
                    if !reduceTransparency {
                        Color.clear.glassEffect(in: Capsule())
                    } else {
                        Color.black.opacity(0.6).clipShape(Capsule())
                    }
                } else {
                    Capsule().fill(.ultraThickMaterial)
                }
            }
    }

    // MARK: - Bottom Bar

    @ViewBuilder
    private func bottomBar(geometry: GeometryProxy) -> some View {
        VStack {
            Spacer()

            switch viewModel.uiState {
            case .idle, .capturing:
                instructionLabel
                    .padding(.bottom, 40)

            case .results:
                // Show results action buttons
                HStack(spacing: 40) {
                    Button("Retake") {
                        viewModel.retake()
                        frozenFrame = nil
                    }
                    .buttonStyle(CaptureButtonStyle(isPrimary: false))

                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(CaptureButtonStyle(isPrimary: true))
                }
                .padding(.bottom, 40)

            default:
                EmptyView()
            }
        }
    }

    private var instructionLabel: some View {
        let text = longPressActive
            ? "Release to analyze"
            : "Double-tap to scan • Hold for burst"

        return Text(text)
            .font(.system(size: 15, weight: .regular, design: .rounded))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background {
                if #available(iOS 26.0, macOS 26.0, *) {
                    if !reduceTransparency {
                        Color.clear.glassEffect(in: Capsule())
                    } else {
                        Color.black.opacity(0.6).clipShape(Capsule())
                    }
                } else {
                    Capsule().fill(.ultraThickMaterial)
                }
            }
    }

    // MARK: - Gestures

    private var doubleTapGesture: some Gesture {
        TapGesture(count: 2)
            .onEnded {
                guard case .idle = viewModel.uiState else { return }
                captureAndProcess()
            }
    }

    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.3)
            .onEnded { _ in
                guard case .idle = viewModel.uiState else { return }
                startBurstCapture()
            }
            .simultaneously(with: DragGesture(minimumDistance: 0)
                .onEnded { _ in
                    if longPressActive {
                        endBurstCapture()
                    }
                }
            )
    }

    // MARK: - Camera Control

    private func setupCamera() {
        Task {
            do {
                try await cameraService.startSession()
            } catch {
                print("Failed to start camera: \(error)")
            }
        }
    }

    private func teardownCamera() {
        cameraService.stopSession()
    }

    // MARK: - Capture Actions

    private func captureAndProcess() {
        Task {
            do {
                // Capture photo
                let photoData = try await cameraService.capturePhoto()

                // Freeze frame
                frozenFrame = photoData

                // Haptic feedback
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                #endif

                // Process
                await viewModel.handleDoubleTap(photoData: photoData)
            } catch {
                print("Capture failed: \(error)")
            }
        }
    }

    private func startBurstCapture() {
        longPressActive = true
        viewModel.startBurstCapture {
            try await cameraService.capturePhoto()
        }
    }

    private func endBurstCapture() {
        longPressActive = false
        Task {
            // Freeze on last captured frame - use lastCapturedPhoto from ViewModel
            if let lastPhoto = viewModel.lastCapturedPhoto {
                frozenFrame = lastPhoto
            }
            await viewModel.endBurstCapture()
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    CaptureView()
}
#endif
