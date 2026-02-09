import XCTest
import SwiftUI
@testable import CollectionFeature

final class FloatingTabBarTests: XCTestCase {
    @MainActor
    func testFloatingTabBarSelectionBinding() {
        let tabBar = FloatingTabBar(selection: .constant(0), items: [
            FloatingTabBar.TabItem(icon: "house", title: "Home"),
            FloatingTabBar.TabItem(icon: "camera", title: "Camera"),
            FloatingTabBar.TabItem(icon: "person", title: "Profile")
        ])
        XCTAssertNotNil(tabBar.body)
    }
}
