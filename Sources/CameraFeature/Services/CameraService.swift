@preconcurrency import AVFoundation // Required for AVFoundation camera capture
import Combine

/// Actor to manage photo capture continuation state safely
private actor CaptureManager {
    private var photoContinuation: CheckedContinuation<Data, Error>?
    
    func setContinuation(_ continuation: CheckedContinuation<Data, Error>) throws {
        guard photoContinuation == nil else {
            throw CameraError.captureInProgress
        }
        photoContinuation = continuation
    }
    
    func getContinuation() -> CheckedContinuation<Data, Error>? {
        let continuation = photoContinuation
        photoContinuation = nil
        return continuation
    }
    
    func clearContinuation() {
        photoContinuation = nil
    }
}

/// Concrete implementation of CameraServiceProtocol using AVFoundation
/// @MainActor ensures thread-safe access to camera resources
@MainActor
public final class CameraService: NSObject, @preconcurrency CameraServiceProtocol, Sendable {

    // MARK: - Properties

    private let sessionActor = CameraSessionActor()
    private let sessionQueue = DispatchQueue(label: "com.abundance.camera.session")
    private let videoQueue = DispatchQueue(label: "com.abundance.camera.video", qos: .userInitiated)

    private let sessionStateSubject = CurrentValueSubject<CameraSessionState, Never>(.notStarted)
    public var sessionState: AnyPublisher<CameraSessionState, Never> {
        sessionStateSubject.eraseToAnyPublisher()
    }

    private let frameSubject = PassthroughSubject<CVPixelBuffer, Never>()
    public var framePublisher: AnyPublisher<CVPixelBuffer, Never> {
        frameSubject.eraseToAnyPublisher()
    }

    private let captureManager = CaptureManager()

    // MARK: - Initialization

    public override init() {
        super.init()
        Task { @MainActor in
            await setupInterruptionObservers()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Interruption Handling

    private func setupInterruptionObservers() async {
        let captureSession = await sessionActor.captureSession
        
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

    @objc private func sessionWasInterrupted(_ notification: Notification) {
        Task { @MainActor in
            #if os(iOS)
            guard let userInfo = notification.userInfo,
                  let rawValue = userInfo[AVCaptureSessionInterruptionReasonKey] as? Int else {
                return
            }
            sessionStateSubject.send(.interrupted(reasonRawValue: rawValue))
            #endif
        }
    }

    @objc private func sessionInterruptionEnded(_ notification: Notification) {
        Task { @MainActor in
            // Restart session when interruption ends
            let isRunning = await sessionActor.isRunning()
            if !isRunning {
                await sessionActor.startRunning()
            }
            sessionStateSubject.send(.running)
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
        
        do {
            try await sessionActor.configure()
            await sessionActor.setSampleBufferDelegate(self, queue: videoQueue)
            await sessionActor.startRunning()
            sessionStateSubject.send(.running)
        } catch {
            sessionStateSubject.send(.failed(error))
            throw error
        }
    }

    public func stopSession() async {
        await sessionActor.stopRunning()
        sessionStateSubject.send(.stopped)
    }

    public func capturePhoto() async throws -> Data {
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self = self else {
                continuation.resume(throwing: CameraError.captureFailure)
                return
            }

            Task {
                do {
                    // Check if capture already in progress
                    try await self.captureManager.setContinuation(continuation)
                    
                    // Check if session is running before attempting to capture
                    let isRunning = await self.sessionActor.isRunning()
                    guard isRunning else {
                        await self.captureManager.clearContinuation()
                        continuation.resume(throwing: CameraError.captureFailure)
                        return
                    }

                    let settings = await self.sessionActor.createPhotoSettings()
                    let photoOutput = await self.sessionActor.photoOutput
                    photoOutput.capturePhoto(with: settings, delegate: self)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func getCaptureSession() async -> AVCaptureSession? {
        return await sessionActor.captureSession
    }

    // MARK: - Public Methods for Focus
    
    public func setFocusPoint(_ point: CGPoint) async throws {
        try await sessionActor.setFocusPoint(point)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: @preconcurrency AVCapturePhotoCaptureDelegate {

    nonisolated public func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        Task {
            let continuation = await captureManager.getContinuation()
            
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
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraService: @preconcurrency AVCaptureVideoDataOutputSampleBufferDelegate {

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
    private func copyPixelBuffer(_ source: CVPixelBuffer) -> CVPixelBuffer? {
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
