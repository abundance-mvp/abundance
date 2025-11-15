import Foundation
import CoreGraphics

/// Domain model representing a detected household item from Vision Framework
public struct HouseholdItem: Identifiable, Codable, Equatable, Sendable {
    /// Unique identifier
    public let id: UUID

    /// Detected object label (e.g., "tent", "backpack", "bottle")
    public let label: String

    /// Detection confidence score
    public let confidence: ConfidenceScore

    /// Bounding box in Vision coordinates (normalized 0-1, origin bottom-left)
    public let boundingBox: CGRect

    /// Bounding box in UIKit coordinates (pixels, origin top-left)
    public let pixelBoundingBox: CGRect

    public init(
        id: UUID = UUID(),
        label: String,
        confidence: ConfidenceScore,
        boundingBox: CGRect,
        imageSize: CGSize
    ) {
        self.id = id
        self.label = label
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.pixelBoundingBox = Self.visionToUIKit(boundingBox, imageSize: imageSize)
    }

    /// Convert Vision coordinates (normalized, bottom-left origin) to UIKit (pixels, top-left origin)
    private static func visionToUIKit(_ rect: CGRect, imageSize: CGSize) -> CGRect {
        let x = rect.origin.x * imageSize.width
        let y = (1 - rect.origin.y - rect.height) * imageSize.height
        let width = rect.width * imageSize.width
        let height = rect.height * imageSize.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
