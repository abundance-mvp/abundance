import Testing
import Foundation
@testable import CameraFeature
import EdgeTAMFeature

@Suite("Sweep Capture ViewModel")
struct SweepCaptureViewModelTests {

    @Test("Initial state is inactive")
    @MainActor
    func initialStateInactive() {
        let vm = SweepCaptureViewModel()
        #expect(vm.sweepState == .inactive)
        #expect(vm.segments.isEmpty)
        #expect(vm.selectedSegments.isEmpty)
    }

    @Test("Select segment adds to selection")
    @MainActor
    func selectSegment() {
        let vm = SweepCaptureViewModel()
        let segment = SegmentedObject(
            boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
            iouScore: 0.8
        )
        vm.segments = [segment]
        vm.toggleSelection(segment.id)
        #expect(vm.selectedSegments.count == 1)
        #expect(vm.canCatalog == true)
    }

    @Test("Deselect segment removes from selection")
    @MainActor
    func deselectSegment() {
        let vm = SweepCaptureViewModel()
        let segment = SegmentedObject(
            boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
            iouScore: 0.8
        )
        vm.segments = [segment]
        vm.selectedSegmentIds.insert(segment.id)
        vm.toggleSelection(segment.id)
        #expect(vm.selectedSegments.isEmpty)
        #expect(vm.canCatalog == false)
    }

    @Test("Clear selections resets state")
    @MainActor
    func clearSelections() {
        let vm = SweepCaptureViewModel()
        let seg1 = SegmentedObject(boundingBox: .init(x: 0, y: 0, width: 0.1, height: 0.1), iouScore: 0.8)
        let seg2 = SegmentedObject(boundingBox: .init(x: 0.5, y: 0.5, width: 0.1, height: 0.1), iouScore: 0.8)
        vm.segments = [seg1, seg2]
        vm.selectedSegmentIds = [seg1.id, seg2.id]
        vm.clearSelections()
        #expect(vm.selectedSegments.isEmpty)
        #expect(vm.selectedSegmentIds.isEmpty)
        #expect(vm.canCatalog == false)
    }

    @Test("Reset clears everything")
    @MainActor
    func resetClearsAll() {
        let vm = SweepCaptureViewModel()
        let seg = SegmentedObject(boundingBox: .init(x: 0, y: 0, width: 0.1, height: 0.1), iouScore: 0.8)
        vm.segments = [seg]
        vm.selectedSegmentIds.insert(seg.id)
        vm.sweepState = .scanning(segmentCount: 1)
        vm.reset()
        #expect(vm.sweepState == .inactive)
        #expect(vm.segments.isEmpty)
        #expect(vm.selectedSegmentIds.isEmpty)
        #expect(vm.canCatalog == false)
    }

    @Test("Segment count matches segments array")
    @MainActor
    func segmentCount() {
        let vm = SweepCaptureViewModel()
        let seg1 = SegmentedObject(boundingBox: .init(x: 0, y: 0, width: 0.1, height: 0.1), iouScore: 0.8)
        let seg2 = SegmentedObject(boundingBox: .init(x: 0.5, y: 0.5, width: 0.1, height: 0.1), iouScore: 0.8)
        vm.segments = [seg1, seg2]
        #expect(vm.segmentCount == 2)
    }

    @Test("Toggle twice returns to unselected")
    @MainActor
    func toggleTwiceUnselects() {
        let vm = SweepCaptureViewModel()
        let seg = SegmentedObject(boundingBox: .init(x: 0, y: 0, width: 0.1, height: 0.1), iouScore: 0.8)
        vm.segments = [seg]
        vm.toggleSelection(seg.id)
        #expect(vm.selectedSegments.count == 1)
        vm.toggleSelection(seg.id)
        #expect(vm.selectedSegments.isEmpty)
    }
}
