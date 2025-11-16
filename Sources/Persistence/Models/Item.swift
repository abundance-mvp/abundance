import Foundation

/// Represents a cataloged household item
/// Lifecycle: pending → layer2a_complete → layer2b_complete → complete
public struct Item: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let userId: String
    public let imageUrl: String
    public var status: ItemStatus

    // Layer 2a extracted attributes (Gemini Flash Lite)
    public var category: String?
    public var color: String?
    public var material: String?
    public var condition: String?
    public var confidence: Double?

    // Layer 2b/3 enriched attributes
    public var estimatedValue: Double?

    // Metadata
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: String,
        userId: String,
        imageUrl: String,
        status: ItemStatus,
        category: String? = nil,
        color: String? = nil,
        material: String? = nil,
        condition: String? = nil,
        confidence: Double? = nil,
        estimatedValue: Double? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.imageUrl = imageUrl
        self.status = status
        self.category = category
        self.color = color
        self.material = material
        self.condition = condition
        self.confidence = confidence
        self.estimatedValue = estimatedValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Item processing status matching Firestore trigger states
public enum ItemStatus: String, Codable, Sendable {
    case pending = "pending"
    case layer2aComplete = "layer2a_complete"
    case layer2bScheduled = "layer2b_scheduled"
    case layer2bComplete = "layer2b_complete"
    case complete = "complete"
    case failed = "failed"
    case failedLayer2a = "failed_layer2a"
    case failedLayer2b = "failed_layer2b"
}
