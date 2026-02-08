import SwiftUI
import Core
@preconcurrency import Vision
import CoreImage
import os.log

/// Custom SwiftUI Shape that extracts organic contour from VNInstanceMaskObservation
/// Uses Vision's contour detection to trace object edges from segmentation mask
/// Falls back to rounded rectangle if mask extraction fails
struct OrganicBorderShape: Shape {

    let mask: VNInstanceMaskObservation?

    /// Corner radius for fallback rectangle
    private let fallbackCornerRadius: CGFloat = 12

    /// Simplification tolerance for path smoothing (reduces jaggedness)
    /// Lower values = more detail, higher values = smoother curves
    private let simplificationEpsilon: Float = 0.005

    /// Logger for debug output
    private static let logger = Logger(subsystem: "com.abundance.camerafeature", category: "OrganicBorderShape")

    func path(in rect: CGRect) -> Path {
        // If no mask, return rounded rectangle as fallback
        guard let mask = mask else {
            Self.logger.debug("OrganicBorderShape: No mask provided, using fallback rectangle")
            return Path(roundedRect: rect, cornerRadius: fallbackCornerRadius)
        }

        // Extract contour from mask
        guard let contourPath = extractContour(from: mask, in: rect) else {
            Self.logger.warning("OrganicBorderShape: Contour extraction failed, using fallback rectangle")
            return Path(roundedRect: rect, cornerRadius: fallbackCornerRadius)
        }

        Self.logger.info("OrganicBorderShape: Successfully extracted organic contour")
        return contourPath
    }

    // MARK: - Contour Extraction

    /// Extracts contour path from VNInstanceMaskObservation using Vision's contour detection
    /// - Parameters:
    ///   - mask: The instance mask observation containing segmentation data
    ///   - rect: The target rectangle to scale the contour into
    /// - Returns: A SwiftUI Path tracing the object boundary, or nil if extraction fails
    private func extractContour(from mask: VNInstanceMaskObservation, in rect: CGRect) -> Path? {
        // Get all instance indices from the mask
        let allInstances = mask.allInstances

        // If no instances detected, return nil
        guard !allInstances.isEmpty else {
            return nil
        }

        // Generate binary mask for all detected instances
        // This creates a CVPixelBuffer where foreground = 255, background = 0
        guard let maskPixelBuffer = try? mask.generateMask(forInstances: allInstances) else {
            return nil
        }

        // Convert pixel buffer to CIImage for contour detection
        let ciImage = CIImage(cvPixelBuffer: maskPixelBuffer)

        // Use VNDetectContoursRequest to extract contours from the binary mask
        let request = VNDetectContoursRequest()
        request.contrastAdjustment = 1.0
        request.detectsDarkOnLight = false // Mask has bright foreground on dark background

        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])

        do {
            try handler.perform([request])
        } catch {
            Self.logger.error("Contour detection failed: \(error.localizedDescription)")
            return nil
        }

        guard let contoursObservation = request.results?.first else {
            Self.logger.warning("No contours found in mask")
            return nil
        }

        Self.logger.debug("Found \(contoursObservation.topLevelContourCount) top-level contours")

        // Build path from detected contours
        return buildPath(from: contoursObservation, in: rect)
    }

    // MARK: - Path Building

    /// Builds a SwiftUI Path from VNContoursObservation
    /// - Parameters:
    ///   - observation: The contours observation from Vision
    ///   - rect: Target rectangle for scaling
    /// - Returns: A smoothed SwiftUI Path
    private func buildPath(
        from observation: VNContoursObservation,
        in rect: CGRect
    ) -> Path? {
        // Get the top-level contour count (outer boundaries)
        // VNContoursObservation organizes contours hierarchically
        let topLevelCount = observation.topLevelContourCount

        guard topLevelCount > 0 else {
            return nil
        }

        // Find the largest contour (most likely to be the main object)
        var largestContour: VNContour?
        var largestPointCount = 0

        for index in 0..<topLevelCount {
            if let contour = try? observation.contour(at: index) {
                if contour.pointCount > largestPointCount {
                    largestPointCount = contour.pointCount
                    largestContour = contour
                }
            }
        }

        guard let contour = largestContour, contour.pointCount >= 3 else {
            Self.logger.warning("No valid contour found (need >= 3 points)")
            return nil
        }

        Self.logger.debug("Largest contour has \(contour.pointCount) points")

        // Simplify the contour to reduce jaggedness while preserving shape
        let simplifiedContour: VNContour
        if let simplified = try? contour.polygonApproximation(epsilon: simplificationEpsilon) {
            Self.logger.debug("Simplified contour: \(contour.pointCount) → \(simplified.pointCount) points")
            simplifiedContour = simplified
        } else {
            Self.logger.debug("Simplification failed, using original contour")
            simplifiedContour = contour
        }

        // Get normalized points from contour
        let normalizedPoints = simplifiedContour.normalizedPoints

        guard normalizedPoints.count >= 3 else {
            return nil
        }

        // Transform points from Vision coordinates (origin bottom-left, 0-1 range)
        // to SwiftUI coordinates (origin top-left)
        let transformedPoints = normalizedPoints.map { point -> CGPoint in
            CGPoint(
                x: rect.origin.x + CGFloat(point.x) * rect.width,
                y: rect.origin.y + (1.0 - CGFloat(point.y)) * rect.height
            )
        }

        // Build smooth path using quadratic curves for organic appearance
        return buildSmoothPath(from: transformedPoints)
    }

    /// Creates a smooth path using quadratic curves for organic appearance
    /// - Parameter points: Array of points forming the contour
    /// - Returns: A smoothed Path
    private func buildSmoothPath(from points: [CGPoint]) -> Path {
        guard points.count >= 3 else {
            var path = Path()
            if let first = points.first {
                path.move(to: first)
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
                path.closeSubpath()
            }
            return path
        }

        var path = Path()

        // Calculate the midpoint between first and last point for starting position
        let startMidpoint = CGPoint(
            x: (points[0].x + points[points.count - 1].x) / 2,
            y: (points[0].y + points[points.count - 1].y) / 2
        )

        path.move(to: startMidpoint)

        // Use quadratic curves through midpoints for smooth organic curves
        for index in 0..<points.count {
            let current = points[index]
            let next = points[(index + 1) % points.count]

            // Calculate midpoint to next point
            let midPoint = CGPoint(
                x: (current.x + next.x) / 2,
                y: (current.y + next.y) / 2
            )

            // Add quadratic curve using current point as control point
            path.addQuadCurve(to: midPoint, control: current)
        }

        path.closeSubpath()

        return path
    }
}

// MARK: - Preview

#Preview("Organic Shape - No Mask (Fallback)") {
    ZStack {
        Color.black.ignoresSafeArea()

        OrganicBorderShape(mask: nil)
            .stroke(Color.salmon, lineWidth: 3)
            .frame(width: 200, height: 250)
    }
}
