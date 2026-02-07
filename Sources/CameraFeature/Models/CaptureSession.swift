import Foundation

/// Capture mode for session
public enum CaptureMode: String, Sendable, Codable {
    /// Single photo from double-tap
    case single
    /// Multiple photos from long-press burst
    case burst
    /// Camera sweep with EdgeTAM on-device segmentation
    case sweep
}

/// Session status matching Firestore document
public enum CaptureSessionStatus: String, Sendable, Codable {
    /// Uploading images to GCS
    case uploading
    /// Server detecting objects via Gemini 3 Flash
    case detecting
    /// Detection complete, results available
    case detected
    /// Detection failed
    case failed
}

/// Detected object from Layer 1 (Gemini 3 Flash)
public struct ServerDetectedObject: Identifiable, Sendable, Codable {
    public let groupId: String
    public let label: String
    public let category: String
    public let attributes: [String: String]
    public let confidence: String
    public let croppedImageUrls: [String]
    public let boundingBoxes: [BoundingBoxInfo]

    public var id: String { groupId }

    public init(
        groupId: String,
        label: String,
        category: String,
        attributes: [String: String],
        confidence: String,
        croppedImageUrls: [String],
        boundingBoxes: [BoundingBoxInfo]
    ) {
        self.groupId = groupId
        self.label = label
        self.category = category
        self.attributes = attributes
        self.confidence = confidence
        self.croppedImageUrls = croppedImageUrls
        self.boundingBoxes = boundingBoxes
    }
}

/// Bounding box info from server
public struct BoundingBoxInfo: Sendable, Codable {
    public let imageIndex: Int
    /// [ymin, xmin, ymax, xmax] normalized 0-1000
    public let box2d: [Int]

    enum CodingKeys: String, CodingKey {
        case imageIndex
        case box2d = "box_2d"
    }

    public init(imageIndex: Int, box2d: [Int]) {
        self.imageIndex = imageIndex
        self.box2d = box2d
    }

    /// Convert to CGRect in normalized coordinates (0-1, origin top-left for SwiftUI)
    ///
    /// Gemini format: [ymin, xmin, ymax, xmax] where:
    /// - ymin = top edge (0 = top of image)
    /// - ymax = bottom edge (1000 = bottom of image)
    /// - xmin = left edge (0 = left of image)
    /// - xmax = right edge (1000 = right of image)
    ///
    /// This matches SwiftUI's coordinate system (origin top-left), so no Y-flip needed.
    public var normalizedRect: CGRect {
        guard box2d.count == 4 else {
            return .zero
        }
        let ymin = Double(box2d[0]) / 1000.0
        let xmin = Double(box2d[1]) / 1000.0
        let ymax = Double(box2d[2]) / 1000.0
        let xmax = Double(box2d[3]) / 1000.0

        return CGRect(
            x: xmin,
            y: ymin, // No flip - Gemini ymin is top edge, matching SwiftUI origin
            width: xmax - xmin,
            height: ymax - ymin
        )
    }
}

/// Crop metadata for sweep mode segments
public struct SweepCropInfo: Sendable, Codable {
    /// GCS URL of the cropped image
    public let cropUrl: String
    /// Bounding box [ymin, xmin, ymax, xmax] normalized 0-1000
    public let boundingBox: [Int]
    /// Index of the keyframe this crop came from
    public let frameIndex: Int
    /// Deduplication group ID (segments of same object grouped together)
    public let groupId: String

    public init(cropUrl: String, boundingBox: [Int], frameIndex: Int, groupId: String) {
        self.cropUrl = cropUrl
        self.boundingBox = boundingBox
        self.frameIndex = frameIndex
        self.groupId = groupId
    }
}

/// Capture session matching Firestore document structure
public struct CaptureSession: Identifiable, Sendable {
    public let id: String
    public let userId: String
    public let captureMode: CaptureMode
    public var status: CaptureSessionStatus
    public let createdAt: Date
    public var detectedAt: Date?

    /// GCS URLs for original images
    public var originalImageUrls: [String]

    /// Number of images uploaded (for progress tracking)
    public var imagesUploaded: Int

    /// Expected total image count (from burst capture)
    public var expectedImageCount: Int

    /// Detected objects from Layer 1
    public var detectedObjects: [ServerDetectedObject]

    /// Reasoning when no objects detected
    public var reasoning: String?

    /// Error message if failed
    public var error: String?

    /// Error code if failed
    public var errorCode: String?

    /// Sweep mode crop metadata (empty for single/burst modes)
    public var sweepCrops: [SweepCropInfo]

    public init(
        id: String,
        userId: String,
        captureMode: CaptureMode,
        status: CaptureSessionStatus = .uploading,
        createdAt: Date = Date(),
        detectedAt: Date? = nil,
        originalImageUrls: [String] = [],
        imagesUploaded: Int = 0,
        expectedImageCount: Int = 1,
        detectedObjects: [ServerDetectedObject] = [],
        reasoning: String? = nil,
        error: String? = nil,
        errorCode: String? = nil,
        sweepCrops: [SweepCropInfo] = []
    ) {
        self.id = id
        self.userId = userId
        self.captureMode = captureMode
        self.status = status
        self.createdAt = createdAt
        self.detectedAt = detectedAt
        self.originalImageUrls = originalImageUrls
        self.imagesUploaded = imagesUploaded
        self.expectedImageCount = expectedImageCount
        self.detectedObjects = detectedObjects
        self.reasoning = reasoning
        self.error = error
        self.errorCode = errorCode
        self.sweepCrops = sweepCrops
    }
}
