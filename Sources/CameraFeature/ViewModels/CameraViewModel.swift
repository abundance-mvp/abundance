import Foundation
import Combine

/// ViewModel for camera capture feature (MVVM pattern)
@MainActor
public final class CameraViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published public var sessionState: CameraSessionState = .notStarted
    @Published public var capturedPhotoData: Data?
    @Published public var isCapturing: Bool = false
    @Published public var errorMessage: String?
    @Published public var authorizationStatus: CameraAuthorizationStatus = .notDetermined

    // MARK: - Dependencies

    private let cameraService: CameraServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    public init(cameraService: CameraServiceProtocol) {
        self.cameraService = cameraService

        // Observe session state changes
        cameraService.sessionState
            .receive(on: DispatchQueue.main)
            .assign(to: &$sessionState)
    }

    // MARK: - Public Methods

    public func checkCameraPermission() async {
        authorizationStatus = await cameraService.checkAuthorization()

        if authorizationStatus == .authorized {
            await startCamera()
        } else {
            errorMessage = "Camera access denied. Please enable in Settings."
        }
    }

    public func startCamera() async {
        do {
            try await cameraService.startSession()
            errorMessage = nil
        } catch {
            errorMessage = "Failed to start camera: \(error.localizedDescription)"
        }
    }

    public func capturePhoto() async {
        guard sessionState == .running else { return }

        isCapturing = true
        defer { isCapturing = false }

        do {
            let photoData = try await cameraService.capturePhoto()
            capturedPhotoData = photoData
            errorMessage = nil
        } catch {
            errorMessage = "Failed to capture photo: \(error.localizedDescription)"
        }
    }

    public func stopCamera() {
        cameraService.stopSession()
    }
}
