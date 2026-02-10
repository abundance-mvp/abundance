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
    @State private var showingEditProfile = false

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
                        itemCount: viewModel.itemCount,
                        onEdit: { showingEditProfile = true }
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
            .sheet(isPresented: $showingEditProfile) {
                EditProfileSheet(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
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
                NavigationLink {
                    NotificationsSettingsView()
                } label: {
                    settingsRowContent(icon: "bell", title: "Notifications")
                }
                .accessibilityIdentifier("profile.notifications")

                Divider().padding(.leading, 48)

                NavigationLink {
                    PrivacySettingsView()
                } label: {
                    settingsRowContent(icon: "lock.shield", title: "Privacy")
                }
                .accessibilityIdentifier("profile.privacy")

                Divider().padding(.leading, 48)

                NavigationLink {
                    HelpView()
                } label: {
                    settingsRowContent(icon: "questionmark.circle", title: "Help")
                }
                .accessibilityIdentifier("profile.help")
            }
            .abundanceCardStyle()
        }
    }

    private func settingsRowContent(icon: String, title: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color.salmon)
                .frame(width: 24)
            Text(title)
                .font(.body)
                .foregroundStyle(Color.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    // MARK: - Export Section

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Export Data")

            if let doc = viewModel.csvDocument {
                ShareLink(
                    item: doc,
                    preview: SharePreview("Abundance Collection", image: Image(systemName: "tablecells"))
                ) {
                    exportButtonLabel
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("profile.shareCSV")
                .accessibilityLabel("Share CSV export")
            } else {
                Button {
                    Task { await viewModel.exportData(format: .csv) }
                } label: {
                    exportButtonLabel
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("profile.exportCSV")
                .accessibilityLabel("Export as CSV")
                .accessibilityHint("Double tap to generate a CSV file of your collection")
            }
        }
    }

    private var exportButtonLabel: some View {
        HStack {
            Image(systemName: "tablecells")
                .font(.title3)
                .foregroundStyle(Color.salmon)
            Text(viewModel.csvDocument != nil ? "Share CSV" : "Export as CSV")
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
        .abundanceCardStyle()
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
            .abundanceCardStyle()
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
