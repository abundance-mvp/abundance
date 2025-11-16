import Foundation
import CoreVideo

/// Protocol for assessing image quality of detected objects
/// Enables dependency injection and testing with mock implementations
public protocol ImageQualityAssessorProtocol: Actor, Sendable {
    /// Assesses the overall quality of an object region in a pixel buffer
    /// - Parameters:
    ///   - pixelBuffer: The CVPixelBuffer containing the image data
    ///   - boundingBox: The normalized bounding box (0.0-1.0) of the object region
    /// - Returns: Composite quality score from 0.0 to 1.0
    /// - Note: Typical latency is 20-35ms per assessment
    nonisolated func assess(
        pixelBuffer: CVPixelBuffer,
        boundingBox: CGRect
    ) async -> Double
}
