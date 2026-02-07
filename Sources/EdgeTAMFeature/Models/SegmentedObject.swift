import Foundation
import CoreGraphics

/// A segmented object detected by EdgeTAM
public struct SegmentedObject: Identifiable, Sendable {
    public let id: UUID
    public let boundingBox: CGRect
    public let maskData: Data?
    public let maskWidth: Int
    public let maskHeight: Int
    public let iouScore: Float
    public var isSelected: Bool
    public let frameIndex: Int
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        boundingBox: CGRect,
        maskData: Data? = nil,
        maskWidth: Int = 0,
        maskHeight: Int = 0,
        iouScore: Float = 0.0,
        isSelected: Bool = false,
        frameIndex: Int = 0,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.boundingBox = boundingBox
        self.maskData = maskData
        self.maskWidth = maskWidth
        self.maskHeight = maskHeight
        self.iouScore = iouScore
        self.isSelected = isSelected
        self.frameIndex = frameIndex
        self.timestamp = timestamp
    }
}
