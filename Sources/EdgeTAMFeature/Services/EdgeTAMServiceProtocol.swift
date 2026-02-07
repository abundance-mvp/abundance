import Foundation
import CoreVideo

/// Protocol for EdgeTAM service, enabling test mocking
public protocol EdgeTAMServiceProtocol: Sendable {
    func warmup() async throws
    func encodeFrame(_ pixelBuffer: CVPixelBuffer) async throws -> String
    func decodeMask(at point: CGPoint, featureToken: String) async throws -> SegmentedObject
    func autoSegment(featureToken: String) async throws -> [SegmentedObject]
    func unload() async
    var isLoaded: Bool { get async }
}
