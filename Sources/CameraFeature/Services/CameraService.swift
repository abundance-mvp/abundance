@preconcurrency import AVFoundation // Required for AVFoundation camera capture
import Combine

/// Concrete implementation of CameraServiceProtocol using AVFoundation
/// @MainActor ensures thread-safe access to camera resources
@MainActor
public final class CameraService: NSObject, @preconcurrency CameraServiceProtocol, @unchecked Sendable {

    // MARK: - Properties

    nonisolated(unsafe) private let captureSession = AVCaptureSession()
    nonisolated(unsafe) private let photoOutput = AVCapturePhotoOutput()
    nonisolated(unsafe) private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.abundance.camera.session")
    private let videoQueue = DispatchQueue(label: "com.abundance.camera.video", qos: .userInitiated)

    nonisolated(unsafe) private let sessionStateSubject = CurrentValueSubject<CameraSessionState, Never>(.notStarted)
    public var sessionState: AnyPublisher<CameraSessionState, Never> {
        sessionStateSubject.eraseToAnyPublisher()
    }

    nonisolated(unsafe) private let frameSubject = PassthroughSubject<CVPixelBuffer, Never>()
    public var framePublisher: AnyPublisher<CVPixelBuffer, Never> {
        frameSubject.eraseToAnyPublisher()
    }

    nonisolated(unsafe) private var photoContinuation: CheckedContinuation<Data, Error>?
    private let continuationLock = NSLock()

    // MARK: - Initialization

