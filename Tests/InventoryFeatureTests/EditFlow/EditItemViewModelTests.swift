import Testing
import Foundation
@testable import InventoryFeature
@testable import Persistence

@Suite("EditItemViewModel Tests")
@MainActor
struct EditItemViewModelTests {

    // MARK: - State Machine Tests

    @Test("Initial state is idle")
    func testInitialState() async throws {
        // Given: A new view model
        let item = makeTestItem()
        let viewModel = EditItemViewModel(
            item: item,
            itemRepository: MockEditItemRepository(),
            storageService: MockEditStorageService()
        )

        // Then: State should be idle
        #expect(viewModel.state == .idle)
        #expect(viewModel.originalItem == item)
        #expect(viewModel.editableItem == item)
    }

    @Test("startEditFlow transitions to promptingRescan")
    func testStartEditFlow() async throws {
        // Given: A view model in idle state
        let viewModel = makeViewModel()

        // When: Start edit flow
        viewModel.startEditFlow()

        // Then: State should be promptingRescan
        #expect(viewModel.state == .promptingRescan)
    }

    @Test("beginRescan transitions to capturing")
    func testBeginRescan() async throws {
        // Given: A view model prompting rescan
        let viewModel = makeViewModel()
        viewModel.startEditFlow()

        // When: Begin rescan
        viewModel.beginRescan()

        // Then: State should be capturing
        #expect(viewModel.state == .capturing)
    }

    @Test("cancelFlow returns to idle and resets state")
    func testCancelFlow() async throws {
        // Given: A view model in editing state with changes
        let viewModel = makeViewModel()
        viewModel.startEditFlow()
        viewModel.updateField(\.name, value: "Changed Name", fieldName: "name")

        // When: Cancel flow
        viewModel.cancelFlow()

        // Then: Should return to idle with clean state
        #expect(viewModel.state == .idle)
        #expect(viewModel.rescanResult == nil)
        #expect(viewModel.fieldTracker.editedFields.isEmpty)
        #expect(viewModel.validationErrors.isEmpty)
    }

    @Test("unlockManualEdit transitions to editing")
    func testUnlockManualEdit() async throws {
        // Given: A view model with rescan result
        let viewModel = makeViewModel()
        let rescanItem = makeTestItem(name: "Rescanned Item")
        viewModel.rescanResult = rescanItem

        // When: Unlock manual edit
        viewModel.unlockManualEdit()

        // Then: State should be editing with rescan result as editable
        #expect(viewModel.state == .editing)
        #expect(viewModel.editableItem.name == "Rescanned Item")
    }

    @Test("unlockManualEdit without rescan uses original item")
    func testUnlockManualEditWithoutRescan() async throws {
        // Given: A view model without rescan result
        let originalItem = makeTestItem(name: "Original Item")
        let viewModel = EditItemViewModel(
            item: originalItem,
            itemRepository: MockEditItemRepository(),
            storageService: MockEditStorageService()
        )

        // When: Unlock manual edit
        viewModel.unlockManualEdit()

        // Then: Should use original item
        #expect(viewModel.state == .editing)
        #expect(viewModel.editableItem.name == "Original Item")
    }

    // MARK: - Field Tracking Tests

    @Test("updateField tracks edited field")
    func testUpdateFieldTracking() async throws {
        // Given: A view model
        let viewModel = makeViewModel()

        // When: Update a field
        viewModel.updateField(\.name, value: "New Name", fieldName: "name")

        // Then: Field should be tracked
        #expect(viewModel.fieldTracker.editedFields.contains("name"))
        #expect(viewModel.editableItem.name == "New Name")
    }

    @Test("updateField tracks multiple fields")
    func testUpdateMultipleFields() async throws {
        // Given: A view model
        let viewModel = makeViewModel()

        // When: Update multiple fields
        viewModel.updateField(\.name, value: "New Name", fieldName: "name")
        viewModel.updateField(\.brand, value: "New Brand", fieldName: "brand")
        viewModel.updateField(\.color, value: "Blue", fieldName: "color")

        // Then: All fields should be tracked
        let tracked = viewModel.fieldTracker.asArray
        #expect(tracked.contains("name"))
        #expect(tracked.contains("brand"))
        #expect(tracked.contains("color"))
        #expect(tracked.count == 3)
    }

    @Test("fieldTracker asArray returns sorted fields")
    func testFieldTrackerSorted() async throws {
        // Given: A view model with fields updated in random order
        let viewModel = makeViewModel()
        viewModel.updateField(\.color, value: "Red", fieldName: "color")
        viewModel.updateField(\.brand, value: "Acme", fieldName: "brand")
        viewModel.updateField(\.name, value: "Widget", fieldName: "name")

        // Then: asArray should return sorted fields
        let tracked = viewModel.fieldTracker.asArray
        #expect(tracked == ["brand", "color", "name"])
    }

    // MARK: - Validation Tests

