import Foundation
@preconcurrency import CoreVideo
@preconcurrency import Vision
@testable import VisionCore

actor MockObjectDeduplicator: ObjectDeduplicatorProtocol {
    var stubbedFingerprint: String? = "mock-fingerprint-123"
    var stubbedIsDuplicate: Bool = false
    var stubbedIsSimilar: Bool = false
    var didCallGenerateFingerprint: Bool = false
    var didCallIsDuplicate: Bool = false
    var didCallAddToCache: Bool = false
    var didCallIsSimilarToRecent: Bool = false
    var cachedFingerprints: [String] = []

    nonisolated func generateFingerprint(pixelBuffer: CVPixelBuffer, boundingBox: CGRect) async -> String? {
        await markGenerateFingerprintCalled()
        return await stubbedFingerprint
    }

    func isDuplicate(_ fingerprint: String) async -> Bool {
        didCallIsDuplicate = true
        return stubbedIsDuplicate
    }

    func addToCache(_ fingerprint: String) async {
        didCallAddToCache = true
        cachedFingerprints.append(fingerprint)
    }

    nonisolated func isSimilarToRecent(pixelBuffer: CVPixelBuffer, boundingBox: CGRect) async -> Bool {
        await markIsSimilarCalled()
        return await stubbedIsSimilar
    }

    func cacheFingerprint(_ fingerprint: VNFeaturePrintObservation) async {
        // Not used in tests
    }

    private func markGenerateFingerprintCalled() {
        didCallGenerateFingerprint = true
    }

    private func markIsSimilarCalled() {
        didCallIsSimilarToRecent = true
    }

    func reset() {
        stubbedFingerprint = "mock-fingerprint-123"
        stubbedIsDuplicate = false
        stubbedIsSimilar = false
        didCallGenerateFingerprint = false
        didCallIsDuplicate = false
        didCallAddToCache = false
        didCallIsSimilarToRecent = false
        cachedFingerprints = []
    }
}
