import SwiftUI
import AVFoundation
import Core

/// Main capture view with double-tap and long-press gestures
/// Uses server-side Gemini detection - no local YOLO detection
public struct CaptureView: View {

    @StateObject private var viewModel: CaptureSessionViewModel
    @StateObject private var networkMonitor = NetworkMonitor.shared
    private let cameraService: CameraService
    private let onDone: () -> Void
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    @State private var frozenFrame: Data?
    @State private var longPressActive = false
    @State private var captureSession: AVCaptureSession?
    @State private var isCaptureInProgress = false  // Synchronous guard for race prevention

    // Error recovery state
    @State private var cameraError: CameraError?
    @State private var showingCameraError = false
    @State private var authorizationStatus: CameraAuthorizationStatus = .notDetermined

    public init(
        viewModel: CaptureSessionViewModel = CaptureSessionViewModel(),
        cameraService: CameraService = CameraService(),
        onDone: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.cameraService = cameraService
        self.onDone = onDone
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                captureContent(geometry: geometry)
                    .gesture(gesturesEnabled ? doubleTapGesture : nil)
                    .gesture(gesturesEnabled ? longPressGesture : nil)
                    .accessibilityAction(named: "Capture photo") {
                        guard gesturesEnabled else { return }
                        captureAndProcess()
                    }
                    .accessibilityAction(named: "Burst capture") {
                        guard gesturesEnabled else { return }
                        startBurstCapture()
                    }

                // Offline mode indicator
                if !networkMonitor.isConnected {
                    VStack {
                        HStack {
                            Spacer()
                            OfflineModeIndicator()
                                .padding(.trailing, 16)
                                .padding(.top, 60)
                        }
                        Spacer()
                    }
                }

                // Camera error recovery overlay
                if let error = cameraError, showingCameraError {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    ErrorRecoveryView(
                        cameraError: error,
                        onRetry: {
                            Task {
                                await retryCamera()
                            }
                        },
                        onDismiss: {
                            showingCameraError = false
                            cameraError = nil
                            viewModel.retake()
                            onDone()
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(reduceMotion ? .brandReducedMotion : .brandDefault, value: showingCameraError)
            .animation(reduceMotion ? .brandReducedMotion : .brandPress, value: networkMonitor.isConnected)
            .onAppear {
                // Restart camera when returning to this tab
                Task {
                    await restartCameraIfNeeded()
                }
            }
            .task {
                // Initial authorization check on first appearance
                await checkCameraAuthorization()
            }
            .onDisappear {
                teardownCamera()
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                Task {
                    switch newPhase {
                    case .active:
                        // App returning to foreground - restart camera if authorized
                        if authorizationStatus == .authorized {
                            await restartCameraIfNeeded()
                        }
                    case .background:
                        // App going to background - stop camera to save battery
                        teardownCamera()
                    case .inactive:
                        // Transitioning state - do nothing
                        break
                    @unknown default:
                        break
                    }
                }
            }
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
    }

    /// Only enable gestures in idle state to prevent blocking UI elements
    private var gesturesEnabled: Bool {
        guard !showingCameraError else { return false }
        guard !isCaptureInProgress else { return false }  // Synchronous race prevention
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
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                        viewModel.retake()
                        onDone()
                    }
                )
            }
        }
    }

    // MARK: - Camera Layer

    private var cameraLayer: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let captureSession = captureSession {
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
                        .accessibilityHidden(true)
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
                Task {
                    await setupCameraSession()
                }
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        VStack {
            HStack {
                Button {
                    viewModel.retake()
                    onDone()
                } label: {
                    Text("Cancel")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(16)
                }
                .accessibilityLabel("Cancel capture")
                .accessibilityHint("Returns to catalog view")

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
            .font(.caption.weight(.semibold))
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
            .accessibilityLabel("Capture status: \(text)")
            .accessibilityAddTraits(.updatesFrequently)
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
                    .accessibilityHint("Retakes the photo and returns to camera")

                    Button("Done") {
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                        viewModel.retake()
                        onDone()
                    }
                    .buttonStyle(CaptureButtonStyle(isPrimary: true))
                    .accessibilityHint("Saves results and returns to catalog")
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
            .font(.subheadline)
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
            .accessibilityLabel(
                longPressActive
                    ? "Release to analyze"
                    : "Use actions menu to capture photo or start burst capture"
            )
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

    /// Check camera authorization and setup if authorized
    private func checkCameraAuthorization() async {
        authorizationStatus = await cameraService.checkAuthorization()

        switch authorizationStatus {
        case .authorized:
            await setupCameraSession()
        case .denied:
            cameraError = .authorizationDenied
            showingCameraError = true
        case .notDetermined:
            // Wait for user to respond to permission dialog
            break
        }
    }

    /// Setup camera session with error handling
    private func setupCameraSession() async {
        do {
            try await cameraService.startSession()
            captureSession = await cameraService.getCaptureSession()
            cameraError = nil
            showingCameraError = false
        } catch let error as CameraError {
            cameraError = error
            showingCameraError = true
        } catch {
            cameraError = .configurationFailed(error)
            showingCameraError = true
        }
    }

    /// Retry camera setup after error
    private func retryCamera() async {
        showingCameraError = false
        cameraError = nil

        // Re-check authorization in case user changed settings
        await checkCameraAuthorization()
    }

    /// Restart camera session when returning to this tab (after onDisappear stopped it)
    private func restartCameraIfNeeded() async {
        // Only restart if we're authorized
        guard authorizationStatus == .authorized else { return }

        // Get the CURRENT session from the service, not cached @State
        let currentSession = await cameraService.getCaptureSession()

        if let session = currentSession, !session.isRunning {
            // Session exists but stopped - restart it
            await setupCameraSession()
        } else if currentSession == nil {
            // No session yet - set up fresh
            await setupCameraSession()
        }
        // else: session already running, nothing to do
    }

    private func teardownCamera() {
        let service = cameraService  // Capture reference before Task
        Task {
            await service.stopSession()
        }
    }

    // MARK: - Capture Actions

    private func captureAndProcess() {
        // Check network before starting capture that requires upload
        guard networkMonitor.isConnected else {
            viewModel.uiState = .error(.networkTimeout)
            return
        }

        // Synchronous guard - prevents race condition on rapid double-taps
        guard !isCaptureInProgress else { return }
        isCaptureInProgress = true

        Task {
            defer { isCaptureInProgress = false }
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
            } catch let error as CameraError {
                cameraError = error
                showingCameraError = true
            } catch {
                cameraError = .captureFailure
                showingCameraError = true
            }
        }
    }

    private func startBurstCapture() {
        // Check network before starting capture that requires upload
        guard networkMonitor.isConnected else {
            viewModel.uiState = .error(.networkTimeout)
            return
        }

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
