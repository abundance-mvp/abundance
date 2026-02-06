// ProfileView.swift
// ProfileFeature
//
// Created: 2026-01-14
// Stage: 2.6 UI/UX Refactoring with Liquid Glass

import SwiftUI
import Core

/// Profile view with user info, settings, and export options
/// Uses Liquid Glass effect on iOS 26+ with thickMaterial fallback
public struct ProfileView: View {
    // MARK: - Properties

    @Bindable var viewModel: ProfileViewModel
    var onSignOut: (() -> Void)?

    // MARK: - State

    @State private var showingSignOutConfirmation = false

    // MARK: - Initializer

    public init(
        viewModel: ProfileViewModel = ProfileViewModel(),
        onSignOut: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onSignOut = onSignOut
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // User Info Card
                    UserInfoCard(
                        displayName: viewModel.displayName,
                        email: viewModel.email,
                        itemCount: viewModel.itemCount
                    )

                    // Settings Section
                    settingsSection

                    // Export Section
                    exportSection

                    // Sign Out Button
                    signOutButton
                }
                .padding()
            }
            .background(Color.backgroundDefault)
            .navigationTitle("Profile")
            .task {
                await viewModel.loadProfile()
            }
            .alert("Sign Out", isPresented: $showingSignOutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task {
                        await viewModel.signOut()
                        onSignOut?()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .overlay {
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Settings")

            VStack(spacing: 0) {
                SettingsRow(
                    icon: "bell",
                    title: "Notifications",
                    action: { /* Navigate to notifications settings */ }
                )
                .accessibilityIdentifier("profile.notifications")

                Divider()
                    .padding(.leading, 48)

                SettingsRow(
                    icon: "lock.shield",
                    title: "Privacy",
                    action: { /* Navigate to privacy settings */ }
                )
                .accessibilityIdentifier("profile.privacy")

                Divider()
                    .padding(.leading, 48)

                SettingsRow(
                    icon: "questionmark.circle",
                    title: "Help",
                    action: { /* Navigate to help */ }
                )
                .accessibilityIdentifier("profile.help")
            }
            .adaptiveGlass(cornerRadius: 16)
        }
    }

    // MARK: - Export Section

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Export Data")

            Button {
                Task {
                    await viewModel.exportData(format: .csv)
                }
            } label: {
                HStack {
                    Image(systemName: "tablecells")
                        .font(.title3)
                        .foregroundStyle(Color.textBrightBlue)
                    Text("Export as CSV")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, minHeight: 44)
                .adaptiveGlass(cornerRadius: 16)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .accessibilityIdentifier("profile.exportCSV")
            .accessibilityLabel("Export as CSV")
            .accessibilityHint("Double tap to export your inventory data as a CSV file")
        }
    }

    // MARK: - Sign Out Button

    private var signOutButton: some View {
        Button {
            showingSignOutConfirmation = true
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sign Out")
            }
            .font(.body.weight(.medium))
            .foregroundStyle(Color.errorColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .adaptiveGlass(cornerRadius: 16)
        }
        .accessibilityIdentifier("profile.signOutButton")
        .accessibilityLabel("Sign out")
        .accessibilityHint("Double tap to sign out of your account")
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)
                .tint(.white)
        }
    }

    // MARK: - Helper Views

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(Color.textPrimary)
            .padding(.leading, 4)
    }
}

// MARK: - Settings Row

private struct SettingsRow: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(Color.textBrightBlue)
                    .frame(width: 24)

                Text(title)
                    .font(.body)
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to open \(title.lowercased()) settings")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Previews

#Preview("ProfileView - Default") {
    let viewModel = ProfileViewModel(
        userId: "preview-user",
        displayName: "John Doe",
        email: "john.doe@example.com",
        requiresAuthentication: false
    )
    ProfileView(viewModel: viewModel)
}

#Preview("ProfileView - Loading") {
    ProfileView(
        viewModel: {
            let vm = ProfileViewModel(
                userId: "preview-user",
                displayName: "John Doe",
                email: "john.doe@example.com",
                requiresAuthentication: false
            )
            vm.isLoading = true
            return vm
        }()
    )
}
