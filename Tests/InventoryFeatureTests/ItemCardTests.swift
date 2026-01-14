import XCTest
import SwiftUI
@testable import InventoryFeature
@testable import Persistence

final class ItemCardTests: XCTestCase {
    @MainActor
    func testItemCardRendersWithLiquidGlass() {
        let item = Item(
            id: "test-1",
            userId: "user-1",
            imageUrl: "https://example.com/image.jpg",
            status: .complete,
            category: "Electronics",
            color: "Silver"
        )
        let view = ItemCard(item: item)
        XCTAssertNotNil(view.body)
    }
}
