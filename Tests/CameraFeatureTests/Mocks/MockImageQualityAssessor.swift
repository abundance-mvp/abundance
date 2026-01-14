import Foundation
@preconcurrency import CoreVideo
@testable import VisionCore

actor MockImageQualityAssessor: ImageQualityAssessorProtocol {
    var stubbedQualityScore: Double = 0.75
    var didCallAssess: Bool = false

    nonisolated func assess(pixelBuffer: CVPixelBuffer, boundingBox: CGRect) async -> Double {
        await markCalled()
        return await stubbedQualityScore
    }

    private func markCalled() {
        didCallAssess = true
    }

    func reset() {
        stubbedQualityScore = 0.75
        didCallAssess = false
    }

    func setQualityScore(_ score: Double) {
        stubbedQualityScore = score
    }
}
