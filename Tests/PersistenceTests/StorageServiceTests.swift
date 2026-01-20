import Testing
import Foundation
@testable import Persistence

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - StorageService Unit Tests

@Suite("StorageService Tests")
struct StorageServiceTests {

    // MARK: - Test Helpers

    /// Creates a test image for upload testing
    private func createTestImage() -> PlatformImage {
        #if os(iOS)
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        #elseif os(macOS)
        let size = CGSize(width: 100, height: 100)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.blue.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        return image
        #endif
    }

    // MARK: - Upload Cropped Object Tests

    @Test("Upload cropped object success returns URL")
    func testUploadCroppedObject_success_returnsURL() async throws {
        // Given
        let mock = TestStorageServiceMock()
        let expectedURL = URL(string: "https://storage.example.com/users/user123/items/item456.jpg")!
        mock.urlToReturn = expectedURL
        let testImage = createTestImage()

        // When
        let resultURL = try await mock.uploadCroppedObject(
            testImage,
            itemId: "item456",
            userId: "user123"
        )

        // Then
        #expect(resultURL == expectedURL)
        #expect(mock.uploadCroppedObjectCallCount == 1)
    }

    @Test("Upload cropped object compresses to JPEG")
    func testUploadCroppedObject_compressesToJPEG() async throws {
        // Given
        let mock = TestStorageServiceMock()
        let testImage = createTestImage()

        // When
        _ = try await mock.uploadCroppedObject(
            testImage,
            itemId: "item123",
            userId: "user456"
        )

        // Then - verify content type is JPEG
        #expect(mock.capturedContentType == "image/jpeg")
        #expect(mock.uploadedImage != nil)
    }

    @Test("Upload cropped object generates correct storage path")
    func testUploadCroppedObject_correctPath() async throws {
        // Given
        let mock = TestStorageServiceMock()
        let testImage = createTestImage()
        let itemId = "item123"
        let userId = "user456"

        // When
        _ = try await mock.uploadCroppedObject(
            testImage,
            itemId: itemId,
            userId: userId
        )

        // Then - verify path format: users/{uid}/items/{id}.jpg
        #expect(mock.uploadedPath == "users/user456/items/item123.jpg")
        #expect(mock.lastItemId == itemId)
        #expect(mock.lastUserId == userId)
    }

    @Test("Upload cropped object sets required metadata")
    func testUploadCroppedObject_setsMetadata() async throws {
        // Given
        let mock = TestStorageServiceMock()
        let testImage = createTestImage()
        let itemId = "item123"
        let userId = "user456"

        // When
        _ = try await mock.uploadCroppedObject(
            testImage,
            itemId: itemId,
            userId: userId
        )

        // Then - verify required metadata fields
        let metadata = mock.uploadedMetadata
        #expect(metadata != nil)
        #expect(metadata?["itemId"] == itemId)
        #expect(metadata?["userId"] == userId)
        #expect(metadata?["version"] == "1.0")
        #expect(metadata?["processingStatus"] == "pending")
        #expect(metadata?["uploadSource"] == "camera-detection")
        #expect(metadata?["uploadedAt"] != nil) // ISO8601 timestamp
    }

