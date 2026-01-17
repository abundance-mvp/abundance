import Foundation

/// Errors that can occur during the capture and detection flow
public enum CaptureError: Error, LocalizedError, Sendable, Equatable {
    public static func == (lhs: CaptureError, rhs: CaptureError) -> Bool {
        switch (lhs, rhs) {
        case (.notAuthenticated, .notAuthenticated),
             (.authenticationExpired, .authenticationExpired),
             (.captureFailure, .captureFailure),
             (.invalidImageData, .invalidImageData),
             (.burstCaptureTooShort, .burstCaptureTooShort),
             (.networkTimeout, .networkTimeout),
             (.quotaExceeded, .quotaExceeded),
             (.detectionTimeout, .detectionTimeout),
             (.invalidResponse, .invalidResponse),
             (.sessionNotFound, .sessionNotFound):
            return true
        case (.uploadFailed, .uploadFailed),
             (.unknownError, .unknownError):
            // Compare by error code since underlying Error isn't Equatable
            return true
        case (.detectionFailed(let lhsReason), .detectionFailed(let rhsReason)):
            return lhsReason == rhsReason
        default:
            return false
        }
    }
    // MARK: - Authentication Errors
    case notAuthenticated
    case authenticationExpired

    // MARK: - Capture Errors
    case captureFailure
    case invalidImageData
    case burstCaptureTooShort

    // MARK: - Upload Errors
    case uploadFailed(underlying: Error?)
    case networkTimeout
    case quotaExceeded

    // MARK: - Detection Errors
    case detectionTimeout
    case detectionFailed(reason: String)
    case invalidResponse

    // MARK: - General Errors
    case sessionNotFound
    case unknownError(underlying: Error?)

    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to capture items"
        case .authenticationExpired:
            return "Your session has expired. Please sign in again."
        case .captureFailure:
            return "Failed to capture photo"
        case .invalidImageData:
            return "Photo data is invalid"
        case .burstCaptureTooShort:
            return "Hold longer to capture multiple photos"
        case .uploadFailed:
            return "Failed to upload photo. Please try again."
        case .networkTimeout:
            return "Network timeout. Check your connection."
        case .quotaExceeded:
            return "Upload quota exceeded"
        case .detectionTimeout:
            return "Detection timed out. Please try again."
        case .detectionFailed(let reason):
            return "Detection failed: \(reason)"
        case .invalidResponse:
            return "Invalid response from server"
        case .sessionNotFound:
            return "Session not found"
        case .unknownError(let underlying):
            if let error = underlying {
                return "An error occurred: \(error.localizedDescription)"
            }
            return "An unknown error occurred"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .notAuthenticated, .authenticationExpired:
            return "Tap to sign in"
        case .captureFailure, .invalidImageData:
            return "Try taking another photo"
        case .burstCaptureTooShort:
            return "Press and hold for at least 1 second"
        case .uploadFailed, .networkTimeout:
            return "Check your internet connection and try again"
        case .quotaExceeded:
            return "Please wait and try again later"
        case .detectionTimeout, .detectionFailed, .invalidResponse:
            return "Tap Retake to try again"
        case .sessionNotFound:
            return "Start a new capture"
        case .unknownError:
            return "Please try again"
        }
    }

    /// Whether this error can be retried
    public var isRetryable: Bool {
        switch self {
        case .notAuthenticated, .authenticationExpired, .quotaExceeded:
            return false
        default:
            return true
        }
    }

    /// Error code for analytics/logging
    public var errorCode: String {
        switch self {
        case .notAuthenticated: return "AUTH_REQUIRED"
        case .authenticationExpired: return "AUTH_EXPIRED"
        case .captureFailure: return "CAPTURE_FAILED"
        case .invalidImageData: return "INVALID_DATA"
        case .burstCaptureTooShort: return "BURST_TOO_SHORT"
        case .uploadFailed: return "UPLOAD_FAILED"
        case .networkTimeout: return "NETWORK_TIMEOUT"
        case .quotaExceeded: return "QUOTA_EXCEEDED"
        case .detectionTimeout: return "DETECTION_TIMEOUT"
        case .detectionFailed: return "DETECTION_FAILED"
        case .invalidResponse: return "INVALID_RESPONSE"
        case .sessionNotFound: return "SESSION_NOT_FOUND"
        case .unknownError: return "UNKNOWN_ERROR"
        }
    }
}
