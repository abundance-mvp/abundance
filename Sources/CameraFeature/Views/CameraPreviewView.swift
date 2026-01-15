import SwiftUI
import AVFoundation

#if os(iOS)
import UIKit

/// UIViewRepresentable wrapper for AVCaptureVideoPreviewLayer (iOS)
/// - Note: AVCaptureVideoPreviewLayer has no SwiftUI equivalent as of iOS 18
/// - ADR-010 Compliance: UIViewRepresentable is SwiftUI's official bridging mechanism
public struct CameraPreviewView: UIViewRepresentable {

    public let captureSession: AVCaptureSession

    public init(captureSession: AVCaptureSession) {
        self.captureSession = captureSession
    }

    public func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        // Store layer in context for updateUIView
        context.coordinator.previewLayer = previewLayer

        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {
        // Update layer frame when view size changes
        if let previewLayer = context.coordinator.previewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public class Coordinator {
        public var previewLayer: AVCaptureVideoPreviewLayer?
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
        if let previewLayer = context.coordinator.previewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = nsView.bounds
            }
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
