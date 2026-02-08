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
///
/// - Note: Phase 3 infrastructure — not yet instantiated. Awaiting integration with SweepCaptureViewModel.
@MainActor
public final class SweepARSessionManager: NSObject {

    private let logger = Logger(subsystem: "com.abundance.camerafeature", category: "SweepARSession")

    #if os(iOS)
    private var arSession: ARSession?

    /// Camera transform extracted from latest AR frame (avoids retaining full ARFrame ~1-4MB)
    public var cameraTransform: simd_float4x4?

    /// Camera tracking state extracted from latest AR frame
    public var trackingState: ARCamera.TrackingState?

    /// Whether ARKit world tracking is available on this device
    public var isARAvailable: Bool = false

    public override init() {
        super.init()
        isARAvailable = ARWorldTrackingConfiguration.isSupported
    }

    deinit {
        // Cleanup handled by stopTracking() — called explicitly before deallocation.
        // Cannot access @MainActor-isolated arSession from nonisolated deinit (Swift 6).
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
        cameraTransform = nil
        trackingState = nil
        logger.info("AR session stopped")
    }

    /// Project a 2D normalized point to 3D world position using current AR frame
    /// - Parameter normalizedPoint: Point in normalized coordinates (0.0-1.0)
    /// - Returns: 3D world position, or nil if raycast fails
    public func worldPosition(for normalizedPoint: CGPoint) -> SIMD3<Float>? {
        // Access the session's current frame transiently (not retained as a property)
        guard let frame = arSession?.currentFrame else { return nil }

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
        // Extract only lightweight primitives BEFORE the Task boundary
        // Do NOT capture the full ARFrame (~1-4MB) across the isolation boundary
        let transform = frame.camera.transform
        let tracking = frame.camera.trackingState
        Task { @MainActor [weak self] in
            self?.cameraTransform = transform
            self?.trackingState = tracking
        }
    }
}
#endif