    @Test("validateField catches name too long")
    func testValidateNameTooLong() async throws {
        // Given: A view model
        let viewModel = makeViewModel()

        // When: Set name longer than 100 characters
        let longName = String(repeating: "a", count: 101)
        viewModel.updateField(\.name, value: longName, fieldName: "name")

        // Then: Should have validation error
        #expect(viewModel.validationErrors["name"] != nil)
        #expect(viewModel.validationErrors["name"]!.contains("100 characters"))
    }

    @Test("validateField allows valid name")
    func testValidateValidName() async throws {
        // Given: A view model
        let viewModel = makeViewModel()

        // When: Set valid name
        viewModel.updateField(\.name, value: "Valid Name", fieldName: "name")

        // Then: Should have no validation error
        #expect(viewModel.validationErrors["name"] == nil)
    }

    @Test("validateField catches negative value")
    func testValidateNegativeValue() async throws {
        // Given: A view model
        let viewModel = makeViewModel()

        // When: Set negative estimated value
        viewModel.updateField(\.estimatedValue, value: -10.0, fieldName: "estimatedValue")

        // Then: Should have validation error
        #expect(viewModel.validationErrors["estimatedValue"] != nil)
        #expect(viewModel.validationErrors["estimatedValue"]!.contains("negative"))
    }

    @Test("validateField catches very high value")
    func testValidateVeryHighValue() async throws {
        // Given: A view model
        let viewModel = makeViewModel()

        // When: Set value over 1 million
        viewModel.updateField(\.estimatedValue, value: 1_000_001.0, fieldName: "estimatedValue")

        // Then: Should have validation error (warning)
        #expect(viewModel.validationErrors["estimatedValue"] != nil)
        #expect(viewModel.validationErrors["estimatedValue"]!.contains("high"))
    }

    @Test("validateField catches quantity less than 1")
    func testValidateQuantityTooLow() async throws {
        // Given: A view model
        let viewModel = makeViewModel()

        // When: Set quantity to 0
        viewModel.updateField(\.quantity, value: 0, fieldName: "quantity")

        // Then: Should have validation error
        #expect(viewModel.validationErrors["quantity"] != nil)
        #expect(viewModel.validationErrors["quantity"]!.contains("at least 1"))
    }

    @Test("validateField catches quantity too high")
    func testValidateQuantityTooHigh() async throws {
        // Given: A view model
        let viewModel = makeViewModel()

        // When: Set quantity over 1000
        viewModel.updateField(\.quantity, value: 1001, fieldName: "quantity")

        // Then: Should have validation error
        #expect(viewModel.validationErrors["quantity"] != nil)
        #expect(viewModel.validationErrors["quantity"]!.contains("high"))
    }

    // MARK: - Save Tests

    @Test("saveManualEdits calls repository with edited fields")
    func testSaveManualEdits() async throws {
        // Given: A view model with edited fields
        let mockRepository = MockEditItemRepository()
        let viewModel = EditItemViewModel(
            item: makeTestItem(),
            itemRepository: mockRepository,
            storageService: MockEditStorageService()
        )
        viewModel.updateField(\.name, value: "Updated Name", fieldName: "name")
        viewModel.updateField(\.brand, value: "Updated Brand", fieldName: "brand")

        // When: Save manual edits
        try await viewModel.saveManualEdits()

        // Then: Repository should be called with correct data
        #expect(mockRepository.updateItemCalled)
        #expect(mockRepository.lastUpdatedItem?.name == "Updated Name")
        #expect(mockRepository.lastUpdatedItem?.brand == "Updated Brand")
        #expect(mockRepository.lastUserEditedFields?.contains("name") == true)
        #expect(mockRepository.lastUserEditedFields?.contains("brand") == true)
    }

    @Test("saveManualEdits fails with validation errors")
    func testSaveFailsWithValidationErrors() async throws {
        // Given: A view model with validation errors
        let mockRepository = MockEditItemRepository()
        let viewModel = EditItemViewModel(
            item: makeTestItem(),
            itemRepository: mockRepository,
            storageService: MockEditStorageService()
        )
        viewModel.updateField(\.estimatedValue, value: -10.0, fieldName: "estimatedValue")

        // When: Try to save
        try? await viewModel.saveManualEdits()

        // Then: Should stay in editing state
        #expect(viewModel.state == .editing)
        #expect(mockRepository.updateItemCalled == false)
    }

    @Test("saveManualEdits transitions to saving then idle on success")
    func testSaveStateTransitions() async throws {
        // Given: A view model ready to save
        let mockRepository = MockEditItemRepository()
        let viewModel = EditItemViewModel(
            item: makeTestItem(),
            itemRepository: mockRepository,
            storageService: MockEditStorageService()
        )
        viewModel.updateField(\.name, value: "Valid Name", fieldName: "name")

        // When: Save
        try await viewModel.saveManualEdits()

        // Then: Should end in idle state
        #expect(viewModel.state == .idle)
    }

