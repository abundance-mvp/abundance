import Foundation

/// Decides when to run the EdgeTAM image encoder on incoming camera frames.
///
/// The image encoder is the bottleneck (~60-900ms). Running it every frame (30 FPS)
/// is impossible. Instead, we run it on "keyframes" — frames spaced at a configurable
/// interval (default 0.5s). Between keyframes, cached features are reused for mask decoding.
///
/// Thread Safety: Actor-isolated for safe concurrent access from camera frame callbacks.
public actor FrameScheduler {

    private let keyframeInterval: TimeInterval
    private var lastKeyframeTime: Date?
    private var keyframeCount: Int = 0

    public init(keyframeInterval: TimeInterval = 0.5) {
        self.keyframeInterval = keyframeInterval
    }

    /// Determines if a frame should be encoded (is it a keyframe?)
    /// - Parameter timestamp: Frame capture timestamp
    /// - Returns: true if this frame should be encoded, false to skip
    public func shouldEncodeFrame(at timestamp: Date) -> Bool {
        guard let lastTime = lastKeyframeTime else {
            lastKeyframeTime = timestamp
            keyframeCount += 1
            return true
        }

        let elapsed = timestamp.timeIntervalSince(lastTime)
        if elapsed >= keyframeInterval {
            lastKeyframeTime = timestamp
            keyframeCount += 1
            return true
        }

        return false
    }

    /// Current keyframe index (for SegmentedObject.frameIndex)
    public var currentFrameIndex: Int {
        keyframeCount
    }

    /// Reset scheduler state (call on sweep mode exit)
    public func reset() {
        lastKeyframeTime = nil
        keyframeCount = 0
    }
}
