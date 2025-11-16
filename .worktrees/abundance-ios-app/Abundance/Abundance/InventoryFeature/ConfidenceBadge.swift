import SwiftUI

/// Display AI confidence level with color-coded visual indicator
/// **Design Spec:** DESIGN-031-swiftui-component-library.md (ConfidenceBadge)
struct ConfidenceBadge: View {
    // MARK: - Confidence Level

    enum ConfidenceLevel {
        case high, medium, low

        var color: Color {
            switch self {
            case .high: return .successColor
            case .medium: return .warningColor
            case .low: return .errorColor
            }
        }

        var label: String {
            switch self {
            case .high: return "High"
            case .medium: return "Medium"
            case .low: return "Low"
            }
        }

        var iconName: String {
            switch self {
            case .high: return "checkmark.circle.fill"
            case .medium: return "exclamationmark.triangle.fill"
            case .low: return "questionmark.circle.fill"
            }
        }
    }

    // MARK: - Properties

    let confidence: Double
    var showPercentage: Bool = false

    // MARK: - Computed Properties

    private var level: ConfidenceLevel {
        if confidence >= 0.8 {
            return .high
        } else if confidence >= 0.5 {
            return .medium
        } else {
            return .low
        }
    }

    private var displayText: String {
        if showPercentage {
            return "\(Int(confidence * 100))%"
        } else {
            return "\(level.label) • \(Int(confidence * 100))%"
        }
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: level.iconName)
                .font(.system(size: 14))
                .foregroundStyle(level.color)

            Text(displayText)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(level.color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(level.color.opacity(0.2), in: Capsule())
        .accessibilityLabel("AI confidence: \(displayText)")
    }
}

// MARK: - Preview

#Preview("Confidence Badges") {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            ConfidenceBadge(confidence: 0.95)
            ConfidenceBadge(confidence: 0.95, showPercentage: true)
        }

        HStack(spacing: 12) {
            ConfidenceBadge(confidence: 0.65)
            ConfidenceBadge(confidence: 0.65, showPercentage: true)
        }

        HStack(spacing: 12) {
            ConfidenceBadge(confidence: 0.35)
            ConfidenceBadge(confidence: 0.35, showPercentage: true)
        }
    }
    .padding()
}
