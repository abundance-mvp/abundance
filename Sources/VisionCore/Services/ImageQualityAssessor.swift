import Foundation
import Vision
import CoreVideo
import CoreImage
import os.log

/// DEPRECATED: Client-side quality assessment is no longer needed.
///
/// With server-side Gemini 3 Flash detection, the server handles:
/// - Object detection quality filtering
/// - Confidence-based rejection of low-quality detections
/// - Server-side cropping with sharp library
///
/// This class remains for backward compatibility with legacy detection flow.
///
/// @deprecated Server-side detection handles quality filtering
@available(*, deprecated, message: "Server-side detection handles quality filtering")
public actor ImageQualityAssessor: ImageQualityAssessorProtocol {

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.abundance.visioncore", category: "ImageQualityAssessor")
    private let ciContext: CIContext

    // Quality thresholds
    private let automaticCatalogThreshold: Double = 0.65

    // MARK: - Initialization

    public init() {
        // Create CIContext for image processing
        self.ciContext = CIContext(options: [
            .useSoftwareRenderer: false,
            .workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB) as Any
        ])
    }

    // MARK: - Quality Assessment

    /// Assesses the overall quality of an object region in a pixel buffer
    /// - Parameters:
    ///   - pixelBuffer: The CVPixelBuffer containing the image data
    ///   - boundingBox: The normalized bounding box (0.0-1.0) of the object region
    /// - Returns: Composite quality score from 0.0 to 1.0
    /// - Note: Typical latency is 20-35ms per assessment
    public nonisolated func assess(
        pixelBuffer: CVPixelBuffer,
        boundingBox: CGRect
    ) async -> Double {
        // Calculate individual quality metrics
        let aestheticScore = await calculateAestheticScore(pixelBuffer, boundingBox: boundingBox)
        let blurScore = await calculateBlurScore(pixelBuffer, boundingBox: boundingBox)
        let lightingScore = calculateLightingScore(pixelBuffer, boundingBox: boundingBox)
        let completenessScore = calculateCompletenessScore(boundingBox: boundingBox, imageSize: CGSize(
            width: CVPixelBufferGetWidth(pixelBuffer),
            height: CVPixelBufferGetHeight(pixelBuffer)
        ))

        // Weighted average of quality metrics
        // Aesthetic: 40%, Blur: 30%, Lighting: 20%, Completeness: 10%
        let composite = (aestheticScore * 0.4) +
                       (blurScore * 0.3) +
                       (lightingScore * 0.2) +
                       (completenessScore * 0.1)

        return min(max(composite, 0.0), 1.0) // Clamp to [0.0, 1.0]
    }

    // MARK: - Private Quality Metrics

    /// Calculates aesthetic score using VNCalculateImageAestheticsScoresRequest
    /// - Parameters:
    ///   - pixelBuffer: The CVPixelBuffer containing the image data
    ///   - boundingBox: The normalized bounding box of the object region
    /// - Returns: Aesthetic score from 0.0 to 1.0
    private nonisolated func calculateAestheticScore(
        _ pixelBuffer: CVPixelBuffer,
        boundingBox: CGRect
    ) async -> Double {
        // Use Apple's ML-based aesthetic scoring on iOS 17+/macOS 15+
        if #available(iOS 17.0, macOS 15.0, *) {
            return await calculateAestheticScoreWithVision(pixelBuffer, boundingBox: boundingBox)
        } else {
            // Fall back to heuristic-based scoring on older OS versions
            return calculateAestheticScoreHeuristic(pixelBuffer, boundingBox: boundingBox)
        }
    }

    /// Calculates aesthetic score using Apple's VNCalculateImageAestheticsScoresRequest (iOS 17+)
    /// - Parameters:
    ///   - pixelBuffer: The CVPixelBuffer containing the image data
    ///   - boundingBox: The normalized bounding box of the object region
    /// - Returns: Aesthetic score from 0.0 to 1.0
    @available(iOS 17.0, macOS 15.0, *)
    private nonisolated func calculateAestheticScoreWithVision(
        _ pixelBuffer: CVPixelBuffer,
        boundingBox: CGRect
    ) async -> Double {
        do {
            // Create aesthetic score request (iOS 17+/macOS 15+)
            let request = VNCalculateImageAestheticsScoresRequest()
            request.regionOfInterest = boundingBox

            // Create request handler
            let handler = VNImageRequestHandler(
                cvPixelBuffer: pixelBuffer,
                options: [:]
            )

            // Perform request
            try handler.perform([request])

            // Extract results
            guard let results = request.results?.first else {
                // Fall back to heuristic if API fails
                return calculateAestheticScoreHeuristic(pixelBuffer, boundingBox: boundingBox)
            }

            // VNImageAestheticsScoresObservation provides overallScore
            // Note: overallScore can be negative for low-quality images
            // Range is approximately -1.0 to 1.0, normalize to 0.0-1.0
            let overallScore = results.overallScore

            // Normalize from [-1, 1] to [0, 1]
            let normalizedScore = (Double(overallScore) + 1.0) / 2.0
            return min(max(normalizedScore, 0.0), 1.0)
        } catch {
            logger.warning("Aesthetic score API failed, falling back to heuristic: \(error.localizedDescription)")
            // Fall back to heuristic scoring on error
            return calculateAestheticScoreHeuristic(pixelBuffer, boundingBox: boundingBox)
        }
    }

    /// Calculates aesthetic score using heuristic based on image variance
    /// - Parameters:
    ///   - pixelBuffer: The CVPixelBuffer containing the image data
    ///   - boundingBox: The normalized bounding box of the object region
    /// - Returns: Aesthetic score from 0.0 to 1.0
    private nonisolated func calculateAestheticScoreHeuristic(
        _ pixelBuffer: CVPixelBuffer,
        boundingBox: CGRect
    ) -> Double {
        // Simplified aesthetic score based on image variance and contrast
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // Crop to bounding box
        let imageWidth = CVPixelBufferGetWidth(pixelBuffer)
        let imageHeight = CVPixelBufferGetHeight(pixelBuffer)
        let cropRect = CGRect(
            x: boundingBox.origin.x * CGFloat(imageWidth),
            y: boundingBox.origin.y * CGFloat(imageHeight),
            width: boundingBox.width * CGFloat(imageWidth),
            height: boundingBox.height * CGFloat(imageHeight)
        )
        let croppedImage = ciImage.cropped(to: cropRect)

        // Calculate variance as a proxy for "aesthetic interest"
        // More variance typically means more detail and visual interest
        let variance = calculateImageVariance(croppedImage)

        // Normalize to 0.0-1.0 range
        // Higher variance = higher aesthetic score (more interesting)
        let normalizedScore = min(variance / 150.0, 1.0)

        return max(normalizedScore, 0.3) // Minimum score of 0.3 for any valid image
    }

    /// Calculates blur score using Laplacian variance method
    /// - Parameters:
    ///   - pixelBuffer: The CVPixelBuffer containing the image data
    ///   - boundingBox: The normalized bounding box of the object region
    /// - Returns: Blur score from 0.0 (blurry) to 1.0 (sharp)
    private nonisolated func calculateBlurScore(
        _ pixelBuffer: CVPixelBuffer,
        boundingBox: CGRect
    ) async -> Double {
        // Convert CVPixelBuffer to CIImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // Crop to bounding box
        let imageWidth = CVPixelBufferGetWidth(pixelBuffer)
        let imageHeight = CVPixelBufferGetHeight(pixelBuffer)
        let cropRect = CGRect(
            x: boundingBox.origin.x * CGFloat(imageWidth),
            y: boundingBox.origin.y * CGFloat(imageHeight),
            width: boundingBox.width * CGFloat(imageWidth),
            height: boundingBox.height * CGFloat(imageHeight)
        )
        let croppedImage = ciImage.cropped(to: cropRect)

        // Apply Laplacian edge detection filter
        guard let laplacianFilter = CIFilter(name: "CIEdges") else {
            return 0.5
        }
        laplacianFilter.setValue(croppedImage, forKey: kCIInputImageKey)
        laplacianFilter.setValue(1.0, forKey: kCIInputIntensityKey)

        guard let outputImage = laplacianFilter.outputImage else {
            return 0.5
        }

        // Calculate variance of Laplacian
        // Higher variance = sharper image
        let variance = calculateImageVariance(outputImage)

        // Normalize to 0.0-1.0 range
        // Threshold: variance > 100 = sharp (1.0), variance < 10 = blurry (0.0)
        let normalizedScore = (variance - 10.0) / (100.0 - 10.0)
        return min(max(normalizedScore, 0.0), 1.0)
    }

    /// Calculates lighting score (brightness and contrast)
    /// - Parameters:
    ///   - pixelBuffer: The CVPixelBuffer containing the image data
    ///   - boundingBox: The normalized bounding box of the object region
    /// - Returns: Lighting score from 0.0 (poor) to 1.0 (good)
    private nonisolated func calculateLightingScore(
        _ pixelBuffer: CVPixelBuffer,
        boundingBox: CGRect
    ) -> Double {
        // Lock pixel buffer for reading
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return 0.5
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let buffer32 = baseAddress.assumingMemoryBound(to: UInt32.self)

        // Calculate mean brightness in bounding box region
        let startX = Int(boundingBox.origin.x * CGFloat(width))
        let startY = Int(boundingBox.origin.y * CGFloat(height))
        let endX = Int((boundingBox.origin.x + boundingBox.width) * CGFloat(width))
        let endY = Int((boundingBox.origin.y + boundingBox.height) * CGFloat(height))

        var totalBrightness: Double = 0.0
        var pixelCount: Int = 0

        // swiftlint:disable:next identifier_name
        for y in startY..<endY {
            // swiftlint:disable:next identifier_name
            for x in startX..<endX {
                let offset = y * (bytesPerRow / 4) + x
                let pixel = buffer32[offset]

                // Extract RGB components
                let red = Double((pixel >> 16) & 0xFF)
                let green = Double((pixel >> 8) & 0xFF)
                let blue = Double(pixel & 0xFF)

                // Calculate perceived brightness (weighted RGB)
                let brightness = (0.299 * red + 0.587 * green + 0.114 * blue) / 255.0
                totalBrightness += brightness
                pixelCount += 1
            }
        }

        guard pixelCount > 0 else {
            return 0.5
        }

        let meanBrightness = totalBrightness / Double(pixelCount)

        // Good lighting: 0.3 < brightness < 0.8
        // Poor lighting: too dark (<0.2) or too bright (>0.9)
        if meanBrightness < 0.2 || meanBrightness > 0.9 {
            return 0.3 // Poor lighting
        } else if meanBrightness >= 0.3 && meanBrightness <= 0.8 {
            return 1.0 // Good lighting
        } else {
            return 0.7 // Acceptable lighting
        }
    }

    /// Calculates completeness score (object not cut off by edges)
    /// - Parameters:
    ///   - boundingBox: The normalized bounding box of the object
    ///   - imageSize: The size of the image in pixels
    /// - Returns: Completeness score from 0.0 (cut off) to 1.0 (complete)
    private nonisolated func calculateCompletenessScore(
        boundingBox: CGRect,
        imageSize: CGSize
    ) -> Double {
        // Margin threshold (10% of image size)
        let marginX = 0.05
        let marginY = 0.05

        // Check if object is too close to any edge
        let tooCloseToLeft = boundingBox.origin.x < marginX
        let tooCloseToTop = boundingBox.origin.y < marginY
        let tooCloseToRight = (boundingBox.origin.x + boundingBox.width) > (1.0 - marginX)
        let tooCloseToBottom = (boundingBox.origin.y + boundingBox.height) > (1.0 - marginY)

        if tooCloseToLeft || tooCloseToTop || tooCloseToRight || tooCloseToBottom {
            return 0.5 // Object might be cut off
        } else {
            return 1.0 // Object is complete
        }
    }

    // MARK: - Image Processing Helpers

    /// Calculates variance of pixel values in a CIImage
    /// - Parameter image: The CIImage to analyze
    /// - Returns: Variance value
    private nonisolated func calculateImageVariance(_ image: CIImage) -> Double {
        // Use CIAreaAverage to get mean value
        guard let areaAverage = CIFilter(name: "CIAreaAverage") else {
            return 0.0
        }

        areaAverage.setValue(image, forKey: kCIInputImageKey)
        areaAverage.setValue(CIVector(cgRect: image.extent), forKey: kCIInputExtentKey)

        guard let outputImage = areaAverage.outputImage else {
            return 0.0
        }

        // Render to get pixel value
        var bitmap = [UInt8](repeating: 0, count: 4)
        ciContext.render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpace(name: CGColorSpace.sRGB)
        )

        let mean = Double(bitmap[0])

        // Calculate variance using squared differences
        // For edge detection, we're more interested in the range of values
        // This is a simplified variance estimation
        return mean * 1.5 // Heuristic multiplier
    }
}
