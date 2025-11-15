import AVFoundation // Required for AVFoundation camera capture
import Combine

/// Concrete implementation of CameraServiceProtocol using AVFoundation
public final class CameraService: NSObject, CameraServiceProtocol {

    // MARK: - Properties

    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "com.abundance.camera.session")

    private let sessionStateSubject = CurrentValueSubject<CameraSessionState, Never>(.notStarted)
    public var sessionState: AnyPublisher<CameraSessionState, Never> {
        sessionStateSubject.eraseToAnyPublisher()
    }

    private var photoContinuation: CheckedContinuation<Data, Error>?

    // MARK: - Initialization

    public override init() {
        super.init()
    }

    // MARK: - Public Methods

    public func checkAuthorization() async -> CameraAuthorizationStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            return granted ? .authorized : .denied
        @unknown default:
            return .denied
        }
    }

    public func startSession() async throws {
        sessionStateSubject.send(.configuring)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: CameraError.deviceNotAvailable)
                    return
                }

                do {
                    try self.configureSession()
                    continuation.resume()
                } catch {
                    self.sessionStateSubject.send(.failed(error))
                    continuation.resume(throwing: error)
                    return
                }

                self.captureSession.startRunning()
                self.sessionStateSubject.send(.running)
            }
        }
    }

    public func stopSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
            self?.sessionStateSubject.send(.stopped)
        }
    }

    public func capturePhoto() async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            self.photoContinuation = continuation

            let settings = AVCapturePhotoSettings()
            settings.photoQualityPrioritization = .quality

            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: CameraError.captureFailure)
                    return
                }

                // Check if session is running before attempting to capture
                guard self.captureSession.isRunning else {
                    continuation.resume(throwing: CameraError.captureFailure)
                    return
                }

                self.photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    // MARK: - Private Methods

    private func configureSession() throws {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        // Set session preset for high-quality photos
        captureSession.sessionPreset = .photo

        // Add video input (camera)
        guard let camera = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
            throw CameraError.deviceNotAvailable
        }

        let videoInput = try AVCaptureDeviceInput(device: camera)
        guard captureSession.canAddInput(videoInput) else {
            throw CameraError.cannotAddInput
        }
        captureSession.addInput(videoInput)

        // Add photo output
        guard captureSession.canAddOutput(photoOutput) else {
            throw CameraError.cannotAddOutput
        }
        captureSession.addOutput(photoOutput)

        // Configure photo output settings
        photoOutput.isHighResolutionCaptureEnabled = true
        photoOutput.maxPhotoQualityPrioritization = .quality
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {

    public func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            photoContinuation?.resume(throwing: error)
            photoContinuation = nil
            return
        }

        // AVCapturePhoto.fileDataRepresentation() returns Data directly
        // No UIKit or UIImage conversion needed - ADR-010 compliant
        guard let imageData = photo.fileDataRepresentation() else {
            photoContinuation?.resume(throwing: CameraError.invalidImageData)
            photoContinuation = nil
            return
        }

        photoContinuation?.resume(returning: imageData)
        photoContinuation = nil
    }
}
