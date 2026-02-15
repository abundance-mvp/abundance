import SwiftUI
@preconcurrency import Vision
import CoreImage
import os.log

/// Custom SwiftUI Shape that renders organic contours from binary mask data.
///
/// Used by SegmentOverlayView when EdgeTAM provides mask data for a segment.
/// Converts the binary mask (from `SegmentedObject.maskData`) to a smooth
/// contour path using Vision's VNDetectContoursRequest.
///
/// Falls back to RoundedRectangle if mask processing fails.
struct MaskContourShape: Shape {

    /// Binary mask data (1 byte/pixel, 255=foreground, 0=background)
    let maskData: Data

    /// Mask dimensions
    let maskWidth: Int
    let maskHeight: Int

    private let fallbackCornerRadius: CGFloat = 8
    private let simplificationEpsilon: Float = 0.008
    private static let logger = Logger(subsystem: "com.abundance.camerafeature", category: "MaskContourShape")

    func path(in rect: CGRect) -> Path {
        guard !maskData.isEmpty, maskWidth > 0, maskHeight > 0 else {
            return Path(roundedRect: rect, cornerRadius: fallbackCornerRadius)
        }

        guard let contourPath = extractContour(in: rect) else {
            return Path(roundedRect: rect, cornerRadius: fallbackCornerRadius)
        }

        return contourPath
    }

    // MARK: - Contour Extraction

    /// Extract contour from binary mask data using Vision framework
    private func extractContour(in rect: CGRect) -> Path? {
        // Create grayscale CVPixelBuffer from mask data
        guard let pixelBuffer = createPixelBuffer() else {
            Self.logger.warning("Failed to create pixel buffer from mask data")
            return nil
        }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // Detect contours
        let request = VNDetectContoursRequest()
        request.contrastAdjustment = 1.0
        request.detectsDarkOnLight = false

        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])

        do {
            try handler.perform([request])
        } catch {
            Self.logger.error("Contour detection failed: \(error.localizedDescription)")
            return nil
        }

        guard let observation = request.results?.first else {
            return nil
        }

        return buildPath(from: observation, in: rect)
    }

    /// Create a single-channel CVPixelBuffer from binary mask data
    private func createPixelBuffer() -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
        ]

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            maskWidth,
            maskHeight,
            kCVPixelFormatType_OneComponent8,
            attrs as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else {
            return nil
        }

        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let destPtr = baseAddress.assumingMemoryBound(to: UInt8.self)

        // Copy mask data row by row (bytesPerRow may differ from maskWidth)
        maskData.withUnsafeBytes { srcPtr in
            guard let src = srcPtr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
            for y in 0..<maskHeight {
                let srcOffset = y * maskWidth
                let dstOffset = y * bytesPerRow
                let copyLength = min(maskWidth, bytesPerRow)
                memcpy(destPtr.advanced(by: dstOffset), src.advanced(by: srcOffset), copyLength)
            }
        }

        return buffer
    }

    // MARK: - Path Building

    /// Build SwiftUI Path from VNContoursObservation
    private func buildPath(from observation: VNContoursObservation, in rect: CGRect) -> Path? {
        let topLevelCount = observation.topLevelContourCount
        guard topLevelCount > 0 else { return nil }

        // Find largest contour
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
            return nil
        }

        // Simplify contour
        let simplifiedContour: VNContour
        if let simplified = try? contour.polygonApproximation(epsilon: simplificationEpsilon) {
            simplifiedContour = simplified
        } else {
            simplifiedContour = contour
        }

        let normalizedPoints = simplifiedContour.normalizedPoints
        guard normalizedPoints.count >= 3 else { return nil }

        // Transform from Vision coords (bottom-left origin, 0-1) to SwiftUI coords
        let transformedPoints = normalizedPoints.map { point -> CGPoint in
            CGPoint(
                x: rect.origin.x + CGFloat(point.x) * rect.width,
                y: rect.origin.y + (1.0 - CGFloat(point.y)) * rect.height
            )
        }

        return buildSmoothPath(from: transformedPoints)
    }

    /// Smooth path using quadratic curves through midpoints
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

        let startMidpoint = CGPoint(
            x: (points[0].x + points[points.count - 1].x) / 2,
            y: (points[0].y + points[points.count - 1].y) / 2
        )

        path.move(to: startMidpoint)

        for index in 0..<points.count {
            let current = points[index]
            let next = points[(index + 1) % points.count]
            let midPoint = CGPoint(
                x: (current.x + next.x) / 2,
                y: (current.y + next.y) / 2
            )
            path.addQuadCurve(to: midPoint, control: current)
        }

        path.closeSubpath()
        return path
    }
}
