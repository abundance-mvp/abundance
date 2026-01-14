import XCTest
import SwiftUI
@testable import Core

final class BrandColorsTests: XCTestCase {
    func testMintGreenColor() {
        let mintGreen = Color.brandMintGreen
        XCTAssertNotNil(mintGreen)
    }

    func testBrightBlueColor() {
        let brightBlue = Color.brandBrightBlue
        XCTAssertNotNil(brightBlue)
    }

    func testCoralOrangeColor() {
        let coralOrange = Color.brandCoralOrange
        XCTAssertNotNil(coralOrange)
    }

    func testBackgroundDefaultColor() {
        let background = Color.backgroundDefault
        XCTAssertNotNil(background)
    }
}
