import XCTest
@preconcurrency import CoreVideo
@testable import CameraFeature
@testable import VisionCore
@testable import Persistence

@MainActor
final class CameraDetectionViewModelTests: XCTestCase, @unchecked Sendable {

    var sut: CameraDetectionViewModel!
    var mockDetector: MockHouseholdItemDetector!
    var mockQualityAssessor: MockImageQualityAssessor!
    var mockDeduplicator: MockObjectDeduplicator!
    var mockMaskGenerator: MockSubjectMaskGenerator!

    nonisolated override func setUp() {
        super.setUp()

        MainActor.assumeIsolated {
            mockDetector = MockHouseholdItemDetector()
            mockQualityAssessor = MockImageQualityAssessor()
            mockDeduplicator = MockObjectDeduplicator()
            mockMaskGenerator = MockSubjectMaskGenerator()

            sut = CameraDetectionViewModel(
                yoloDetector: mockDetector,
                qualityAssessor: mockQualityAssessor,
                deduplicator: mockDeduplicator,
                maskGenerator: mockMaskGenerator,
                storageService: nil,
                itemService: nil
            )
        }
    }

    nonisolated override func tearDown() {
        MainActor.assumeIsolated {
            sut = nil
            mockDetector = nil
            mockQualityAssessor = nil
            mockDeduplicator = nil
            mockMaskGenerator = nil
        }
        super.tearDown()
    }

    // MARK: - Frame Processing Tests

    func testProcessFrame_withYOLOResults_createsDetectedObjects() async throws {
        // Given
        let pixelBuffer = try createTestPixelBuffer()
        let yoloResult = YOLOResult(
            label: "bottle",
            confidence: 0.85,
            boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
        )
        mockDetector.stubbedYOLOResults = [yoloResult]
        await mockQualityAssessor.setStubbedScore(0.75)
        await mockDeduplicator.setStubbedSimilar(false)

        // When
        await sut.processFrame(pixelBuffer)

        // Then
        XCTAssertEqual(sut.detectedObjects.count, 1)
        XCTAssertEqual(sut.detectedObjects.first?.label, "bottle")
        XCTAssertEqual(sut.detectedObjects.first?.confidence, 0.85)
    }

    func testProcessFrame_withMultipleObjects_processesInParallel() async throws {
        // Given
        let pixelBuffer = try createTestPixelBuffer()
        let results = [
            YOLOResult(label: "bottle", confidence: 0.85, boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.3)),
            YOLOResult(label: "cup", confidence: 0.78, boundingBox: CGRect(x: 0.5, y: 0.5, width: 0.3, height: 0.4)),
            YOLOResult(label: "laptop", confidence: 0.92, boundingBox: CGRect(x: 0.2, y: 0.6, width: 0.4, height: 0.3))
        ]
        mockDetector.stubbedYOLOResults = results
        await mockQualityAssessor.setStubbedScore(0.75)
        await mockDeduplicator.setStubbedSimilar(false)

        // When
        await sut.processFrame(pixelBuffer)

