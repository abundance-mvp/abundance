// ProfileFeatureTests.swift
// ProfileFeatureTests
//
// Created: 2026-01-14
// Stage: 2.6 UI/UX Refactoring with Liquid Glass

import Testing
import SwiftUI
import Combine
import FirebaseFirestore
@testable import ProfileFeature
@testable import Persistence

@Suite("ProfileFeature Tests")
@MainActor
struct ProfileFeatureTests {
    @Test("ProfileView can be initialized with viewModel")
    func testProfileViewInit() {
        let mockAuthProvider = TestAuthUserProvider(userId: "test-user-123")
        let mockRepository = TestItemRepository()
        let viewModel = ProfileViewModel(
            userId: "test-user-123",
            displayName: "Test User",
            email: "test@example.com",
            itemRepository: mockRepository,
            authProvider: mockAuthProvider,
            requiresAuthentication: false
        )
        let view = ProfileView(viewModel: viewModel)
        #expect(type(of: view) == ProfileView.self)
    }

    @Test("UserInfoCard can be initialized")
    func testUserInfoCardInit() {
        let card = UserInfoCard(
            displayName: "Test User",
            email: "test@example.com",
            itemCount: 5
        )
        #expect(type(of: card) == UserInfoCard.self)
    }
}

// MARK: - Test Auth User Provider

/// Test AuthUserProvider for this test file
struct TestAuthUserProvider: AuthUserProvider {
    let currentUserId: String?
    let currentDisplayName: String?
    let currentEmail: String?

    init(
        userId: String?,
        displayName: String? = nil,
        email: String? = nil
    ) {
        self.currentUserId = userId
        self.currentDisplayName = displayName
        self.currentEmail = email
    }
}

// MARK: - Test Item Repository

/// Test ItemRepository for this test file
final class TestItemRepository: ItemRepository, @unchecked Sendable {
    func createItem(userId: String, imageUrl: String) async throws -> String {
        return "mock-item-id"
    }

    func createItemWithLayer1Metadata(
        itemId: String,
        userId: String,
        imageUrl: String,
        layer1Metadata: Layer1Metadata
    ) async throws {
        // Mock implementation
    }

    func getItem(id: String) async throws -> Item? {
        return nil
    }

    func getItems(userId: String) async throws -> [Item] {
        return []
    }

    func observeItem(id: String, onChange: @escaping (Item?) -> Void) -> ListenerRegistration {
        fatalError("Mock observeItem not implemented")
    }

    func observeItems(userId: String) -> AnyPublisher<[Item], Never> {
        Just([]).eraseToAnyPublisher()
    }
}
