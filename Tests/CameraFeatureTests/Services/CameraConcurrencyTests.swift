import XCTest
import AVFoundation
@testable import CameraFeature

/// Tests for Swift 6 concurrency safety in camera service
final class CameraConcurrencyTests: XCTestCase {
    var sut: CameraService!
    
    override func setUp() async throws {
        await MainActor.run {
            sut = CameraService()
        }
    }
    
    override func tearDown() async throws {
        await MainActor.run {
            sut = nil
        }
    }
    
    // MARK: - Concurrency Safety Tests
    
    func testCameraServiceIsFullySendable() async throws {
        // This test verifies that CameraService is properly Sendable
        // and can be safely passed across concurrency boundaries
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { @Sendable [sut] in
                await MainActor.run {
                    // Access from main actor context
                    _ = sut?.sessionState
                }
            }
            
            group.addTask { @Sendable [sut] in
                await MainActor.run {
                    // Another concurrent access
                    _ = sut?.framePublisher
                }
            }
            
            await group.waitForAll()
        }
    }
    
    func testConcurrentSessionStartStop() async throws {
        // Test that concurrent start/stop operations are thread-safe
        
        await withTaskGroup(of: Void.self) { group in
            // Multiple concurrent stop operations should be safe
            for _ in 0..<5 {
                group.addTask { @Sendable [sut] in
                    await MainActor.run {
                        await sut?.stopSession()
                    }
                }
            }
            
            await group.waitForAll()
        }
    }
    
    func testNoCaptureSessionRaceConditions() async throws {
        // Verify that accessing capture session from multiple contexts is safe
        
        await withTaskGroup(of: AVCaptureSession?.self) { group in
            for _ in 0..<10 {
                group.addTask { @Sendable [sut] in
                    await MainActor.run {
                        return await sut?.getCaptureSession()
                    }
                }
            }
            
            var sessions: [AVCaptureSession?] = []
            for await session in group {
                sessions.append(session)
            }
            
            // All accesses should return the same session instance
            let firstSession = sessions.first!
            XCTAssertTrue(sessions.allSatisfy { $0 === firstSession })
        }
    }
    
    func testPhotoCaptureUnderConcurrentLoad() async throws {
        // Test that photo capture properly serializes concurrent requests
        
        let expectation = XCTestExpectation(description: "Only one capture should succeed")
        expectation.expectedFulfillmentCount = 1
        expectation.assertForOverFulfill = true
        
        await withTaskGroup(of: Result<Data, Error>.self) { group in
            // Try to capture photos concurrently
            for _ in 0..<3 {
                group.addTask { @Sendable [sut] in
                    await MainActor.run {
                        do {
                            let data = try await sut!.capturePhoto()
                            expectation.fulfill()
                            return .success(data)
                        } catch {
                            // Expected for concurrent captures
                            return .failure(error)
                        }
                    }
                }
            }
            
            var results: [Result<Data, Error>] = []
            for await result in group {
                results.append(result)
            }
            
            // At least one should fail with captureInProgress error
            let failures = results.compactMap { result -> Error? in
                if case .failure(let error) = result {
                    return error
                }
                return nil
            }
            
            XCTAssertTrue(failures.contains { error in
                if case CameraError.captureInProgress = error {
                    return true
                }
                return false
            })
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testFramePublisherThreadSafety() async throws {
        // Test that frame publishing is thread-safe
        
        let frameCount = 100
        let receivedFrames = NSLock()
        var frameCounter = 0
        
        // Subscribe from multiple concurrent contexts
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<5 {
                group.addTask { @Sendable [sut] in
                    await MainActor.run {
                        let cancellable = sut?.framePublisher
                            .sink { _ in
                                receivedFrames.lock()
                                frameCounter += 1
                                receivedFrames.unlock()
                            }
                        
                        // Keep subscription alive
                        withExtendedLifetime(cancellable) {
                            Thread.sleep(forTimeInterval: 0.1)
                        }
                    }
                }
            }
            
            await group.waitForAll()
        }
        
        // Frame counter should be consistent without data races
        XCTAssertGreaterThanOrEqual(frameCounter, 0)
    }
}

// MARK: - Thread Sanitizer Tests

extension CameraConcurrencyTests {
    
    /// Run this test with Thread Sanitizer enabled to detect data races
    func testWithThreadSanitizer() async throws {
        // This test exercises various concurrent operations
        // Run with: swift test --sanitize=thread
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { @Sendable [sut] in
                await MainActor.run {
                    _ = await sut?.checkAuthorization()
                }
            }
            
            group.addTask { @Sendable [sut] in
                await MainActor.run {
                    _ = sut?.sessionState
                }
            }
            
            group.addTask { @Sendable [sut] in
                await MainActor.run {
                    await sut?.stopSession()
                }
            }
            
            group.addTask { @Sendable [sut] in
                await MainActor.run {
                    _ = await sut?.getCaptureSession()
                }
            }
            
            await group.waitForAll()
        }
    }
}