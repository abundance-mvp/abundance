import Foundation
import CoreGraphics

/// A segmented object detected by EdgeTAM
public struct SegmentedObject: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let boundingBox: CGRect
    public let maskData: Data?
    public let maskWidth: Int
    public let maskHeight: Int
    public let iouScore: Float
    public let frameIndex: Int
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        boundingBox: CGRect,
        maskData: Data? = nil,
        maskWidth: Int = 0,
        maskHeight: Int = 0,
        iouScore: Float = 0.0,
        frameIndex: Int = 0,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.boundingBox = boundingBox
        self.maskData = maskData
        self.maskWidth = maskWidth
        self.maskHeight = maskHeight
        self.iouScore = iouScore
        self.frameIndex = frameIndex
        self.timestamp = timestamp
    }

    // maskData excluded from equality to avoid expensive Data comparison in
    // SwiftUI diffing hot paths. Identity is determined by id + spatial properties.
    public static func == (lhs: SegmentedObject, rhs: SegmentedObject) -> Bool {
        lhs.id == rhs.id &&
        lhs.boundingBox == rhs.boundingBox &&
        lhs.maskWidth == rhs.maskWidth &&
        lhs.maskHeight == rhs.maskHeight &&
        lhs.iouScore == rhs.iouScore &&
        lhs.frameIndex == rhs.frameIndex &&
        lhs.timestamp == rhs.timestamp
    }
}
