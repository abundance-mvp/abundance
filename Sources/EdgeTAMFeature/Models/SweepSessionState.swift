import Foundation

/// State machine for sweep capture mode
public enum SweepSessionState: Equatable, Sendable {
    case inactive
    case loading
    case ready
    case scanning(segmentCount: Int)
    case reviewing(selectedCount: Int, totalCount: Int)
    case uploading(progress: Double)
    case processing
    case complete(itemCount: Int)
    case error(SweepError)

    /// Whether this state is an error state (used for retry logic)
    public var isError: Bool {
        if case .error = self { return true }
        return false
    }
}

/// Sweep-specific errors
public enum SweepError: Equatable, Sendable, LocalizedError {
    case modelLoadFailed(String)
    case encoderFailed
    case decoderFailed
    case noSegmentsDetected
    case deviceNotSupported
    case modelsNotBundled
    case memoryPressure
    case catalogFailed(String)

    public var errorDescription: String? {
        switch self {
        case .modelLoadFailed(let detail):
            return "Failed to load EdgeTAM model: \(detail)"
        case .encoderFailed:
            return "Image encoding failed"
        case .decoderFailed:
            return "Mask decoding failed"
        case .noSegmentsDetected:
            return "No objects detected. Try pointing at a shelf with visible items."
        case .deviceNotSupported:
            return "Sweep mode requires iPhone 15 Pro or later"
        case .modelsNotBundled:
            return "Sweep mode is coming soon"
        case .memoryPressure:
            return "Low memory. Try selecting fewer items."
        case .catalogFailed(let detail):
            return "Failed to catalog items: \(detail)"
        }
    }
}
