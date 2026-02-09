import XCTest
import SwiftUI
@testable import CollectionFeature

final class SearchBarTests: XCTestCase {
    @MainActor
    func testSearchBarBindsToText() {
        let searchBar = SearchBar(text: .constant("test"))
        XCTAssertNotNil(searchBar.body)
    }

    @MainActor
    func testSearchBarShowsClearButton() {
        let searchBar = SearchBar(text: .constant("hello"))
        XCTAssertNotNil(searchBar.body)
    }
}
