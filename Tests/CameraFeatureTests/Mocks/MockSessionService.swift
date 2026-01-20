import Foundation
import Combine
@testable import CameraFeature
@testable import Persistence

/// Mock SessionService for testing CaptureSessionViewModel
/// Allows verification of session creation, updates, and observation
final class MockSessionService: SessionServiceProtocol, @unchecked Sendable {
    // MARK: - Call Tracking

    var createSessionCallCount = 0
    var addUploadedImageCallCount = 0
    var markReadyForDetectionCallCount = 0
    var getSessionCallCount = 0
    var deleteSessionCallCount = 0
    var observeSessionCallCount = 0

    // MARK: - Captured Parameters

    var capturedUserId: String?
    var capturedCaptureMode: CaptureMode?
    var capturedExpectedImageCount: Int?
    var capturedSessionIds: [String] = []
    var capturedImageUrls: [String] = []

    // MARK: - Stubbed Responses

    var stubbedSessionId = "test-session-id"
    var stubbedSession: CaptureSession?
    var sessionPublisher = PassthroughSubject<CaptureSession?, Never>()

    // MARK: - Error Simulation

    var errorToThrow: Error?
    var markReadyForDetectionError: Error?

    // MARK: - SessionServiceProtocol

    func createSession(
        userId: String,
        captureMode: CaptureMode,
        expectedImageCount: Int
    ) async throws -> String {
        createSessionCallCount += 1
        capturedUserId = userId
        capturedCaptureMode = captureMode
        capturedExpectedImageCount = expectedImageCount

        if let error = errorToThrow {
            throw error
        }

        return stubbedSessionId
    }

    func addUploadedImage(sessionId: String, imageUrl: String) async throws {
        addUploadedImageCallCount += 1
        capturedSessionIds.append(sessionId)
        capturedImageUrls.append(imageUrl)

        if let error = errorToThrow {
            throw error
        }
    }

    func markReadyForDetection(sessionId: String) async throws {
        markReadyForDetectionCallCount += 1
        capturedSessionIds.append(sessionId)

        if let error = markReadyForDetectionError ?? errorToThrow {
            throw error
        }
    }

    func observeSession(sessionId: String) -> AnyPublisher<CaptureSession?, Never> {
        observeSessionCallCount += 1
        capturedSessionIds.append(sessionId)

        // Return the subject for external control
        return sessionPublisher.eraseToAnyPublisher()
    }

    func getSession(sessionId: String) async throws -> CaptureSession? {
        getSessionCallCount += 1

        if let error = errorToThrow {
            throw error
        }

        return stubbedSession
    }

    func deleteSession(sessionId: String) async throws {
        deleteSessionCallCount += 1

        if let error = errorToThrow {
            throw error
        }
    }

    // MARK: - Test Helpers

    /// Simulate a session update for observers
    func simulateSessionUpdate(_ session: CaptureSession?) {
        sessionPublisher.send(session)
    }

    /// Simulate detection completion
    func simulateDetectionComplete(sessionId: String, objects: [ServerDetectedObject]) {
        let session = CaptureSession(
            id: sessionId,
            userId: capturedUserId ?? "test-user",
            captureMode: capturedCaptureMode ?? .single,
            status: .detected,
            detectedObjects: objects
        )
        sessionPublisher.send(session)
    }

    /// Simulate detection failure
    func simulateDetectionFailed(sessionId: String, error: String) {
        let session = CaptureSession(
            id: sessionId,
            userId: capturedUserId ?? "test-user",
            captureMode: capturedCaptureMode ?? .single,
            status: .failed,
            error: error
        )
        sessionPublisher.send(session)
    }

    /// Reset all state for clean test setup
    func reset() {
        createSessionCallCount = 0
        addUploadedImageCallCount = 0
        markReadyForDetectionCallCount = 0
        getSessionCallCount = 0
        deleteSessionCallCount = 0
        observeSessionCallCount = 0

        capturedUserId = nil
        capturedCaptureMode = nil
        capturedExpectedImageCount = nil
        capturedSessionIds = []
        capturedImageUrls = []

        stubbedSessionId = "test-session-id"
        stubbedSession = nil
        errorToThrow = nil
        markReadyForDetectionError = nil

        sessionPublisher = PassthroughSubject<CaptureSession?, Never>()
    }
}
