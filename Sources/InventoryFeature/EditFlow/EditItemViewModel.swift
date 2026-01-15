import Foundation
import SwiftUI
import Combine
import Persistence

/// State machine for the rescan edit flow
public enum EditFlowState: Equatable {
    case idle
    case promptingRescan
    case capturing
    case processing
    case comparing(newItem: Item)
    case editing
    case saving
    case error(String)

    public static func == (lhs: EditFlowState, rhs: EditFlowState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.promptingRescan, .promptingRescan),
             (.capturing, .capturing),
             (.processing, .processing),
             (.editing, .editing),
             (.saving, .saving):
            return true
        case (.comparing(let lhsItem), .comparing(let rhsItem)):
            return lhsItem.id == rhsItem.id
        case (.error(let lhsMsg), .error(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}

/// Tracks which fields the user has manually edited
public struct EditedFieldTracker: Sendable {
    public var editedFields: Set<String> = []

    public init() {}

    public mutating func markEdited(_ field: String) {
        editedFields.insert(field)
    }

    public var asArray: [String] {
        Array(editedFields).sorted()
    }
}

/// ViewModel managing the entire rescan -> compare -> edit flow
@MainActor
@Observable
public final class EditItemViewModel {
    // MARK: - Published State

    public var state: EditFlowState = .idle
    public var originalItem: Item
    public var editableItem: Item
    public var rescanResult: Item?
    public var fieldTracker = EditedFieldTracker()
    public var validationErrors: [String: String] = [:]

    // MARK: - Dependencies

    private let itemRepository: ItemRepository
    private let storageService: StorageServiceProtocol

    // MARK: - Initialization

    public init(
        item: Item,
        itemRepository: ItemRepository = ItemService(),
        storageService: StorageServiceProtocol = StorageService()
    ) {
        self.originalItem = item
        self.editableItem = item
        self.itemRepository = itemRepository
        self.storageService = storageService
    }

    // MARK: - Flow Control

    /// Start the edit flow by showing rescan prompt
    public func startEditFlow() {
        state = .promptingRescan
    }

    /// User chose to take a new photo
    public func beginRescan() {
        state = .capturing
    }

    /// Cancel and return to idle
    public func cancelFlow() {
        state = .idle
        editableItem = originalItem
        rescanResult = nil
        fieldTracker = EditedFieldTracker()
        validationErrors = [:]
    }

    /// Called when camera captures a new image
    public func handleCapturedImage(_ image: PlatformImage) async {
        state = .processing

        do {
            // Upload new image to Firebase Storage
            guard let userId = editableItem.userId.nilIfEmpty else {
                throw EditFlowError.missingUserId
            }

            let newImageUrl = try await storageService.uploadCroppedObject(
                image,
                itemId: editableItem.id + "-rescan-\(Int(Date().timeIntervalSince1970))",
                userId: userId
            )

            // Trigger Gemini reprocessing (updates Firestore via Cloud Function)
            try await triggerRescan(newImageUrl: newImageUrl)

            // Wait for processing to complete (poll or listen)
            let updatedItem = try await waitForProcessingComplete()

            rescanResult = updatedItem
            state = .comparing(newItem: updatedItem)

        } catch {
            state = .error(error.localizedDescription)
        }
    }

    /// User accepts the rescan result
    public func acceptRescanResult() async {
        guard let rescanResult = rescanResult else { return }

        state = .saving
        do {
            try await saveRescanResult(rescanResult)
            state = .idle
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    /// User indicates rescan result is still incorrect -> unlock manual edit
    public func unlockManualEdit() {
        // Start with rescan result if available, otherwise original
        if let rescanResult = rescanResult {
            editableItem = rescanResult
        }
        state = .editing
    }

    /// Save manual edits
    public func saveManualEdits() async throws {
        state = .saving

        // Validate before saving
        guard validateAllFields() else {
            state = .editing
            return
        }

        do {
            try await itemRepository.updateItem(
                editableItem,
                userEditedFields: fieldTracker.asArray
            )
            state = .idle
        } catch {
            state = .error(error.localizedDescription)
            throw error
        }
    }

    // MARK: - Field Editing

    /// Update a field and track the edit
    public func updateField<T>(_ keyPath: WritableKeyPath<Item, T>, value: T, fieldName: String) {
        editableItem[keyPath: keyPath] = value
        fieldTracker.markEdited(fieldName)
        validateField(fieldName)
    }

    // MARK: - Validation

    /// Validate a single field
    public func validateField(_ fieldName: String) {
        switch fieldName {
        case "name":
            if let name = editableItem.name, name.count > 100 {
                validationErrors["name"] = "Name must be 100 characters or less"
            } else {
                validationErrors.removeValue(forKey: "name")
            }

        case "estimatedValue":
            if let value = editableItem.estimatedValue, value < 0 {
                validationErrors["estimatedValue"] = "Value cannot be negative"
            } else if let value = editableItem.estimatedValue, value > 1_000_000 {
                validationErrors["estimatedValue"] = "Value seems unusually high"
            } else {
                validationErrors.removeValue(forKey: "estimatedValue")
            }

        case "quantity":
            if let qty = editableItem.quantity, qty < 1 {
                validationErrors["quantity"] = "Quantity must be at least 1"
            } else if let qty = editableItem.quantity, qty > 1000 {
                validationErrors["quantity"] = "Quantity seems unusually high"
            } else {
                validationErrors.removeValue(forKey: "quantity")
            }

        default:
            break
        }
    }

    /// Validate all fields before save
    private func validateAllFields() -> Bool {
        ["name", "estimatedValue", "quantity"].forEach { validateField($0) }
        return validationErrors.isEmpty
    }

    // MARK: - Private Helpers

    private func triggerRescan(newImageUrl: URL) async throws {
        // Create new item with updated image URL to trigger Cloud Function rescan
        // Note: imageUrl is a let constant in Item, so we create a new instance
        let updatedItem = Item(
            id: editableItem.id,
            userId: editableItem.userId,
            imageUrl: newImageUrl.absoluteString,
            status: .pending,
            name: editableItem.name,
            category: editableItem.category,
            subCategory: editableItem.subCategory,
            brand: editableItem.brand,
            model: editableItem.model,
            color: editableItem.color,
            material: editableItem.material,
            condition: editableItem.condition,
            dimensions: editableItem.dimensions,
            quantity: editableItem.quantity,
            estimatedValue: editableItem.estimatedValue,
            confidence: editableItem.confidence,
            processingNotes: editableItem.processingNotes,
            userEditedFields: editableItem.userEditedFields,
            lastRescanAt: Date(),
            photoMetadata: editableItem.photoMetadata,
            createdAt: editableItem.createdAt,
            updatedAt: Date()
        )

        try await itemRepository.rescanItem(updatedItem)
    }

    private func waitForProcessingComplete() async throws -> Item {
        // Poll for status change (or use real-time listener)
        var attempts = 0
        let maxAttempts = 30 // 30 seconds max

        while attempts < maxAttempts {
            try await Task.sleep(for: .seconds(1))

            if let item = try await itemRepository.getItem(id: editableItem.id) {
                if item.status == .complete || item.status == .layer2aComplete {
                    return item
                }
                if item.status == .failed || item.status == .failedLayer2a {
                    throw EditFlowError.rescanProcessingFailed
                }
            }
            attempts += 1
        }

        throw EditFlowError.rescanTimeout
    }

    private func saveRescanResult(_ item: Item) async throws {
        var updatedItem = item
        updatedItem.lastRescanAt = Date()
        try await itemRepository.updateItem(updatedItem, userEditedFields: nil)
    }
}

// MARK: - Errors

public enum EditFlowError: LocalizedError {
    case missingUserId
    case rescanProcessingFailed
    case rescanTimeout
    case validationFailed

    public var errorDescription: String? {
        switch self {
        case .missingUserId:
            return "User authentication required"
        case .rescanProcessingFailed:
            return "Failed to analyze the new photo"
        case .rescanTimeout:
            return "Photo analysis timed out"
        case .validationFailed:
            return "Please fix validation errors"
        }
    }
}

// MARK: - String Extension

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
