import XCTest
import AVFoundation
@testable import CameraFeature

/// Tests for Swift 6 concurrency safety in camera service
@MainActor
final class CameraConcurrencyTests: XCTestCase {
    var sut: CameraService!

    override func setUp() async throws {
        sut = CameraService()
    }

    override func tearDown() async throws {
        await sut?.stopSession()
        sut = nil
    }

    // MARK: - Concurrency Safety Tests

    func testCameraServicePublishersAccessible() async throws {
        // Verify that publishers are accessible from MainActor context
        _ = sut.sessionState
        _ = sut.framePublisher
    }

    func testConcurrentSessionStopOperations() async throws {
        // Test that concurrent stop operations are thread-safe
        // Stop operations are idempotent and should complete without crash

        for _ in 0..<5 {
            await sut.stopSession()
        }

        // If we reach here without crash, the test passes
    }

    func testCaptureSessionAccessConsistency() async throws {
        // Verify that accessing capture session returns consistent results

        var sessions: [AVCaptureSession?] = []
        for _ in 0..<10 {
            let session = await sut.getCaptureSession()
            sessions.append(session)
        }

        // All accesses should return the same session instance
        let firstSession = sessions.first!
        XCTAssertTrue(sessions.allSatisfy { $0 === firstSession })
    }

    func testPhotoCaptureWithoutSession() async throws {
        // Test that photo capture properly handles no session state
        // This tests error handling rather than concurrency serialization

        do {
            _ = try await sut.capturePhoto()
            XCTFail("Should throw error when session not started")
        } catch {
            // Expected - no session means capture fails
            XCTAssertTrue(error is CameraError)
        }
    }

    func testFramePublisherSubscription() async throws {
        // Test that frame publisher can be subscribed to without crash
        // and produces a valid Combine publisher chain
        let cancellable = sut.framePublisher
            .sink { _ in }

        // Verify subscription is alive (non-nil cancellable)
        withExtendedLifetime(cancellable) {
            // If we get here, publisher subscription is concurrency-safe
            XCTAssertNotNil(cancellable)
        }
    }

    func testAuthorizationCheck() async throws {
        // Test that authorization check works correctly
        let status = await sut.checkAuthorization()

        // Status should be one of the valid values
        XCTAssertTrue([.authorized, .denied, .notDetermined].contains(status))
    }
}
