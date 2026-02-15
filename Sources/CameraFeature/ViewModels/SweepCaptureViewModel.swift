import Foundation
@preconcurrency import Combine
@preconcurrency import CoreVideo
import QuartzCore
import os.log
import Core
import EdgeTAMFeature
import VisionCore
import Persistence
#if canImport(UIKit)
import UIKit // Memory pressure notification only (ADR-010 infrastructure exception)
#endif

/// Adaptive UX tier based on measured EdgeTAM inference FPS
public enum PerformanceTier: Sendable {
    /// 10+ FPS: Segments update smoothly, real-time overlay
    case premium
    /// 4-10 FPS: Slight lag, fully usable
    case good
    /// 1-4 FPS: Snapshots every ~1s, delayed overlays
    case acceptable
    /// <1 FPS: Fallback to tap-to-scan mode
    case fallback
}

/// Protocol abstracting haptic feedback to avoid UIKit in ViewModels (ADR-010)
public protocol HapticFeedbackProviding: Sendable {
    @MainActor func playImpact(style: HapticStyle)
}

/// Haptic intensity level
public enum HapticStyle: Sendable {
    case light, medium, heavy
}

/// MainActor-bound ViewModel for sweep capture mode.
///
/// Manages the sweep state machine:
/// inactive -> loading -> scanning -> reviewing -> uploading -> processing -> complete
///
/// Coordinates between EdgeTAMService (segmentation), ObjectDeduplicator (dedup),
/// and SessionService (Firestore persistence).
@MainActor @Observable
public final class SweepCaptureViewModel {

    // MARK: - Observable Properties

    /// Current sweep session state
    public var sweepState: SweepSessionState = .inactive

    /// All detected segments (including unselected)
    public var segments: [SegmentedObject] = []

    /// IDs of selected segments
    public var selectedSegmentIds: Set<UUID> = []

    /// Whether the catalog button is enabled
    public var canCatalog: Bool = false

    /// IDs of segments detected as duplicates (already seen in previous frames)
    public var duplicateSegmentIds: Set<UUID> = []

    /// Measured FPS from EdgeTAM inference (updated during scanning)
    public var measuredFPS: Double = 0

    /// Adaptive UX tier based on measured FPS
    public var performanceTier: PerformanceTier {
        switch measuredFPS {
        case 10...: return .premium
        case 4..<10: return .good
        case 1..<4: return .acceptable
        default: return .fallback
        }
    }

    // MARK: - Computed Properties

    /// Selected segments for the selection tray
    public var selectedSegments: [SegmentedObject] {
        segments.filter { selectedSegmentIds.contains($0.id) }
    }

    /// Total number of visible segments
    public var segmentCount: Int {
        segments.count
    }

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.abundance.camerafeature", category: "SweepCaptureVM")
    private let haptics: HapticFeedbackProviding?

    /// Active frame processing subscription
    private var frameSubscription: AnyCancellable?

    /// Session completion observer
    private var sessionSubscription: AnyCancellable?

    /// Scanning task (warmup + frame processing loop)
    private var scanningTask: Task<Void, Never>?

    /// Tracks whether a frame is currently being processed (prevents overlap)
    private var isProcessingFrame = false

    /// Timestamp of last haptic for new segment (throttle: 1 per 500ms)
    private var lastSegmentHapticTime: CFTimeInterval = 0

    /// Retained keyframe pixel buffers for crop extraction (max 5, ~40 MB)
    private var keyframeBuffers: [Int: CVPixelBuffer] = [:]
    private let maxKeyframeBuffers = 5

    /// Memory pressure tracking
    private var memoryWarningSubscription: AnyCancellable?
    private var memoryWarningCount = 0

    /// Retained EdgeTAM service reference for model unloading on stop
    private var edgeTAMService: (any EdgeTAMServiceProtocol)?

    // MARK: - Persistent Segment Tracking

    /// Tracks a segment across frames with a stable identity
    struct PersistentSegment {
        var segment: SegmentedObject
        var lastSeenFrame: Int
        var firstSeenFrame: Int
    }

    /// All segments tracked across frames, keyed by stable UUID
    private var persistentSegments: [UUID: PersistentSegment] = [:]

