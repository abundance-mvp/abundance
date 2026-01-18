import SwiftUI
import AVFoundation

/// SwiftUI view for camera preview only (capture functionality removed).
/// - Important: Use CaptureView for server-side detection with capture.
@available(*, deprecated, message: "Use CaptureView for server-side detection experience.")
public struct LegacyCameraView: View {

    @StateObject private var viewModel: CameraViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var captureSession: AVCaptureSession?

    public init(cameraService: CameraServiceProtocol) {
        _viewModel = StateObject(wrappedValue: CameraViewModel(cameraService: cameraService))
    }

    public var body: some View {
        ZStack {
            // Camera preview background
            Color.black
                .ignoresSafeArea()

            // Camera preview (only when running)
            if viewModel.sessionState == .running,
               let captureSession = captureSession {
                CameraPreviewView(captureSession: captureSession)
                    .ignoresSafeArea()
            }

            // Deprecation notice overlay
            VStack {
                Spacer()

                Text("This view is deprecated.\nUse CaptureView instead.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 40)
            }

            // Error message overlay
            if let errorMessage = viewModel.errorMessage {
                VStack {
                    errorBanner(message: errorMessage)
                    Spacer()
                }
            }
        }
        .task {
            await viewModel.checkCameraPermission()
            captureSession = await viewModel.getCaptureSession()
        }
        .onDisappear {
            Task {
                await viewModel.stopCamera()
            }
        }
    }

    // MARK: - Subviews

    private func errorBanner(message: String) -> some View {
        Text(message)
            .foregroundColor(.white)
            .padding()
            .background(Color.red.opacity(0.8))
            .cornerRadius(10)
            .padding()
    }
}

/// Backward compatibility alias
/// - Warning: Deprecated. Use CaptureView instead.
@available(*, deprecated, renamed: "LegacyCameraView", message: "Use CaptureView for server-side detection")
public typealias CameraView = LegacyCameraView
