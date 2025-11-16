import Foundation

/// Represents the authorization status for camera access
public enum CameraAuthorizationStatus: Equatable, Sendable {
    /// User has granted camera access
    case authorized

    /// User has denied camera access
    case denied

    /// User has not been asked for camera access yet
    case notDetermined
}
