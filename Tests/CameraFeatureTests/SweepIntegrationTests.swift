import Testing
import Foundation
@testable import CameraFeature
@testable import Persistence
import EdgeTAMFeature

/// Integration tests for the sweep mode pipeline:
/// start → segments appear → select → catalog → session created
@Suite("Sweep Integration")
struct SweepIntegrationTests {

    // MARK: - Start Flow

    @Test("Start transitions from inactive through loading")
    @MainActor
    func startTransitionsFromInactive() {
        let vm = SweepCaptureViewModel()
        #expect(vm.sweepState == .inactive)

        vm.start()

        // On macOS (non-simulator), hardware check fails → error
        // On iOS simulator, transitions to ready
        #if targetEnvironment(simulator)
        #expect(vm.sweepState == .ready)
        #else
        // macOS: device not supported is expected
        #expect(vm.sweepState == .error(.deviceNotSupported))
        #endif
    }

    @Test("Start from error state attempts recovery")
    @MainActor
    func startFromErrorAttempts() {
        let vm = SweepCaptureViewModel()
        vm.sweepState = .error(.noSegmentsDetected)

        vm.start()

        // Verifies it doesn't stay in noSegmentsDetected error
        #if targetEnvironment(simulator)
        #expect(vm.sweepState == .ready)
        #else
        // macOS: different error (deviceNotSupported) proves recovery was attempted
        #expect(vm.sweepState == .error(.deviceNotSupported))
        #endif
    }

    @Test("Start does nothing when already scanning")
    @MainActor
    func startDoesNothingWhenScanning() {
        let vm = SweepCaptureViewModel()
        vm.sweepState = .scanning(segmentCount: 3)

        vm.start()

        // Should remain scanning, not reset
        #expect(vm.sweepState == .scanning(segmentCount: 3))
    }

    // MARK: - Selection Flow

    @Test("Select multiple segments enables catalog")
    @MainActor
    func selectMultipleSegments() {
        let vm = SweepCaptureViewModel()
        let seg1 = SegmentedObject(boundingBox: .init(x: 0.1, y: 0.1, width: 0.2, height: 0.2), iouScore: 0.9)
        let seg2 = SegmentedObject(boundingBox: .init(x: 0.5, y: 0.1, width: 0.2, height: 0.2), iouScore: 0.85)
        let seg3 = SegmentedObject(boundingBox: .init(x: 0.1, y: 0.5, width: 0.2, height: 0.2), iouScore: 0.7)

        vm.segments = [seg1, seg2, seg3]

        vm.toggleSelection(seg1.id)
        vm.toggleSelection(seg3.id)

        #expect(vm.selectedSegments.count == 2)
        #expect(vm.canCatalog == true)
        #expect(vm.selectedSegmentIds.contains(seg1.id))
        #expect(vm.selectedSegmentIds.contains(seg3.id))
        #expect(!vm.selectedSegmentIds.contains(seg2.id))
    }

    @Test("Deselecting all disables catalog")
    @MainActor
    func deselectAllDisablesCatalog() {
        let vm = SweepCaptureViewModel()
        let seg = SegmentedObject(boundingBox: .init(x: 0.1, y: 0.1, width: 0.2, height: 0.2), iouScore: 0.9)
        vm.segments = [seg]

        vm.toggleSelection(seg.id)
        #expect(vm.canCatalog == true)

        vm.toggleSelection(seg.id)
        #expect(vm.canCatalog == false)
    }

    // MARK: - Duplicate Tracking

    @Test("Duplicate segment IDs are tracked separately from selection")
    @MainActor
    func duplicateSegmentTracking() {
        let vm = SweepCaptureViewModel()
        let seg1 = SegmentedObject(boundingBox: .init(x: 0.1, y: 0.1, width: 0.2, height: 0.2), iouScore: 0.9)
        let seg2 = SegmentedObject(boundingBox: .init(x: 0.5, y: 0.1, width: 0.2, height: 0.2), iouScore: 0.85)

        vm.segments = [seg1, seg2]
        vm.duplicateSegmentIds = [seg2.id]

        // Duplicate can still be selected
        vm.toggleSelection(seg2.id)
        #expect(vm.selectedSegmentIds.contains(seg2.id))
        #expect(vm.duplicateSegmentIds.contains(seg2.id))
    }

    // MARK: - Performance Tier

