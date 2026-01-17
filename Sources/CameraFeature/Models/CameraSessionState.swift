import Foundation

/// Represents the current state of the camera capture session
public enum CameraSessionState: Equatable, Sendable {
    /// Session has not been started yet
    case notStarted

    /// Session is being configured
    case configuring

    /// Session is actively running
    case running

    /// Session was interrupted (phone call, other app, etc.)
    /// The associated Int is the raw value of AVCaptureSession.InterruptionReason (iOS only)
    case interrupted(reasonRawValue: Int)

    /// Session has been stopped
    case stopped

    /// Session failed with an error
    case failed(Error)

    // MARK: - Equatable

    public static func == (lhs: CameraSessionState, rhs: CameraSessionState) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted),
             (.configuring, .configuring),
             (.running, .running),
             (.stopped, .stopped):
            return true
        case (.interrupted(let lhsReason), .interrupted(let rhsReason)):
            return lhsReason == rhsReason
        case (.failed(let lhsError), .failed(let rhsError)):
            return (lhsError as NSError).domain == (rhsError as NSError).domain &&
                   (lhsError as NSError).code == (rhsError as NSError).code
        default:
            return false
        }
    }
}
