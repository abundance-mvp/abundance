import Foundation
import CoreVideo
import CoreGraphics
import CoreImage

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Utility for cropping images from CVPixelBuffers using Vision Framework bounding boxes
public enum PixelBufferCropper {

    public enum CropError: Error, Equatable {
        case invalidPixelBuffer
        case invalidBoundingBox
        case conversionFailed
    }

    /// Reusable CIContext — creating one per-crop costs 100-250ms of GPU/CPU setup.
    private static let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    /// Crop image from CVPixelBuffer using Vision bounding box
    /// - Parameters:
    ///   - pixelBuffer: Source pixel buffer from camera
    ///   - boundingBox: Vision normalized bounding box (origin bottom-left, 0-1 range)
    /// - Returns: Cropped platform image
    public static func cropImage(
        from pixelBuffer: CVPixelBuffer,
        boundingBox: CGRect
    ) throws -> PlatformImage {
        // Validate bounding box
        guard boundingBox.minX >= 0 && boundingBox.minY >= 0 &&
              boundingBox.maxX <= 1 && boundingBox.maxY <= 1 else {
            throw CropError.invalidBoundingBox
        }

        // Convert to CIImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // Get dimensions
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        // Convert Vision coordinates (bottom-left origin) to CoreImage (top-left origin)
        let cropRect = CGRect(
            x: boundingBox.minX * CGFloat(width),
            y: (1 - boundingBox.maxY) * CGFloat(height),
            width: boundingBox.width * CGFloat(width),
            height: boundingBox.height * CGFloat(height)
        )

        // Crop
        let croppedCI = ciImage.cropped(to: cropRect)

        // Convert to platform image
        guard let cgImage = ciContext.createCGImage(croppedCI, from: croppedCI.extent) else {
            throw CropError.conversionFailed
        }

        #if os(iOS)
        return UIImage(cgImage: cgImage)
        #elseif os(macOS)
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        #endif
    }
}
