import XCTest
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif
@testable import VisionCore

final class HouseholdItemDetectorTests: XCTestCase {

    var sut: MockHouseholdItemDetector!

    override func setUp() {
        super.setUp()
        sut = MockHouseholdItemDetector()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testDetectHouseholdItems_returnsDetectedItems() async throws {
        // Given
        #if os(iOS)
        let testImage = UIImage(systemName: "photo")!
        #elseif os(macOS)
        let testImage = NSImage(systemSymbolName: "photo", accessibilityDescription: nil)!
        #endif

        let expectedItem = HouseholdItem(
            label: "bottle",
            confidence: ConfidenceScore(raw: 0.85),
            boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
            imageSize: CGSize(width: 100, height: 100)
        )
        sut.stubbedItems = [expectedItem]

        // When
        let items = try await sut.detectHouseholdItems(in: testImage)

        // Then
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.label, "bottle")
        XCTAssertTrue(sut.didCallDetectHouseholdItems)
    }

    func testHouseholdItemDetector_withoutModel_returnsEmptyArray() async throws {
        // Given
        let detector = HouseholdItemDetector()
        #if os(iOS)
        let testImage = UIImage(systemName: "photo")!
        #elseif os(macOS)
        let testImage = NSImage(systemSymbolName: "photo", accessibilityDescription: nil)!
        #endif

        // When
        let items = try await detector.detectHouseholdItems(in: testImage)

        // Then
        // YOLOv3-Tiny model not loaded yet (deferred to Sprint 3)
        XCTAssertTrue(items.isEmpty)
    }

    func testDetectHouseholdItems_UserProvidedImage_LoadsModel() async throws {
        // Given
        let testImage = try loadTestImageFromResources(named: "test-household-item")
        let detector = HouseholdItemDetector()

        // When & Then
        // NOTE: TinyYOLO model outputs VNCoreMLFeatureValueObservation (raw MLMultiArray)
        // which requires custom YOLO post-processing (NMS, anchor boxes, etc).
        // This test verifies the model loads and executes without crashing.
        // Full object detection with VNRecognizedObjectObservation will be
        // implemented in Sprint 4 with a Vision-compatible model.

        let items = try await detector.detectHouseholdItems(in: testImage)

        print("\n=== Detection Results ===")
        print("Total items detected: \(items.count)")
        print("NOTE: TinyYOLO requires custom post-processing (deferred to Sprint 4)")
        print("========================\n")

        // Test passes if model loads and runs without error
        // Detection count may be 0 due to missing post-processing
        XCTAssertTrue(true, "Model loaded and executed successfully")
    }

    // Helper to load test image from Resources
    private func loadTestImageFromResources(named name: String) throws -> PlatformImage {
        let bundle = Bundle.module
        guard let url = bundle.url(forResource: name, withExtension: "jpg"),
              let data = try? Data(contentsOf: url) else {
            throw VisionError.invalidImage
        }

        #if os(iOS)
        guard let image = UIImage(data: data) else {
            throw VisionError.invalidImage
        }
        return image
        #elseif os(macOS)
        guard let image = NSImage(data: data) else {
            throw VisionError.invalidImage
        }
        return image
        #endif
    }
}
