import XCTest
import SwiftUI
@testable import Core

final class BrandColorsTests: XCTestCase {
    func testSalmonColor() {
        let color = Color.salmon
        XCTAssertNotNil(color)
    }

    func testPeachColor() {
        let color = Color.peach
        XCTAssertNotNil(color)
    }

    func testCreamColor() {
        let color = Color.cream
        XCTAssertNotNil(color)
    }

    func testDeepPlumColor() {
        let color = Color.deepPlum
        XCTAssertNotNil(color)
    }

    func testWarmWhiteColor() {
        let color = Color.warmWhite
        XCTAssertNotNil(color)
    }

    func testSoftTealColor() {
        let color = Color.softTeal
        XCTAssertNotNil(color)
    }

    func testMutedSageColor() {
        let color = Color.mutedSage
        XCTAssertNotNil(color)
    }

    func testSemanticAliases() {
        XCTAssertNotNil(Color.accentPrimary)
        XCTAssertNotNil(Color.accentSecondary)
        XCTAssertNotNil(Color.textPrimary)
        XCTAssertNotNil(Color.successColor)
        XCTAssertNotNil(Color.errorColor)
        XCTAssertNotNil(Color.backgroundDefault)
    }

    func testBehindGlassVariants() {
        XCTAssertNotNil(Color.salmonBehindGlass)
        XCTAssertNotNil(Color.peachBehindGlass)
        XCTAssertNotNil(Color.tealBehindGlass)
    }

    func testHighContrastVariants() {
        XCTAssertNotNil(Color.salmonHighContrast)
        XCTAssertNotNil(Color.deepPlumHighContrast)
    }
}
