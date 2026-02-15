import SwiftUI
@preconcurrency import AVFoundation
import CameraFeature
import Persistence

/// Full-screen camera view for capturing additional photos
/// Based on RescanCameraView pattern but for adding photos to existing items
struct AddPhotoCameraView: View {
    @Bindable var viewModel: EditItemViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var cameraService = CameraService()
    @State private var isCapturing = false
    @State private var captureSession: AVCaptureSession?

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            if let captureSession {
                CameraPreviewView(captureSession: captureSession)
                    .ignoresSafeArea()
            }

            VStack {
                // Top bar
                HStack {
                    Button("Cancel") {
                        viewModel.state = .editing
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(16)
                    .accessibilityLabel("Cancel photo capture")
                    .accessibilityIdentifier("addPhoto.cancelButton")

                    Spacer()
                }

                Spacer()

                Text("Add another photo")
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background {
                        Color.clear
                            .adaptiveGlass(in: Capsule())
                    }

                // Capture button
                Button {
                    capturePhoto()
                } label: {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 72, height: 72)
                        Circle()
                            .stroke(.white.opacity(0.3), lineWidth: 4)
                            .frame(width: 84, height: 84)
                    }
                }
                .disabled(isCapturing || viewModel.isUploadingPhoto)
                .opacity(isCapturing || viewModel.isUploadingPhoto ? 0.5 : 1.0)
                .padding(.top, 24)
                .padding(.bottom, 48)
                .accessibilityLabel("Take photo")
                .accessibilityIdentifier("addPhoto.captureButton")
            }

            // Upload overlay
            if viewModel.isUploadingPhoto {
                ZStack {
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()

                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(1.5)
                            .tint(.white)

                        Text("Uploading photo...")
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .padding(32)
                    .adaptiveGlass(cornerRadius: 20)
                }
            }
        }
        .onAppear {
            Task {
                try? await cameraService.startSession()
                captureSession = await cameraService.getCaptureSession()
            }
        }
        .onDisappear {
            Task {
                await cameraService.stopSession()
            }
        }
        .onChange(of: viewModel.state) { _, newState in
            if newState == .editing {
                dismiss()
            }
        }
    }

    private func capturePhoto() {
        guard !isCapturing else { return }
        isCapturing = true

        Task {
            do {
                let imageData = try await cameraService.capturePhoto()

                guard let image = PlatformImage(data: imageData) else {
                    viewModel.photoError = "Failed to process captured image"
                    isCapturing = false
                    return
                }

                await viewModel.handleAdditionalPhotoCapture(image)
            } catch {
                viewModel.photoError = "Failed to capture photo: \(error.localizedDescription)"
                viewModel.state = .editing
            }
            isCapturing = false
        }
    }
}
