import XCTest
import SwiftUI
@testable import Core

final class BrandAnimationsTests: XCTestCase {
    func testBrandSnappyAnimation() {
        let animation = Animation.brandSnappy
        XCTAssertNotNil(animation)
    }

    func testBrandBouncyAnimation() {
        let animation = Animation.brandBouncy
        XCTAssertNotNil(animation)
    }

    func testBrandGentleAnimation() {
        let animation = Animation.brandGentle
        XCTAssertNotNil(animation)
    }

    func testBrandDefaultAnimation() {
        let animation = Animation.brandDefault
        XCTAssertNotNil(animation)
    }
}
