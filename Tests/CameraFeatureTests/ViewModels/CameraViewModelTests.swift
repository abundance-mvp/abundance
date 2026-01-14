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

    func testStartCamera_whenSucceeds_clearsErrorMessage() async {
        // Given
        mockCameraService.stubbedAuthStatus = .authorized
        sut.errorMessage = "Previous error"

        // When
        await sut.startCamera()

        // Then
        XCTAssertTrue(mockCameraService.didCallStartSession)
        XCTAssertNil(sut.errorMessage)
    }

    func testStartCamera_whenFails_setsErrorMessage() async {
        // Given
        mockCameraService.shouldFailStartSession = true

        // When
        await sut.startCamera()

        // Then
        XCTAssertTrue(mockCameraService.didCallStartSession)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("Failed to start camera"))
    }

    func testStopCamera_callsStopSession() {
        // When
        sut.stopCamera()

        // Then
        XCTAssertTrue(mockCameraService.didCallStopSession)
    }

    func testGetCaptureSession_returnsCameraServiceSession() {
        // When
        let session = sut.getCaptureSession()

        // Then
        // MockCameraService returns nil for getCaptureSession
        XCTAssertNil(session)
    }
}

// Note: Tests for photo capture functionality have been removed.
// Photo capture is now handled by CameraDetectionViewModel.
// See CameraDetectionViewModelTests for real-time detection tests.
