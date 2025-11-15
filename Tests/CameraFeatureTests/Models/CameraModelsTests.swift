import XCTest
@testable import CameraFeature

final class CameraModelsTests: XCTestCase {

    func testCameraSessionState_notStarted_isCorrectState() {
        // Given
        let state = CameraSessionState.notStarted

        // Then
        if case .notStarted = state {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected notStarted state")
        }
    }

    func testCameraSessionState_running_isCorrectState() {
        // Given
        let state = CameraSessionState.running

        // Then
        if case .running = state {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected running state")
        }
    }

    func testCameraSessionState_failed_containsError() {
        // Given
        let testError = NSError(domain: "test", code: 1)
        let state = CameraSessionState.failed(testError)

        // Then
        if case .failed(let error) = state {
            XCTAssertEqual((error as NSError).domain, "test")
        } else {
            XCTFail("Expected failed state with error")
        }
    }

    func testCameraAuthorizationStatus_authorized_isCorrectStatus() {
        // Given
        let status = CameraAuthorizationStatus.authorized

        // Then
        XCTAssertEqual(status, .authorized)
    }

    func testCameraAuthorizationStatus_denied_isCorrectStatus() {
        // Given
        let status = CameraAuthorizationStatus.denied

        // Then
        XCTAssertEqual(status, .denied)
    }

    func testCameraAuthorizationStatus_notDetermined_isCorrectStatus() {
        // Given
        let status = CameraAuthorizationStatus.notDetermined

        // Then
        XCTAssertEqual(status, .notDetermined)
    }

    func testCameraError_deviceNotAvailable_hasCorrectMessage() {
        // Given
        let error = CameraError.deviceNotAvailable

        // Then
        XCTAssertEqual(error.errorDescription, "Camera device not available")
    }

    func testCameraError_authorizationDenied_hasCorrectMessage() {
        // Given
        let error = CameraError.authorizationDenied

        // Then
        XCTAssertEqual(error.errorDescription, "Camera authorization denied")
    }

    func testCameraError_captureFailure_hasCorrectMessage() {
        // Given
        let error = CameraError.captureFailure

        // Then
        XCTAssertEqual(error.errorDescription, "Failed to capture photo")
    }
}
