import Foundation
import Combine
@testable import CameraFeature

/// Thread-safe state storage for MockCatalogService
/// Uses NSLock for thread-safe access to mutable state
final class MockCatalogServiceState: @unchecked Sendable {
    private let lock = NSLock()
    private var _catalogCallCount = 0
    private var _lastSessionId: String?
    private var _lastGroupId: String?
    private var _lastUserId: String?
    private var _shouldThrowError = false
    private var _capturedRequestKeys: [String] = []
    private var _capturedObjects: [ServerDetectedObject] = []

    var catalogCallCount: Int {
        lock.withLock { _catalogCallCount }
    }

    var lastSessionId: String? {
        lock.withLock { _lastSessionId }
    }

    var lastGroupId: String? {
        lock.withLock { _lastGroupId }
    }

    var lastUserId: String? {
        lock.withLock { _lastUserId }
    }

    var capturedRequestKeys: [String] {
        lock.withLock { _capturedRequestKeys }
    }

    var capturedObjects: [ServerDetectedObject] {
        lock.withLock { _capturedObjects }
    }

    var shouldThrowError: Bool {
        get { lock.withLock { _shouldThrowError } }
        set { lock.withLock { _shouldThrowError = newValue } }
    }

    func recordCall(userId: String, sessionId: String, object: ServerDetectedObject) -> Bool {
        lock.withLock {
            _catalogCallCount += 1
            _lastUserId = userId
            _lastSessionId = sessionId
            _lastGroupId = object.groupId
            _capturedRequestKeys.append("\(sessionId):\(object.groupId)")
            _capturedObjects.append(object)
            return _shouldThrowError
        }
    }

    func reset() {
        lock.withLock {
            _catalogCallCount = 0
            _lastSessionId = nil
            _lastGroupId = nil
            _lastUserId = nil
            _shouldThrowError = false
            _capturedRequestKeys = []
            _capturedObjects = []
        }
    }
}

/// Mock CatalogService for testing object cataloging
/// Tracks catalog calls and allows verification of idempotency
final class MockCatalogService: CatalogServiceProtocol, @unchecked Sendable {
    // MARK: - Thread-Safe State

    let state = MockCatalogServiceState()

    // MARK: - Convenience Accessors

    var catalogCallCount: Int { state.catalogCallCount }
    var lastSessionId: String? { state.lastSessionId }
    var lastGroupId: String? { state.lastGroupId }
    var lastUserId: String? { state.lastUserId }
    var capturedRequestKeys: [String] { state.capturedRequestKeys }
    var capturedObjects: [ServerDetectedObject] { state.capturedObjects }

    var shouldThrowError: Bool {
        get { state.shouldThrowError }
        set { state.shouldThrowError = newValue }
    }

    // MARK: - Item Status Simulation

    private let itemStatusSubject = PassthroughSubject<ItemCatalogStatus?, Never>()
    var stubbedItemStatuses: [String: ItemCatalogStatus] = [:]

    // MARK: - Timing Simulation

    var catalogDelay: TimeInterval = 0

    // MARK: - CatalogServiceProtocol

    func catalogDetectedObject(
        userId: String,
        sessionId: String,
        object: ServerDetectedObject
    ) async throws -> String {
        let shouldThrow = state.recordCall(userId: userId, sessionId: sessionId, object: object)

        // Simulate network delay if configured
        if catalogDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(catalogDelay * 1_000_000_000))
        }

        if shouldThrow {
            throw MockCatalogError.catalogFailed(
                reason: "Mock catalog error for \(object.groupId)"
            )
        }

        return "test-item-id-\(object.groupId)"
    }

    func observeItem(itemId: String) -> AnyPublisher<ItemCatalogStatus?, Never> {
        // If we have a stubbed status, return it immediately
        if let stubbedStatus = stubbedItemStatuses[itemId] {
            return Just(stubbedStatus).eraseToAnyPublisher()
        }

        // Otherwise return the subject for external control
        return itemStatusSubject.eraseToAnyPublisher()
    }

    // MARK: - Test Helpers

    /// Simulate item status update
    func simulateItemStatus(_ status: ItemCatalogStatus) {
        itemStatusSubject.send(status)
    }

    /// Simulate item cataloging complete
    func simulateItemComplete(itemId: String, name: String, category: String) {
        let status = ItemCatalogStatus(
            itemId: itemId,
            status: "complete",
            name: name,
            category: category,
            error: nil
        )
        stubbedItemStatuses[itemId] = status
        itemStatusSubject.send(status)
    }

    /// Simulate item cataloging failure
    func simulateItemFailed(itemId: String, error: String) {
        let status = ItemCatalogStatus(
            itemId: itemId,
            status: "failed",
            name: nil,
            category: nil,
            error: error
        )
        stubbedItemStatuses[itemId] = status
        itemStatusSubject.send(status)
    }

    /// Reset all state for clean test setup
    func reset() {
        state.reset()
        stubbedItemStatuses = [:]
        catalogDelay = 0
    }
}

/// Catalog errors for testing
enum MockCatalogError: Error, LocalizedError {
    case catalogFailed(reason: String)
    case networkError
    case quotaExceeded
    case invalidObject

    var errorDescription: String? {
        switch self {
        case .catalogFailed(let reason):
            return "Catalog failed: \(reason)"
        case .networkError:
            return "Network error during cataloging"
        case .quotaExceeded:
            return "Catalog quota exceeded"
        case .invalidObject:
            return "Invalid object data"
        }
    }
}

// MARK: - Test Data Factory

extension ServerDetectedObject {
    /// Create a mock detected object for testing
    static func mock(
        groupId: String = "test-group-1",
        label: String = "Test Object",
        category: String = "test-category",
        attributes: [String: String] = [:],
        confidence: String = "high",
        croppedImageUrls: [String] = ["https://example.com/cropped.jpg"],
        boundingBoxes: [BoundingBoxInfo] = []
    ) -> ServerDetectedObject {
        ServerDetectedObject(
            groupId: groupId,
            label: label,
            category: category,
            attributes: attributes,
            confidence: confidence,
            croppedImageUrls: croppedImageUrls,
            boundingBoxes: boundingBoxes
        )
    }
}

extension CaptureSession {
    /// Create a mock capture session for testing
    static func mock(
        id: String = "test-session-1",
        userId: String = "test-user",
        captureMode: CaptureMode = .single,
        status: CaptureSessionStatus = .uploading,
        detectedObjects: [ServerDetectedObject] = []
    ) -> CaptureSession {
        CaptureSession(
            id: id,
            userId: userId,
            captureMode: captureMode,
            status: status,
            detectedObjects: detectedObjects
        )
    }
}
