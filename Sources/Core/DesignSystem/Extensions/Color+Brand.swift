import SwiftUI

public extension Color {
    // MARK: - Hex Initializer

    /// Initialize Color from hex string
    /// - Parameter hex: Hex string (with or without #)
    /// - Returns: Color instance
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0) // Fallback to black
        }

        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: 1.0
        )
    }

    // MARK: - Primary Brand Colors

    /// Salmon - Primary accent, CTA buttons, active states
    static let salmon = Color(hex: "E8907A")

    /// Peach - Secondary accent, borders, card strokes
    static let peach = Color(hex: "EDBE9E")

    /// Cream - Card backgrounds, content surfaces
    static let cream = Color(hex: "F0DCC0")

    /// Soft Teal - Decorative accent, leaf icon
    static let softTeal = Color(hex: "8ECAC0")

    /// Muted Sage - Success states, positive feedback
    static let mutedSage = Color(hex: "9DC4A8")

    // MARK: - Text Colors

    /// Deep Plum - Primary body text
    static let deepPlum = Color(hex: "3B2E3A")

    /// Dark Plum - High-emphasis text
    static let darkPlum = Color(hex: "2D2226")

    /// Ultra Dark Plum - Maximum contrast text
    static let ultraDarkPlum = Color(hex: "1A1218")

    // MARK: - Background Colors

    /// Background Teal - Decorative background accent
    static let backgroundTeal = Color(hex: "5BB8C9")

    /// Warm White - Default screen background
    static let warmWhite = Color(hex: "FAF6F0")

    // MARK: - Behind-Glass Pre-Saturated Variants

    /// Salmon pre-saturated for use behind glass effects
    static let salmonBehindGlass = Color(hex: "E87A60")

    /// Peach pre-saturated for use behind glass effects
    static let peachBehindGlass = Color(hex: "EDB085")

    /// Teal pre-saturated for use behind glass effects
    static let tealBehindGlass = Color(hex: "7AC4B8")

    // MARK: - Increase Contrast Variants

    /// Salmon variant for increased contrast accessibility
    static let salmonHighContrast = Color(hex: "C0705A")

    /// Deep plum variant for increased contrast accessibility
    static let deepPlumHighContrast = Color.ultraDarkPlum

    // MARK: - Semantic Aliases

    /// Primary accent color for interactive elements
    static let accentPrimary = Color.salmon

    /// Secondary accent color for borders and highlights
    static let accentSecondary = Color.peach

    /// Primary text color
    static let textPrimary = Color.deepPlum

    /// Success color for positive feedback
    static let successColor = Color.mutedSage

    /// Error color for validation failures
    static let errorColor = Color.salmon

    /// Default background color
    static let backgroundDefault = Color.warmWhite
}
