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
            ZStack {
                // Show results view when detection complete
                if case .results = viewModel.uiState {
                    resultsView
                } else {
                    // Camera preview or frozen frame
                    cameraLayer

                    // Overlay based on UI state
                    overlayForState(geometry: geometry)

                    // Top bar (always visible)
                    topBar

                    // Bottom bar (mode-dependent)
                    bottomBar(geometry: geometry)
                }
            }
            .gesture(doubleTapGesture)
            .gesture(longPressGesture)
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
                viewModel.dismissError()
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

// MARK: - Supporting Views

struct CaptureOverlay: View {
    let photoCount: Int
    let isLongPress: Bool

    var body: some View {
        VStack {
            Spacer()

            if isLongPress && photoCount > 0 {
                Text("\(photoCount) photos")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
            }

            Spacer()
        }
    }
}

struct UploadingOverlay: View {
    let progress: Double

    var body: some View {
        VStack(spacing: 16) {
            ProgressView(value: progress)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)

            Text("Uploading...")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)

            Text("\(Int(progress * 100))%")
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct AnalyzingOverlay: View {
    @State private var animationPhase: Double = 0

    var body: some View {
        VStack(spacing: 16) {
            // Pulsing scan lines animation
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Rectangle()
                        .fill(.white.opacity(0.3))
                        .frame(height: 2)
                        .offset(y: CGFloat(index - 1) * 30)
                        .opacity(scanLineOpacity(for: index))
                }
            }
            .frame(width: 100, height: 100)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animationPhase)

            Text("Analyzing...")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)

            Text("Detecting objects")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .onAppear {
            animationPhase = 1
        }
    }

    private func scanLineOpacity(for index: Int) -> Double {
        let offset = Double(index) * 0.3
        return 0.3 + 0.7 * sin((animationPhase + offset) * .pi)
    }
}

struct ErrorOverlay: View {
    let error: CaptureError
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow)

            Text(error.localizedDescription)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }

            Button("Try Again") {
                onDismiss()
            }
            .buttonStyle(CaptureButtonStyle(isPrimary: true))
            .padding(.top, 8)
        }
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct CaptureButtonStyle: ButtonStyle {
    let isPrimary: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(isPrimary ? .black : .white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isPrimary ? .white : .white.opacity(0.2))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    CaptureView()
}
#endif
