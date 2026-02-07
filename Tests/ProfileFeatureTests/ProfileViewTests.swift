// ProfileViewTests.swift
// ProfileFeatureTests
//
// Created: 2026-01-14
// Stage: 2.6 UI/UX Refactoring with Liquid Glass

import Testing
import SwiftUI
@testable import ProfileFeature

@Suite("ProfileViewModel Tests")
@MainActor
struct ProfileViewModelTests {

    // MARK: - Initialization Tests

    @Test("Init with no userId and auth required sets error state")
    func testInit_withNoUserIdAndAuthRequired_setsErrorState() async throws {
        // Given: No authenticated user (nil userId)
        let mockRepository = MockItemRepository()
        let mockAuthService = MockAuthService()
        let mockAuthProvider = MockAuthUserProvider(userId: nil)

        // When: Create ViewModel without userId
        let viewModel = ProfileViewModel(
            userId: nil,
            itemRepository: mockRepository,
            authService: mockAuthService,
            authProvider: mockAuthProvider,
            requiresAuthentication: true
        )

        // Then: Should have error state
        #expect(viewModel.error == "Authentication required")
        #expect(viewModel.displayName == "")
        #expect(viewModel.email == "")
        #expect(viewModel.itemCount == 0)
    }

    @Test("Init with valid userId does not set error")
    func testInit_withValidUserId_noError() async throws {
        // Given: Valid user ID
        let mockRepository = MockItemRepository()
        let mockAuthService = MockAuthService()
        let mockAuthProvider = MockAuthUserProvider(userId: "test-user-123")

        // When: Create ViewModel with userId
        let viewModel = ProfileViewModel(
            userId: "test-user-123",
            displayName: "Test User",
            email: "test@example.com",
            itemRepository: mockRepository,
            authService: mockAuthService,
            authProvider: mockAuthProvider,
            requiresAuthentication: true
        )

        // Then: Should not have error
        #expect(viewModel.error == nil)
        #expect(viewModel.displayName == "Test User")
        #expect(viewModel.email == "test@example.com")
    }

    @Test("Init with requiresAuthentication=false allows nil userId")
    func testInit_withNoAuthRequired_allowsNilUserId() async throws {
        // Given: No auth required mode (for previews/testing)
        let mockRepository = MockItemRepository()
        let mockAuthService = MockAuthService()
        let mockAuthProvider = MockAuthUserProvider(userId: nil)

        // When: Create ViewModel without userId and auth not required
        let viewModel = ProfileViewModel(
            userId: nil,
            itemRepository: mockRepository,
            authService: mockAuthService,
            authProvider: mockAuthProvider,
            requiresAuthentication: false
        )

        // Then: Should not have error (for preview mode)
        #expect(viewModel.error == nil)
    }

    // MARK: - Load Profile Tests

    @Test("loadProfile with no auth sets error")
    func testLoadProfile_withNoAuth_setsError() async throws {
        // Given: ViewModel with no userId
        let mockRepository = MockItemRepository()
        let mockAuthService = MockAuthService()
        let mockAuthProvider = MockAuthUserProvider(userId: nil)
        let viewModel = ProfileViewModel(
            userId: nil,
            itemRepository: mockRepository,
            authService: mockAuthService,
            authProvider: mockAuthProvider,
            requiresAuthentication: true
        )

        // When: Try to load profile
        await viewModel.loadProfile()

        // Then: Should have auth error
        #expect(viewModel.error == "Authentication required")
        #expect(mockRepository.getItemsCalled == false)
    }

    @Test("loadProfile with valid auth fetches item count")
    func testLoadProfile_withValidAuth_fetchesItemCount() async throws {
        // Given: ViewModel with valid userId
        let mockRepository = MockItemRepository()
        mockRepository.mockItems = [
            MockItem(id: "item-1"),
            MockItem(id: "item-2"),
            MockItem(id: "item-3")
        ]
        let mockAuthService = MockAuthService()
        let mockAuthProvider = MockAuthUserProvider(userId: "test-user-123")
        let viewModel = ProfileViewModel(
            userId: "test-user-123",
            displayName: "Test User",
            email: "test@example.com",
            itemRepository: mockRepository,
            authService: mockAuthService,
            authProvider: mockAuthProvider,
            requiresAuthentication: true
        )

        // When: Load profile
        await viewModel.loadProfile()

        // Then: Should have item count
        #expect(viewModel.error == nil)
        #expect(viewModel.itemCount == 3)
        #expect(mockRepository.getItemsCalled == true)
        #expect(mockRepository.lastUserId == "test-user-123")
    }

    @Test("loadProfile handles repository error")
    func testLoadProfile_withRepositoryError_setsError() async throws {
        // Given: ViewModel with repository that throws
        let mockRepository = MockItemRepository()
        mockRepository.shouldThrowError = MockError.testError
        let mockAuthService = MockAuthService()
        let mockAuthProvider = MockAuthUserProvider(userId: "test-user-123")
        let viewModel = ProfileViewModel(
            userId: "test-user-123",
            displayName: "Test User",
            email: "test@example.com",
            itemRepository: mockRepository,
            authService: mockAuthService,
            authProvider: mockAuthProvider,
            requiresAuthentication: true
        )

        // When: Load profile
        await viewModel.loadProfile()

        // Then: Should have error
        #expect(viewModel.error != nil)
        #expect(viewModel.isLoading == false)
    }

    // MARK: - Sign Out Tests

