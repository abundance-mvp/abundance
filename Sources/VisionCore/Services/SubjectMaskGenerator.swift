import Foundation
import Vision
import CoreVideo
import os.log

/// Actor responsible for generating subject instance masks from pixel buffers
/// Uses VNGenerateForegroundInstanceMaskRequest to extract organic object boundaries
/// for rendering glowing borders in the UI
public actor SubjectMaskGenerator: SubjectMaskGeneratorProtocol {

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.abundance.visioncore", category: "SubjectMaskGenerator")

    // MARK: - Initialization

    public init() {}

    // MARK: - Mask Generation

    /// Generates a subject instance mask for the specified bounding box region
    /// - Parameters:
    ///   - pixelBuffer: The CVPixelBuffer containing the image data
    ///   - boundingBox: The normalized bounding box (0.0-1.0) of the object region
    /// - Returns: VNInstanceMaskObservation if successful, nil if mask generation fails
    /// - Note: Typical latency is 50-80ms per mask (validated in Stage 0 research)
    public nonisolated func generateMask(
        pixelBuffer: CVPixelBuffer,
        boundingBox: CGRect
    ) async -> VNInstanceMaskObservation? {
        do {
            // Create foreground instance mask request
            // Available in iOS 17+, generates pixel-accurate subject masks
            let request = VNGenerateForegroundInstanceMaskRequest()

            // Set region of interest to the bounding box to focus mask generation
            // This improves performance and ensures we get the mask for our detected object
            request.regionOfInterest = boundingBox

            // Create request handler with pixel buffer
            let handler = VNImageRequestHandler(
                cvPixelBuffer: pixelBuffer,
                options: [:]
            )

            // Perform the request
            try handler.perform([request])

            // Extract results
            // VNGenerateForegroundInstanceMaskRequest.results returns [VNInstanceMaskObservation]
            guard let results = request.results as? [VNInstanceMaskObservation],
                  let firstMask = results.first else {
                return nil
            }

            // Return the first (and typically only) mask for the region of interest
            // If multiple instances are detected in the ROI, return the first one
            return firstMask
        } catch {
            // Log error but return nil gracefully
            // This allows the UI to fall back to rectangular borders
            logger.warning("Failed to generate mask: \(error.localizedDescription)")
            return nil
        }
    }

}
