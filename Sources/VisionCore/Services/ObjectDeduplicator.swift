import Foundation
import Vision
@preconcurrency import CoreVideo
import CryptoKit
import os.log

/// Actor responsible for detecting and preventing duplicate object detections
/// Uses VNImageFingerprint (iOS 17+) for perceptual hashing and similarity comparison
/// Maintains a time-based cache to deduplicate objects detected in consecutive frames
public actor ObjectDeduplicator: ObjectDeduplicatorProtocol {

    // MARK: - Types

    /// Cached fingerprint entry with timestamp
    private struct CacheEntry {
        let fingerprint: VNFeaturePrintObservation?
        let timestamp: Date
    }

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.abundance.visioncore", category: "ObjectDeduplicator")

    /// Cache of recently seen fingerprints with timestamps
    private var cache: [String: CacheEntry] = [:]

    /// Time-to-live for cached fingerprints (5 minutes)
    private let cacheTTL: TimeInterval = 300.0 // 5 minutes in seconds

    /// Similarity threshold for considering two objects as duplicates
    /// 0.90 = 90% similar (higher = more strict)
    private let similarityThreshold: Float = 0.90

    // MARK: - Initialization

    public init() {}

    // MARK: - Public API

    /// Generates a perceptual fingerprint for an object region
    /// - Parameters:
    ///   - pixelBuffer: The CVPixelBuffer containing the image data
    ///   - boundingBox: The normalized bounding box (0.0-1.0) of the object region
    /// - Returns: String identifier for the fingerprint
    public nonisolated func generateFingerprint(
        pixelBuffer: CVPixelBuffer,
        boundingBox: CGRect
    ) async -> String? {
        do {
            // Create image feature print request (iOS 17+)
            // VNGenerateImageFeaturePrintRequest generates perceptual hashes
            let request = VNGenerateImageFeaturePrintRequest()
            request.regionOfInterest = boundingBox

            // Create request handler
            let handler = VNImageRequestHandler(
                cvPixelBuffer: pixelBuffer,
                options: [:]
            )

            // Perform request
            try handler.perform([request])

            // Extract results
            guard let results = request.results as? [VNFeaturePrintObservation],
                  let featurePrint = results.first else {
                return nil
            }

            // Generate unique identifier for this fingerprint
            // We hash the feature print data to create a stable string ID
            let identifier = hashFeaturePrint(featurePrint)

            return identifier
        } catch {
            logger.warning("Failed to generate fingerprint: \(error.localizedDescription)")
            return nil
        }
    }

    /// Checks if a fingerprint matches any cached fingerprint within similarity threshold
    /// - Parameter fingerprint: The fingerprint identifier to check
    /// - Returns: true if a similar fingerprint exists in cache, false otherwise
    public func isDuplicate(_ fingerprint: String) async -> Bool {
        // Clean expired entries first
        await cleanCache()

        // Check if this exact fingerprint exists in cache
        if cache[fingerprint] != nil {
            return true
        }

        // TODO: Implement similarity comparison using VNFeaturePrintObservation.computeDistance
        // For now, we only check exact matches
        // This requires storing the actual VNFeaturePrintObservation and computing distances

        return false
    }

    /// Adds a fingerprint to the cache with current timestamp
    /// - Parameter fingerprint: The fingerprint identifier to cache
    public func addToCache(_ fingerprint: String) async {
        // Note: This simplified version only stores the identifier for exact matching
        // For full similarity comparison, use cacheFingerprint() instead
        let entry = CacheEntry(
            fingerprint: nil, // No observation for string-based cache
            timestamp: Date()
        )

        cache[fingerprint] = entry

        // Clean old entries
        await cleanCache()
    }

    /// Checks if a new fingerprint is similar to any cached fingerprints
    /// - Parameters:
    ///   - newFingerprint: The new VNFeaturePrintObservation to check
    ///   - pixelBuffer: The pixel buffer (needed to generate fingerprint)
    ///   - boundingBox: The bounding box region
    /// - Returns: true if a similar object was recently detected, false otherwise
    public func isSimilarToRecent(
        pixelBuffer: CVPixelBuffer,
        boundingBox: CGRect
    ) async -> Bool {
        do {
            // Generate fingerprint for current object
            let request = VNGenerateImageFeaturePrintRequest()
            request.regionOfInterest = boundingBox

            let handler = VNImageRequestHandler(
                cvPixelBuffer: pixelBuffer,
                options: [:]
            )

            try handler.perform([request])

            guard let results = request.results as? [VNFeaturePrintObservation],
                  let newFingerprint = results.first else {
                return false
            }

            // Check similarity against cached fingerprints
            return isFingerPrintDuplicate(newFingerprint)
        } catch {
            logger.warning("Similarity check failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Private Methods

    /// Checks if a fingerprint is similar to any cached fingerprints
    /// - Parameter fingerprint: The fingerprint to check
    /// - Returns: true if similar to a cached fingerprint
    private func isFingerPrintDuplicate(_ fingerprint: VNFeaturePrintObservation) -> Bool {
        // Clean expired entries
        cleanCacheSync()

        for (_, entry) in cache {
            // Skip entries without fingerprint observation data
            guard let cachedFingerprint = entry.fingerprint else {
                continue
            }

            do {
                var distance: Float = 0
                try fingerprint.computeDistance(&distance, to: cachedFingerprint)

                // If distance is small enough, fingerprints are similar
                // Lower distance = more similar
                // Threshold: 1 - similarityThreshold (e.g., 1 - 0.90 = 0.10)
                let maxDistance = Float(1.0 - similarityThreshold)

                if distance <= maxDistance {
                    return true // Found a duplicate
                }
            } catch {
                // If comparison fails, skip this entry
                continue
            }
        }

        return false
    }

    /// Removes expired entries from the cache
    private func cleanCache() async {
        cleanCacheSync()
    }

    /// Synchronous cache cleaning (for use in nonisolated contexts)
    private func cleanCacheSync() {
        let now = Date()
        cache = cache.filter { _, entry in
            now.timeIntervalSince(entry.timestamp) < cacheTTL
        }
    }

    /// Generates a hash string from a feature print observation
    /// - Parameter featurePrint: The feature print to hash
    /// - Returns: Hexadecimal string representation
    private nonisolated func hashFeaturePrint(_ featurePrint: VNFeaturePrintObservation) -> String {
        // Convert feature print data to a stable hash
        // VNFeaturePrintObservation doesn't expose raw data directly
        // So we use its description as a proxy (not ideal but works for testing)
        let data = featurePrint.description.data(using: .utf8) ?? Data()
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Adds a fingerprint observation to the cache
    /// - Parameter fingerprint: The VNFeaturePrintObservation to cache
    public func cacheFingerprint(_ fingerprint: VNFeaturePrintObservation) async {
        let identifier = hashFeaturePrint(fingerprint)
        let entry = CacheEntry(
            fingerprint: fingerprint,
            timestamp: Date()
        )

        cache[identifier] = entry

        // Clean old entries
        await cleanCache()
    }
}
