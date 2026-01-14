// AppLoggerTests.swift
// Tests for AppLogger framework
//
// Created: 2025-11-16
// References: TEST-STRATEGY-001 (80% coverage target)

import XCTest
@testable import Abundance

/// Tests for AppLogger event generation and metadata
class AppLoggerTests: XCTestCase {

    // MARK: - Event Message Generation

    func testButtonTappedEventMessage() {
        // Given
        let event = LogEvent.buttonTapped(button: "Submit", screen: "LoginView", context: [:])

        // Then
        XCTAssertEqual(event.message, "Button tapped: Submit on LoginView")
        XCTAssertEqual(event.category, "ui")
        XCTAssertEqual(event.severity, .info)
    }

    func testButtonUnresponsiveEventMessage() {
        // Given
        let event = LogEvent.buttonUnresponsive(button: "Catalog", screen: "HomeView", reason: "Not authenticated")

        // Then
        XCTAssertEqual(event.message, "Button unresponsive: Catalog on HomeView - Not authenticated")
        XCTAssertEqual(event.category, "ui")
        XCTAssertEqual(event.severity, .error)
    }

    func testDataLoadedEventMessage() {
        // Given
        let event = LogEvent.dataLoaded(type: "CatalogItem", count: 10, duration: 0.5)

        // Then
        XCTAssertEqual(event.message, "Data loaded: CatalogItem (10 items)")
        XCTAssertEqual(event.category, "data")
        XCTAssertEqual(event.severity, .info)
    }

    func testFirestoreQueryEventMessage() {
        // Given
        let event = LogEvent.firestoreQueryCompleted(collection: "items", resultCount: 5, duration: 0.3)

        // Then
        XCTAssertEqual(event.message, "Firestore query completed: items (5 results)")
        XCTAssertEqual(event.category, "firebase")
        XCTAssertEqual(event.severity, .info)
    }

    // MARK: - Spec Violation

    func testSpecViolationCriticalSeverity() {
        // Given
        let event = LogEvent.specViolation(
            spec: "mvp-vision-features",
            section: "Processing Time",
            expected: "< 6 seconds",
            actual: "8.2 seconds",
            severity: .critical
        )

        // Then
        XCTAssertEqual(event.message, "SPEC VIOLATION: mvp-vision-features § Processing Time - Expected: < 6 seconds, Actual: 8.2 seconds")
        XCTAssertEqual(event.category, "spec-violation")
        XCTAssertEqual(event.severity, .fault)  // Critical maps to .fault
    }

    func testSpecViolationMediumSeverity() {
        // Given
        let event = LogEvent.specViolation(
            spec: "test-spec",
            section: "Load Time",
            expected: "< 2s",
            actual: "3s",
            severity: .medium
        )

        // Then
        XCTAssertEqual(event.severity, .error)  // Medium maps to .error
    }

    // MARK: - Silent Failure

    func testSilentFailureEventMessage() {
        // Given
        let event = LogEvent.silentFailure(
            feature: "Navigation",
            expectedBehavior: "Navigate to detail view",
            actualBehavior: "Tap has no effect",
            reproSteps: ["Open app", "Tap item"]
        )

        // Then
        XCTAssertEqual(event.message, "SILENT FAILURE: Navigation - Expected: Navigate to detail view, Actual: Tap has no effect")
        XCTAssertEqual(event.category, "silent-failure")
        XCTAssertEqual(event.severity, .error)
    }

    // MARK: - Metadata Extraction

    func testButtonTappedMetadata() {
        // Given
        let context = ["userId": "user123", "sessionId": "session456"]
        let event = LogEvent.buttonTapped(button: "Login", screen: "LoginView", context: context)

        // When
        let metadata = event.metadata

        // Then
        XCTAssertEqual(metadata["button"] as? String, "Login")
        XCTAssertEqual(metadata["screen"] as? String, "LoginView")
        XCTAssertEqual(metadata["userId"] as? String, "user123")
        XCTAssertEqual(metadata["sessionId"] as? String, "session456")
        XCTAssertNotNil(metadata["timestamp"])
    }

    func testPerformanceMetricMetadata() {
        // Given
        let metadata = ["operation": "imageProcessing", "imageSize": 1024000]
        let event = LogEvent.performanceMetric(operation: "imageProcessing", duration: 1500, metadata: metadata)

        // When
        let eventMetadata = event.metadata

        // Then
        XCTAssertEqual(eventMetadata["operation"] as? String, "imageProcessing")
        XCTAssertEqual(eventMetadata["duration"] as? Double, 1500)
        XCTAssertEqual(eventMetadata["imageSize"] as? Int, 1024000)
    }

    // MARK: - Performance Measurement

    func testMeasureBlockReturnsResult() {
        // When
        let result = AppLogger.measure("testOperation") {
            return 42
        }

        // Then
        XCTAssertEqual(result, 42)
    }

    func testMeasureBlockExecutes() {
        // Given
        var executed = false

        // When
        _ = AppLogger.measure("testOperation") {
            executed = true
            return "done"
        }

        // Then
        XCTAssertTrue(executed)
    }

    func testMeasureAsyncBlockCompletion() async {
        // When
        let result = await AppLogger.measureAsync("asyncOperation") {
            return "success"
        }

        // Then
        XCTAssertEqual(result, "success")
    }

    func testMeasureAsyncBlockExecutes() async {
        // Given
        var executed = false

        // When
        _ = await AppLogger.measureAsync("asyncOperation") {
            executed = true
            return true
        }

        // Then
        XCTAssertTrue(executed)
    }

    // MARK: - Category Classification

    func testEventCategoryMapping() {
        // UI events
        XCTAssertEqual(LogEvent.buttonTapped(button: "", screen: "").category, "ui")
        XCTAssertEqual(LogEvent.screenAppeared(screen: "").category, "ui")

        // Data events
        XCTAssertEqual(LogEvent.dataLoaded(type: "", count: 0, duration: 0).category, "data")
        XCTAssertEqual(LogEvent.dataMissing(expected: "", context: "").category, "data")

        // Firebase events
        XCTAssertEqual(LogEvent.firestoreQueryStarted(collection: "", filter: "").category, "firebase")

        // AI pipeline events
        XCTAssertEqual(LogEvent.visionDetectionStarted(imageSize: 0).category, "ai-pipeline")
        XCTAssertEqual(LogEvent.barcodeDetected(type: "", value: "").category, "ai-pipeline")

        // Auth events
        XCTAssertEqual(LogEvent.authSignInStarted(provider: "").category, "auth")

        // Performance events
        XCTAssertEqual(LogEvent.performanceMetric(operation: "", duration: 0).category, "performance")

        // Special events
        XCTAssertEqual(LogEvent.specViolation(spec: "", section: "", expected: "", actual: "", severity: .low).category, "spec-violation")
        XCTAssertEqual(LogEvent.silentFailure(feature: "", expectedBehavior: "", actualBehavior: "", reproSteps: []).category, "silent-failure")
    }
}
