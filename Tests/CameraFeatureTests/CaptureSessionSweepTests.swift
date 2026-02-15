import Foundation
import Testing
@testable import CameraFeature

@Suite("Capture Session Sweep Mode")
struct CaptureSessionSweepTests {

    @Test("CaptureMode includes sweep")
    func captureModeIncludesSweep() {
        let mode = CaptureMode(rawValue: "sweep")
        #expect(mode == .sweep)
    }

    @Test("Sweep mode raw value is 'sweep'")
    func sweepRawValue() {
        #expect(CaptureMode.sweep.rawValue == "sweep")
    }

    @Test("Sweep session initializes with sweep mode")
    func sweepSessionInit() {
        let session = CaptureSession(
            id: "test-1",
            userId: "user-1",
            captureMode: .sweep
        )
        #expect(session.captureMode == .sweep)
    }

    @Test("Sweep crops field defaults to empty")
    func sweepCropsDefaultEmpty() {
        let session = CaptureSession(
            id: "test-1",
            userId: "user-1",
            captureMode: .sweep
        )
        #expect(session.sweepCrops.isEmpty)
    }

    @Test("SweepCropInfo initializes correctly")
    func sweepCropInfoInit() {
        let crop = SweepCropInfo(
            cropUrl: "gs://bucket/crop.jpg",
            boundingBox: [100, 200, 300, 400],
            frameIndex: 0,
            groupId: "group-1"
        )
        #expect(crop.cropUrl == "gs://bucket/crop.jpg")
        #expect(crop.boundingBox == [100, 200, 300, 400])
        #expect(crop.frameIndex == 0)
        #expect(crop.groupId == "group-1")
    }

    @Test("SweepCropInfo is Codable")
    func sweepCropInfoCodable() throws {
        let crop = SweepCropInfo(
            cropUrl: "gs://bucket/crop.jpg",
            boundingBox: [100, 200, 300, 400],
            frameIndex: 2,
            groupId: "group-abc"
        )
        let data = try JSONEncoder().encode(crop)
        let decoded = try JSONDecoder().decode(SweepCropInfo.self, from: data)
        #expect(decoded.cropUrl == crop.cropUrl)
        #expect(decoded.boundingBox == crop.boundingBox)
        #expect(decoded.frameIndex == crop.frameIndex)
        #expect(decoded.groupId == crop.groupId)
    }
}
