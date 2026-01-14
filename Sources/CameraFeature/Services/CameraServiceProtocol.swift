import Foundation
import Combine
import AVFoundation

/// Protocol defining camera capture operations
/// - Note: Uses Data for images to avoid UIKit dependency in protocol
public protocol CameraServiceProtocol: Sendable {
    /// Publisher for current camera session state
    var sessionState: AnyPublisher<CameraSessionState, Never> { get }

    /// Publisher emitting camera frames as CVPixelBuffer for real-time processing
    var framePublisher: AnyPublisher<CVPixelBuffer, Never> { get }

    /// Configure and start the camera session
    /// - Throws: CameraError if session cannot be started
    func startSession() async throws

    /// Stop the camera session and release resources
    func stopSession()

    /// Capture a photo from the camera
    /// - Returns: Photo data (JPEG format)
    /// - Throws: CameraError if capture fails
    func capturePhoto() async throws -> Data

    /// Check camera authorization status
    /// - Returns: Current authorization status
    func checkAuthorization() async -> CameraAuthorizationStatus

    /// Get the underlying AVCaptureSession for preview layer
    /// - Note: Only needed for UIViewRepresentable bridge to AVCaptureVideoPreviewLayer
    /// - Returns: AVCaptureSession instance, or nil if not supported
    func getCaptureSession() -> AVCaptureSession?
}
