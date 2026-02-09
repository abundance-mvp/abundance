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
public final class CameraService: NSObject, ObservableObject, @preconcurrency CameraServiceProtocol {

    // MARK: - Properties

    /// Camera configuration settings
    public let configuration: CameraConfiguration

    private let sessionActor: CameraSessionActor
    private let sessionQueue: DispatchQueue
    private let videoQueue: DispatchQueue

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

    /// Creates a camera service with default configuration
    public override convenience init() {
        self.init(configuration: .default)
    }

    /// Creates a camera service with custom configuration
    /// - Parameter configuration: Camera configuration settings
    public init(configuration: CameraConfiguration) {
        self.configuration = configuration
        self.sessionActor = CameraSessionActor(configuration: configuration)
        self.sessionQueue = DispatchQueue(label: configuration.sessionQueueLabel)
        self.videoQueue = DispatchQueue(label: configuration.videoQueueLabel, qos: configuration.videoQueueQoS)
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
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            #if os(iOS)
            guard let userInfo = notification.userInfo,
                  let rawValue = userInfo[AVCaptureSessionInterruptionReasonKey] as? Int else {
                return
            }
            self.sessionStateSubject.send(.interrupted(reasonRawValue: rawValue))
            #endif
        }
    }

    @objc private func sessionInterruptionEnded(_ notification: Notification) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            // Restart session when interruption ends
            let captureSession = await self.sessionActor.captureSession
            let sessionQueue = self.sessionQueue

            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                sessionQueue.async {
                    if !captureSession.isRunning {
                        captureSession.startRunning()
                    }
                    continuation.resume()
                }
            }
            // Only report running if session actually restarted
            if captureSession.isRunning {
                self.sessionStateSubject.send(.running)
            }
        }
    }

    // MARK: - Audio Session Configuration

    private func configureAudioSession() {
        #if os(iOS)
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, options: [.duckOthers, .defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            // Audio session config is best-effort; camera works without it
        }
        #endif
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

        // Configure audio session before capture session to prevent conflicts
        configureAudioSession()

        do {
            try await sessionActor.configure()
            await sessionActor.setSampleBufferDelegate(self, queue: videoQueue)

            // startRunning() is a blocking call - must run on dedicated session queue
            // NOT on main thread or actor executor (Apple: "Don't call startRunning on main thread")
            let captureSession = await sessionActor.captureSession

            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                sessionQueue.async {
                    captureSession.startRunning()
                    continuation.resume()
                }
            }

            sessionStateSubject.send(.running)
        } catch {
            sessionStateSubject.send(.failed(error))
            throw error
        }
    }

    public func stopSession() async {
        // stopRunning() is also blocking - run on session queue for consistency
        let captureSession = await sessionActor.captureSession
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            sessionQueue.async {
                captureSession.stopRunning()
                continuation.resume()
            }
        }
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
        // Capture manager reference before Task to avoid data race (Swift 6 compliance)
        // See: SE-0338 - nonisolated async functions must not send self across boundaries
        let manager = captureManager

        Task {
            let continuation = await manager.getContinuation()

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
        guard let copiedBuffer = Self.copyPixelBuffer(pixelBuffer) else { return }

        // Dispatch to MainActor to publish to the subject
        Task { @MainActor [weak self] in
            self?.frameSubject.send(copiedBuffer)
        }
    }

    /// Creates a deep copy of a CVPixelBuffer to prevent data races with camera buffer recycling.
    ///
    /// Camera frame buffers are reused by the capture system. When buffers are passed to
    /// async consumers (via Combine subjects with throttle operators), the original buffer
    /// may be overwritten before processing completes. This function creates a safe copy.
    ///
    /// - Parameter source: The source pixel buffer to copy
    /// - Returns: A new pixel buffer with copied data, or nil if copy fails
    nonisolated private static func copyPixelBuffer(_ source: CVPixelBuffer) -> CVPixelBuffer? {
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
