import SwiftUI

public extension Animation {
    // MARK: - Abundance Animation Presets

    /// Press animation for quick interactions (button taps, toggles)
    /// - Response: 0.3s (fast)
    /// - Damping: 0.6 (medium bounce)
    static let brandPress = Animation.spring(response: 0.3, dampingFraction: 0.6)

    /// Default animation for standard transitions
    /// - Response: 0.5s (balanced)
    /// - Damping: 0.6 (medium bounce)
    /// - Usage: Screen transitions, card entrance, modal presentation
    static let brandDefault = Animation.spring(response: 0.5, dampingFraction: 0.6)

    /// Reduced motion fallback — minimal, non-spring animation
    /// - Duration: 0.2s ease-in-out
    /// - Usage: All animations when accessibilityReduceMotion is enabled
    static let brandReducedMotion = Animation.easeInOut(duration: 0.2)
}
