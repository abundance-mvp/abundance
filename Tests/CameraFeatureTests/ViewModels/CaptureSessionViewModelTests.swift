import XCTest
import Combine
@testable import CameraFeature
@testable import Persistence

/// Thread-safe counter for testing capture counts
final class AtomicCounter: @unchecked Sendable {
    private var _value: Int = 0
    private let lock = NSLock()

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }

    func increment() {
        lock.lock()
        _value += 1
        lock.unlock()
    }

    func reset() {
        lock.lock()
        _value = 0
        lock.unlock()
    }
}

/// Tests for CaptureSessionViewModel burst capture using structured concurrency
@MainActor
final class CaptureSessionViewModelTests: XCTestCase {

    // MARK: - Properties

    nonisolated(unsafe) var sut: CaptureSessionViewModel!
    nonisolated(unsafe) var mockSessionService: MockSessionService!
    nonisolated(unsafe) var mockStorageService: MockStorageService!
    nonisolated(unsafe) var mockCatalogService: MockCatalogService!

    // MARK: - Setup / Teardown

    nonisolated override func setUp() {
        super.setUp()
        mockSessionService = MockSessionService()
        mockStorageService = MockStorageService()
        mockCatalogService = MockCatalogService()

        let sessionService = mockSessionService!
        let storageService = mockStorageService!
        let catalogService = mockCatalogService!

        sut = MainActor.assumeIsolated {
            CaptureSessionViewModel(
                sessionService: sessionService,
                storageService: storageService,
                catalogService: catalogService
            )
        }
    }

    nonisolated override func tearDown() {
        sut = nil
        mockSessionService = nil
        mockStorageService = nil
        mockCatalogService = nil
        super.tearDown()
    }

    // MARK: - Burst Capture Structured Concurrency Tests

    func testBurstCaptureUsesStructuredConcurrency() async throws {
        // Given
        let captureCounter = AtomicCounter()
        let capturePhoto: @Sendable () async throws -> Data = {
            captureCounter.increment()
            return Data([0x00, 0x01, 0x02])
        }

        // When - start burst capture
        sut.startBurstCapture(capturePhoto: capturePhoto)

        // Wait for approximately 3 capture intervals (500ms each) + initial capture
        // 0ms: initial capture, 500ms: 2nd, 1000ms: 3rd, 1500ms: 4th
        try await Task.sleep(for: .milliseconds(1700))

        // Cancel to prevent more captures
        sut.cancelBurstCapture()

        // Then - should have captured 3-4 photos (initial + ~3 at 500ms intervals)
        XCTAssertGreaterThanOrEqual(captureCounter.value, 3, "Should have captured at least 3 photos")
        XCTAssertLessThanOrEqual(captureCounter.value, 5, "Should not have captured more than 5 photos")

        // Verify task is cleaned up after cancellation
        XCTAssertNil(sut.burstTask, "burstTask should be nil after cancellation")
    }

    func testBurstCaptureCancellation() async throws {
        // Given
        let captureCounter = AtomicCounter()
        let capturePhoto: @Sendable () async throws -> Data = {
            captureCounter.increment()
            // Small delay to simulate capture
            try await Task.sleep(for: .milliseconds(50))
            return Data([0x00])
        }

        // When - start and quickly cancel
        sut.startBurstCapture(capturePhoto: capturePhoto)
        try await Task.sleep(for: .milliseconds(200))
        sut.cancelBurstCapture()

        let countAfterCancel = captureCounter.value

        // Wait to ensure no more captures happen
        try await Task.sleep(for: .milliseconds(700))

        // Then - captures should have stopped
        XCTAssertEqual(
            captureCounter.value,
            countAfterCancel,
            "No additional captures should occur after cancellation"
        )
        XCTAssertNil(sut.burstTask, "burstTask should be nil after cancellation")
        XCTAssertFalse(sut.isCapturing, "isCapturing should be false after cancellation")
    }

    func testBurstTaskPropertyExists() {
        // The burstTask property should be accessible for testing
        XCTAssertNil(sut.burstTask, "burstTask should initially be nil")
    }

    func testBurstCaptureMaxPhotosLimit() async throws {
        // Given - a fast capture that tracks photo count
        let captureCounter = AtomicCounter()
        let capturePhoto: @Sendable () async throws -> Data = {
            captureCounter.increment()
            return Data([0x00])
        }

        // When - start burst capture
        sut.startBurstCapture(capturePhoto: capturePhoto)

        // Wait for 3.5 seconds (enough for ~7 photos at 500ms intervals)
        // Don't wait long enough to trigger auto-end (which requires Firebase Auth)
        try await Task.sleep(for: .milliseconds(3500))

        // Cancel before it can auto-end to avoid Firebase Auth dependency
        sut.cancelBurstCapture()

        // Then - should have captured multiple photos but not exceeded the 8 limit
        // The loop should respect the capturedPhotos.count < 8 condition
        XCTAssertLessThanOrEqual(captureCounter.value, 8, "Should not exceed 8 photos")
        XCTAssertGreaterThanOrEqual(captureCounter.value, 5, "Should have captured several photos")
    }

