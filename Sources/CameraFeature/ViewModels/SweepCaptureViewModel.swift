import Foundation
import os.log
import EdgeTAMFeature
import Persistence

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
public protocol HapticFeedbackProviding {
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

    // MARK: - Initialization

    public init(haptics: HapticFeedbackProviding? = nil) {
        self.haptics = haptics
    }

    // MARK: - Selection Management

    /// Toggle selection state of a segment with haptic feedback
    /// - Parameter segmentId: ID of the segment to toggle
    public func toggleSelection(_ segmentId: UUID) {
        let wasSelected = selectedSegmentIds.contains(segmentId)
        if wasSelected {
            selectedSegmentIds.remove(segmentId)
        } else {
            selectedSegmentIds.insert(segmentId)
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
        sweepState = .inactive
        segments = []
        selectedSegmentIds = []
        canCatalog = false
        measuredFPS = 0
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

        sweepState = .uploading(progress: 0)

        do {
            var crops: [SweepCropInfo] = []

            for (index, segment) in selected.enumerated() {
                // TODO: Crop pixelBuffer using segment.boundingBox via PixelBufferCropper
                // TODO: JPEG encode cropped region
                // TODO: Upload to GCS temp bucket via storageService

                let progress = Double(index + 1) / Double(selected.count)
                sweepState = .uploading(progress: progress)

                // Placeholder crop info — replace with actual upload URL after GCS upload
                #warning("Replace placeholder GCS URLs with actual upload before shipping")
                crops.append(SweepCropInfo(
                    cropUrl: "gs://abundance-temp/sweep_crop_\(index).jpg",
                    boundingBox: [
                        Int(segment.boundingBox.minY * 1000),
                        Int(segment.boundingBox.minX * 1000),
                        Int(segment.boundingBox.maxY * 1000),
                        Int(segment.boundingBox.maxX * 1000)
                    ],
                    frameIndex: segment.frameIndex,
                    groupId: segment.id.uuidString
                ))
            }

            // Create Firestore session with sweep mode
            _ = try await sessionService.createSweepSession(
                userId: userId,
                sweepCrops: crops,
                originalFrameUrls: []  // TODO: include keyframe URLs
            )

            sweepState = .processing
            // Session listener will update to .complete when server finishes

        } catch {
            sweepState = .error(.catalogFailed(error.localizedDescription))
        }
    }
}
