import Foundation
import CoreGraphics

/// Model representing a detected barcode from Vision Framework
public struct BarcodeResult: Identifiable, Codable, Equatable {
    /// Unique identifier
    public let id: UUID

    /// Barcode payload string (UPC/EAN code)
    public let payload: String

    /// Barcode symbology (e.g., "EAN13", "UPCA", "QR")
    public let symbology: String

    /// Detection confidence (0-1)
    public let confidence: Float

    /// Bounding box in Vision coordinates (optional)
    public let boundingBox: CGRect?

    public init(
        id: UUID = UUID(),
        payload: String,
        symbology: String,
        confidence: Float,
        boundingBox: CGRect? = nil
    ) {
        self.id = id
        self.payload = payload
        self.symbology = symbology
        self.confidence = confidence
        self.boundingBox = boundingBox
    }
}