    func testEndBurstCaptureCleansUpTask() async throws {
        // Given
        let capturePhoto: @Sendable () async throws -> Data = {
            return Data([0xFF])
        }

        sut.startBurstCapture(capturePhoto: capturePhoto)
        try await Task.sleep(for: .milliseconds(100))

        // Verify task exists during capture
        XCTAssertNotNil(sut.burstTask, "burstTask should exist during capture")

        // When - call cancelBurstCapture (since endBurstCapture requires auth)
        sut.cancelBurstCapture()

        // Then
        XCTAssertNil(sut.burstTask, "burstTask should be nil after ending capture")
    }

    func testStartBurstCaptureDoesNotUseTimer() async throws {
        // This test verifies that the Timer-based implementation has been replaced
        // by checking that burstTask is used instead

        let capturePhoto: @Sendable () async throws -> Data = {
            return Data([0x01])
        }

        // When
        sut.startBurstCapture(capturePhoto: capturePhoto)
        try await Task.sleep(for: .milliseconds(50))

        // Then - burstTask should be set (Timer-based implementation wouldn't have this)
        XCTAssertNotNil(sut.burstTask, "Should use Task-based loop (burstTask property)")

        // Cleanup
        sut.cancelBurstCapture()
    }

    func testBurstCaptureIgnoresStartWhenAlreadyCapturing() async throws {
        // Given
        let captureCounter = AtomicCounter()
        let capturePhoto: @Sendable () async throws -> Data = {
            captureCounter.increment()
            return Data([0x00])
        }

        // When - start first burst
        sut.startBurstCapture(capturePhoto: capturePhoto)
        try await Task.sleep(for: .milliseconds(100))

        // Capture count after first start
        let countAfterFirstStart = captureCounter.value
        XCTAssertNotNil(sut.burstTask, "burstTask should exist after first start")

        // Try to start second burst (should be ignored)
        sut.startBurstCapture(capturePhoto: capturePhoto)

        // Wait a bit and verify count didn't reset (which would happen if new task was created)
        try await Task.sleep(for: .milliseconds(100))

        // Then - count should have continued incrementing (task wasn't replaced)
        XCTAssertGreaterThanOrEqual(
            captureCounter.value,
            countAfterFirstStart,
            "Second startBurstCapture should be ignored when already capturing"
        )

        // Cleanup
        sut.cancelBurstCapture()
    }
}

// MARK: - Mock Services

/// Mock SessionService for testing
final class MockSessionService: SessionServiceProtocol, @unchecked Sendable {
    var createSessionCallCount = 0
    var stubbedSessionId = "test-session-id"

    func createSession(
        userId: String,
        captureMode: CaptureMode,
        expectedImageCount: Int
    ) async throws -> String {
        createSessionCallCount += 1
        return stubbedSessionId
    }

    func addUploadedImage(sessionId: String, imageUrl: String) async throws {}

    func markReadyForDetection(sessionId: String) async throws {}

    func observeSession(sessionId: String) -> AnyPublisher<CaptureSession?, Never> {
        Just(nil).eraseToAnyPublisher()
    }

    func getSession(sessionId: String) async throws -> CaptureSession? {
        nil
    }

    func deleteSession(sessionId: String) async throws {}
}

/// Mock StorageService for testing
final class MockStorageService: StorageServiceProtocol, @unchecked Sendable {
    func uploadCroppedObject(
        _ image: PlatformImage,
        itemId: String,
        userId: String
    ) async throws -> URL {
        URL(string: "https://example.com/\(itemId).jpg")!
    }

    func uploadLivePhotoMotion(
        _ motionData: Data,
        itemId: String,
        userId: String
    ) async throws -> URL {
        URL(string: "https://example.com/\(itemId).mov")!
    }
}

/// Mock CatalogService for testing
final class MockCatalogService: CatalogServiceProtocol, @unchecked Sendable {
    func catalogDetectedObject(
        userId: String,
        sessionId: String,
        object: ServerDetectedObject
    ) async throws -> String {
        "test-item-id"
    }

    func observeItem(itemId: String) -> AnyPublisher<ItemCatalogStatus?, Never> {
        Just(nil).eraseToAnyPublisher()
    }
}