    @Test("Performance tier maps FPS ranges correctly")
    @MainActor
    func performanceTierMapping() {
        let vm = SweepCaptureViewModel()

        vm.measuredFPS = 15.0
        #expect(vm.performanceTier == .premium)

        vm.measuredFPS = 7.0
        #expect(vm.performanceTier == .good)

        vm.measuredFPS = 2.5
        #expect(vm.performanceTier == .acceptable)

        vm.measuredFPS = 0.5
        #expect(vm.performanceTier == .fallback)

        vm.measuredFPS = 0
        #expect(vm.performanceTier == .fallback)
    }

    // MARK: - Catalog Flow

    @Test("Catalog with no selected segments is a no-op")
    @MainActor
    func catalogEmptySelectionIsNoOp() async {
        let vm = SweepCaptureViewModel()
        let sessionService = MockSessionService()
        let storageService = MockStorageService()

        await vm.catalogSelectedSegments(
            userId: "user-1",
            sessionService: sessionService,
            storageService: storageService
        )

        #expect(sessionService.createSweepSessionCallCount == 0)
        #expect(storageService.uploadCroppedObjectCallCount == 0)
    }

    @Test("Catalog skips segments without keyframe buffers")
    @MainActor
    func catalogSkipsSegmentsWithoutBuffers() async {
        let vm = SweepCaptureViewModel()
        let seg = SegmentedObject(
            boundingBox: .init(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
            iouScore: 0.9,
            frameIndex: 99 // No buffer retained for this frame
        )
        vm.segments = [seg]
        vm.toggleSelection(seg.id)

        let sessionService = MockSessionService()
        let storageService = MockStorageService()

        await vm.catalogSelectedSegments(
            userId: "user-1",
            sessionService: sessionService,
            storageService: storageService
        )

        // Upload should not be called since no keyframe buffer exists
        #expect(storageService.uploadCroppedObjectCallCount == 0)
        // Session should still be created (with empty crops)
        #expect(sessionService.createSweepSessionCallCount == 1)
        #expect(sessionService.capturedSweepCrops.isEmpty)
    }

    // MARK: - State Machine

    @Test("SweepSessionState equality works for all cases")
    func sweepStateEquality() {
        #expect(SweepSessionState.inactive == .inactive)
        #expect(SweepSessionState.loading == .loading)
        #expect(SweepSessionState.ready == .ready)
        #expect(SweepSessionState.scanning(segmentCount: 3) == .scanning(segmentCount: 3))
        #expect(SweepSessionState.scanning(segmentCount: 3) != .scanning(segmentCount: 5))
        #expect(SweepSessionState.uploading(progress: 0.5) == .uploading(progress: 0.5))
        #expect(SweepSessionState.complete(itemCount: 2) == .complete(itemCount: 2))
        #expect(SweepSessionState.error(.memoryPressure) == .error(.memoryPressure))
    }

    @Test("SweepError has user-facing descriptions")
    func sweepErrorDescriptions() {
        #expect(SweepError.deviceNotSupported.errorDescription != nil)
        #expect(SweepError.modelsNotBundled.errorDescription != nil)
        #expect(SweepError.memoryPressure.errorDescription != nil)
        #expect(SweepError.encoderFailed.errorDescription != nil)
        #expect(SweepError.decoderFailed.errorDescription != nil)
        #expect(SweepError.noSegmentsDetected.errorDescription != nil)
        #expect(SweepError.catalogFailed("test").errorDescription?.contains("test") == true)
    }

    // MARK: - Reset

    @Test("Reset clears all state including measured FPS")
    @MainActor
    func resetClearsAllState() {
        let vm = SweepCaptureViewModel()

        // Set up state
        let seg = SegmentedObject(boundingBox: .init(x: 0, y: 0, width: 0.1, height: 0.1), iouScore: 0.8)
        vm.segments = [seg]
        vm.selectedSegmentIds.insert(seg.id)
        vm.duplicateSegmentIds.insert(seg.id)
        vm.sweepState = .scanning(segmentCount: 1)
        vm.measuredFPS = 12.0

        vm.reset()

        #expect(vm.sweepState == .inactive)
        #expect(vm.segments.isEmpty)
        #expect(vm.selectedSegmentIds.isEmpty)
        #expect(vm.duplicateSegmentIds.isEmpty)
        #expect(vm.canCatalog == false)
        #expect(vm.measuredFPS == 0)
    }
}
