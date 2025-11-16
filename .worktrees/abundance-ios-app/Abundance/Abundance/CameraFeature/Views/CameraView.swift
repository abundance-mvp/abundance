import SwiftUI

/// SwiftUI view for camera capture with MVVM pattern
public struct CameraView: View {

    @StateObject private var viewModel: CameraViewModel
    @Environment(\.dismiss) private var dismiss

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
               let captureSession = viewModel.getCaptureSession() {
                CameraPreviewView(captureSession: captureSession)
                    .ignoresSafeArea()
            }

            // Capture button overlay
            VStack {
                Spacer()

                captureButton
                    .padding(.bottom, 40)
            }

            // Error message overlay
            if let errorMessage = viewModel.errorMessage {
                VStack {
                    errorBanner(message: errorMessage)
                    Spacer()
                }
            }

            // Loading indicator
            if viewModel.isCapturing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2)
            }
        }
        .task {
            await viewModel.checkCameraPermission()
        }
        .onDisappear {
            viewModel.stopCamera()
        }
        .onChange(of: viewModel.capturedPhotoData) { _, newValue in
            if newValue != nil {
                dismiss()
            }
        }
    }

    // MARK: - Subviews

    private var captureButton: some View {
        Button {
            Task {
                await viewModel.capturePhoto()
            }
        } label: {
            Circle()
                .fill(Color.white)
                .frame(width: 70, height: 70)
                .overlay {
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 80, height: 80)
                }
        }
        .disabled(viewModel.isCapturing || viewModel.sessionState != .running)
        .opacity(viewModel.isCapturing ? 0.5 : 1.0)
    }

    private func errorBanner(message: String) -> some View {
        Text(message)
            .foregroundColor(.white)
            .padding()
            .background(Color.red.opacity(0.8))
            .cornerRadius(10)
            .padding()
    }
}