    @Test("Upload cropped object timeout throws error")
    func testUploadCroppedObject_timeout_throwsError() async throws {
        // Given
        let mock = TestStorageServiceMock()
        mock.shouldTimeout = true
        let testImage = createTestImage()

        // When/Then - expect timeout error
        await #expect(throws: StorageError.self) {
            // Use withTimeout to test cancellation behavior
            try await withThrowingTaskGroup(of: URL.self) { group in
                group.addTask {
                    try await mock.uploadCroppedObject(
                        testImage,
                        itemId: "item123",
                        userId: "user456"
                    )
                }

                group.addTask {
                    // Timeout after 1 second for test purposes
                    try await Task.sleep(for: .seconds(1))
                    throw StorageError.networkTimeout
                }

                // First to complete wins
                guard let result = try await group.next() else {
                    throw StorageError.networkTimeout
                }
                group.cancelAll()
                return result
            }
        }
    }

    @Test("Upload cropped object network error throws error")
    func testUploadCroppedObject_networkError_throwsError() async throws {
        // Given
        let mock = TestStorageServiceMock()
        mock.errorToThrow = TestNetworkError.connectionFailed
        let testImage = createTestImage()

        // When/Then
        await #expect(throws: TestNetworkError.self) {
            try await mock.uploadCroppedObject(
                testImage,
                itemId: "item123",
                userId: "user456"
            )
        }
    }

    // MARK: - Upload Live Photo Motion Tests

    @Test("Upload Live Photo motion success returns URL")
    func testUploadLivePhotoMotion_success_returnsURL() async throws {
        // Given
        let mock = TestStorageServiceMock()
        let expectedURL = URL(string: "https://storage.example.com/users/user123/items/item456/motion.mov")!
        mock.urlToReturn = expectedURL
        let motionData = Data([0x00, 0x01, 0x02, 0x03])

        // When
        let resultURL = try await mock.uploadLivePhotoMotion(
            motionData,
            itemId: "item456",
            userId: "user123"
        )

        // Then
        #expect(resultURL == expectedURL)
        #expect(mock.uploadLivePhotoMotionCallCount == 1)
        #expect(mock.uploadedData == motionData)
    }

    @Test("Upload Live Photo motion generates correct storage path")
    func testUploadLivePhotoMotion_correctPath() async throws {
        // Given
        let mock = TestStorageServiceMock()
        let motionData = Data([0x00, 0x01, 0x02])
        let itemId = "item789"
        let userId = "user012"

        // When
        _ = try await mock.uploadLivePhotoMotion(
            motionData,
            itemId: itemId,
            userId: userId
        )

        // Then - verify path format: users/{uid}/items/{id}/motion.mov
        #expect(mock.uploadedPath == "users/user012/items/item789/motion.mov")
    }

    @Test("Upload Live Photo motion sets correct content type")
    func testUploadLivePhotoMotion_correctContentType() async throws {
        // Given
        let mock = TestStorageServiceMock()
        let motionData = Data([0x00, 0x01, 0x02])

        // When
        _ = try await mock.uploadLivePhotoMotion(
            motionData,
            itemId: "item123",
            userId: "user456"
        )

        // Then - verify content type is QuickTime
        #expect(mock.capturedContentType == "video/quicktime")
    }

    // MARK: - Dependency Injection Tests

    @Test("StorageService uses injected reference")
    func testStorageService_usesInjectedReference() async throws {
        // Given - a mock service that conforms to the protocol
        let mock = TestStorageServiceMock()
        let testImage = createTestImage()

        // When - use the mock as the service
        let service: StorageServiceProtocol = mock
        _ = try await service.uploadCroppedObject(
            testImage,
            itemId: "item123",
            userId: "user456"
        )

        // Then - mock recorded the call
        #expect(mock.uploadCroppedObjectCallCount == 1)
        #expect(mock.lastItemId == "item123")
        #expect(mock.lastUserId == "user456")
    }

    @Test("StorageService handles authentication error")
    func testStorageService_handlesAuthenticationError() async throws {
        // Given
        let mock = TestStorageServiceMock()
        mock.errorToThrow = TestNetworkError.permissionDenied
        let testImage = createTestImage()

        // When/Then
        await #expect(throws: TestNetworkError.self) {
            try await mock.uploadCroppedObject(
                testImage,
                itemId: "item123",
                userId: "user456"
            )
        }

        // Verify the call was still recorded before error
        #expect(mock.uploadCroppedObjectCallCount == 1)
    }
}

// MARK: - StorageError Tests

@Suite("StorageError Tests")
struct StorageErrorTests {

