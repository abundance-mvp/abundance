import Foundation

/// Errors that can occur during camera operations
public enum CameraError: Error, LocalizedError, Sendable, Equatable {

    // MARK: - Device Errors

    /// Camera device is not available on this device
    case deviceNotAvailable

    /// Cannot add camera input to capture session
    case cannotAddInput

    /// Cannot add photo output to capture session
    case cannotAddOutput

    // MARK: - Authorization Errors

    /// User denied camera authorization
    case authorizationDenied

    // MARK: - Capture Errors

    /// Photo capture failed
    case captureFailure

    /// Invalid image data received from camera
    case invalidImageData

    /// Photo capture already in progress
    case captureInProgress

    // MARK: - Configuration Errors

    /// Configuration of camera session failed
    case configurationFailed(Error)

    // MARK: - Session Errors

    /// Camera session was interrupted (e.g., incoming call)
    case sessionInterrupted

    /// Camera session failed to start
    case sessionStartFailed

    // MARK: - Equatable

    public static func == (lhs: CameraError, rhs: CameraError) -> Bool {
        switch (lhs, rhs) {
        case (.deviceNotAvailable, .deviceNotAvailable),
             (.cannotAddInput, .cannotAddInput),
             (.cannotAddOutput, .cannotAddOutput),
             (.authorizationDenied, .authorizationDenied),
             (.captureFailure, .captureFailure),
             (.invalidImageData, .invalidImageData),
             (.captureInProgress, .captureInProgress),
             (.sessionInterrupted, .sessionInterrupted),
             (.sessionStartFailed, .sessionStartFailed):
            return true
        case (.configurationFailed, .configurationFailed):
            // Compare by type since underlying Error isn't Equatable
            return true
        default:
            return false
        }
    }

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .deviceNotAvailable:
            return "Camera not available"
        case .cannotAddInput:
            return "Unable to access camera"
        case .cannotAddOutput:
            return "Unable to configure camera output"
        case .authorizationDenied:
            return "Camera access denied"
        case .captureFailure:
            return "Failed to capture photo"
        case .invalidImageData:
            return "Photo could not be processed"
        case .captureInProgress:
            return "Capture already in progress"
        case .configurationFailed(let error):
            return "Camera setup failed: \(error.localizedDescription)"
        case .sessionInterrupted:
            return "Camera was interrupted"
        case .sessionStartFailed:
            return "Unable to start camera"
        }
    }

    /// Whether this error allows retry
    public var isRetryable: Bool {
        switch self {
        case .authorizationDenied:
            return false // Requires Settings navigation
        case .deviceNotAvailable:
            return false // Hardware issue
        default:
            return true
        }
    }

    /// Error code for analytics/logging
    public var errorCode: String {
        switch self {
        case .deviceNotAvailable: return "CAM_DEVICE_UNAVAILABLE"
        case .cannotAddInput: return "CAM_INPUT_FAILED"
        case .cannotAddOutput: return "CAM_OUTPUT_FAILED"
        case .authorizationDenied: return "CAM_AUTH_DENIED"
        case .captureFailure: return "CAM_CAPTURE_FAILED"
        case .invalidImageData: return "CAM_INVALID_DATA"
        case .captureInProgress: return "CAM_BUSY"
        case .configurationFailed: return "CAM_CONFIG_FAILED"
        case .sessionInterrupted: return "CAM_INTERRUPTED"
        case .sessionStartFailed: return "CAM_START_FAILED"
        }
    }
}