    nonisolated public override init() {
        super.init()
        setupInterruptionObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Interruption Handling

    nonisolated private func setupInterruptionObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionWasInterrupted),
            name: AVCaptureSession.wasInterruptedNotification,
            object: captureSession
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionInterruptionEnded),
            name: AVCaptureSession.interruptionEndedNotification,
            object: captureSession
        )
    }

    @objc nonisolated private func sessionWasInterrupted(_ notification: Notification) {
        #if os(iOS)
        guard let userInfo = notification.userInfo,
              let rawValue = userInfo[AVCaptureSessionInterruptionReasonKey] as? Int else {
            return
        }
        sessionStateSubject.send(.interrupted(reasonRawValue: rawValue))
        #endif
    }

    @objc nonisolated private func sessionInterruptionEnded(_ notification: Notification) {
        // Restart session when interruption ends
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
            self.sessionStateSubject.send(.running)
        }
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

    nonisolated public func stopSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
            self?.sessionStateSubject.send(.stopped)
        }
    }

    public func capturePhoto() async throws -> Data {
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self = self else {
                continuation.resume(throwing: CameraError.captureFailure)
                return
            }

            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: CameraError.captureFailure)
                    return
                }

                // Lock before accessing photoContinuation
                self.continuationLock.lock()

                // Check if capture already in progress
                if self.photoContinuation != nil {
                    self.continuationLock.unlock()
                    continuation.resume(throwing: CameraError.captureInProgress)
                    return
                }

                // Check if session is running before attempting to capture
                guard self.captureSession.isRunning else {
                    self.continuationLock.unlock()
                    continuation.resume(throwing: CameraError.captureFailure)
                    return
                }

                self.photoContinuation = continuation
                self.continuationLock.unlock()

                let settings = AVCapturePhotoSettings()
                settings.photoQualityPrioritization = .quality
                self.photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    public func getCaptureSession() -> AVCaptureSession? {
        return captureSession
    }

    // MARK: - Private Methods

    nonisolated private func configureSession() throws {
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
        // Use maxPhotoDimensions for high-resolution capture (iOS 16.0+)
        // Per Apple docs: "The dimensions you set must match one returned by supportedMaxPhotoDimensions"
        // https://developer.apple.com/documentation/avfoundation/avcapturephotooutput/maxphotodimensions
        let supportedDimensions = camera.activeFormat.supportedMaxPhotoDimensions
        if let maxDimension = supportedDimensions.max(by: { $0.width * $0.height < $1.width * $1.height }) {
            photoOutput.maxPhotoDimensions = maxDimension
        } else {
            // Fallback: use first supported dimension or default
            photoOutput.maxPhotoDimensions = supportedDimensions.first ?? CMVideoDimensions(width: 0, height: 0)
        }
        photoOutput.maxPhotoQualityPrioritization = .quality

        // Add video data output for frame-by-frame processing
        guard captureSession.canAddOutput(videoOutput) else {
            throw CameraError.cannotAddOutput
        }
        captureSession.addOutput(videoOutput)

        // Configure video output for real-time processing
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

@MainActor
extension CameraService: AVCapturePhotoCaptureDelegate {

    nonisolated public func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        // Lock before accessing photoContinuation
        continuationLock.lock()
        let continuation = photoContinuation
        photoContinuation = nil
        continuationLock.unlock()

        // Now safely use continuation outside lock
        if let error = error {
            continuation?.resume(throwing: error)
            return
        }

        // AVCapturePhoto.fileDataRepresentation() returns Data directly
        // No UIKit or UIImage conversion needed - ADR-010 compliant
        guard let imageData = photo.fileDataRepresentation() else {
            continuation?.resume(throwing: CameraError.invalidImageData)
            return
        }

        continuation?.resume(returning: imageData)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

@MainActor
extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {

    nonisolated public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Copy the pixel buffer before publishing to prevent data race.
        // Per Apple docs: "If you need to reference the CMSampleBuffer object outside
        // of the scope of this method... consider copying the data into a new buffer"
        // The camera system may recycle buffers before async consumers process them.
        guard let copiedBuffer = copyPixelBuffer(pixelBuffer) else { return }
        frameSubject.send(copiedBuffer)
    }

    /// Creates a deep copy of a CVPixelBuffer to prevent data races with camera buffer recycling.
    ///
    /// Camera frame buffers are reused by the capture system. When buffers are passed to
    /// async consumers (via Combine subjects with throttle operators), the original buffer
    /// may be overwritten before processing completes. This function creates a safe copy.
    ///
    /// - Parameter source: The source pixel buffer to copy
    /// - Returns: A new pixel buffer with copied data, or nil if copy fails
    nonisolated private func copyPixelBuffer(_ source: CVPixelBuffer) -> CVPixelBuffer? {
        let width = CVPixelBufferGetWidth(source)
        let height = CVPixelBufferGetHeight(source)
        let pixelFormat = CVPixelBufferGetPixelFormatType(source)

        // Create attributes for the new buffer
        let attributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]

        var destinationBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            pixelFormat,
            attributes as CFDictionary,
            &destinationBuffer
        )

        guard status == kCVReturnSuccess, let destination = destinationBuffer else {
            return nil
        }

        // Lock both buffers for access
        CVPixelBufferLockBaseAddress(source, .readOnly)
        CVPixelBufferLockBaseAddress(destination, [])
        defer {
            CVPixelBufferUnlockBaseAddress(source, .readOnly)
            CVPixelBufferUnlockBaseAddress(destination, [])
        }

        // Copy plane data
        let planeCount = CVPixelBufferGetPlaneCount(source)
        if planeCount == 0 {
            // Non-planar format - single data block
            guard let sourceBase = CVPixelBufferGetBaseAddress(source),
                  let destBase = CVPixelBufferGetBaseAddress(destination) else {
                return nil
            }
            let bytesPerRow = CVPixelBufferGetBytesPerRow(source)
            memcpy(destBase, sourceBase, bytesPerRow * height)
        } else {
            // Planar format - copy each plane
            for plane in 0..<planeCount {
                guard let sourceBase = CVPixelBufferGetBaseAddressOfPlane(source, plane),
                      let destBase = CVPixelBufferGetBaseAddressOfPlane(destination, plane) else {
                    return nil
                }
                let planeHeight = CVPixelBufferGetHeightOfPlane(source, plane)
                let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(source, plane)
                memcpy(destBase, sourceBase, bytesPerRow * planeHeight)
            }
        }

        return destination
    }
}
