import Foundation
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// Platform-agnostic image type alias
#if os(iOS)
public typealias PlatformImage = UIImage
#elseif os(macOS)
public typealias PlatformImage = NSImage
#endif

/// Protocol for household item detection using Vision Framework
public protocol HouseholdItemDetectorProtocol {
    /// Detect household items in an image using Vision Framework
    /// - Parameter image: Input image to analyze
    /// - Returns: Array of detected household items
    /// - Throws: VisionError if detection fails
    func detectHouseholdItems(in image: PlatformImage) async throws -> [HouseholdItem]
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
