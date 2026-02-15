import SwiftUI
import AVFoundation

#if os(iOS)
import UIKit

/// Custom UIView that properly handles AVCaptureVideoPreviewLayer layout
/// The preview layer frame must be updated in layoutSubviews, not just in makeUIView
/// Internal (not private) for testability - see CameraPreviewViewTests
class CameraPreviewUIView: UIView {
    let previewLayer: AVCaptureVideoPreviewLayer

    /// Rotation coordinator for device-orientation-aware preview (iOS 17+)
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    private var rotationObservation: NSKeyValueObservation?

    init(session: AVCaptureSession) {
        self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
        super.init(frame: .zero)

        backgroundColor = .black
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)

        setupRotationCoordinator(session: session)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupRotationCoordinator(session: AVCaptureSession) {
        guard let device = (session.inputs.first as? AVCaptureDeviceInput)?.device else { return }

        let coordinator = AVCaptureDevice.RotationCoordinator(
            device: device,
            previewLayer: previewLayer
        )
        self.rotationCoordinator = coordinator

        // Apply initial rotation
        if let connection = previewLayer.connection {
            connection.videoRotationAngle = coordinator.videoRotationAngleForHorizonLevelPreview
        }

        // Observe rotation changes as device orientation shifts
        rotationObservation = coordinator.observe(
            \.videoRotationAngleForHorizonLevelPreview,
            options: .new
        ) { [weak self] coord, _ in
            // Capture value before crossing async boundary to avoid accessing
            // coordinator properties from a different execution context
            let angle = coord.videoRotationAngleForHorizonLevelPreview
            DispatchQueue.main.async { [weak self] in
                guard let self, let connection = self.previewLayer.connection else { return }
                connection.videoRotationAngle = angle
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Critical: Update preview layer frame when view layout changes
        // This is called by UIKit when the view's bounds change
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        previewLayer.frame = bounds
        CATransaction.commit()
    }
}

/// UIViewRepresentable wrapper for AVCaptureVideoPreviewLayer (iOS)
/// - Note: AVCaptureVideoPreviewLayer has no SwiftUI equivalent as of iOS 18
/// - ADR-010 Compliance: UIViewRepresentable is SwiftUI's official bridging mechanism
public struct CameraPreviewView: UIViewRepresentable {

    public let captureSession: AVCaptureSession

    public init(captureSession: AVCaptureSession) {
        self.captureSession = captureSession
    }

    public func makeUIView(context: Context) -> UIView {
        CameraPreviewUIView(session: captureSession)
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        // Force a layout pass so the preview layer frame matches current bounds.
        // After a session stop/restart cycle the layer may retain stale geometry
        // (zoomed-in/offset) if no layout invalidation occurred.
        uiView.setNeedsLayout()
    }
}

#else
import AppKit

/// NSViewRepresentable wrapper for AVCaptureVideoPreviewLayer (macOS)
/// - Note: AVCaptureVideoPreviewLayer has no SwiftUI equivalent
/// - ADR-010 Compliance: NSViewRepresentable is SwiftUI's official bridging mechanism
public struct CameraPreviewView: NSViewRepresentable {

    public let captureSession: AVCaptureSession

    public init(captureSession: AVCaptureSession) {
        self.captureSession = captureSession
    }

    public func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer?.addSublayer(previewLayer)

        // Store layer in context for updateNSView
        context.coordinator.previewLayer = previewLayer

        return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {
        // Update layer frame when view size changes
        // Synchronous update with disabled animations to prevent race conditions
        // during overlay transitions (fixes P1 camera preview offset)
        if let previewLayer = context.coordinator.previewLayer {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            previewLayer.frame = nsView.bounds
            CATransaction.commit()
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public class Coordinator {
        public var previewLayer: AVCaptureVideoPreviewLayer?
    }
}
#endif
