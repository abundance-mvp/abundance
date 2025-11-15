import Foundation
import CoreGraphics

/// Raw detection result from YOLO model for real-time streaming
/// Used in the detection pipeline before quality assessment and deduplication
public struct YOLOResult: Identifiable, Equatable, Sendable {
    /// Unique identifier for this detection
    public let id: UUID

    /// Primary detected object label from YOLO (e.g., "bottle", "laptop", "chair")
    public let label: String

    /// YOLO detection confidence score (0.0-1.0)
    public let confidence: Double

    /// Normalized bounding box in Vision coordinates (0.0-1.0, origin bottom-left)
    public let boundingBox: CGRect

    /// Alternative label suggestions from YOLO with lower confidence
    /// Ordered by confidence, provides backup classification options
    public let alternativeLabels: [AlternativeLabel]

    public init(
        id: UUID = UUID(),
        label: String,
        confidence: Double,
        boundingBox: CGRect,
        alternativeLabels: [AlternativeLabel] = []
    ) {
        self.id = id
        self.label = label
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.alternativeLabels = alternativeLabels
    }
}
