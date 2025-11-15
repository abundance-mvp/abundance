import Foundation

/// Represents an alternative label suggestion from the YOLO detector
/// Used to provide backup classification options for objects
public struct AlternativeLabel: Codable, Equatable, Sendable {
    /// Alternative label name (e.g., "cup" as alternative to "mug")
    public let label: String

    /// Confidence score for this alternative classification (0.0-1.0)
    public let confidence: Double

    public init(label: String, confidence: Double) {
        self.label = label
        self.confidence = confidence
    }
}