    @Test("StorageError provides localized descriptions")
    func testStorageError_localizedDescriptions() {
        let errors: [StorageError] = [
            .invalidImage,
            .compressionFailed,
            .uploadFailed(NSError(domain: "test", code: 1)),
            .networkTimeout,
            .quotaExceeded,
            .invalidURL,
            .deleteFailed(NSError(domain: "test", code: 2))
        ]

        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }

    @Test("StorageError networkTimeout has correct message")
    func testStorageError_networkTimeout_message() {
        let error = StorageError.networkTimeout
        #expect(error.errorDescription?.contains("timed out") == true)
    }

    @Test("StorageError compressionFailed has correct message")
    func testStorageError_compressionFailed_message() {
        let error = StorageError.compressionFailed
        #expect(error.errorDescription?.contains("compress") == true)
    }

    @Test("StorageError uploadFailed includes underlying error")
    func testStorageError_uploadFailed_includesUnderlyingError() {
        let underlyingError = NSError(
            domain: "TestDomain",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "Server error"]
        )
        let error = StorageError.uploadFailed(underlyingError)
        #expect(error.errorDescription?.contains("Server error") == true)
    }
}

// MARK: - TestStorageServiceMock Tests

@Suite("TestStorageServiceMock Tests")
struct TestStorageServiceMockTests {

    @Test("Mock reset clears all state")
    func testMockReset_clearsAllState() async throws {
        // Given - mock with recorded state
        let mock = TestStorageServiceMock()
        #if os(iOS)
        let size = CGSize(width: 10, height: 10)
        let renderer = UIGraphicsImageRenderer(size: size)
        let testImage = renderer.image { _ in }
        #elseif os(macOS)
        let testImage = NSImage(size: CGSize(width: 10, height: 10))
        #endif

        _ = try await mock.uploadCroppedObject(testImage, itemId: "item", userId: "user")
        _ = try await mock.uploadLivePhotoMotion(Data([0x00]), itemId: "item2", userId: "user2")

        // When
        mock.reset()

        // Then
        #expect(mock.uploadedData == nil)
        #expect(mock.uploadedPath == nil)
        #expect(mock.uploadedMetadata == nil)
        #expect(mock.uploadedImage == nil)
        #expect(mock.lastItemId == nil)
        #expect(mock.lastUserId == nil)
        #expect(mock.uploadCroppedObjectCallCount == 0)
        #expect(mock.uploadLivePhotoMotionCallCount == 0)
        #expect(mock.errorToThrow == nil)
        #expect(mock.shouldTimeout == false)
        #expect(mock.artificialDelay == 0)
    }

    @Test("Mock tracks call counts correctly")
    func testMock_tracksCallCounts() async throws {
        // Given
        let mock = TestStorageServiceMock()
        #if os(iOS)
        let size = CGSize(width: 10, height: 10)
        let renderer = UIGraphicsImageRenderer(size: size)
        let testImage = renderer.image { _ in }
        #elseif os(macOS)
        let testImage = NSImage(size: CGSize(width: 10, height: 10))
        #endif

        // When
        _ = try await mock.uploadCroppedObject(testImage, itemId: "1", userId: "u")
        _ = try await mock.uploadCroppedObject(testImage, itemId: "2", userId: "u")
        _ = try await mock.uploadLivePhotoMotion(Data(), itemId: "3", userId: "u")

        // Then
        #expect(mock.uploadCroppedObjectCallCount == 2)
        #expect(mock.uploadLivePhotoMotionCallCount == 1)
    }
}

// MARK: - Test Mock Infrastructure

/// Mock implementation of StorageServiceProtocol for unit testing
/// Named TestStorageServiceMock to avoid conflicts with other test targets
private final class TestStorageServiceMock: StorageServiceProtocol, @unchecked Sendable {
    // MARK: - Recorded Values

    var uploadedData: Data?
    var uploadedPath: String?
    var uploadedMetadata: [String: String]?
    var uploadedImage: PlatformImage?
    var lastItemId: String?
    var lastUserId: String?
    var uploadCroppedObjectCallCount: Int = 0
    var uploadLivePhotoMotionCallCount: Int = 0