    /// Frames a segment can be absent before eviction
    private let segmentTTLFrames = 10

    /// Monotonic frame counter
    private var frameCounter: Int = 0

    /// Intersection over Union for two rectangles
    nonisolated static func iou(_ a: CGRect, _ b: CGRect) -> CGFloat {
        let intersection = a.intersection(b)
        guard !intersection.isNull else { return 0 }
        let intersectionArea = intersection.width * intersection.height
        let unionArea = a.width * a.height + b.width * b.height - intersectionArea
        guard unionArea > 0 else { return 0 }
        return intersectionArea / unionArea
    }

    /// Match new frame segments to persistent store via IoU, add new, evict stale.
    /// Returns mapping from new segment UUID → persistent segment UUID
    @discardableResult
    private func mergeSegments(_ newSegments: [SegmentedObject]) -> [UUID: UUID] {
        frameCounter += 1
        var matched = Set<UUID>()
        var ephemeralToPersistent: [UUID: UUID] = [:]

        for newSeg in newSegments {
            // Find best IoU match among existing persistent segments
            var bestId: UUID?
            var bestIoU: CGFloat = 0.3 // minimum threshold

            for (id, persistent) in persistentSegments {
                guard !matched.contains(id) else { continue }
                let overlap = Self.iou(newSeg.boundingBox, persistent.segment.boundingBox)
                if overlap > bestIoU {
                    bestIoU = overlap
                    bestId = id
                }
            }

            if let matchedId = bestId {
                // Update existing segment — reconstruct with stable UUID (id is let)
                let stableId = persistentSegments[matchedId]!.segment.id
                let updated = SegmentedObject(
                    id: stableId,
                    boundingBox: newSeg.boundingBox,
                    maskData: newSeg.maskData,
                    maskWidth: newSeg.maskWidth,
                    maskHeight: newSeg.maskHeight,
                    iouScore: newSeg.iouScore,
                    frameIndex: newSeg.frameIndex,
                    timestamp: newSeg.timestamp
                )
                persistentSegments[matchedId]!.segment = updated
                persistentSegments[matchedId]!.lastSeenFrame = frameCounter
                matched.insert(matchedId)
                ephemeralToPersistent[newSeg.id] = stableId
            } else {
                // New segment — assign fresh stable identity
                let id = newSeg.id
                ephemeralToPersistent[newSeg.id] = id
                persistentSegments[id] = PersistentSegment(
                    segment: newSeg,
                    lastSeenFrame: frameCounter,
                    firstSeenFrame: frameCounter
                )
                AppLogger.log(.sweepSegmentAppeared(
                    segmentId: String(id.uuidString.prefix(8)),
                    frameIndex: frameCounter
                ))
            }
        }

        // Evict stale segments
        let staleIds = persistentSegments.filter { $0.value.lastSeenFrame < frameCounter - segmentTTLFrames }.map(\.key)
        for id in staleIds {
            let framesVisible = persistentSegments[id].map { $0.lastSeenFrame - $0.firstSeenFrame + 1 } ?? 0
            selectedSegmentIds.remove(id)
            persistentSegments.removeValue(forKey: id)
            AppLogger.log(.sweepSegmentLost(
                segmentId: String(id.uuidString.prefix(8)),
                framesVisible: framesVisible
            ))
        }

        // Update published segments array
        self.segments = persistentSegments.values.map(\.segment)
        canCatalog = !selectedSegmentIds.isEmpty
        return ephemeralToPersistent
    }

    // MARK: - Initialization

    public init(haptics: HapticFeedbackProviding? = nil) {
        self.haptics = haptics
    }

    // Note: No deinit needed — AnyCancellable subscriptions auto-cancel on dealloc.
    // scanningTask is cancelled via stopScanning() which is called by reset() and
    // the owning view's onDisappear. Cannot access @MainActor properties from nonisolated deinit.

    // MARK: - Selection Management

