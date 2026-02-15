import Testing
import Foundation
@testable import CameraFeature

@Suite("Sweep Segment Persistence")
struct SweepSegmentPersistenceTests {

    // MARK: - IoU Tests

    @Test("IoU: no overlap returns 0")
    func iouNoOverlap() {
        let a = CGRect(x: 0, y: 0, width: 0.1, height: 0.1)
        let b = CGRect(x: 0.5, y: 0.5, width: 0.1, height: 0.1)
        #expect(SweepCaptureViewModel.iou(a, b) == 0)
    }

    @Test("IoU: identical rects returns 1")
    func iouIdentical() {
        let r = CGRect(x: 0.2, y: 0.2, width: 0.3, height: 0.3)
        #expect(SweepCaptureViewModel.iou(r, r) == 1.0)
    }

    @Test("IoU: partial overlap returns value between 0 and 1")
    func iouPartialOverlap() {
        let a = CGRect(x: 0, y: 0, width: 0.4, height: 0.4)
        let b = CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.4)
        let result = SweepCaptureViewModel.iou(a, b)
        #expect(result > 0)
        #expect(result < 1)
    }

    @Test("IoU: zero-area rect returns 0")
    func iouZeroArea() {
        let a = CGRect(x: 0, y: 0, width: 0, height: 0.1)
        let b = CGRect(x: 0, y: 0, width: 0.1, height: 0.1)
        #expect(SweepCaptureViewModel.iou(a, b) == 0)
    }
}
