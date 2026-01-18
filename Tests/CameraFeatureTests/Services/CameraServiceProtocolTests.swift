import XCTest
import Combine
@testable import CameraFeature

final class CameraServiceProtocolTests: XCTestCase {

    var sut: MockCameraService!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        sut = MockCameraService()
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        super.tearDown()
    }

    func testSessionState_initiallyNotStarted() {
        // Given/When
        let expectation = XCTestExpectation(description: "Session state published")
        var receivedState: CameraSessionState?

        sut.sessionState
            .sink { state in
                receivedState = state
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedState, .notStarted)
    }

    func testStartSession_changesStateToRunning() async throws {
        // Given
        let expectation = XCTestExpectation(description: "State changes to running")
        var finalState: CameraSessionState?

        sut.sessionState
            .dropFirst() // Skip initial .notStarted
            .sink { state in
                finalState = state
                if case .running = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        try await sut.startSession()

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(finalState, .running)
    }

    func testStopSession_changesStateToStopped() async throws {
        // Given
        try await sut.startSession()
        let expectation = XCTestExpectation(description: "State changes to stopped")
        var finalState: CameraSessionState?

        sut.sessionState
            .sink { state in
                finalState = state
                if case .stopped = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        await sut.stopSession()

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(finalState, .stopped)
    }

    func testCapturePhoto_returnsImageData() async throws {
        // Given
        try await sut.startSession()
        sut.stubbedPhotoData = Data([0xFF, 0xD8, 0xFF, 0xE0]) // JPEG header

        // When
        let photoData = try await sut.capturePhoto()

        // Then
        XCTAssertEqual(photoData.count, 4)
        XCTAssertTrue(sut.didCallCapturePhoto)
    }

    func testCheckAuthorization_returnsAuthorizationStatus() async {
        // Given
        sut.stubbedAuthStatus = .authorized

        // When
        let status = await sut.checkAuthorization()

        // Then
        XCTAssertEqual(status, .authorized)
        XCTAssertTrue(sut.didCallCheckAuthorization)
    }
}
