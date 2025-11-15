import XCTest
@testable import Persistence
import FirebaseCore
import FirebaseStorage

@available(iOS 17.0, *)
final class StorageServiceTests: XCTestCase {

    var sut: StorageService!

    override func setUp() async throws {
        try await super.setUp()

        // Configure Firebase for testing if not already configured
        if FirebaseApp.app() == nil {
            let options = FirebaseOptions(googleAppID: "1:123:ios:123abc", gcmSenderID: "123")
            options.projectID = "abundance-test"
            options.apiKey = "test-api-key"
            options.storageBucket = "abundance-test.appspot.com"
            FirebaseApp.configure(options: options)
        }

        // Use emulator storage
        let storage = Storage.storage()
        storage.useEmulator(withHost: "localhost", port: 9199)

        sut = StorageService(storage: storage)
    }

    override func tearDown() async throws {
        sut = nil
        try await super.tearDown()
    }

    func testUploadImage_ValidImage_ReturnsDownloadURL() async throws {
        // This test requires Firebase Storage Emulator to be running
        // Skip if emulator is not available
        guard isEmulatorRunning() else {
            throw XCTSkip("Firebase Storage Emulator is not running. Start with: firebase emulators:start")
        }

        // Given
        let testImage = createTestImage()
        let itemId = "test_item_123"
        let userId = "test_user_456"

        // When
        let downloadURL = try await sut.uploadCroppedObject(
            testImage,
            itemId: itemId,
            userId: userId
        )

        // Then
        XCTAssertNotNil(downloadURL)
        XCTAssertTrue(downloadURL.absoluteString.contains("localhost:9199") || downloadURL.absoluteString.contains("firebasestorage.googleapis.com"))
    }

    // Helper: Check if emulator is running
    private func isEmulatorRunning() -> Bool {
        // Try to connect to emulator port
        let task = Process()
        task.launchPath = "/usr/bin/nc"
        task.arguments = ["-z", "localhost", "9199"]
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus == 0
    }

    // Helper: Create test image
    private func createTestImage() -> PlatformImage {
        #if os(iOS)
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        #else
        fatalError("macOS not supported")
        #endif
    }
}
