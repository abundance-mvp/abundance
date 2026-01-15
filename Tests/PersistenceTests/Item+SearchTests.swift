// Tests/PersistenceTests/Item+SearchTests.swift

import Testing
import Foundation
@testable import Persistence

// swiftlint:disable explicit_type_interface

@Suite("Item Search Tests")
struct ItemSearchTests {

    // MARK: - Test Fixtures

    /// Create a test item with all searchable fields populated
    private func makeTestItem(
        name: String? = nil,
        category: String? = nil,
        subCategory: String? = nil,
        brand: String? = nil,
        model: String? = nil,
        color: String? = nil,
        material: String? = nil,
        condition: ItemCondition? = nil
    ) -> Item {
        Item(
            id: "test-\(UUID().uuidString)",
            userId: "test-user",
            imageUrl: "https://example.com/image.jpg",
            status: .complete,
            name: name,
            category: category,
            subCategory: subCategory,
            brand: brand,
            model: model,
            color: color,
            material: material,
            condition: condition
        )
    }

    // MARK: - Empty Query Tests

    @Test("Empty search query matches all items")
    func testEmptyQueryMatchesAll() {
        let item = makeTestItem(category: "Electronics", color: "Blue")
        #expect(item.matchesSearchQuery("") == true)
    }

    @Test("Whitespace-only query does not match items without whitespace")
    func testWhitespaceQueryBehavior() {
        let item = makeTestItem(category: "Electronics")
        // Whitespace-only query is treated as non-empty, so it searches for whitespace
        #expect(item.matchesSearchQuery("   ") == false)
    }

    // MARK: - Field-Specific Search Tests

    @Test("Search finds match in name field")
    func testSearchMatchesName() {
        let item = makeTestItem(name: "Coleman Sundome Tent")
        #expect(item.matchesSearchQuery("coleman") == true)
        #expect(item.matchesSearchQuery("SUNDOME") == true)
        #expect(item.matchesSearchQuery("tent") == true)
    }

    @Test("Search finds match in category field")
    func testSearchMatchesCategory() {
        let item = makeTestItem(category: "Electronics")
        #expect(item.matchesSearchQuery("electronics") == true)
        #expect(item.matchesSearchQuery("ELECTRONICS") == true)
        #expect(item.matchesSearchQuery("elec") == true) // Partial match
    }

    @Test("Search finds match in subCategory field")
    func testSearchMatchesSubCategory() {
        let item = makeTestItem(subCategory: "Portable Speakers")
        #expect(item.matchesSearchQuery("portable") == true)
        #expect(item.matchesSearchQuery("speakers") == true)
    }

    @Test("Search finds match in brand field")
    func testSearchMatchesBrand() {
        let item = makeTestItem(brand: "Apple")
        #expect(item.matchesSearchQuery("apple") == true)
        #expect(item.matchesSearchQuery("APPLE") == true)
    }

    @Test("Search finds match in model field")
    func testSearchMatchesModel() {
        let item = makeTestItem(model: "iPhone 15 Pro")
        #expect(item.matchesSearchQuery("iphone") == true)
        #expect(item.matchesSearchQuery("15 pro") == true)
    }

    @Test("Search finds match in color field")
    func testSearchMatchesColor() {
        let item = makeTestItem(color: "Midnight Blue")
        #expect(item.matchesSearchQuery("midnight") == true)
        #expect(item.matchesSearchQuery("blue") == true)
        #expect(item.matchesSearchQuery("BLUE") == true) // Case insensitive
    }

    @Test("Search finds match in material field")
    func testSearchMatchesMaterial() {
        let item = makeTestItem(material: "Stainless Steel")
        #expect(item.matchesSearchQuery("stainless") == true)
        #expect(item.matchesSearchQuery("steel") == true)
        #expect(item.matchesSearchQuery("STAINLESS") == true)
    }

    @Test("Search finds match in condition field")
    func testSearchMatchesCondition() {
        let item = makeTestItem(condition: .likeNew)
        #expect(item.matchesSearchQuery("like") == true)
        #expect(item.matchesSearchQuery("new") == true)
        #expect(item.matchesSearchQuery("LIKE NEW") == true)
    }

    // MARK: - No Match Tests

    @Test("Search returns false when no fields match")
    func testSearchNoMatch() {
        let item = makeTestItem(
            category: "Electronics",
            color: "Black",
            material: "Plastic"
        )
        #expect(item.matchesSearchQuery("refrigerator") == false)
        #expect(item.matchesSearchQuery("xyz123") == false)
    }

    @Test("Search handles nil fields gracefully")
    func testSearchHandlesNilFields() {
        let item = makeTestItem() // All searchable fields are nil
        #expect(item.matchesSearchQuery("anything") == false)
    }

    // MARK: - Cross-Field Tests

