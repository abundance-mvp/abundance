import Foundation
import Combine
import AVFoundation
import CoreVideo
@testable import CameraFeature

/// Mock implementation of CameraServiceProtocol for testing
final class MockCameraService: CameraServiceProtocol, @unchecked Sendable {

    // MARK: - Published State

    private let sessionStateSubject = CurrentValueSubject<CameraSessionState, Never>(.notStarted)
    var sessionState: AnyPublisher<CameraSessionState, Never> {
        sessionStateSubject.eraseToAnyPublisher()
    }

    private let frameSubject = PassthroughSubject<CVPixelBuffer, Never>()
    var framePublisher: AnyPublisher<CVPixelBuffer, Never> {
        frameSubject.eraseToAnyPublisher()
    }

    // MARK: - Stubbed Values

    var stubbedPhotoData: Data?
    var stubbedAuthStatus: CameraAuthorizationStatus = .notDetermined
    var shouldFailStartSession: Bool = false
    var shouldFailCapturePhoto: Bool = false

    // MARK: - Tracking Calls

    var didCallStartSession: Bool = false
    var didCallStopSession: Bool = false
    var didCallCapturePhoto: Bool = false
    var didCallCheckAuthorization: Bool = false

    // MARK: - Protocol Methods

    func startSession() async throws {
        didCallStartSession = true

        if shouldFailStartSession {
            sessionStateSubject.send(.failed(CameraError.deviceNotAvailable))
            throw CameraError.deviceNotAvailable
        }

        sessionStateSubject.send(.configuring)
        await Task.yield()
        sessionStateSubject.send(.running)
    }

    func stopSession() async {
        didCallStopSession = true
        sessionStateSubject.send(.stopped)
    }

    func capturePhoto() async throws -> Data {
        didCallCapturePhoto = true

        if shouldFailCapturePhoto {
            throw CameraError.captureFailure
        }

        guard let photoData = stubbedPhotoData else {
            throw CameraError.invalidImageData
        }

        return photoData
    }

    func checkAuthorization() async -> CameraAuthorizationStatus {
        didCallCheckAuthorization = true
        return stubbedAuthStatus
    }

    func getCaptureSession() async -> AVCaptureSession? {
        return nil // Mock doesn't need real session
    }

    // MARK: - Helper Methods

    func reset() {
        sessionStateSubject.send(.notStarted)
        stubbedPhotoData = nil
        stubbedAuthStatus = .notDetermined
        shouldFailStartSession = false
        shouldFailCapturePhoto = false
        didCallStartSession = false
        didCallStopSession = false
        didCallCapturePhoto = false
        didCallCheckAuthorization = false
    }

    /// Helper method for testing frame processing
    func emitFrame(_ pixelBuffer: CVPixelBuffer) {
        frameSubject.send(pixelBuffer)
    }
}