    /// Toggle selection state of a segment with haptic feedback
    /// - Parameter segmentId: ID of the segment to toggle
    public func toggleSelection(_ segmentId: UUID) {
        let wasSelected = selectedSegmentIds.contains(segmentId)
        if wasSelected {
            selectedSegmentIds.remove(segmentId)
            AppLogger.log(.sweepSegmentDeselected(segmentId: String(segmentId.uuidString.prefix(8))))
        } else {
            selectedSegmentIds.insert(segmentId)
            AppLogger.log(.sweepSegmentSelected(segmentId: String(segmentId.uuidString.prefix(8))))
        }
        canCatalog = !selectedSegmentIds.isEmpty

        haptics?.playImpact(style: wasSelected ? .light : .medium)
    }

    /// Clear all selections
    public func clearSelections() {
        selectedSegmentIds.removeAll()
        canCatalog = false
    }

    /// Reset entire sweep state
    public func reset() {
        let totalSeen = persistentSegments.count
        let totalSelected = selectedSegmentIds.count
        stopScanning()
        sweepState = .inactive
        segments = []
        persistentSegments = [:]
        frameCounter = 0
        selectedSegmentIds = []
        duplicateSegmentIds = []
        canCatalog = false
        measuredFPS = 0
        keyframeBuffers.removeAll()
        memoryWarningCount = 0
        if totalSeen > 0 {
            AppLogger.log(.sweepStopped(totalSegmentsSeen: totalSeen, totalSelected: totalSelected))
        }
    }

    // MARK: - Lifecycle

    /// Start sweep mode: check prerequisites and transition to ready/error state.
    /// Call when the user enters sweep mode (captureMode -> .sweep).
    public func start() {
        guard sweepState == .inactive || sweepState.isError else { return }

        sweepState = .loading

        // Check hardware eligibility first
        guard DeviceEligibility.isHardwareEligible else {
            logger.error("Sweep mode unavailable: device not supported")
            sweepState = .error(.deviceNotSupported)
            return
        }

        // Check if EdgeTAM models are bundled
        guard DeviceEligibility.areModelsAvailable else {
            logger.error("Sweep mode unavailable: EdgeTAM models not bundled")
            sweepState = .error(.modelsNotBundled)
            return
        }

        // Models available — transition to ready state
        sweepState = .ready
        logger.info("Sweep mode ready")
    }

    // MARK: - Frame Processing

