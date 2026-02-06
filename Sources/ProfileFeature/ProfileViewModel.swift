// ProfileViewModel.swift
// ProfileFeature
//
// Created: 2026-01-14
// Stage: 2.6 UI/UX Refactoring with Liquid Glass

import Foundation
import FirebaseAuth
import Persistence

/// Export format options for user data
public enum ExportFormat: String, CaseIterable, Sendable {
    case csv = "CSV"
}

/// ViewModel for Profile view
/// **Patterns:** DESIGN-037 Pattern 1 (Constructor Injection), @Observable (iOS 17+)
@MainActor
@Observable
public final class ProfileViewModel {
    // MARK: - Published Properties

    public var displayName: String = ""
    public var email: String = ""
    public var itemCount: Int = 0
    public var isLoading: Bool = false
    public var error: String?

    // MARK: - Private Properties

    private let userId: String?
    private let itemRepository: ItemRepository
    private let authService: AuthServiceProtocol

    // MARK: - Initializer

    /// Initialize ProfileViewModel
    /// - Parameters:
    ///   - userId: User ID. If nil, falls back to current Firebase user.
    ///   - displayName: Display name for the user. If nil, falls back to Firebase.
    ///   - email: Email for the user. If nil, falls back to Firebase.
    ///   - itemRepository: Repository for item persistence (injectable for testing)
    ///   - authService: Authentication service (injectable for testing)
    ///   - authProvider: Provider for auth user info (injectable for testing)
    ///   - requiresAuthentication: If true, sets error when no userId available.
    public init(
        userId: String? = nil,
        displayName: String? = nil,
        email: String? = nil,
        itemRepository: ItemRepository = ItemService(),
        authService: AuthServiceProtocol = FirebaseAuthService(),
        authProvider: AuthUserProvider? = nil,
        requiresAuthentication: Bool = true
    ) {
        // Use auth provider to get user info (allows mocking in tests)
        let provider = authProvider ?? FirebaseAuthUserProvider()

        // Resolve userId: explicit > auth provider (only if auth required)
        let resolvedUserId: String?
        if let userId = userId {
            resolvedUserId = userId
        } else if requiresAuthentication {
            resolvedUserId = provider.currentUserId
        } else {
            resolvedUserId = nil
        }

        if requiresAuthentication && resolvedUserId == nil {
            self.userId = nil
            self.itemRepository = itemRepository
            self.authService = authService
            self.error = "Authentication required"
            return
        }

        self.userId = resolvedUserId
        self.itemRepository = itemRepository
        self.authService = authService

        // Set user info from explicit values or provider
        if let displayName = displayName {
            self.displayName = displayName
        } else {
            self.displayName = provider.currentDisplayName ?? "User"
        }

        if let email = email {
            self.email = email
        } else {
            self.email = provider.currentEmail ?? ""
        }
    }

    // MARK: - Public Methods

    /// Load user profile data including item count
    public func loadProfile() async {
        guard let userId = userId else {
            error = "Authentication required"
            return
        }

        isLoading = true
        error = nil

        do {
            let items = try await itemRepository.getItems(userId: userId)
            itemCount = items.count
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    /// Sign out the current user
    public func signOut() async {
        isLoading = true
        error = nil

        do {
            try authService.signOut()
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    /// Export user data in the specified format
    /// - Parameter format: The export format (CSV)
    public func exportData(format: ExportFormat) async {
        guard userId != nil else {
            error = "Authentication required"
            return
        }

        isLoading = true
        error = nil

        // Simulate export process
        // In a real implementation, this would generate and share a file
        do {
            try await Task.sleep(for: .milliseconds(500))
            isLoading = false
            // Export success - in production, this would trigger share sheet
        } catch {
            self.error = "Export failed: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

// MARK: - Auth Service Protocol

/// Protocol for authentication service (enables dependency injection for testing)
public protocol AuthServiceProtocol: Sendable {
    func signOut() throws
}

/// Firebase implementation of AuthServiceProtocol
public struct FirebaseAuthService: AuthServiceProtocol {
    public init() {}

    public func signOut() throws {
        try Auth.auth().signOut()
    }
}

// MARK: - Auth User Provider Protocol

/// Protocol for providing current user information (enables dependency injection for testing)
public protocol AuthUserProvider: Sendable {
    var currentUserId: String? { get }
    var currentDisplayName: String? { get }
    var currentEmail: String? { get }
}

/// Firebase implementation of AuthUserProvider
public struct FirebaseAuthUserProvider: AuthUserProvider {
    public init() {}

    public var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    public var currentDisplayName: String? {
        Auth.auth().currentUser?.displayName
    }

    public var currentEmail: String? {
        Auth.auth().currentUser?.email
    }
}