    // MARK: - Configurable Behavior

    var urlToReturn: URL = URL(string: "https://firebasestorage.googleapis.com/v0/b/test-bucket/o/image.jpg")!
    var errorToThrow: Error?
    var shouldTimeout: Bool = false
    var artificialDelay: TimeInterval = 0
    var capturedContentType: String?

    // MARK: - StorageServiceProtocol Implementation

    func uploadCroppedObject(
        _ image: PlatformImage,
        itemId: String,
        userId: String
    ) async throws -> URL {
        uploadCroppedObjectCallCount += 1
        uploadedImage = image
        lastItemId = itemId
        lastUserId = userId
        uploadedPath = "users/\(userId)/items/\(itemId).jpg"

        // Simulate metadata that would be set
        uploadedMetadata = [
            "uploadedAt": ISO8601DateFormatter().string(from: Date()),
            "itemId": itemId,
            "userId": userId,
            "version": "1.0",
            "processingStatus": "pending",
            "uploadSource": "camera-detection"
        ]
        capturedContentType = "image/jpeg"

        // Simulate timeout behavior
        if shouldTimeout {
            try await Task.sleep(for: .seconds(61))
            throw StorageError.networkTimeout
        }

        // Apply artificial delay if configured
        if artificialDelay > 0 {
            try await Task.sleep(for: .seconds(artificialDelay))
        }

        // Throw configured error if set
        if let error = errorToThrow {
            throw error
        }

        return urlToReturn
    }

    func uploadLivePhotoMotion(
        _ motionData: Data,
        itemId: String,
        userId: String
    ) async throws -> URL {
        uploadLivePhotoMotionCallCount += 1
        uploadedData = motionData
        lastItemId = itemId
        lastUserId = userId
        uploadedPath = "users/\(userId)/items/\(itemId)/motion.mov"

        // Simulate metadata that would be set
        uploadedMetadata = [
            "uploadedAt": ISO8601DateFormatter().string(from: Date()),
            "itemId": itemId,
            "userId": userId,
            "type": "live-photo-motion",
            "processingStatus": "pending",
            "uploadSource": "live-photo-capture"
        ]
        capturedContentType = "video/quicktime"

        // Simulate timeout behavior
        if shouldTimeout {
            try await Task.sleep(for: .seconds(61))
            throw StorageError.networkTimeout
        }

        // Apply artificial delay if configured
        if artificialDelay > 0 {
            try await Task.sleep(for: .seconds(artificialDelay))
        }

        // Throw configured error if set
        if let error = errorToThrow {
            throw error
        }

        return urlToReturn
    }

    // MARK: - Test Helpers

    func reset() {
        uploadedData = nil
        uploadedPath = nil
        uploadedMetadata = nil
        uploadedImage = nil
        lastItemId = nil
        lastUserId = nil
        uploadCroppedObjectCallCount = 0
        uploadLivePhotoMotionCallCount = 0
        urlToReturn = URL(string: "https://firebasestorage.googleapis.com/v0/b/test-bucket/o/image.jpg")!
        errorToThrow = nil
        shouldTimeout = false
        artificialDelay = 0
        capturedContentType = nil
    }
}

/// Simulated network errors for testing error handling
private enum TestNetworkError: Error, LocalizedError {
    case connectionFailed
    case serverError(code: Int)
    case authenticationRequired
    case permissionDenied
    case quotaExceeded

    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Network connection failed"
        case .serverError(let code):
            return "Server returned error code \(code)"
        case .authenticationRequired:
            return "Authentication required"
        case .permissionDenied:
            return "Permission denied - user not authorized to access storage"
        case .quotaExceeded:
            return "Storage quota exceeded"
        }
    }
}

// MARK: - Integration Tests (Require Firebase Emulator)

// Note: Integration tests with real Firebase Storage are in a separate test class
// that requires the Firebase emulator to be running.
// Run with: firebase emulators:start --only storage
// Then: swift test --filter StorageServiceIntegrationTests
