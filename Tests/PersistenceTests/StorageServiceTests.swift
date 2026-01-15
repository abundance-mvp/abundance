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
        // In CI, fail loudly to prevent silent coverage gaps
        let isCI = ProcessInfo.processInfo.environment["CI"] == "true"
        let emulatorRunning = isEmulatorRunning()

        if isCI && !emulatorRunning {
            XCTFail("CI environment requires Firebase Storage Emulator for integration tests")
            return
        }

        // Locally, skip if emulator is not available
        guard emulatorRunning else {
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
        let urlString = downloadURL.absoluteString
        XCTAssertTrue(urlString.contains("localhost:9199") || urlString.contains("firebasestorage.googleapis.com"))
    }

    // Helper: Check if emulator is running
    private func isEmulatorRunning() -> Bool {
        #if os(macOS)
        // Try to connect to emulator port (macOS only - Process not available on iOS)
        let task: Process = Process()
        task.launchPath = "/usr/bin/nc"
        task.arguments = ["-z", "localhost", "9199"]
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus == 0
        #else
        // On iOS, assume emulator is not running (tests run against real Firebase)
        return false
        #endif
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
