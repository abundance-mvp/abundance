import Foundation
import os.log

#if os(iOS)
import CoreMotion
#endif

/// Motion-based keyframe detection using device gyroscope.
///
/// Complements `FrameScheduler` (time-based) with stabilization-based triggers.
/// When the camera stabilizes (rotation rate drops below threshold), it's a good
/// time to run the image encoder — the frame will be sharp and representative.
///
/// Thread Safety: Actor isolation ensures all state access is serialized.
/// On macOS (tests), all methods return safe defaults (no CoreMotion available).
public actor MotionKeyframeDetector {

    // MARK: - Properties

    private let stabilizationThreshold: Double // radians/sec
    private let logger = Logger(subsystem: "com.abundance.edgetam", category: "MotionKeyframe")

    #if os(iOS)
    /// CMMotionManager is not Sendable; actor isolation + nonisolated(unsafe)
    /// ensures all access is serialized (same pattern as EdgeTAMService for MLModel).
    nonisolated(unsafe) private let motionManager = CMMotionManager()
    #endif

    private var isMonitoring = false
    private var wasMoving = false
    private var didStabilizeFlag = false

    // MARK: - Initialization

    /// - Parameter stabilizationThreshold: Rotation rate (rad/s) below which camera is "stable".
    ///   Default 0.1 rad/s (~5.7 deg/s) — hand-held camera at rest.
    public init(stabilizationThreshold: Double = 0.1) {
        self.stabilizationThreshold = stabilizationThreshold
    }

    // MARK: - Public API

    /// Start monitoring device motion for stabilization events.
    public func startMonitoring() {
        guard !isMonitoring else { return }

        #if os(iOS)
        guard motionManager.isDeviceMotionAvailable else {
            logger.warning("Device motion not available")
            return
        }

        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0 // 30 Hz
        motionManager.startDeviceMotionUpdates()
        #endif

        isMonitoring = true
        wasMoving = false
        didStabilizeFlag = false
        logger.debug("Motion monitoring started (threshold: \(self.stabilizationThreshold) rad/s)")
    }

    /// Stop monitoring device motion.
    public func stopMonitoring() {
        guard isMonitoring else { return }

        #if os(iOS)
        motionManager.stopDeviceMotionUpdates()
        #endif

        isMonitoring = false
        wasMoving = false
        didStabilizeFlag = false
        logger.debug("Motion monitoring stopped")
    }

    /// Check if the device just stabilized (rising-edge detection).
    ///
    /// Returns `true` once when rotation rate transitions from above to below
    /// the stabilization threshold. Resets after reading so it fires once per
    /// stabilization event.
    ///
    /// Call this on each frame to decide whether to trigger an encode.
    public func checkStabilized() -> Bool {
        #if os(iOS)
        guard isMonitoring,
              let motion = motionManager.deviceMotion else {
            return false
        }

        let rate = motion.rotationRate
        let magnitude = sqrt(rate.x * rate.x + rate.y * rate.y + rate.z * rate.z)
        let isStable = magnitude < stabilizationThreshold

        if wasMoving && isStable {
            // Rising edge: just stabilized
            wasMoving = false
            didStabilizeFlag = true
            logger.debug("Camera stabilized (rate: \(String(format: "%.3f", magnitude)) rad/s)")
            return true
        }

        if !isStable {
            wasMoving = true
            didStabilizeFlag = false
        }

        return false
        #else
        return false
        #endif
    }

    /// Whether motion monitoring is currently active.
    public var isActive: Bool {
        isMonitoring
    }
}
