import Foundation
import SwiftUI
import Combine
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

/// MainActor-bound ViewModel for sweep capture mode.
///
/// Manages the sweep state machine:
/// inactive -> loading -> scanning -> reviewing -> uploading -> processing -> complete
///
/// Coordinates between EdgeTAMService (segmentation), ObjectDeduplicator (dedup),
/// and SessionService (Firestore persistence).
@MainActor
public final class SweepCaptureViewModel: ObservableObject {

    // MARK: - Published Properties

    /// Current sweep session state
    @Published public var sweepState: SweepSessionState = .inactive

    /// All detected segments (including unselected)
    @Published public var segments: [SegmentedObject] = []

    /// IDs of selected segments
    @Published public var selectedSegmentIds: Set<UUID> = []

    /// Whether the catalog button is enabled
    @Published public var canCatalog: Bool = false

    /// Measured FPS from EdgeTAM inference (updated during scanning)
    @Published public var measuredFPS: Double = 0

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

    // MARK: - Initialization

    public init() {}

    // MARK: - Selection Management

    /// Toggle selection state of a segment
    /// - Parameter segmentId: ID of the segment to toggle
    public func toggleSelection(_ segmentId: UUID) {
        if selectedSegmentIds.contains(segmentId) {
            selectedSegmentIds.remove(segmentId)
        } else {
            selectedSegmentIds.insert(segmentId)
        }
        canCatalog = !selectedSegmentIds.isEmpty
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

                // Placeholder crop info -- replace with actual upload URL after GCS upload
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
            let _ = try await sessionService.createSweepSession(
                userId: userId,
                sweepCrops: crops,
                originalFrameUrls: []  // TODO: include keyframe URLs
            )

            sweepState = .processing
            // Session listener will update to .complete when server finishes

        } catch {
            sweepState = .error(.modelLoadFailed(error.localizedDescription))
        }
    }
}
