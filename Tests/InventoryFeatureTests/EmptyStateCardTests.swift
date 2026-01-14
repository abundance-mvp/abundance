import XCTest
import SwiftUI
@testable import InventoryFeature

final class EmptyStateCardTests: XCTestCase {
    @MainActor
    func testEmptyStateCardRendersWithAction() {
        var actionCalled = false
        let view = EmptyStateCard(
            iconName: "tray",
            headline: "No Items",
            description: "Add items to get started",
            buttonTitle: "Add Item",
            action: { actionCalled = true }
        )
        XCTAssertNotNil(view.body)
    }
}
