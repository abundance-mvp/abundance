import Foundation
import Vision
import CoreImage
import CoreGraphics
import os.log

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Service for cropping a PlatformImage to its primary subject using Vision framework saliency detection.
///
/// Used in the retake photo flow (Edit Item > Retake) to crop the captured image to the individual item,
/// matching the cropping behavior of the initial capture flow (which crops server-side via Gemini).
///
/// Strategy:
/// 1. Run attention-based saliency detection to find the most salient region
/// 2. Expand the salient region with padding for context
/// 3. Crop the image to that region
/// 4. Fall back to center crop if saliency detection fails
public enum ImageSubjectCropper {

    // MARK: - Errors

    public enum CropError: Error, Equatable {
        case invalidImage
        case cgImageConversionFailed
        case saliencyFailed
        case croppingFailed
    }

    // MARK: - Configuration

    /// Padding factor around the detected salient region (0.15 = 15% on each side)
    private static let paddingFactor: CGFloat = 0.15

    /// Minimum dimension ratio for a valid saliency bounding box (prevents tiny crops)
    private static let minimumDimensionRatio: CGFloat = 0.1

    /// Center crop ratio used as fallback (crops to center 70% of the image)
    private static let centerCropRatio: CGFloat = 0.70

    private static let logger = Logger(subsystem: "com.abundance.visioncore", category: "ImageSubjectCropper")

    // MARK: - Public API

    /// Crop a PlatformImage to its primary subject using Vision saliency detection.
    ///
    /// - Parameter image: The full-frame captured image
    /// - Returns: A cropped image focused on the primary subject
    /// - Note: Falls back to center crop if saliency detection yields no usable result.
    ///         Typical latency is 30-80ms on device.
    public static func cropToSubject(_ image: PlatformImage) throws -> PlatformImage {
        guard let cgImage = cgImage(from: image) else {
            throw CropError.invalidImage
        }

        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)

        // Attempt saliency-based crop
        if let saliencyRect = detectSalientRegion(cgImage: cgImage) {
            // Validate the saliency region is meaningful (not too small, not the whole image)
            let isRegionTooSmall = saliencyRect.width < minimumDimensionRatio
                || saliencyRect.height < minimumDimensionRatio
            let isRegionFullImage = saliencyRect.width > 0.95 && saliencyRect.height > 0.95

            if !isRegionTooSmall && !isRegionFullImage {
                // Apply padding and convert to pixel coordinates
                let paddedRect = applyPadding(to: saliencyRect, padding: paddingFactor)
                let pixelRect = CGRect(
                    x: paddedRect.minX * imageWidth,
                    y: paddedRect.minY * imageHeight,
                    width: paddedRect.width * imageWidth,
                    height: paddedRect.height * imageHeight
                )

                if let cropped = cgImage.cropping(to: pixelRect) {
                    logger.info("Saliency crop: \(Int(pixelRect.width))x\(Int(pixelRect.height)) from \(Int(imageWidth))x\(Int(imageHeight))")
                    return platformImage(from: cropped)
                }
            }
        }

        // Fallback: center crop
        logger.info("Saliency detection insufficient, using center crop fallback")
        return try centerCrop(cgImage: cgImage, ratio: centerCropRatio)
    }

    // MARK: - Saliency Detection

    /// Run attention-based saliency detection on a CGImage.
    ///
    /// Returns a normalized bounding box (0-1 range, origin top-left) of the most salient region,
    /// or nil if detection fails or yields no results.
    private static func detectSalientRegion(cgImage: CGImage) -> CGRect? {
        let request = VNGenerateAttentionBasedSaliencyImageRequest()

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
        } catch {
            logger.warning("Saliency request failed: \(error.localizedDescription)")
            return nil
        }

        guard let results = request.results, let observation = results.first else {
            return nil
        }

        // VNSaliencyImageObservation.salientObjects returns bounding boxes of salient regions
        // These are in Vision coordinates: origin bottom-left, normalized 0-1
        guard let salientObjects = observation.salientObjects, !salientObjects.isEmpty else {
            return nil
        }

        // Union all salient object bounding boxes to get the overall salient region
        var unionBox = salientObjects[0].boundingBox
        for object in salientObjects.dropFirst() {
            unionBox = unionBox.union(object.boundingBox)
        }

        // Convert from Vision coordinates (bottom-left origin) to image coordinates (top-left origin)
        let convertedRect = CGRect(
            x: unionBox.minX,
            y: 1.0 - unionBox.maxY,
            width: unionBox.width,
            height: unionBox.height
        )

        return convertedRect
    }

    // MARK: - Crop Helpers

    /// Apply padding around a normalized rect, clamping to 0-1 bounds
    private static func applyPadding(to rect: CGRect, padding: CGFloat) -> CGRect {
        let padX = rect.width * padding
        let padY = rect.height * padding

        let expanded = CGRect(
            x: max(0, rect.minX - padX),
            y: max(0, rect.minY - padY),
            width: min(1.0 - max(0, rect.minX - padX), rect.width + 2 * padX),
            height: min(1.0 - max(0, rect.minY - padY), rect.height + 2 * padY)
        )

        return expanded
    }

    /// Center crop a CGImage to the given ratio
    private static func centerCrop(cgImage: CGImage, ratio: CGFloat) throws -> PlatformImage {
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)

        let cropWidth = imageWidth * ratio
        let cropHeight = imageHeight * ratio
        let cropX = (imageWidth - cropWidth) / 2.0
        let cropY = (imageHeight - cropHeight) / 2.0

        let cropRect = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)

        guard let cropped = cgImage.cropping(to: cropRect) else {
            throw CropError.croppingFailed
        }

        logger.info("Center crop: \(Int(cropWidth))x\(Int(cropHeight)) from \(Int(imageWidth))x\(Int(imageHeight))")
        return platformImage(from: cropped)
    }

    // MARK: - Platform Conversion

    /// Extract a CGImage from a PlatformImage
    private static func cgImage(from image: PlatformImage) -> CGImage? {
        #if os(iOS)
        return image.cgImage
        #elseif os(macOS)
        return image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        #endif
    }

    /// Create a PlatformImage from a CGImage
    private static func platformImage(from cgImage: CGImage) -> PlatformImage {
        #if os(iOS)
        return UIImage(cgImage: cgImage)
        #elseif os(macOS)
        return NSImage(
            cgImage: cgImage,
            size: NSSize(width: cgImage.width, height: cgImage.height)
        )
        #endif
    }
}
