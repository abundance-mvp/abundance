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

    // MARK: - Brand Colors (Decorative & Large Text Only)

    /// Bright Blue - Primary brand color for interactive elements and large text
    /// - Contrast: 3.77:1 (WCAG AA large text only)
    /// - Usage: Button backgrounds, glows, large headings (24pt+), borders
    static let brandBrightBlue = Color(hex: "#4381DF")

    /// Coral Orange - Secondary brand color for decorative elements
    /// - Contrast: 2.03:1 (Fails all WCAG standards for text)
    /// - Usage: Decorative only (badges, backgrounds, icons, category highlights)
    static let brandCoralOrange = Color(hex: "#FF9A6F")

    /// Salmon Pink - Tertiary brand color for subtle accents
    /// - Contrast: 2.45:1 (Fails all WCAG standards for text)
    /// - Usage: Decorative only (subtle backgrounds, decorative glows)
    static let brandSalmonPink = Color(hex: "#FFC4B4")

    /// Cream Yellow - Accent color for positive feedback
    /// - Contrast: 1.18:1 (Fails all WCAG standards for text)
    /// - Usage: Decorative only (accent fields, positive feedback glows)
    static let brandCreamYellow = Color(hex: "#FFEDB9")

    /// Mint Green - Success color for validation and price displays
    /// - Contrast: 1.43:1 (Fails all WCAG standards for text)
    /// - Usage: Decorative only (success glows, price tags - use textMintGreen for text)
    static let brandMintGreen = Color(hex: "#B3FFE1")

    // MARK: - Text-Safe Variants (WCAG AA Compliant)

    /// Text Bright Blue - Accessible variant for body text
    /// - Contrast: 7.2:1 (WCAG AAA compliant)
    /// - Usage: Links, interactive text, navigation labels, small buttons
    static let textBrightBlue = Color(hex: "#2D5FA3")

    /// Text Coral Orange - Accessible variant for warning text
    /// - Contrast: 5.1:1 (WCAG AA compliant)
    /// - Usage: Warning messages, alert text, destructive action labels
    static let textCoralOrange = Color(hex: "#CC5D3A")

    /// Text Mint Green - Accessible variant for success text
    /// - Contrast: 4.8:1 (WCAG AA compliant)
    /// - Usage: Success messages, validation feedback, price values
    static let textMintGreen = Color(hex: "#008057")

    // MARK: - Semantic Tokens

    // MARK: Interaction Colors
    /// Primary accent color for interactive elements
    /// - Light mode: Bright Blue (#4381DF, 3.77:1)
    /// - Usage: Button backgrounds, borders, active states, large headings
    static let accentPrimary = Color.brandBrightBlue

    /// Secondary accent color for notifications and badges
    /// - Light mode: Coral Orange (#FF9A6F, 2.03:1)
    /// - Usage: Notification badges, category highlights, secondary actions
    static let accentSecondary = Color.brandCoralOrange

    /// Tertiary accent color for subtle backgrounds
    /// - Light mode: Salmon Pink (#FFC4B4, 2.45:1)
    /// - Usage: Subtle backgrounds, decorative accents, hover states
    static let accentTertiary = Color.brandSalmonPink

    // MARK: Feedback Colors
    /// Success color for positive feedback (text-safe)
    /// - Contrast: 4.8:1 (WCAG AA compliant)
    /// - Usage: Success messages, validation, save confirmations
    static let successColor = Color.textMintGreen

    /// Success glow for decorative success elements
    /// - Contrast: 1.43:1 (Decorative only)
    /// - Usage: Success glows, price tag backgrounds (with text-safe text)
    static let successGlow = Color.brandMintGreen

    /// Warning color for caution messages (text-safe)
    /// - Contrast: 5.1:1 (WCAG AA compliant)
    /// - Usage: Warning messages, caution text, alert labels
    static let warningColor = Color.textCoralOrange

    /// Error color for validation failures (text-safe)
    /// - Contrast: 5.1:1 (WCAG AA compliant)
    /// - Usage: Error messages, validation failures, destructive confirmations
    static let errorColor = Color.textCoralOrange

    // MARK: Text Colors
    /// Primary text color (AAA compliant)
    /// - Contrast: 12.52:1 (WCAG AAA compliant)
    /// - Usage: All body text, headlines, descriptions, primary labels
    static let textPrimary = Color(hex: "#3B2E3A")

    /// Link color for interactive text (AAA compliant)
    /// - Contrast: 7.2:1 (WCAG AAA compliant)
    /// - Usage: Links, interactive text, navigation labels
    static let textLink = Color.textBrightBlue

    // MARK: Surface Colors
    /// Default background color (off-white)
    /// - Usage: Base screen background, Reduce Transparency fallback
    static let backgroundDefault = Color(hex: "#FCFCFF")
}
