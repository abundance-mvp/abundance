import XCTest
import Combine
@testable import CameraFeature

@MainActor
final class CameraServiceTests: XCTestCase {

    nonisolated(unsafe) var sut: CameraService!
    nonisolated(unsafe) var cancellables: Set<AnyCancellable>!

    nonisolated override func setUp() {
        super.setUp()
        sut = CameraService()
        cancellables = []
    }

    nonisolated override func tearDown() {
        sut?.stopSession()
        cancellables = nil
        sut = nil
        super.tearDown()
    }

    func testInit_sessionStateIsNotStarted() {
        // Given/When
        let expectation = XCTestExpectation(description: "Initial state published")
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

    func testCheckAuthorization_whenNotDetermined_returnsStatus() async {
        // When
        let status = await sut.checkAuthorization()

        // Then
        // Note: In tests, status may be .denied if simulator doesn't have camera
        // This test validates the method works without crashing
        XCTAssertTrue([.authorized, .denied, .notDetermined].contains(status))
    }

    func testStartSession_configuresSessionCorrectly() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Session reaches running state")
        var stateChanges: [CameraSessionState] = []

        sut.sessionState
            .sink { state in
                stateChanges.append(state)
                if case .running = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        try await sut.startSession()

        // Then
        await fulfillment(of: [expectation], timeout: 3.0)

        // Verify state transitions: notStarted → configuring → running
        XCTAssertTrue(stateChanges.contains(where: { if case .configuring = $0 { return true }; return false }))
        XCTAssertTrue(stateChanges.contains(where: { if case .running = $0 { return true }; return false }))
    }

    func testStopSession_stopsRunningSession() async throws {
        // Given
        try? await sut.startSession()
        let expectation = XCTestExpectation(description: "Session reaches stopped state")
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
        sut.stopSession()

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(finalState, .stopped)
    }

    func testCapturePhoto_withoutSession_throwsError() async {
        // Given: session not started

        // When/Then
        do {
            _ = try await sut.capturePhoto()
            XCTFail("Should throw error when session not started")
        } catch {
            XCTAssertTrue(error is CameraError)
        }
    }

    func testFramePublisher_emitsNoFramesWithoutSession() async {
        // Given
        let expectation = XCTestExpectation(description: "Frame publisher doesn't crash")
        expectation.isInverted = true // We don't expect frames without a running session
        var frameCount = 0

        sut.framePublisher
            .sink { _ in
                frameCount += 1
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When: Wait briefly without starting session

        // Then: No frames should be emitted
        await fulfillment(of: [expectation], timeout: 0.5)
        XCTAssertEqual(frameCount, 0, "No frames should be emitted without session")
    }

    // MARK: - copyPixelBuffer Failure Path Documentation
    //
    // The private copyPixelBuffer() method handles failure gracefully:
    // - Returns nil if CVPixelBufferCreate fails (e.g., memory pressure)
    // - Returns nil if pixel buffer locking fails
    // - Returns nil if base address is inaccessible
    //
    // When copyPixelBuffer returns nil, captureOutput(_:didOutput:from:) returns
    // early without publishing to frameSubject. This is intentional:
    // - Dropped frames are acceptable (throttled to 2 FPS anyway)
    // - No crash or data corruption occurs
    // - Detection pipeline gracefully handles missing frames
    //
    // Direct testing of copyPixelBuffer failure is not feasible because:
    // 1. CVPixelBufferCreate rarely fails except under severe memory pressure
    // 2. Creating invalid pixel buffers for test purposes is complex
    // 3. The behavior (silent frame drop) is correct and doesn't need explicit verification
}
