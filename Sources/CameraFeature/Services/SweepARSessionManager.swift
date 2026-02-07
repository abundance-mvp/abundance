import Foundation
import os.log

#if os(iOS)
import ARKit
#endif

/// Manages an optional ARWorldTrackingConfiguration during sweep mode.
///
/// Provides 6DOF camera pose and 3D world coordinates for spatial deduplication.
/// If ARKit is unavailable or fails, sweep mode continues with VNFeaturePrint-only dedup.
///
/// Thread Safety: @MainActor-isolated. ARSession delegate callbacks dispatched to MainActor.
@MainActor
public final class SweepARSessionManager: NSObject, ObservableObject {

    private let logger = Logger(subsystem: "com.abundance.camerafeature", category: "SweepARSession")

    #if os(iOS)
    private var arSession: ARSession?

    /// Current AR frame (updated per AR frame callback)
    @Published public var currentFrame: ARFrame?

    /// Whether ARKit world tracking is available on this device
    @Published public var isARAvailable: Bool = false

    public override init() {
        super.init()
        isARAvailable = ARWorldTrackingConfiguration.isSupported
    }

    deinit {
        arSession?.delegate = nil
        arSession?.pause()
    }

    /// Start AR session for spatial tracking during sweep
    public func startTracking() {
        guard isARAvailable else {
            logger.info("ARKit not available — falling back to visual dedup only")
            return
        }

        let session = ARSession()
        session.delegate = self

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.frameSemantics = []  // No need for people occlusion etc.

        session.run(config)
        arSession = session
        logger.info("AR session started for spatial deduplication")
    }

    /// Stop AR session (call on sweep mode exit)
    public func stopTracking() {
        arSession?.delegate = nil
        arSession?.pause()
        arSession = nil
        currentFrame = nil
        logger.info("AR session stopped")
    }

    /// Project a 2D normalized point to 3D world position using current AR frame
    /// - Parameter normalizedPoint: Point in normalized coordinates (0.0-1.0)
    /// - Returns: 3D world position, or nil if raycast fails
    public func worldPosition(for normalizedPoint: CGPoint) -> SIMD3<Float>? {
        guard let frame = currentFrame else { return nil }

        let imageResolution = frame.camera.imageResolution
        let screenPoint = CGPoint(
            x: normalizedPoint.x * imageResolution.width,
            y: normalizedPoint.y * imageResolution.height
        )

        // Use raycast to find 3D position
        guard let query = frame.raycastQuery(
            from: screenPoint,
            allowing: .estimatedPlane,
            alignment: .any
        ) else { return nil }

        let results = arSession?.raycast(query) ?? []
        guard let firstResult = results.first else { return nil }

        let column3 = firstResult.worldTransform.columns.3
        return SIMD3<Float>(column3.x, column3.y, column3.z)
    }
    #else
    // macOS stub — ARKit not available
    public override init() {
        super.init()
    }
    #endif
}

#if os(iOS)
extension SweepARSessionManager: @preconcurrency ARSessionDelegate {
    nonisolated public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Delegate value capture pattern per axiom-swift-concurrency Pattern 2:
        // Capture frame value BEFORE Task boundary
        let updatedFrame = frame
        Task { @MainActor [weak self] in
            self?.currentFrame = updatedFrame
        }
    }
}
#endif