    @Test("saveManualEdits sets error state on failure")
    func testSaveErrorState() async throws {
        // Given: A view model with failing repository
        let mockRepository = MockEditItemRepository()
        mockRepository.shouldFailUpdate = true
        let viewModel = EditItemViewModel(
            item: makeTestItem(),
            itemRepository: mockRepository,
            storageService: MockEditStorageService()
        )
        viewModel.updateField(\.name, value: "Valid Name", fieldName: "name")

        // When: Try to save (should fail)
        do {
            try await viewModel.saveManualEdits()
            #expect(Bool(false), "Should have thrown error")
        } catch {
            // Expected
        }

        // Then: Should be in error state
        if case .error = viewModel.state {
            // Expected
        } else {
            #expect(Bool(false), "Should be in error state")
        }
    }

    // MARK: - Accept Rescan Tests

    @Test("acceptRescanResult saves rescan result")
    func testAcceptRescanResult() async throws {
        // Given: A view model with rescan result
        let mockRepository = MockEditItemRepository()
        let viewModel = EditItemViewModel(
            item: makeTestItem(),
            itemRepository: mockRepository,
            storageService: MockEditStorageService()
        )
        let rescanItem = makeTestItem(name: "Rescanned Item")
        viewModel.rescanResult = rescanItem
        viewModel.state = .comparing(newItem: rescanItem)

        // When: Accept rescan result
        viewModel.acceptRescanResult()

        // Wait for async operation
        try await Task.sleep(for: .milliseconds(100))

        // Then: Repository should be called
        #expect(mockRepository.updateItemCalled)
    }

    // MARK: - Helpers

    private func makeTestItem(
        id: String = "test-item-1",
        name: String? = "Test Item",
        userId: String = "test-user"
    ) -> Item {
        Item(
            id: id,
            userId: userId,
            imageUrl: "https://example.com/image.jpg",
            status: .complete,
            name: name,
            category: "Test Category",
            brand: "Test Brand",
            color: "Red",
            condition: .good,
            estimatedValue: 100.0
        )
    }

    private func makeViewModel() -> EditItemViewModel {
        EditItemViewModel(
            item: makeTestItem(),
            itemRepository: MockEditItemRepository(),
            storageService: MockEditStorageService()
        )
    }
}

// MARK: - Mock Repository

final class MockEditItemRepository: ItemRepository, @unchecked Sendable {
    var updateItemCalled = false
    var lastUpdatedItem: Item?
    var lastUserEditedFields: [String]?
    var shouldFailUpdate = false
    var rescanItemCalled = false
    var lastRescanItem: Item?
    var mockItems: [Item] = []

    func createItem(userId: String, imageUrl: String) async throws -> String {
        "mock-id"
    }

    func createItemWithLayer1Metadata(
        itemId: String,
        userId: String,
        imageUrl: String,
        layer1Metadata: Layer1Metadata
    ) async throws {}

    func createItemWithPhotoMetadata(
        itemId: String,
        userId: String,
        imageUrl: String,
        layer1Metadata: Layer1Metadata,
        photoMetadata: PhotoMetadata
    ) async throws {}

    func getItem(id: String) async throws -> Item? {
        mockItems.first { $0.id == id }
    }

    func getItems(userId: String) async throws -> [Item] {
        mockItems
    }

    func observeItem(id: String, onChange: @escaping (Item?) -> Void) -> FirebaseFirestore.ListenerRegistration {
        fatalError("Not implemented")
    }

    func observeItems(userId: String) -> AnyPublisher<[Item], Never> {
        Just(mockItems).eraseToAnyPublisher()
    }

    func deleteItem(id: String) async throws {}

    func deleteItems(ids: Set<String>) async throws {}

    func updateItem(_ item: Item, userEditedFields: [String]?) async throws {
        if shouldFailUpdate {
            throw NSError(domain: "test", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock update error"])
        }
        updateItemCalled = true
        lastUpdatedItem = item
        lastUserEditedFields = userEditedFields
    }

    func rescanItem(_ item: Item) async throws {
        rescanItemCalled = true
        lastRescanItem = item
    }
}

// MARK: - Mock Storage Service

final class MockEditStorageService: StorageServiceProtocol, @unchecked Sendable {
    var uploadCalled = false
    var shouldFailUpload = false

    func uploadCroppedObject(_ image: PlatformImage, itemId: String, userId: String) async throws -> URL {
        if shouldFailUpload {
            throw NSError(domain: "test", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock upload error"])
        }
        uploadCalled = true
        return URL(string: "https://example.com/uploaded/\(itemId).jpg")!
    }

    func uploadLivePhotoMotion(_ motionData: Data, itemId: String, userId: String) async throws -> URL {
        URL(string: "https://example.com/motion/\(itemId).mov")!
    }
}

// Need to import Combine for AnyPublisher
import Combine
import FirebaseFirestore
