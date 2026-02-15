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
    var onEdit: (() -> Void)?

    @ScaledMetric(relativeTo: .title) private var avatarSize: CGFloat = 80

    // MARK: - Initializer

    public init(displayName: String, email: String, itemCount: Int, onEdit: (() -> Void)? = nil) {
        self.displayName = displayName
        self.email = email
        self.itemCount = itemCount
        self.onEdit = onEdit
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

            // Edit Button
            if onEdit != nil {
                Button {
                    onEdit?()
                } label: {
                    Label("Edit Profile", systemImage: "pencil")
                        .font(.callout)
                        .foregroundStyle(Color.salmon)
                }
                .accessibilityIdentifier("profile.editButton")
            }

            // Item Count Badge
            itemCountBadge
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .abundanceCardStyle(cornerRadius: 20)
        .accessibilityIdentifier("profile.userInfoCard")
        .accessibilityElement(children: .combine)
        .accessibilityLabel("User profile: \(displayName), \(email), \(itemCount) items")
    }

    // MARK: - Subviews

    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(Color.accentPrimary.opacity(0.2))
                .frame(width: avatarSize, height: avatarSize)

            Text(avatarInitials)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Color.salmon)
        }
        .accessibilityHidden(true)
    }

    private var itemCountBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "tray.full")
                .font(.body)
                .foregroundStyle(Color.salmon)

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