        // Then
        XCTAssertEqual(sut.detectedObjects.count, 3)
        XCTAssertTrue(mockDetector.didCallDetectInStream)
    }

    func testProcessFrame_withDuplicateObject_filtersOut() async throws {
        // Given
        let pixelBuffer = try createTestPixelBuffer()
        let yoloResult = YOLOResult(
            label: "bottle",
            confidence: 0.85,
            boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
        )
        mockDetector.stubbedYOLOResults = [yoloResult]
        await mockDeduplicator.setStubbedSimilar(true) // Mark as duplicate

        // When
        await sut.processFrame(pixelBuffer)

        // Then
        XCTAssertEqual(sut.detectedObjects.count, 0, "Duplicate objects should be filtered out")
    }

    // MARK: - Catalog Mode Determination Tests

    func testCatalogMode_highConfidenceHighQuality_isAutomatic() async throws {
        // Given
        let pixelBuffer = try createTestPixelBuffer()
        let yoloResult = YOLOResult(
            label: "laptop",
            confidence: 0.92, // > 0.70 (automatic threshold)
            boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.3)
        )
        mockDetector.stubbedYOLOResults = [yoloResult]
        await mockQualityAssessor.setStubbedScore(0.85) // > 0.65 (quality threshold)
        await mockDeduplicator.setStubbedSimilar(false)

        // When
        await sut.processFrame(pixelBuffer)

        // Then
        XCTAssertEqual(sut.detectedObjects.count, 1)
        XCTAssertEqual(sut.detectedObjects.first?.catalogMode, .automatic)
    }

    func testCatalogMode_mediumConfidenceOrLowQuality_isManual() async throws {
        // Given
        let pixelBuffer = try createTestPixelBuffer()
        let yoloResult = YOLOResult(
            label: "chair",
            confidence: 0.89, // > 0.70 but quality is low
            boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.3)
        )
        mockDetector.stubbedYOLOResults = [yoloResult]
        await mockQualityAssessor.setStubbedScore(0.55) // < 0.65 (quality threshold)
        await mockDeduplicator.setStubbedSimilar(false)

        // When
        await sut.processFrame(pixelBuffer)

        // Then
        XCTAssertEqual(sut.detectedObjects.count, 1)
        XCTAssertEqual(sut.detectedObjects.first?.catalogMode, .manual)
    }

    func testCatalogMode_lowConfidence_isIgnored() async throws {
        // Given
        let pixelBuffer = try createTestPixelBuffer()
        let yoloResult = YOLOResult(
            label: "unknown",
            confidence: 0.35, // < 0.40 (manual threshold)
            boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.3)
        )
        mockDetector.stubbedYOLOResults = [yoloResult]
        await mockQualityAssessor.setStubbedScore(0.70) // Quality doesn't matter
        await mockDeduplicator.setStubbedSimilar(false)

        // When
        await sut.processFrame(pixelBuffer)

        // Then
        XCTAssertEqual(sut.detectedObjects.count, 0, "Low confidence objects should be ignored")
    }

    // MARK: - Boundary Condition Tests

    func testCatalogMode_atAutomaticConfidenceThreshold_withHighQuality_isAutomatic() async throws {
        // Given: Exactly at automatic threshold (0.70) with high quality
        let pixelBuffer = try createTestPixelBuffer()
        let yoloResult = YOLOResult(
            label: "backpack",
            confidence: 0.70, // Exactly at automatic confidence threshold
            boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.3)
        )
        mockDetector.stubbedYOLOResults = [yoloResult]
        await mockQualityAssessor.setStubbedScore(0.80) // > 0.65 (quality threshold)
        await mockDeduplicator.setStubbedSimilar(false)

        // When
        await sut.processFrame(pixelBuffer)

        // Then
        XCTAssertEqual(sut.detectedObjects.count, 1)
        XCTAssertEqual(sut.detectedObjects.first?.catalogMode, .automatic)
    }

    func testCatalogMode_atQualityThreshold_withHighConfidence_isAutomatic() async throws {
        // Given: High confidence with exactly at quality threshold (0.65)
        let pixelBuffer = try createTestPixelBuffer()
        let yoloResult = YOLOResult(
            label: "tent",
            confidence: 0.85, // > 0.70 (automatic confidence threshold)
            boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.3)
        )
        mockDetector.stubbedYOLOResults = [yoloResult]
        await mockQualityAssessor.setStubbedScore(0.65) // Exactly at quality threshold
        await mockDeduplicator.setStubbedSimilar(false)

        // When
        await sut.processFrame(pixelBuffer)

        // Then
        XCTAssertEqual(sut.detectedObjects.count, 1)
        XCTAssertEqual(sut.detectedObjects.first?.catalogMode, .automatic)
    }

    func testCatalogMode_atManualConfidenceThreshold_isManual() async throws {
        // Given: Exactly at manual threshold (0.40)
        let pixelBuffer = try createTestPixelBuffer()
        let yoloResult = YOLOResult(
            label: "cup",
            confidence: 0.40, // Exactly at manual confidence threshold
            boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.3)
        )
        mockDetector.stubbedYOLOResults = [yoloResult]
        await mockQualityAssessor.setStubbedScore(0.70) // High quality doesn't matter
        await mockDeduplicator.setStubbedSimilar(false)

        // When
        await sut.processFrame(pixelBuffer)

        // Then
        XCTAssertEqual(sut.detectedObjects.count, 1)
        XCTAssertEqual(sut.detectedObjects.first?.catalogMode, .manual)
    }

    func testCatalogMode_justBelowManualThreshold_isIgnored() async throws {
        // Given: Just below manual threshold (0.40)
        let pixelBuffer = try createTestPixelBuffer()
        let yoloResult = YOLOResult(
            label: "unknown",
            confidence: 0.39, // Just below manual threshold
            boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.3)
        )
        mockDetector.stubbedYOLOResults = [yoloResult]
        await mockQualityAssessor.setStubbedScore(0.90) // Quality doesn't matter
        await mockDeduplicator.setStubbedSimilar(false)

        // When
        await sut.processFrame(pixelBuffer)

        // Then
        XCTAssertEqual(sut.detectedObjects.count, 0, "Objects below manual threshold should be ignored")
    }

    func testCatalogMode_justBelowAutomaticThreshold_isManual() async throws {
        // Given: Just below automatic confidence threshold (0.70) with high quality
        let pixelBuffer = try createTestPixelBuffer()
        let yoloResult = YOLOResult(
            label: "bottle",
            confidence: 0.69, // Just below automatic threshold
            boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.3)
        )
        mockDetector.stubbedYOLOResults = [yoloResult]
        await mockQualityAssessor.setStubbedScore(0.80) // High quality
        await mockDeduplicator.setStubbedSimilar(false)

        // When
        await sut.processFrame(pixelBuffer)

        // Then
        XCTAssertEqual(sut.detectedObjects.count, 1)
        XCTAssertEqual(sut.detectedObjects.first?.catalogMode, .manual)
    }

    func testCatalogMode_highConfidence_justBelowQualityThreshold_isManual() async throws {
        // Given: High confidence but just below quality threshold (0.65)
        let pixelBuffer = try createTestPixelBuffer()
        let yoloResult = YOLOResult(
            label: "chair",
            confidence: 0.85, // > 0.70 (automatic confidence threshold)
            boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.3)
        )
        mockDetector.stubbedYOLOResults = [yoloResult]
        await mockQualityAssessor.setStubbedScore(0.64) // Just below quality threshold
        await mockDeduplicator.setStubbedSimilar(false)

        // When
        await sut.processFrame(pixelBuffer)

        // Then
        XCTAssertEqual(sut.detectedObjects.count, 1)
        XCTAssertEqual(sut.detectedObjects.first?.catalogMode, .manual)
    }

    // MARK: - Double-Tap Handler Tests

    func testHandleDoubleTap_onDetectedObject_changesCatalogMode() async throws {
        // Given
        let object = DetectedObject(
            label: "bottle",
            confidence: 0.85,
            boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
            qualityScore: 0.75,
            catalogMode: .manual,
            fingerprint: "test-123"
        )
        sut.addObject(object)

        // When
        let tapLocation = CGPoint(x: 0.25, y: 0.35) // Inside bounding box
        await sut.handleDoubleTap(at: tapLocation)

        // Then
        XCTAssertEqual(sut.detectedObjects.first?.catalogMode, .automatic)
    }

    func testHandleDoubleTap_outsideBounds_doesNothing() async throws {
        // Given
        let object = DetectedObject(
            label: "bottle",
            confidence: 0.85,
            boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
            qualityScore: 0.75,
            catalogMode: .automatic,
            fingerprint: "test-123"
        )
        sut.addObject(object)

        // When
        let tapLocation = CGPoint(x: 0.9, y: 0.9) // Outside bounding box
        await sut.handleDoubleTap(at: tapLocation)

        // Then
        XCTAssertEqual(sut.detectedObjects.first?.catalogMode, .automatic, "Should not change")
    }

    // MARK: - Deduplication Integration Tests

    func testDeduplication_cachesFingerprint() async throws {
        // Given
        let pixelBuffer = try createTestPixelBuffer()
        let yoloResult = YOLOResult(
            label: "bottle",
            confidence: 0.85,
            boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
        )
        mockDetector.stubbedYOLOResults = [yoloResult]
        await mockQualityAssessor.setStubbedScore(0.75)
        await mockDeduplicator.setStubbedSimilar(false)

        // When
        await sut.processFrame(pixelBuffer)

        // Then
        let didCache = await mockDeduplicator.didCallAddToCache
        XCTAssertTrue(didCache, "Fingerprint should be cached")
    }

    // MARK: - Error Handling Tests

    func testProcessFrame_withYOLOError_returnsEmptyArray() async throws {
        // Given
        let pixelBuffer = try createTestPixelBuffer()
        mockDetector.shouldFail = true

        // When
        await sut.processFrame(pixelBuffer)

        // Then
        XCTAssertEqual(sut.detectedObjects.count, 0)
    }

    // MARK: - Helper Methods

    private func createTestPixelBuffer() throws -> CVPixelBuffer {
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            640,
            480,
            kCVPixelFormatType_32BGRA,
            [
                kCVPixelBufferCGImageCompatibilityKey: true,
                kCVPixelBufferCGBitmapContextCompatibilityKey: true
            ] as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            throw VisionError.invalidImage
        }

        return buffer
    }
}

// MARK: - Mock Helper Extensions

extension MockImageQualityAssessor {
    func setStubbedScore(_ score: Double) async {
        stubbedQualityScore = score
    }
}

extension MockObjectDeduplicator {
    func setStubbedSimilar(_ similar: Bool) async {
        stubbedIsSimilar = similar
    }
}
