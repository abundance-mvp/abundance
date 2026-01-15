import Foundation
import CoreGraphics

/// Photo source type for fraud detection
/// Identifies how the image was captured or imported
public enum PhotoSourceType: String, Codable, Sendable, CaseIterable {
    case camera          // Direct camera capture
    case screenshot      // Screen capture
    case savedFromWeb    // Downloaded from internet
    case imported        // Imported from files/other app
    case unknown         // Unable to determine
}

/// Photo metadata for fraud prevention and authenticity verification
/// Captured at the moment of photo capture, stored with each item
public struct PhotoMetadata: Codable, Equatable, Sendable {

    // MARK: - Location & Time

    /// GPS latitude in degrees (-90 to 90)
    public var latitude: Double?

    /// GPS longitude in degrees (-180 to 180)
    public var longitude: Double?

    /// Altitude in meters above sea level
    public var altitude: Double?

    /// Timestamp when photo was actually captured (not upload time)
    public var captureTimestamp: Date?

    /// IANA timezone identifier (e.g., "America/Los_Angeles")
    public var timezone: String?

    // MARK: - Device & Authenticity

    /// Device model identifier (e.g., "iPhone16,2")
    public var deviceModel: String?

    /// iOS version (e.g., "18.0")
    public var osVersion: String?

    /// How the photo was obtained
    public var sourceType: PhotoSourceType?

    /// SHA-256 hash of original image data (hex string)
    public var imageHash: String?

    // MARK: - Camera Technical

    /// Lens type description (e.g., "Wide Angle", "Telephoto")
    public var lensType: String?

    /// Whether the photo includes depth data (Portrait mode)
    public var hasDepthData: Bool?

    /// Whether this is a Live Photo with motion clip
    public var isLivePhoto: Bool?

    /// Image dimensions in pixels
    public var imageWidth: Int?
    public var imageHeight: Int?

    // MARK: - Initializer

    public init(
        latitude: Double? = nil,
        longitude: Double? = nil,
        altitude: Double? = nil,
        captureTimestamp: Date? = nil,
        timezone: String? = nil,
        deviceModel: String? = nil,
        osVersion: String? = nil,
        sourceType: PhotoSourceType? = nil,
        imageHash: String? = nil,
        lensType: String? = nil,
        hasDepthData: Bool? = nil,
        isLivePhoto: Bool? = nil,
        imageWidth: Int? = nil,
        imageHeight: Int? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.captureTimestamp = captureTimestamp
        self.timezone = timezone
        self.deviceModel = deviceModel
        self.osVersion = osVersion
        self.sourceType = sourceType
        self.imageHash = imageHash
        self.lensType = lensType
        self.hasDepthData = hasDepthData
        self.isLivePhoto = isLivePhoto
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
    }
}

// MARK: - Firestore Encoding Helpers

extension PhotoMetadata {
    // Convert to Firestore-compatible dictionary
    // swiftlint:disable:next cyclomatic_complexity
    public func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [:]

        if let latitude { data["latitude"] = latitude }
        if let longitude { data["longitude"] = longitude }
        if let altitude { data["altitude"] = altitude }
        if let captureTimestamp { data["captureTimestamp"] = captureTimestamp }
        if let timezone { data["timezone"] = timezone }
        if let deviceModel { data["deviceModel"] = deviceModel }
        if let osVersion { data["osVersion"] = osVersion }
        if let sourceType { data["sourceType"] = sourceType.rawValue }
        if let imageHash { data["imageHash"] = imageHash }
        if let lensType { data["lensType"] = lensType }
        if let hasDepthData { data["hasDepthData"] = hasDepthData }
        if let isLivePhoto { data["isLivePhoto"] = isLivePhoto }
        if let imageWidth { data["imageWidth"] = imageWidth }
        if let imageHeight { data["imageHeight"] = imageHeight }

        return data
    }

    /// Initialize from Firestore data
    public init(fromFirestoreData data: [String: Any]) {
        self.latitude = data["latitude"] as? Double
        self.longitude = data["longitude"] as? Double
        self.altitude = data["altitude"] as? Double
        // Note: Firestore Timestamp handled by caller if needed
        self.captureTimestamp = data["captureTimestamp"] as? Date
        self.timezone = data["timezone"] as? String
        self.deviceModel = data["deviceModel"] as? String
        self.osVersion = data["osVersion"] as? String
        if let sourceTypeRaw = data["sourceType"] as? String {
            self.sourceType = PhotoSourceType(rawValue: sourceTypeRaw)
        }
        self.imageHash = data["imageHash"] as? String
        self.lensType = data["lensType"] as? String
        self.hasDepthData = data["hasDepthData"] as? Bool
        self.isLivePhoto = data["isLivePhoto"] as? Bool
        self.imageWidth = data["imageWidth"] as? Int
        self.imageHeight = data["imageHeight"] as? Int
    }
}
