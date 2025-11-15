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
}
