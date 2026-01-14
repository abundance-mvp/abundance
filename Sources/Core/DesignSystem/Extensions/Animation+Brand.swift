import SwiftUI

public extension Animation {
    // MARK: - Abundance Animation Presets

    /// Snappy animation for quick interactions
    /// - Response: 0.3s (fast)
    /// - Damping: 0.6 (medium bounce)
    /// - Usage: Button taps, tab switches, immediate feedback
    static let brandSnappy = Animation.spring(response: 0.3, dampingFraction: 0.6)

    /// Default animation for standard transitions
    /// - Response: 0.4s (balanced)
    /// - Damping: 0.7 (subtle bounce)
    /// - Usage: Screen transitions, card entrance, modal presentation
    static let brandDefault = Animation.spring(response: 0.4, dampingFraction: 0.7)

    /// Bouncy animation for celebratory moments
    /// - Response: 0.5s (slower)
    /// - Damping: 0.5 (high bounce)
    /// - Usage: Success animations, scan completion, save confirmation
    static let brandBouncy = Animation.spring(response: 0.5, dampingFraction: 0.5)

    /// Gentle animation for subtle updates
    /// - Response: 0.6s (slow)
    /// - Damping: 0.8 (minimal bounce)
    /// - Usage: Background updates, Firestore sync, non-critical changes
    static let brandGentle = Animation.spring(response: 0.6, dampingFraction: 0.8)
}
