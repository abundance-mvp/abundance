import Foundation
@preconcurrency import CoreVideo
@preconcurrency import Vision
@testable import VisionCore

actor MockSubjectMaskGenerator: SubjectMaskGeneratorProtocol {
    var stubbedMask: VNInstanceMaskObservation? = nil
    var didCallGenerateMask: Bool = false

    nonisolated func generateMask(pixelBuffer: CVPixelBuffer, boundingBox: CGRect) async -> VNInstanceMaskObservation? {
        await markCalled()
        return await stubbedMask
    }

    private func markCalled() {
        didCallGenerateMask = true
    }

    func reset() {
        stubbedMask = nil
        didCallGenerateMask = false
    }
}