    /// Start scanning camera frames with EdgeTAM segmentation.
    ///
    /// - Parameters:
    ///   - framePublisher: Combine publisher of camera pixel buffers
    ///   - edgeTAMService: EdgeTAM service for segmentation inference
    ///   - frameScheduler: Keyframe scheduler (determines when to encode)
    ///   - deduplicator: Optional object deduplicator for VNFeaturePrint filtering
    ///   - arSessionManager: Optional AR session manager for spatial dedup
    public func startScanning(
        framePublisher: AnyPublisher<CVPixelBuffer, Never>,
        edgeTAMService: some EdgeTAMServiceProtocol,
        frameScheduler: FrameScheduler = FrameScheduler(),
        deduplicator: ObjectDeduplicator? = nil,
        arSessionManager: SweepARSessionManager? = nil
    ) {
        stopScanning()
        self.edgeTAMService = edgeTAMService
        sweepState = .loading

        // Start AR tracking if available
        #if os(iOS)
        arSessionManager?.startTracking()
        #endif

        // Monitor memory pressure
        startMemoryPressureMonitoring()

        scanningTask = Task { [weak self] in
            guard let self else { return }

            // Warmup models
            do {
                try await edgeTAMService.warmup()
            } catch {
                self.sweepState = .error(.modelLoadFailed(error.localizedDescription))
                return
            }

            self.sweepState = .scanning(segmentCount: 0)
            self.logger.info("Sweep scanning started")
            AppLogger.log(.sweepStarted)

            // Subscribe to frames
            self.frameSubscription = framePublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] pixelBuffer in
                    guard let self else { return }
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        await self.processFrame(
                            pixelBuffer,
                            edgeTAMService: edgeTAMService,
                            frameScheduler: frameScheduler,
                            deduplicator: deduplicator,
                            arSessionManager: arSessionManager
                        )
                    }
                }
        }
    }

    /// Stop scanning and unload models.
    public func stopScanning() {
        frameSubscription?.cancel()
        frameSubscription = nil
        scanningTask?.cancel()
        scanningTask = nil
        sessionSubscription?.cancel()
        sessionSubscription = nil
        memoryWarningSubscription?.cancel()
        memoryWarningSubscription = nil
        isProcessingFrame = false

        // Unload CoreML models to free Neural Engine resources (~50-100 MB)
        if let service = edgeTAMService {
            Task { await service.unload() }
            edgeTAMService = nil
        }
    }

    // MARK: - Memory Pressure

    /// Start monitoring for memory warnings during scanning.
    /// First warning: evict all but newest keyframe buffer.
    /// Second warning: stop scanning entirely.
    private func startMemoryPressureMonitoring() {
        memoryWarningCount = 0
        #if os(iOS)
        memoryWarningSubscription = NotificationCenter.default
            .publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.memoryWarningCount += 1

                if self.memoryWarningCount == 1 {
                    // First warning: evict all but most recent keyframe buffer
                    self.logger.warning("Memory pressure: evicting keyframe buffers")
                    if let newest = self.keyframeBuffers.keys.max() {
                        let newestBuffer = self.keyframeBuffers[newest]
                        self.keyframeBuffers.removeAll()
                        if let newestBuffer {
                            self.keyframeBuffers[newest] = newestBuffer
                        }
                    }
                } else {
                    // Second+ warning: stop scanning
                    self.logger.error("Memory pressure critical: stopping sweep scan")
                    self.stopScanning()
                    self.sweepState = .error(.memoryPressure)
                }
            }
        #endif
    }

    /// Process a single camera frame through EdgeTAM with optional deduplication.
    private func processFrame(
        _ pixelBuffer: CVPixelBuffer,
        edgeTAMService: some EdgeTAMServiceProtocol,
        frameScheduler: FrameScheduler,
        deduplicator: ObjectDeduplicator?,
        arSessionManager: SweepARSessionManager?
    ) async {
        // Skip if already processing (prevents overlap on fast frame delivery)
        guard !isProcessingFrame else { return }

        // Check keyframe scheduling
        let now = Date()
        let shouldEncode = await frameScheduler.shouldEncodeFrame(at: now)
        guard shouldEncode else { return }

        isProcessingFrame = true
        defer { isProcessingFrame = false }

        let startTime = CACurrentMediaTime()

        do {
            // Encode frame
            let featureToken = try await edgeTAMService.encodeFrame(pixelBuffer)

            // Retain keyframe buffer for later crop extraction
            let frameIndex = await frameScheduler.currentFrameIndex
            keyframeBuffers[frameIndex] = pixelBuffer
            // Evict oldest if over limit
            if keyframeBuffers.count > maxKeyframeBuffers,
               let oldest = keyframeBuffers.keys.min() {
                keyframeBuffers.removeValue(forKey: oldest)
            }

            // Auto-segment (4x4 grid)
            var newSegments = try await edgeTAMService.autoSegment(featureToken: featureToken)
            // Tag segments with current frame index
            for i in newSegments.indices {
                newSegments[i].frameIndex = frameIndex
            }

            // Deduplication pass
            var duplicates: Set<UUID> = []
            if let deduplicator {
                for segment in newSegments {
                    let isDuplicate = await deduplicator.isSimilarToRecent(
                        pixelBuffer: pixelBuffer,
                        boundingBox: segment.boundingBox
                    )
                    if isDuplicate {
                        duplicates.insert(segment.id)
                    }

                    // Spatial dedup via ARKit (if available)
                    #if os(iOS)
                    if let arManager = arSessionManager {
                        let center = CGPoint(
                            x: segment.boundingBox.midX,
                            y: segment.boundingBox.midY
                        )
                        if let worldPos = arManager.worldPosition(for: center) {
                            let isSpatialDupe = await deduplicator.isSpatialDuplicate(position: worldPos)
                            if isSpatialDupe {
                                duplicates.insert(segment.id)
                            } else {
                                await deduplicator.addSpatialEntry(
                                    position: worldPos,
                                    identifier: segment.id.uuidString
                                )
                            }
                        }
                    }
                    #endif
                }
            }

            let frameTime = CACurrentMediaTime() - startTime
            let fps = 1.0 / frameTime

            // Accumulate segments across frames with stable IDs
            self.measuredFPS = fps
            let idMapping = mergeSegments(newSegments)
            self.duplicateSegmentIds = Set(duplicates.compactMap { idMapping[$0] })
            self.sweepState = .scanning(segmentCount: self.segments.count)

            // Throttled haptic on new segments
            let uniqueCount = newSegments.count - duplicates.count
            if uniqueCount > 0 {
                let now = CACurrentMediaTime()
                if now - lastSegmentHapticTime > 0.5 {
                    haptics?.playImpact(style: .light)
                    lastSegmentHapticTime = now
                }
            }

            logger.debug("Frame processed: \(self.segments.count) segments (\(duplicates.count) dupes) at \(String(format: "%.1f", fps)) FPS")
            // Log every 10th frame to reduce disk I/O (4-10 FPS → 0.4-1 log/s)
            if frameCounter % 10 == 0 {
                AppLogger.log(.sweepFrameProcessed(
                    segmentCount: self.segments.count,
                    duplicateCount: duplicates.count,
                    fps: fps
                ))
            }

        } catch {
            logger.error("Frame processing failed: \(error.localizedDescription)")
            AppLogger.log(.sweepError(error: error.localizedDescription))
        }
    }

    // MARK: - Catalog Flow

    /// Crop selected segments, upload to GCS, create sweep session
    /// - Parameters:
    ///   - userId: Current user ID
    ///   - sessionService: Service for creating Firestore session
    ///   - storageService: Service for uploading images to GCS
    public func catalogSelectedSegments(
        userId: String,
        sessionService: SessionServiceProtocol,
        storageService: StorageServiceProtocol
    ) async {
        let selected = selectedSegments
        guard !selected.isEmpty else { return }

        AppLogger.log(.sweepCatalogStarted(selectedCount: selected.count))
        sweepState = .uploading(progress: 0)

        do {
            var crops: [SweepCropInfo] = []

            for (index, segment) in selected.enumerated() {
                // Look up retained keyframe buffer
                guard let pixelBuffer = keyframeBuffers[segment.frameIndex] else {
                    logger.warning("Keyframe buffer not found for frame \(segment.frameIndex), skipping segment")
                    continue
                }

                // Crop using PixelBufferCropper
                let croppedImage = try PixelBufferCropper.cropImage(
                    from: pixelBuffer,
                    boundingBox: segment.boundingBox
                )

                // Upload to GCS via storage service
                let cropId = segment.id.uuidString
                let downloadUrl = try await storageService.uploadCroppedObject(
                    croppedImage,
                    itemId: "sweep_\(cropId)",
                    userId: userId
                )

                let progress = Double(index + 1) / Double(selected.count)
                sweepState = .uploading(progress: progress)

                crops.append(SweepCropInfo(
                    cropUrl: downloadUrl.absoluteString,
                    boundingBox: [
                        Int(segment.boundingBox.minY * 1000),
                        Int(segment.boundingBox.minX * 1000),
                        Int(segment.boundingBox.maxY * 1000),
                        Int(segment.boundingBox.maxX * 1000)
                    ],
                    frameIndex: segment.frameIndex,
                    groupId: cropId
                ))
            }

            // Create Firestore session with sweep mode
            let sessionId = try await sessionService.createSweepSession(
                userId: userId,
                sweepCrops: crops,
                originalFrameUrls: []
            )

            sweepState = .processing

            // Observe session status for completion
            sessionSubscription = sessionService.observeSession(sessionId: sessionId)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] session in
                    guard let self, let session else { return }
                    switch session.status {
                    case .detected:
                        let itemCount = session.detectedObjects.isEmpty ? crops.count : session.detectedObjects.count
                        self.sweepState = .complete(itemCount: itemCount)
                        self.sessionSubscription?.cancel()
                        self.sessionSubscription = nil
                    case .failed:
                        self.sweepState = .error(.catalogFailed("Server processing failed"))
                        self.sessionSubscription?.cancel()
                        self.sessionSubscription = nil
                    default:
                        break // Still processing
                    }
                }

        } catch {
            sweepState = .error(.catalogFailed(error.localizedDescription))
        }
    }
}
