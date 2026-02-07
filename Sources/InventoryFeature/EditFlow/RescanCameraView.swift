import SwiftUI
@preconcurrency import AVFoundation
import CameraFeature
import Persistence

/// Full-screen camera view for rescan capture
/// Reuses CameraService infrastructure but captures single photo
public struct RescanCameraView: View {
    @Bindable var viewModel: EditItemViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var cameraService = CameraService()
    @State private var isCapturing = false
    @State private var captureSession: AVCaptureSession?

    public init(viewModel: EditItemViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            // Camera preview
            Color.black
                .ignoresSafeArea()

            if let captureSession {
                CameraPreviewView(captureSession: captureSession)
                    .ignoresSafeArea()
            }

            // Overlay controls
            VStack {
                // Top bar
                HStack {
                    Button("Cancel") {
                        viewModel.cancelFlow()
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(16)

                    Spacer()
                }

                Spacer()

                // Instruction text
                Text("Position the item in frame")
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
                .disabled(isCapturing || viewModel.state == .processing)
                .opacity(isCapturing || viewModel.state == .processing ? 0.5 : 1.0)
                .padding(.top, 24)
                .padding(.bottom, 48)
            }

            // Processing overlay
            if viewModel.state == .processing {
                ProcessingOverlay()
                    .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
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
            // Handle state changes
            if case .comparing = newState {
                dismiss()
            } else if case .error = newState {
                // Stay on camera but allow retry
                isCapturing = false
            }
        }
    }

    private func capturePhoto() {
        guard !isCapturing else { return }
        isCapturing = true

        Task {
            do {
                let imageData = try await cameraService.capturePhoto()

                // Convert Data to PlatformImage
                #if os(iOS)
                guard let image = UIImage(data: imageData) else {
                    viewModel.state = .error("Failed to process captured image")
                    isCapturing = false
                    return
                }
                #elseif os(macOS)
                guard let image = NSImage(data: imageData) else {
                    viewModel.state = .error("Failed to process captured image")
                    isCapturing = false
                    return
                }
                #endif

                await viewModel.handleCapturedImage(image)
            } catch {
                viewModel.state = .error("Failed to capture photo: \(error.localizedDescription)")
                isCapturing = false
            }
        }
    }
}

// MARK: - Processing Overlay

private struct ProcessingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Analyzing your photo...")
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(.white)
            }
            .padding(32)
            .adaptiveGlass(cornerRadius: 20)
        }
    }
}

#if DEBUG
#Preview("Rescan Camera View") {
    RescanCameraView(
        viewModel: EditItemViewModel(
            item: Item(
                id: "preview-1",
                userId: "user-1",
                imageUrl: "https://example.com/image.jpg",
                status: .complete,
                name: "Test Item"
            ),
            itemRepository: PreviewRescanItemRepository(),
            storageService: PreviewRescanStorageService()
        )
    )
}

// Preview helpers (defined locally to avoid conflicts)
// swiftlint:disable line_length
private final class PreviewRescanItemRepository: ItemRepository, @unchecked Sendable {
    func createItem(userId: String, imageUrl: String) async throws -> String { "id" }
    func createItemWithLayer1Metadata(itemId: String, userId: String, imageUrl: String, layer1Metadata: Layer1Metadata) async throws {}
    func createItemWithPhotoMetadata(itemId: String, userId: String, imageUrl: String, layer1Metadata: Layer1Metadata, photoMetadata: PhotoMetadata) async throws {}
    func getItem(id: String) async throws -> Item? { nil }
    func getItems(userId: String) async throws -> [Item] { [] }
    func observeItem(id: String, onChange: @escaping (Item?) -> Void) -> FirebaseFirestore.ListenerRegistration { fatalError() }
    func observeItems(userId: String) -> AnyPublisher<[Item], Never> { Just([]).eraseToAnyPublisher() }
    func deleteItem(id: String) async throws {}
    func deleteItems(ids: Set<String>) async throws {}
    func updateItem(_ item: Item, userEditedFields: [String]?) async throws {}
    func rescanItem(_ item: Item) async throws {}
    func refreshImageUrl(id: String) async throws -> String? { nil }
    func requestDeepScan(id: String) async throws {}
}
// swiftlint:enable line_length

private final class PreviewRescanStorageService: StorageServiceProtocol, @unchecked Sendable {
    func uploadCroppedObject(_ image: PlatformImage, itemId: String, userId: String) async throws -> URL {
        URL(string: "https://example.com/image.jpg")!
    }
    func uploadLivePhotoMotion(_ motionData: Data, itemId: String, userId: String) async throws -> URL {
        URL(string: "https://example.com/motion.mov")!
    }
    func uploadAdditionalPhoto(_ image: PlatformImage, itemId: String, photoIndex: Int, userId: String) async throws -> URL {
        URL(string: "https://example.com/photo_\(photoIndex).jpg")!
    }
}
#endif

import Combine
import FirebaseFirestore