    @Test("Search matches across any single field")
    func testSearchMatchesAnyField() {
        // Item with only name populated
        let nameOnlyItem = makeTestItem(name: "Sony Camera")
        #expect(nameOnlyItem.matchesSearchQuery("sony") == true)

        // Item with only category populated
        let categoryOnlyItem = makeTestItem(category: "Furniture")
        #expect(categoryOnlyItem.matchesSearchQuery("furniture") == true)

        // Item with only color populated
        let colorOnlyItem = makeTestItem(color: "Red")
        #expect(colorOnlyItem.matchesSearchQuery("red") == true)

        // Item with only material populated
        let materialOnlyItem = makeTestItem(material: "Wood")
        #expect(materialOnlyItem.matchesSearchQuery("wood") == true)

        // Item with only condition populated
        let conditionOnlyItem = makeTestItem(condition: .good)
        #expect(conditionOnlyItem.matchesSearchQuery("good") == true)
    }

    // MARK: - Case Sensitivity Tests

    @Test("Search is case insensitive for all fields")
    func testCaseInsensitiveSearch() {
        let item = makeTestItem(
            category: "Kitchen Appliances",
            color: "Space Gray",
            material: "Aluminum"
        )

        // Lowercase
        #expect(item.matchesSearchQuery("kitchen") == true)
        #expect(item.matchesSearchQuery("space gray") == true)
        #expect(item.matchesSearchQuery("aluminum") == true)

        // Uppercase
        #expect(item.matchesSearchQuery("KITCHEN") == true)
        #expect(item.matchesSearchQuery("SPACE GRAY") == true)

        // Mixed case
        #expect(item.matchesSearchQuery("Kitchen") == true)
        #expect(item.matchesSearchQuery("SpAcE GrAy") == true)
    }

    // MARK: - Partial Match Tests

    @Test("Search matches partial strings (substring)")
    func testPartialMatch() {
        let item = makeTestItem(
            category: "Professional Camera Equipment",
            material: "Carbon Fiber"
        )

        #expect(item.matchesSearchQuery("prof") == true)
        #expect(item.matchesSearchQuery("camera") == true)
        #expect(item.matchesSearchQuery("equipment") == true)
        #expect(item.matchesSearchQuery("carbon") == true)
        #expect(item.matchesSearchQuery("fiber") == true)
    }

    // MARK: - Multiple Fields Match Tests

    @Test("Search returns true if query matches any of multiple fields")
    func testMultipleFieldsPopulated() {
        let item = makeTestItem(
            name: "MacBook Pro",
            category: "Electronics",
            brand: "Apple",
            color: "Silver",
            material: "Aluminum",
            condition: .good
        )

        // Each field should match independently
        #expect(item.matchesSearchQuery("macbook") == true)
        #expect(item.matchesSearchQuery("electronics") == true)
        #expect(item.matchesSearchQuery("apple") == true)
        #expect(item.matchesSearchQuery("silver") == true)
        #expect(item.matchesSearchQuery("aluminum") == true)
        #expect(item.matchesSearchQuery("good") == true)
    }

    // MARK: - Searchable Fields Documentation Test

    @Test("searchableFieldNames contains expected fields")
    func testSearchableFieldNames() {
        let fieldNames: [String] = Item.searchableFieldNames

        #expect(fieldNames.contains("name"))
        #expect(fieldNames.contains("category"))
        #expect(fieldNames.contains("subCategory"))
        #expect(fieldNames.contains("brand"))
        #expect(fieldNames.contains("model"))
        #expect(fieldNames.contains("color"))
        #expect(fieldNames.contains("material"))
        #expect(fieldNames.contains("condition"))
        #expect(fieldNames.count == 8)
    }

    // MARK: - Edge Cases

    @Test("Search with special characters")
    func testSearchSpecialCharacters() {
        let item = makeTestItem(category: "TV & Electronics")
        #expect(item.matchesSearchQuery("tv") == true)
        #expect(item.matchesSearchQuery("&") == true)
        #expect(item.matchesSearchQuery("tv &") == true)
    }

    @Test("Search with numbers in fields")
    func testSearchWithNumbers() {
        let item = makeTestItem(
            category: "Electronics 2024",
            material: "Grade 5 Titanium"
        )
        #expect(item.matchesSearchQuery("2024") == true)
        #expect(item.matchesSearchQuery("grade 5") == true)
    }

    @Test("Search with unicode characters")
    func testSearchUnicode() {
        let item = makeTestItem(color: "Cafe au lait")
        // localizedCaseInsensitiveContains handles accented characters
        #expect(item.matchesSearchQuery("cafe") == true)
        #expect(item.matchesSearchQuery("lait") == true)
    }

    @Test("Empty item with empty query returns true")
    func testEmptyItemEmptyQuery() {
        let item = makeTestItem() // All fields nil
        #expect(item.matchesSearchQuery("") == true)
    }
}

// swiftlint:enable explicit_type_interface
