import Foundation
@preconcurrency import CoreVideo
@testable import EdgeTAMFeature

/// Mock EdgeTAM service for testing sweep mode integration.
///
/// Returns configurable mock segments without requiring CoreML models.
/// All methods are actor-isolated for thread safety.
public actor MockEdgeTAMService: @preconcurrency EdgeTAMServiceProtocol {

    // MARK: - Configuration

    /// Segments returned by `autoSegment()`. Set before calling.
    public var mockSegments: [SegmentedObject] = []

    /// Segment returned by `decodeMask()`. Set before calling.
    public var mockMaskResult: SegmentedObject?

    /// If set, `encodeFrame()` throws this error.
    public var encodeError: Error?

    /// If set, `decodeMask()` throws this error.
    public var decodeError: Error?

    /// Simulated encode latency (seconds). Default 0 for instant response.
    public var encodeLatency: TimeInterval = 0

    // MARK: - Call Tracking

    /// Number of times `warmup()` was called.
    public private(set) var warmupCallCount = 0

    /// Number of times `encodeFrame()` was called.
    public private(set) var encodeCallCount = 0

    /// Number of times `decodeMask()` was called.
    public private(set) var decodeCallCount = 0

    /// Number of times `autoSegment()` was called.
    public private(set) var autoSegmentCallCount = 0

    /// Number of times `unload()` was called.
    public private(set) var unloadCallCount = 0

    /// Points passed to `decodeMask()`.
    public private(set) var decodedPoints: [CGPoint] = []

    // MARK: - State

    private var loaded = false

    // MARK: - Initialization

    public init() {}

    /// Create a mock pre-configured with sample segments.
    public init(segments: [SegmentedObject]) {
        self.mockSegments = segments
    }

    // MARK: - EdgeTAMServiceProtocol

    public var isLoaded: Bool {
        loaded
    }

    public func warmup() async throws {
        warmupCallCount += 1
        loaded = true
    }

    public func encodeFrame(_ pixelBuffer: CVPixelBuffer) async throws -> String {
        encodeCallCount += 1

        if let error = encodeError {
            throw error
        }

        if encodeLatency > 0 {
            try await Task.sleep(for: .seconds(encodeLatency))
        }

        return UUID().uuidString
    }

    public func decodeMask(at point: CGPoint, featureToken: String) async throws -> SegmentedObject {
        decodeCallCount += 1
        decodedPoints.append(point)

        if let error = decodeError {
            throw error
        }

        if let result = mockMaskResult {
            return result
        }

        // Default: return a segment centered on the tapped point
        return SegmentedObject(
            boundingBox: CGRect(
                x: max(0, point.x - 0.1),
                y: max(0, point.y - 0.1),
                width: 0.2,
                height: 0.2
            ),
            iouScore: 0.95
        )
    }

    public func autoSegment(featureToken: String) async throws -> [SegmentedObject] {
        autoSegmentCallCount += 1
        return mockSegments
    }

    public func unload() async {
        unloadCallCount += 1
        loaded = false
    }

    // MARK: - Test Helpers

    /// Reset all call counts and state.
    public func reset() {
        warmupCallCount = 0
        encodeCallCount = 0
        decodeCallCount = 0
        autoSegmentCallCount = 0
        unloadCallCount = 0
        decodedPoints = []
        loaded = false
        encodeError = nil
        decodeError = nil
        mockSegments = []
        mockMaskResult = nil
        encodeLatency = 0
    }
}
