import Foundation
import SwiftUI
import Combine
import os.log
@preconcurrency import FirebaseAuth
import Persistence

/// UI state for the capture flow
public enum CaptureUIState: Equatable, Sendable {
    /// Idle camera preview, ready for capture
    case idle
    /// Capturing photo(s)
    case capturing(count: Int)
    /// Uploading photos to GCS
    case uploading(progress: Double)
    /// Server analyzing images with Gemini 3 Flash
    case analyzing
    /// Detection results ready
    case results
    /// Error state
    case error(CaptureError)
}

/// MainActor-bound ViewModel for the new capture flow
/// Handles double-tap single capture and long-press burst capture
@MainActor
public final class CaptureSessionViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Current UI state
    @Published public var uiState: CaptureUIState = .idle

    /// Current capture session (nil when idle)
    @Published public var currentSession: CaptureSession?

    /// Detected objects from server
    @Published public var detectedObjects: [ServerDetectedObject] = []

    /// Burst capture count (during long-press)
    @Published public var burstCount: Int = 0

    /// Whether a capture is in progress
    @Published public var isCapturing: Bool = false

    /// Last captured photo data (for displaying frozen frame and results)
    @Published public var lastCapturedPhoto: Data?

    // MARK: - Configuration

    /// Minimum burst hold duration (seconds)
    public let minBurstDuration: TimeInterval = 1.0

    /// Maximum burst hold duration (seconds)
    public let maxBurstDuration: TimeInterval = 4.0

    /// Burst capture interval (seconds)
    public let burstInterval: TimeInterval = 0.5

    /// Detection timeout (seconds)
    public let detectionTimeout: TimeInterval = 45.0

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.abundance.camerafeature", category: "CaptureSessionViewModel")

    private let sessionService: SessionServiceProtocol
    private let storageService: StorageServiceProtocol
    private let catalogService: CatalogServiceProtocol
    private var sessionObserver: AnyCancellable?
    private var itemObservers: [String: AnyCancellable] = [:]

    /// Task for burst capture loop (public for testing)
    public private(set) var burstTask: Task<Void, Never>?
    private var burstStartTime: Date?
    private var capturedPhotos: [Data] = []

    /// Tracks which objects are being cataloged
    @Published public var catalogingObjectIds: Set<String> = []

    /// Tracks which objects have been cataloged successfully
    @Published public var catalogedObjectIds: Set<String> = []

    // MARK: - Initialization

    public init(
        sessionService: SessionServiceProtocol = SessionService(),
        storageService: StorageServiceProtocol = StorageService(),
        catalogService: CatalogServiceProtocol = CatalogService()
    ) {
        self.sessionService = sessionService
        self.storageService = storageService
        self.catalogService = catalogService
    }

    // MARK: - Single Photo Capture (Double-Tap)

    /// Handle double-tap gesture for single photo capture
    /// - Parameter photoData: JPEG data from camera
    public func handleDoubleTap(photoData: Data) async {
        guard !isCapturing else {
            logger.warning("Capture already in progress")
            return
        }

        guard let userId = Auth.auth().currentUser?.uid else {
            uiState = .error(.notAuthenticated)
            return
        }

        isCapturing = true
        uiState = .capturing(count: 1)
        capturedPhotos = [photoData]
        lastCapturedPhoto = photoData

        await processCapture(userId: userId, captureMode: .single)
    }

    // MARK: - Burst Capture (Long-Press)

    /// Start burst capture on long-press begin
    /// Uses Task-based loop with Task.sleep for Swift 6 concurrency compliance
    /// - Parameter capturePhoto: Closure to capture a photo (returns JPEG data)
    public func startBurstCapture(capturePhoto: @escaping @Sendable () async throws -> Data) {
        guard !isCapturing else {
            logger.warning("Capture already in progress")
            return
        }

        isCapturing = true
        burstCount = 0
        capturedPhotos = []
        burstStartTime = Date()
        uiState = .capturing(count: 0)

        // Task-based burst capture loop (replaces Timer for Swift 6 compliance)
        burstTask = Task { @MainActor [weak self] in
            guard let self else { return }

            // Capture first photo immediately
            await self.captureBurstPhoto(capturePhoto: capturePhoto)

            // Continue capturing at intervals until cancelled or limit reached
            while !Task.isCancelled && self.isCapturing && self.capturedPhotos.count < 8 {
                do {
                    // Wait for burst interval (500ms)
                    try await Task.sleep(for: .milliseconds(Int(self.burstInterval * 1000)))

                    // Check cancellation after sleep
                    if Task.isCancelled || !self.isCapturing {
                        break
                    }

                    await self.captureBurstPhoto(capturePhoto: capturePhoto)
                } catch {
                    // Task was cancelled during sleep
                    break
                }
            }

            // Auto-end if we hit max photos
            if self.capturedPhotos.count >= 8 && self.isCapturing {
                await self.endBurstCapture()
            }
        }
    }

    /// End burst capture on long-press end
    public func endBurstCapture() async {
        burstTask?.cancel()
        burstTask = nil

        guard let startTime = burstStartTime else {
            isCapturing = false
            uiState = .idle
            return
        }

        let duration = Date().timeIntervalSince(startTime)
        burstStartTime = nil

        // Check minimum duration
        if duration < minBurstDuration || capturedPhotos.count < 2 {
            isCapturing = false
            uiState = .error(.burstCaptureTooShort)
            capturedPhotos = []
            burstCount = 0
            return
        }

        guard let userId = Auth.auth().currentUser?.uid else {
            isCapturing = false
            uiState = .error(.notAuthenticated)
            capturedPhotos = []
            burstCount = 0
            return
        }

        await processCapture(userId: userId, captureMode: .burst)
    }

    /// Cancel burst capture
    public func cancelBurstCapture() {
        burstTask?.cancel()
        burstTask = nil
        burstStartTime = nil
        capturedPhotos = []
        burstCount = 0
        isCapturing = false
        uiState = .idle
    }

    // MARK: - Private Methods

    private func captureBurstPhoto(capturePhoto: @escaping @Sendable () async throws -> Data) async {
        guard isCapturing else { return }

        // Check max duration
        if let startTime = burstStartTime {
            let duration = Date().timeIntervalSince(startTime)
            if duration >= maxBurstDuration {
                await endBurstCapture()
                return
            }
        }

        // Check max photo count (8 photos max)
        if capturedPhotos.count >= 8 {
            await endBurstCapture()
            return
        }

        do {
            let photoData = try await capturePhoto()
            capturedPhotos.append(photoData)
            burstCount = capturedPhotos.count
            uiState = .capturing(count: burstCount)
            lastCapturedPhoto = photoData // Save for frozen frame display

            // Haptic feedback for each capture
            await triggerHapticPulse()
        } catch {
            logger.error("Failed to capture burst photo: \(error.localizedDescription)")
        }
    }

    private func processCapture(userId: String, captureMode: CaptureMode) async {
        logger.info("Processing \(captureMode.rawValue) capture with \(self.capturedPhotos.count) photos")

        do {
            // 1. Create session
            let sessionId = try await sessionService.createSession(
                userId: userId,
                captureMode: captureMode,
                expectedImageCount: capturedPhotos.count
            )

            // 2. Start observing session for updates
            observeSession(sessionId: sessionId)

            // 3. Upload photos
            uiState = .uploading(progress: 0)

            for (index, photoData) in capturedPhotos.enumerated() {
                // Convert Data to PlatformImage for upload
                #if os(iOS)
                guard let image = UIImage(data: photoData) else {
                    throw CaptureError.invalidImageData
                }
                #elseif os(macOS)
                guard let image = NSImage(data: photoData) else {
                    throw CaptureError.invalidImageData
                }
                #endif

                let itemId = "\(sessionId)_\(index)"
                let url = try await storageService.uploadCroppedObject(
                    image,
                    itemId: itemId,
                    userId: userId
                )

                try await sessionService.addUploadedImage(
                    sessionId: sessionId,
                    imageUrl: url.absoluteString
                )

                let progress = Double(index + 1) / Double(capturedPhotos.count)
                uiState = .uploading(progress: progress)
            }

            // 4. Mark ready for detection
            try await sessionService.markReadyForDetection(sessionId: sessionId)
            uiState = .analyzing

            // 5. Wait for detection with timeout
            await waitForDetection(sessionId: sessionId)

        } catch let error as CaptureError {
            uiState = .error(error)
            isCapturing = false
            cleanupCapture()
        } catch {
            uiState = .error(.unknownError(underlying: error))
            isCapturing = false
            cleanupCapture()
        }
    }

    private func observeSession(sessionId: String) {
        sessionObserver?.cancel()

        sessionObserver = sessionService.observeSession(sessionId: sessionId)
            .sink { [weak self] session in
                guard let self, let session else { return }
                self.handleSessionUpdate(session)
            }
    }

    private func handleSessionUpdate(_ session: CaptureSession) {
        currentSession = session

        switch session.status {
        case .uploading:
            // Still uploading, ignore
            break

        case .detecting:
            uiState = .analyzing

        case .detected:
            detectedObjects = session.detectedObjects
            uiState = .results
            isCapturing = false
            sessionObserver?.cancel()

        case .failed:
            let reason = session.error ?? "Unknown error"
            uiState = .error(.detectionFailed(reason: reason))
            isCapturing = false
            sessionObserver?.cancel()
        }
    }

    private func waitForDetection(sessionId: String) async {
        let deadline = Date().addingTimeInterval(detectionTimeout)

        while Date() < deadline {
            if case .results = uiState {
                return
            }
            if case .error = uiState {
                return
            }

            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }

        // Timeout
        if case .analyzing = uiState {
            uiState = .error(.detectionTimeout)
            isCapturing = false
            sessionObserver?.cancel()
        }
    }

    private func cleanupCapture() {
        capturedPhotos = []
        burstCount = 0
        burstStartTime = nil
        burstTask?.cancel()
        burstTask = nil
        lastCapturedPhoto = nil
    }

    private func triggerHapticPulse() async {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
    }

    // MARK: - Public Actions

    /// Reset to idle state for retake
    public func retake() {
        sessionObserver?.cancel()
        itemObservers.values.forEach { $0.cancel() }
        itemObservers.removeAll()
        currentSession = nil
        detectedObjects = []
        catalogingObjectIds = []
        catalogedObjectIds = []
        isCapturing = false
        cleanupCapture()
        uiState = .idle
    }

    /// Clear error and return to idle
    public func dismissError() {
        if case .error = uiState {
            cleanupCapture()
            uiState = .idle
        }
    }

    // MARK: - Cataloging

    /// Catalog a single detected object
    /// - Parameter object: The detected object to catalog
    public func catalogObject(_ object: ServerDetectedObject) async {
        guard let userId = Auth.auth().currentUser?.uid,
              let sessionId = currentSession?.id else {
            logger.error("Cannot catalog: missing user or session")
            return
        }

        guard !catalogingObjectIds.contains(object.groupId),
              !catalogedObjectIds.contains(object.groupId) else {
            logger.warning("Object \(object.groupId) already cataloging or cataloged")
            return
        }

        catalogingObjectIds.insert(object.groupId)
        logger.info("Starting catalog for object \(object.groupId): \(object.label)")

        do {
            let itemId = try await catalogService.catalogDetectedObject(
                userId: userId,
                sessionId: sessionId,
                object: object
            )

            // Observe item status
            observeItemCataloging(itemId: itemId, groupId: object.groupId)
        } catch {
            logger.error("Failed to catalog object: \(error.localizedDescription)")
            catalogingObjectIds.remove(object.groupId)
        }
    }

    /// Catalog all detected objects
    public func catalogAllObjects() async {
        for object in detectedObjects {
            if !catalogingObjectIds.contains(object.groupId) &&
               !catalogedObjectIds.contains(object.groupId) {
                await catalogObject(object)
            }
        }
    }

    private func observeItemCataloging(itemId: String, groupId: String) {
        let observer = catalogService.observeItem(itemId: itemId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self, let status else { return }

                switch status.status {
                case "complete":
                    self.catalogingObjectIds.remove(groupId)
                    self.catalogedObjectIds.insert(groupId)
                    self.itemObservers[itemId]?.cancel()
                    self.itemObservers.removeValue(forKey: itemId)
                    self.logger.info("Object \(groupId) cataloged as '\(status.name ?? "unknown")'")

                case "failed":
                    self.catalogingObjectIds.remove(groupId)
                    self.itemObservers[itemId]?.cancel()
                    self.itemObservers.removeValue(forKey: itemId)
                    self.logger.error("Object \(groupId) catalog failed: \(status.error ?? "unknown error")")

                default:
                    // Still processing
                    break
                }
            }

        itemObservers[itemId] = observer
    }
}
