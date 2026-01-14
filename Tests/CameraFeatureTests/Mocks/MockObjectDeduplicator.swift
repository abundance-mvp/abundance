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

    func generateFingerprint(pixelBuffer: CVPixelBuffer, boundingBox: CGRect) async -> String? {
        didCallGenerateFingerprint = true
        return stubbedFingerprint
    }

    func isDuplicate(_ fingerprint: String) async -> Bool {
        didCallIsDuplicate = true
        return stubbedIsDuplicate
    }

    func addToCache(_ fingerprint: String) async {
        didCallAddToCache = true
        cachedFingerprints.append(fingerprint)
    }

    func isSimilarToRecent(pixelBuffer: CVPixelBuffer, boundingBox: CGRect) async -> Bool {
        didCallIsSimilarToRecent = true
        return stubbedIsSimilar
    }

    func cacheFingerprint(_ fingerprint: VNFeaturePrintObservation) async {
        // Not used in tests
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
