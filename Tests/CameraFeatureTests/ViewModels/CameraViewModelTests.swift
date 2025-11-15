import XCTest
import Combine
@testable import CameraFeature

@MainActor
final class CameraViewModelTests: XCTestCase {

    nonisolated(unsafe) var sut: CameraViewModel!
    nonisolated(unsafe) var mockCameraService: MockCameraService!
    nonisolated(unsafe) var cancellables: Set<AnyCancellable>!

    nonisolated override func setUp() {
        super.setUp()
        mockCameraService = MockCameraService()
        let service = mockCameraService!
        sut = MainActor.assumeIsolated {
            CameraViewModel(cameraService: service)
        }
        cancellables = []
    }

    nonisolated override func tearDown() {
        cancellables = nil
        sut = nil
        mockCameraService = nil
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
}
