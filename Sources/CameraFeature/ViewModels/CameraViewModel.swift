import Foundation
import Combine
import AVFoundation
import Persistence
#if os(iOS)
import UIKit
public typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
public typealias PlatformImage = NSImage
#endif

/// ViewModel for camera capture feature (MVVM pattern)
@MainActor
public final class CameraViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published public var sessionState: CameraSessionState = .notStarted
    @Published public var capturedPhotoData: Data?
    @Published public var isCapturing: Bool = false
    @Published public var errorMessage: String?
    @Published public var authorizationStatus: CameraAuthorizationStatus = .notDetermined
    @Published public var uploadProgress: Double = 0.0

    // MARK: - Dependencies

    private let cameraService: CameraServiceProtocol
    private let storageService: StorageServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    public init(
        cameraService: CameraServiceProtocol,
        storageService: StorageServiceProtocol = StorageService()
    ) {
        self.cameraService = cameraService
        self.storageService = storageService

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
        uploadProgress = 0.0
        defer { isCapturing = false }

        do {
            // Capture photo
            let photoData = try await cameraService.capturePhoto()
            capturedPhotoData = photoData
            errorMessage = nil

            // Convert to image for upload
            #if os(iOS)
            guard let image = UIImage(data: photoData) else {
                errorMessage = "Failed to convert photo data to image"
                return
            }
            #elseif os(macOS)
            guard let image = NSImage(data: photoData) else {
                errorMessage = "Failed to convert photo data to image"
                return
            }
            #endif

            // Upload to Firebase Storage
            let itemId = UUID().uuidString
            let userId = "current_user_id" // TODO: Get from Auth service

            uploadProgress = 0.5 // Mid-progress

            // Capture storage service reference to avoid sendability issues
            let storage = storageService
            let downloadURL = try await storage.uploadCroppedObject(
                image,
                itemId: itemId,
                userId: userId
            )

            uploadProgress = 1.0

            print("Image uploaded successfully: \(downloadURL.absoluteString)")

        } catch {
            errorMessage = "Failed to capture photo: \(error.localizedDescription)"
        }
    }

    public func stopCamera() {
        cameraService.stopSession()
    }

    public func getCaptureSession() -> AVCaptureSession? {
        return cameraService.getCaptureSession()
    }
}