    @Test("signOut calls auth service")
    func testSignOut_callsAuthService() async throws {
        // Given: ViewModel with mock auth service
        let mockRepository = MockItemRepository()
        let mockAuthService = MockAuthService()
        let mockAuthProvider = MockAuthUserProvider(userId: "test-user-123")
        let viewModel = ProfileViewModel(
            userId: "test-user-123",
            displayName: "Test User",
            email: "test@example.com",
            itemRepository: mockRepository,
            authService: mockAuthService,
            authProvider: mockAuthProvider,
            requiresAuthentication: true
        )

        // When: Sign out
        await viewModel.signOut()

        // Then: Auth service should be called
        #expect(mockAuthService.signOutCalled == true)
        #expect(viewModel.error == nil)
    }

    @Test("signOut handles auth service error")
    func testSignOut_withAuthError_setsError() async throws {
        // Given: ViewModel with auth service that throws
        let mockRepository = MockItemRepository()
        let mockAuthService = MockAuthService()
        mockAuthService.shouldThrowError = MockError.testError
        let mockAuthProvider = MockAuthUserProvider(userId: "test-user-123")
        let viewModel = ProfileViewModel(
            userId: "test-user-123",
            displayName: "Test User",
            email: "test@example.com",
            itemRepository: mockRepository,
            authService: mockAuthService,
            authProvider: mockAuthProvider,
            requiresAuthentication: true
        )

        // When: Sign out
        await viewModel.signOut()

        // Then: Should have error
        #expect(viewModel.error != nil)
        #expect(viewModel.isLoading == false)
    }

    // MARK: - Export Data Tests

    @Test("exportData with no auth sets error")
    func testExportData_withNoAuth_setsError() async throws {
        // Given: ViewModel with no userId
        let mockRepository = MockItemRepository()
        let mockAuthService = MockAuthService()
        let mockAuthProvider = MockAuthUserProvider(userId: nil)
        let viewModel = ProfileViewModel(
            userId: nil,
            itemRepository: mockRepository,
            authService: mockAuthService,
            authProvider: mockAuthProvider,
            requiresAuthentication: true
        )

        // When: Try to export data
        await viewModel.exportData(format: .csv)

        // Then: Should have auth error
        #expect(viewModel.error == "Authentication required")
    }

    @Test("exportData with valid auth completes successfully")
    func testExportData_withValidAuth_completes() async throws {
        // Given: ViewModel with valid userId
        let mockRepository = MockItemRepository()
        let mockAuthService = MockAuthService()
        let mockAuthProvider = MockAuthUserProvider(userId: "test-user-123")
        let viewModel = ProfileViewModel(
            userId: "test-user-123",
            displayName: "Test User",
            email: "test@example.com",
            itemRepository: mockRepository,
            authService: mockAuthService,
            authProvider: mockAuthProvider,
            requiresAuthentication: true
        )

        // When: Export data
        await viewModel.exportData(format: .csv)

        // Then: Should complete without error
        #expect(viewModel.error == nil)
        #expect(viewModel.isLoading == false)
    }
}

@Suite("ExportFormat Tests")
struct ExportFormatTests {

    @Test("ExportFormat has CSV case only")
    func testExportFormat_hasAllCases() {
        let allCases = ExportFormat.allCases
        #expect(allCases.count == 1)
        #expect(allCases.contains(.csv))
    }

    @Test("ExportFormat raw values are correct")
    func testExportFormat_rawValues() {
        #expect(ExportFormat.csv.rawValue == "CSV")
    }
}

// MARK: - Mock Types

/// Mock error for testing
enum MockError: Error {
    case testError
}

/// Mock item for testing
struct MockItem: Identifiable {
    let id: String
}

/// Mock ItemRepository for testing
final class MockItemRepository: @unchecked Sendable {
    var getItemsCalled = false
    var lastUserId: String?
    var mockItems: [MockItem] = []
    var shouldThrowError: Error?
}

// MARK: - ItemRepository Conformance

import Persistence
import Combine
import FirebaseFirestore

extension MockItemRepository: ItemRepository {
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

    func createItemWithPhotoMetadata(
        itemId: String,
        userId: String,
        imageUrl: String,
        layer1Metadata: Layer1Metadata,
        photoMetadata: PhotoMetadata
    ) async throws {
        // Mock implementation
    }

    func getItem(id: String) async throws -> Item? {
        return nil
    }

    func getItems(userId: String) async throws -> [Item] {
        getItemsCalled = true
        lastUserId = userId
        if let error = shouldThrowError {
            throw error
        }
        // Convert mock items to real items
        return mockItems.map { mock in
            Item(
                id: mock.id,
                userId: userId,
                imageUrl: "https://example.com/image.jpg",
                status: .complete,
                category: "test",
                color: nil,
                material: nil,
                condition: nil,
                confidence: .high,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
    }

    func observeItem(id: String, onChange: @escaping (Item?) -> Void) -> ListenerRegistration {
        fatalError("Mock observeItem not implemented")
    }

    func observeItems(userId: String) -> AnyPublisher<[Item], Never> {
        Just([]).eraseToAnyPublisher()
    }

    func deleteItem(id: String) async throws {
        // Mock implementation
    }

    func deleteItems(ids: Set<String>) async throws {
        // Mock implementation
    }

    func updateItem(_ item: Item, userEditedFields: [String]?) async throws {
        // Mock implementation
    }

    func rescanItem(_ item: Item) async throws {
        // Mock implementation
    }

    func refreshImageUrl(id: String) async throws -> String? {
        nil
    }

    func requestDeepScan(id: String) async throws {}

    func recatalogWithPhotos(id: String) async throws {}
}

/// Mock AuthService for testing
final class MockAuthService: AuthServiceProtocol, @unchecked Sendable {
    var signOutCalled = false
    var shouldThrowError: Error?

    func signOut() throws {
        signOutCalled = true
        if let error = shouldThrowError {
            throw error
        }
    }
}

/// Mock AuthUserProvider for testing
struct MockAuthUserProvider: AuthUserProvider {
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
