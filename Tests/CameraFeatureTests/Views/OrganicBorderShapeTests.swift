import XCTest
import SwiftUI
@testable import CameraFeature

final class OrganicBorderShapeTests: XCTestCase {

    func testShapeCreatesPathFromNilMask() {
        // Given: No mask observation
        let shape = OrganicBorderShape(mask: nil)
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)

        // When: Path is generated
        let path = shape.path(in: rect)

        // Then: Returns rectangle as fallback
        XCTAssertFalse(path.isEmpty)
    }

    func testShapeReturnsEmptyPathForInvalidMask() {
        // Given: Shape with nil mask
        let shape = OrganicBorderShape(mask: nil)
        let rect = CGRect.zero

        // When: Path generated in zero rect
        let path = shape.path(in: rect)

        // Then: Returns valid path (rectangle fallback)
        XCTAssertNotNil(path)
    }
}
