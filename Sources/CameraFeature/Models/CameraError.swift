import Foundation

/// Errors that can occur during camera operations
public enum CameraError: Error, LocalizedError, Equatable {
    /// Camera device is not available on this device
    case deviceNotAvailable

    /// Cannot add camera input to capture session
    case cannotAddInput

    /// Cannot add photo output to capture session
    case cannotAddOutput

    /// User denied camera authorization
    case authorizationDenied

    /// Photo capture failed
    case captureFailure

    /// Invalid image data received from camera
    case invalidImageData

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .deviceNotAvailable:
            return "Camera device not available"
        case .cannotAddInput:
            return "Cannot add camera input"
        case .cannotAddOutput:
            return "Cannot add photo output"
        case .authorizationDenied:
            return "Camera authorization denied"
        case .captureFailure:
            return "Failed to capture photo"
        case .invalidImageData:
            return "Invalid image data"
        }
    }
}
