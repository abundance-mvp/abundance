import Foundation
import SwiftUI
import Combine
import os.log
import EdgeTAMFeature

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
    }
}
