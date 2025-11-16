import Foundation
import Vision
import CoreVideo

/// Protocol for generating subject instance masks from pixel buffers
/// Enables dependency injection and testing with mock implementations
public protocol SubjectMaskGeneratorProtocol: Actor, Sendable {
    /// Generates a subject instance mask for the specified bounding box region
    /// - Parameters:
    ///   - pixelBuffer: The CVPixelBuffer containing the image data
    ///   - boundingBox: The normalized bounding box (0.0-1.0) of the object region
    /// - Returns: VNInstanceMaskObservation if successful, nil if mask generation fails
    /// - Note: Typical latency is 50-80ms per mask (validated in Stage 0 research)
    nonisolated func generateMask(
        pixelBuffer: CVPixelBuffer,
        boundingBox: CGRect
    ) async -> VNInstanceMaskObservation?
}
