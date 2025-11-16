import Foundation

/// Confidence score with categorization for UI feedback
public struct ConfidenceScore: Codable, Equatable, Sendable {
    /// Raw confidence from Vision Framework (0-1)
    public let raw: Float

    /// Adjusted confidence after household-item weighting (future: fine-tuning)
    public let adjusted: Float

    /// Categorized confidence level for UI display
    public let category: ConfidenceCategory

    public init(raw: Float, adjusted: Float? = nil) {
        self.raw = raw
        self.adjusted = adjusted ?? raw
        self.category = Self.categorize(adjusted ?? raw)
    }

    private static func categorize(_ confidence: Float) -> ConfidenceCategory {
        switch confidence {
        case 0.8...1.0:
            return .high
        case 0.6..<0.8:
            return .medium
        default:
            return .low
        }
    }

    /// Confidence category for UI feedback
    public enum ConfidenceCategory: String, Codable, Equatable, Sendable {
        case high    // >0.8 (auto-accept)
        case medium  // 0.6-0.8 (prompt verification)
        case low     // <0.6 (filtered out)
    }
}
