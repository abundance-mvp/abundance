import Foundation
@preconcurrency import CoreVideo
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Protocol for household item detection using Vision Framework
public protocol HouseholdItemDetectorProtocol: Sendable {
    /// Detect household items in an image using Vision Framework
    /// - Parameter image: Input image to analyze
    /// - Returns: Array of detected household items
    /// - Throws: VisionError if detection fails
    func detectHouseholdItems(in image: PlatformImage) async throws -> [HouseholdItem]

    /// Detect household items in a real-time video frame using Vision Framework
    /// Optimized for streaming detection pipeline (2 FPS target)
    /// - Parameter pixelBuffer: CVPixelBuffer from camera frame
    /// - Returns: Array of raw YOLO detection results
    /// - Throws: VisionError if detection fails
    /// - Note: Typical latency is <30ms for YOLOv11n inference
    func detectInStream(pixelBuffer: CVPixelBuffer) async throws -> [YOLOResult]
}

/// Errors that can occur during Vision Framework detection
public enum VisionError: Error, LocalizedError {
    case invalidImage
    case modelNotLoaded
    case modelNotFound
    case requestFailed(Error)
    case noItemsDetected

    public var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .modelNotLoaded:
            return "YOLOv3-Tiny model not loaded"
        case .modelNotFound:
            return "YOLOv3-Tiny model not found in bundle"
        case .requestFailed(let error):
            return "Vision request failed: \(error.localizedDescription)"
        case .noItemsDetected:
            return "No household items detected"
        }
    }
}
