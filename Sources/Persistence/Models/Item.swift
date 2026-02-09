import Foundation

/// Item condition assessment (matches Gemini output)
public enum ItemCondition: String, Codable, Sendable, CaseIterable {
    case new
    case likeNew = "like-new"
    case good
    case fair
    case poor

    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .new: return "New"
        case .likeNew: return "Like New"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        }
    }
}

/// AI confidence level for catalog identification
public enum ItemConfidence: String, Codable, Sendable, CaseIterable {
    case high
    case medium
    case low

    /// Numeric value for display (0.0-1.0)
    public var numericValue: Double {
        switch self {
        case .high: return 0.9
        case .medium: return 0.7
        case .low: return 0.4
        }
    }
}

/// Represents a cataloged household item
/// Lifecycle: pending -> layer2a_complete -> layer2b_complete -> complete
public struct Item: Identifiable, Codable, Equatable, Sendable {

    // MARK: - Core Fields

    public let id: String
    public let userId: String
    public let imageUrl: String
    public var status: ItemStatus

    // MARK: - Catalog Data (expanded to match Gemini output)

    /// Product/item name (e.g., "Coleman Sundome Tent")
    public var name: String?

    /// Primary category (e.g., "Outdoor & Camping")
    public var category: String?

    /// Sub-category (e.g., "Tents")
    public var subCategory: String?

    /// Brand name if identifiable (e.g., "Coleman")
    public var brand: String?

    /// Model name/number if identifiable
    public var model: String?

    /// Primary color(s) (e.g., "Blue/Gray")
    public var color: String?

    /// Primary material (e.g., "Polyester")
    public var material: String?

    /// Physical condition assessment
    public var condition: ItemCondition?

    /// Size/dimensions info (e.g., "4-person, 9' x 7'")
    public var dimensions: String?

    /// Number of items (default 1)
    public var quantity: Int?

    /// Estimated market value in USD
    public var estimatedValue: Double?

    // MARK: - AI Metadata (read-only, not user-editable)

    /// AI confidence level for identification
    public var confidence: ItemConfidence?

    /// Processing notes from AI (issues, assumptions made)
    public var processingNotes: String?

    // MARK: - Layer 1 Fallback Data

    /// Label from Layer 1 detection (fallback when Layer 2 fails)
    public var layer1Label: String?

    /// Category from Layer 1 detection (fallback when Layer 2 fails)
    public var layer1Category: String?

    // MARK: - Edit Tracking

    /// Fields that user has manually edited (for training data)
    public var userEditedFields: [String]?

    /// Timestamp of last rescan (for edit flow)
    public var lastRescanAt: Date?

    // MARK: - Additional Photos

    /// URLs for additional photos beyond the primary imageUrl
    public var additionalImageUrls: [String]?

    /// Display name with full fallback chain: name → layer1Label → category → layer1Category
    public var displayName: String {
        name ?? layer1Label ?? category ?? layer1Category ?? "Unknown Item"
    }

    /// All image URLs: primary + additional
    public var allImageUrls: [String] {
        [imageUrl] + (additionalImageUrls ?? [])
    }

    /// Total number of photos
    public var photoCount: Int {
        1 + (additionalImageUrls?.count ?? 0)
    }

    // MARK: - Refresh (Firestore fields: deepScanRequested, deepScanCompletedAt)

    /// Whether a refresh has been requested (Firestore field: deepScanRequested)
    public var refreshRequested: Bool?

    /// When refresh completed (Firestore field: deepScanCompletedAt)
    public var refreshCompletedAt: Date?

    /// Product URL from refresh
    public var productUrl: String?

    /// UPC/barcode from refresh
    public var upcCode: String?

    /// Market price range from refresh (e.g., "$50-$80")
    public var marketPriceRange: String?

    /// Original retail price from refresh
    public var originalRetailPrice: Double?

    // MARK: - Photo Metadata

    /// Captured photo metadata for fraud prevention
    public var photoMetadata: PhotoMetadata?

    // MARK: - Timestamps

    public let createdAt: Date
    public var updatedAt: Date

    // MARK: - Initializer

    public init(
        id: String,
        userId: String,
        imageUrl: String,
        status: ItemStatus,
        name: String? = nil,
        category: String? = nil,
        subCategory: String? = nil,
        brand: String? = nil,
        model: String? = nil,
        color: String? = nil,
        material: String? = nil,
        condition: ItemCondition? = nil,
        dimensions: String? = nil,
        quantity: Int? = nil,
        estimatedValue: Double? = nil,
        confidence: ItemConfidence? = nil,
        processingNotes: String? = nil,
        layer1Label: String? = nil,
        layer1Category: String? = nil,
        userEditedFields: [String]? = nil,
        lastRescanAt: Date? = nil,
        additionalImageUrls: [String]? = nil,
        refreshRequested: Bool? = nil,
        refreshCompletedAt: Date? = nil,
        productUrl: String? = nil,
        upcCode: String? = nil,
        marketPriceRange: String? = nil,
        originalRetailPrice: Double? = nil,
        photoMetadata: PhotoMetadata? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.imageUrl = imageUrl
        self.status = status
        self.name = name
        self.category = category
        self.subCategory = subCategory
        self.brand = brand
        self.model = model
        self.color = color
        self.material = material
        self.condition = condition
        self.dimensions = dimensions
        self.quantity = quantity
        self.estimatedValue = estimatedValue
        self.confidence = confidence
        self.processingNotes = processingNotes
        self.layer1Label = layer1Label
        self.layer1Category = layer1Category
        self.userEditedFields = userEditedFields
        self.lastRescanAt = lastRescanAt
        self.additionalImageUrls = additionalImageUrls
        self.refreshRequested = refreshRequested
        self.refreshCompletedAt = refreshCompletedAt
        self.productUrl = productUrl
        self.upcCode = upcCode
        self.marketPriceRange = marketPriceRange
        self.originalRetailPrice = originalRetailPrice
        self.photoMetadata = photoMetadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Item processing status — simplified to 3 states
/// Legacy Firestore values (pending, layer2a_complete, etc.) are mapped on decode
public enum ItemStatus: String, Codable, Sendable {
    case processing = "processing"
    case complete = "complete"
    case failed = "failed"

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = ItemStatus.fromFirestoreValue(rawValue)
    }

    /// Maps Firestore status strings (including legacy values) to the 3-state enum
    public static func fromFirestoreValue(_ value: String) -> ItemStatus {
        switch value {
        case "complete":
            return .complete
        case "failed", "failed_layer2a", "failed_layer2b":
            return .failed
        case "processing", "pending", "layer2a_complete", "layer2b_scheduled", "layer2b_complete":
            return .processing
        default:
            return .processing
        }
    }
}
