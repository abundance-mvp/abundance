import XCTest
import Combine
@testable import CameraFeature
@testable import Persistence
#if os(iOS)
import UIKit
public typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
public typealias PlatformImage = NSImage
#endif

@MainActor
final class CameraViewModelTests: XCTestCase {

    nonisolated(unsafe) var sut: CameraViewModel!
    nonisolated(unsafe) var mockCameraService: MockCameraService!
    nonisolated(unsafe) var mockStorageService: MockStorageService!
    nonisolated(unsafe) var cancellables: Set<AnyCancellable>!

    nonisolated override func setUp() {
        super.setUp()
        mockCameraService = MockCameraService()
        mockStorageService = MockStorageService()
        let service = mockCameraService!
        let storage = mockStorageService!
        sut = MainActor.assumeIsolated {
            CameraViewModel(cameraService: service, storageService: storage)
        }
        cancellables = []
    }

    nonisolated override func tearDown() {
        cancellables = nil
        sut = nil
        mockCameraService = nil
        mockStorageService = nil
        super.tearDown()
    }

    func testInit_sessionStateIsNotStarted() {
        // Then
        XCTAssertEqual(sut.sessionState, .notStarted)
    }

    func testInit_capturedPhotoIsNil() {
        // Then
        XCTAssertNil(sut.capturedPhotoData)
    }

    func testInit_isCapturingIsFalse() {
        // Then
        XCTAssertFalse(sut.isCapturing)
    }

    func testInit_errorMessageIsNil() {
        // Then
        XCTAssertNil(sut.errorMessage)
    }

    func testCheckCameraPermission_whenAuthorized_startsCamera() async {
        // Given
        mockCameraService.stubbedAuthStatus = .authorized

        // When
        await sut.checkCameraPermission()

        // Then
        XCTAssertTrue(mockCameraService.didCallCheckAuthorization)
        XCTAssertTrue(mockCameraService.didCallStartSession)
        XCTAssertEqual(sut.authorizationStatus, .authorized)
        XCTAssertNil(sut.errorMessage)
    }

    func testCheckCameraPermission_whenDenied_showsError() async {
        // Given
        mockCameraService.stubbedAuthStatus = .denied

        // When
        await sut.checkCameraPermission()

        // Then
        XCTAssertTrue(mockCameraService.didCallCheckAuthorization)
        XCTAssertFalse(mockCameraService.didCallStartSession)
        XCTAssertEqual(sut.authorizationStatus, .denied)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("denied"))
    }

    func testCapturePhoto_whenSessionRunning_capturesPhoto() async {
        // Given
        try? await mockCameraService.startSession()
        sut.sessionState = .running
        let testPhotoData = Data([0xFF, 0xD8, 0xFF, 0xE0]) // JPEG header
        mockCameraService.stubbedPhotoData = testPhotoData

        // When
        await sut.capturePhoto()

        // Then
        XCTAssertTrue(mockCameraService.didCallCapturePhoto)
        XCTAssertEqual(sut.capturedPhotoData, testPhotoData)
        XCTAssertFalse(sut.isCapturing)
        XCTAssertNil(sut.errorMessage)
    }

    func testCapturePhoto_whenSessionNotRunning_doesNotCapture() async {
        // Given
        sut.sessionState = .notStarted

        // When
        await sut.capturePhoto()

        // Then
        XCTAssertFalse(mockCameraService.didCallCapturePhoto)
        XCTAssertNil(sut.capturedPhotoData)
    }

    func testCapturePhoto_whenCaptureFails_showsError() async {
        // Given
        try? await mockCameraService.startSession()
        sut.sessionState = .running
        mockCameraService.shouldFailCapturePhoto = true

        // When
        await sut.capturePhoto()

        // Then
        XCTAssertTrue(mockCameraService.didCallCapturePhoto)
        XCTAssertNil(sut.capturedPhotoData)
        XCTAssertNotNil(sut.errorMessage)
    }

    func testCapturePhoto_WithValidImage_UploadsToStorage() async throws {
        // Given
        let mockStorage = MockStorageService()

        // Create a proper JPEG image data
        #if os(iOS)
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let testImage = renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        let testPhotoData = testImage.jpegData(compressionQuality: 0.8)!
        #elseif os(macOS)
        let testImage = NSImage(size: NSSize(width: 100, height: 100))
        testImage.lockFocus()
        NSColor.blue.setFill()
        NSRect(x: 0, y: 0, width: 100, height: 100).fill()
        testImage.unlockFocus()

        guard let cgImage = testImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            XCTFail("Could not create test image")
            return
        }
        let imageRep = NSBitmapImageRep(cgImage: cgImage)
        let testPhotoData = imageRep.representation(using: .jpeg, properties: [:])!
        #endif

        mockCameraService.stubbedPhotoData = testPhotoData

        let viewModel = CameraViewModel(
            cameraService: mockCameraService,
            storageService: mockStorage
        )

        try? await mockCameraService.startSession()
        viewModel.sessionState = .running

        // When
        await viewModel.capturePhoto()

        // Then
        XCTAssertTrue(mockStorage.uploadCalled, "Storage upload should have been called")
        XCTAssertNotNil(mockStorage.lastUploadedImage, "Last uploaded image should not be nil")
        XCTAssertEqual(viewModel.uploadProgress, 1.0, "Upload progress should be 1.0")
    }
}

// MARK: - Mock StorageService

final class MockStorageService: StorageServiceProtocol, @unchecked Sendable {
    var uploadCalled = false
    var lastUploadedImage: PlatformImage?
    var lastItemId: String?
    var lastUserId: String?

    func uploadCroppedObject(
        _ image: PlatformImage,
        itemId: String,
        userId: String
    ) async throws -> URL {
        uploadCalled = true
        lastUploadedImage = image
        lastItemId = itemId
        lastUserId = userId
        return URL(string: "https://firebasestorage.googleapis.com/test/image.jpg")!
    }
}
