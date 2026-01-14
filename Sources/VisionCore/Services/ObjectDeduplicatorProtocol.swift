import Foundation
import Vision
import CoreVideo

/// Protocol for detecting and preventing duplicate object detections
/// Enables dependency injection and testing with mock implementations
public protocol ObjectDeduplicatorProtocol: Actor, Sendable {
    /// Generates a perceptual fingerprint for an object region
    /// - Parameters:
    ///   - pixelBuffer: The CVPixelBuffer containing the image data (must be copied before crossing isolation boundaries)
    ///   - boundingBox: The normalized bounding box (0.0-1.0) of the object region
    /// - Returns: String identifier for the fingerprint
    /// - Note: Actor-isolated to ensure thread-safe access to CVPixelBuffer per Swift 6 concurrency requirements
    func generateFingerprint(
        pixelBuffer: CVPixelBuffer,
        boundingBox: CGRect
    ) async -> String?

    /// Checks if a fingerprint matches any cached fingerprint within similarity threshold
    /// - Parameter fingerprint: The fingerprint identifier to check
    /// - Returns: true if a similar fingerprint exists in cache, false otherwise
    func isDuplicate(_ fingerprint: String) async -> Bool

    /// Adds a fingerprint to the cache with current timestamp
    /// - Parameter fingerprint: The fingerprint identifier to cache
    func addToCache(_ fingerprint: String) async

    /// Checks if a new fingerprint is similar to any cached fingerprints
    /// - Parameters:
    ///   - pixelBuffer: The pixel buffer (needed to generate fingerprint)
    ///   - boundingBox: The bounding box region
    /// - Returns: true if a similar object was recently detected, false otherwise
    func isSimilarToRecent(
        pixelBuffer: CVPixelBuffer,
        boundingBox: CGRect
    ) async -> Bool

    /// Adds a fingerprint observation to the cache
    /// - Parameter fingerprint: The VNFeaturePrintObservation to cache
    func cacheFingerprint(_ fingerprint: VNFeaturePrintObservation) async
}
