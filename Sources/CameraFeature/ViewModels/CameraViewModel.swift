import Foundation
import Combine
import AVFoundation

/// ViewModel for camera capture feature (MVVM pattern)
/// - Note: For server-side detection, use CaptureSessionViewModel instead.
@MainActor
@Observable
public final class CameraViewModel {

    // MARK: - Observable Properties

    public var sessionState: CameraSessionState = .notStarted
    public var errorMessage: String?
    public var authorizationStatus: CameraAuthorizationStatus = .notDetermined

    // MARK: - Dependencies

    private let cameraService: CameraServiceProtocol
    private var cancellables: Set<AnyCancellable> = Set<AnyCancellable>()

    // MARK: - Initialization

    public init(cameraService: CameraServiceProtocol) {
        self.cameraService = cameraService

        // Observe session state changes
        cameraService.sessionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.sessionState = state
            }
            .store(in: &cancellables)
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

    public func stopCamera() async {
        await cameraService.stopSession()
    }

    public func getCaptureSession() async -> AVCaptureSession? {
        return await cameraService.getCaptureSession()
    }
}
