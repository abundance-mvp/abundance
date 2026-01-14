// UserInfoCard.swift
// ProfileFeature
//
// Created: 2026-01-14
// Stage: 2.6 UI/UX Refactoring with Liquid Glass

import SwiftUI
import Core

/// User information card with avatar, name, email, and item count
/// Uses Liquid Glass effect on iOS 26+ with thickMaterial fallback
public struct UserInfoCard: View {
    // MARK: - Properties

    let displayName: String
    let email: String
    let itemCount: Int

    // MARK: - Environment

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    // MARK: - Initializer

    public init(displayName: String, email: String, itemCount: Int) {
        self.displayName = displayName
        self.email = email
        self.itemCount = itemCount
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 16) {
            // Avatar
            avatarView

            // User Info
            VStack(spacing: 4) {
                Text(displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)

                Text(email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Item Count Badge
            itemCountBadge
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .modifier(GlassBackgroundModifier(reduceTransparency: reduceTransparency))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("User profile: \(displayName), \(email), \(itemCount) items")
    }

    // MARK: - Subviews

    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(Color.accentPrimary.opacity(0.2))
                .frame(width: 80, height: 80)

            Text(avatarInitials)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Color.textBrightBlue)
        }
        .accessibilityHidden(true)
    }

    private var itemCountBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "tray.full")
                .font(.body)
                .foregroundStyle(Color.textBrightBlue)

            Text("\(itemCount) items")
                .font(.callout)
                .fontWeight(.medium)
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.accentPrimary.opacity(0.1), in: Capsule())
    }

    // MARK: - Computed Properties

    private var avatarInitials: String {
        let components = displayName.split(separator: " ")
        let initials = components.prefix(2).compactMap { $0.first }.map(String.init)
        return initials.joined().uppercased()
    }
}

// MARK: - Glass Background Modifier

/// Modifier that applies Liquid Glass on iOS 26+ with material fallback
private struct GlassBackgroundModifier: ViewModifier {
    let reduceTransparency: Bool

    func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .background(Color.backgroundDefault, in: RoundedRectangle(cornerRadius: 20))
        } else {
            glassContent(content)
        }
    }

    @ViewBuilder
    private func glassContent(_ content: Content) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            content
                .brandGlass(cornerRadius: 20, tint: Color.accentPrimary.opacity(0.1))
        } else {
            content
                .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
    }
}

// MARK: - Previews

#Preview("UserInfoCard - Default") {
    UserInfoCard(
        displayName: "John Doe",
        email: "john.doe@example.com",
        itemCount: 42
    )
    .padding()
}

#Preview("UserInfoCard - Long Name") {
    UserInfoCard(
        displayName: "Alexandra Katherine Smith-Johnson",
        email: "alexandra.smith-johnson@verylongcompanyname.com",
        itemCount: 156
    )
    .padding()
}

#Preview("UserInfoCard - Empty") {
    UserInfoCard(
        displayName: "User",
        email: "",
        itemCount: 0
    )
    .padding()
}
