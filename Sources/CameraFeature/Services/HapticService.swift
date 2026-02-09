#if os(iOS)
import UIKit

/// Concrete implementation of `HapticFeedbackProviding` that wraps UIKit haptic generators.
///
/// Lives in the Services layer (infrastructure), where UIKit is permitted per ADR-010.
/// ViewModels inject this via the `HapticFeedbackProviding` protocol to avoid
/// direct UIKit dependencies.
public final class HapticService: HapticFeedbackProviding, @unchecked Sendable {

    public init() {}

    @MainActor
    public func playImpact(style: HapticStyle) {
        let uiStyle: UIImpactFeedbackGenerator.FeedbackStyle
        switch style {
        case .light:
            uiStyle = .light
        case .medium:
            uiStyle = .medium
        case .heavy:
            uiStyle = .heavy
        }
        let generator = UIImpactFeedbackGenerator(style: uiStyle)
        generator.impactOccurred()
    }
}
#endif
