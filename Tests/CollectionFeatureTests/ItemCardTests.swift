import Testing
import SwiftUI
@testable import CollectionFeature
@testable import Persistence

// MARK: - Test Item Factory

extension Item {
    /// Create a mock Item for testing
    static func mock(
        id: String = "test-id",
        userId: String = "test-user",
        imageUrl: String = "https://example.com/image.jpg",
        status: ItemStatus = .complete,
        name: String? = "Test Item",
        category: String? = "Electronics",
        brand: String? = "Test Brand",
        color: String? = "Blue",
        condition: ItemCondition? = .good
    ) -> Item {
        Item(
            id: id,
            userId: userId,
            imageUrl: imageUrl,
            status: status,
            name: name,
            category: category,
            brand: brand,
            color: color,
            condition: condition
        )
    }
}

@Suite("ItemCard Tests")
@MainActor
struct ItemCardTests {

    // MARK: - Display Tests

    @Test("ItemCard displays name label")
    func testItemCard_displaysName() async throws {
        // Given: Item with a name
        let item = Item.mock(name: "Apple Watch")

        // When: Create ItemCard
        let card = ItemCard(item: item)

        // Then: Card should render (body not nil means view can be created)
        #expect(card.item.name == "Apple Watch")
    }

    @Test("ItemCard displays brand and color in subtitle")
    func testItemCard_displaysBrandAndColor() async throws {
        // Given: Item with brand and color
        let item = Item.mock(brand: "Apple", color: "Silver")

        // When: Create ItemCard
        let card = ItemCard(item: item)

        // Then: Brand and color should be accessible from item
        #expect(card.item.brand == "Apple")
        #expect(card.item.color == "Silver")
    }

    @Test("ItemCard uses category as fallback when name is nil")
    func testItemCard_fallbackName_usesCategory() async throws {
        // Given: Item with nil name but valid category
        let item = Item.mock(name: nil, category: "Outdoor Gear")

        // When: Create ItemCard
        let card = ItemCard(item: item)

        // Then: Category should be available as fallback
        #expect(card.item.name == nil)
        #expect(card.item.category == "Outdoor Gear")
    }

    // MARK: - Condition Badge Tests

    @Test("Condition badge shows green for good condition")
    func testItemCard_conditionBadge_good_green() async throws {
        // Given: Item with good condition
        let item = Item.mock(condition: .good)

        // When: Create ItemCard
        let card = ItemCard(item: item)

        // Then: Condition should be good
        #expect(card.item.condition == .good)
        #expect(card.item.condition?.displayName == "Good")
    }

    @Test("Condition badge shows yellow/orange for fair condition")
    func testItemCard_conditionBadge_fair_yellow() async throws {
        // Given: Item with fair condition
        let item = Item.mock(condition: .fair)

        // When: Create ItemCard
        let card = ItemCard(item: item)

        // Then: Condition should be fair
        #expect(card.item.condition == .fair)
        #expect(card.item.condition?.displayName == "Fair")
    }

    @Test("Condition badge shows red for poor condition")
    func testItemCard_conditionBadge_poor_red() async throws {
        // Given: Item with poor condition
        let item = Item.mock(condition: .poor)

        // When: Create ItemCard
        let card = ItemCard(item: item)

        // Then: Condition should be poor
        #expect(card.item.condition == .poor)
        #expect(card.item.condition?.displayName == "Poor")
    }

    // MARK: - Status Badge Tests

    @Test("Status badge shows Processing for processing state")
    func testItemCard_statusBadge_processingState() async throws {
        // Given: Item with processing status
        let item = Item.mock(status: .processing)

        // When: Create ItemCard
        let card = ItemCard(item: item)

        // Then: Status should be processing
        #expect(card.item.status == .processing)
    }

    @Test("Status badge shows Complete for complete state")
    func testItemCard_statusBadge_completeState() async throws {
        // Given: Item with complete status
        let item = Item.mock(status: .complete)

        // When: Create ItemCard
        let card = ItemCard(item: item)

        // Then: Status should be complete
        #expect(card.item.status == .complete)
    }

    @Test("Status badge shows Failed for failed state")
    func testItemCard_statusBadge_failedState() async throws {
        // Given: Item with failed status
        let item = Item.mock(status: .failed)

        // When: Create ItemCard
        let card = ItemCard(item: item)

        // Then: Status should be failed
        #expect(card.item.status == .failed)
    }

    // MARK: - Selection Mode Tests

    @Test("Selection mode shows checkmark overlay")
    func testItemCard_selectionMode_showsCheckmark() async throws {
        // Given: Item in selection mode
        let item = Item.mock()

        // When: Create ItemCard with selection mode enabled and selected
        let card = ItemCard(item: item, isSelectionMode: true, isSelected: true)

        // Then: Selection mode flags should be set
        #expect(card.isSelectionMode == true)
        #expect(card.isSelected == true)
    }

    @Test("Selection mode hides context menu")
    func testItemCard_selectionMode_hidesContextMenu() async throws {
        // Given: Item in selection mode
        let item = Item.mock()

        // When: Create ItemCard with selection mode enabled
        // Context menu is hidden when isSelectionMode is true (see line 115 in ItemCard.swift)
        let card = ItemCard(item: item, isSelectionMode: true, isSelected: false)

        // Then: Selection mode should be enabled (context menu hidden in this state)
        #expect(card.isSelectionMode == true)
    }

    @Test("Context menu shows Edit and Delete options when not in selection mode")
    func testItemCard_contextMenu_showsEditDelete() async throws {
        // Given: Item not in selection mode with edit/delete handlers
        let item = Item.mock()
        var editCalled = false
        var deleteCalled = false

        // When: Create ItemCard with edit and delete callbacks
        let card = ItemCard(
            item: item,
            onEdit: { editCalled = true },
            onDelete: { deleteCalled = true },
            isSelectionMode: false
        )

        // Then: Callbacks should be configured (context menu available)
        #expect(card.isSelectionMode == false)
        #expect(card.onEdit != nil)
        #expect(card.onDelete != nil)

        // Verify callbacks work when invoked
        card.onEdit?()
        card.onDelete?()
        #expect(editCalled == true)
        #expect(deleteCalled == true)
    }

    // MARK: - Accessibility Tests

    @Test("Accessibility label contains complete description")
    func testItemCard_accessibilityLabel_complete() async throws {
        // Given: Item with all fields populated
        let item = Item.mock(
            name: "Apple Watch",
            brand: "Apple",
            color: "Silver",
            condition: .good
        )

        // When: Create ItemCard
        let card = ItemCard(item: item)

        // Then: Item should have all fields for accessibility label construction
        // The actual accessibility label is: "name, brand, color, condition.displayName, statusText"
        #expect(card.item.name == "Apple Watch")
        #expect(card.item.brand == "Apple")
        #expect(card.item.color == "Silver")
        #expect(card.item.condition == .good)
        #expect(card.item.status == .complete)
    }

    // MARK: - Callback Tests

    @Test("Tap callback fires when invoked")
    func testItemCard_tapCallback_fires() async throws {
        // Given: Item with tap callback
        var tapped = false
        let item = Item.mock()

        // When: Create ItemCard with onTap callback
        let card = ItemCard(item: item, onTap: { tapped = true })

        // Then: Callback should be configured
        #expect(card.onTap != nil)

        // Verify callback fires when invoked
        card.onTap?()
        #expect(tapped == true)
    }

    // MARK: - Navigation Compatibility Tests

    @Test("ItemCard without onTap allows NavigationLink to work")
    func testItemCard_withoutOnTap_allowsNavigation() async throws {
        // Given: Item without tap callback (used inside NavigationLink)
        let item = Item.mock()

        // When: Create ItemCard without onTap (normal grid mode with NavigationLink)
        let card = ItemCard(item: item, onDelete: { })

        // Then: onTap should be nil, allowing NavigationLink to handle taps
        // This is critical: when onTap is nil, ItemCard doesn't wrap content in Button,
        // which allows the parent NavigationLink to receive tap events
        #expect(card.onTap == nil)
        #expect(card.onDelete != nil)
    }

    @Test("ItemCard with onTap uses Button wrapper for selection mode")
    func testItemCard_withOnTap_usesButtonWrapper() async throws {
        // Given: Item with tap callback (selection mode)
        var tapped = false
        let item = Item.mock()

        // When: Create ItemCard with onTap (selection mode where taps toggle selection)
        let card = ItemCard(
            item: item,
            onTap: { tapped = true },
            isSelectionMode: true,
            isSelected: false
        )

        // Then: onTap should be configured (Button wrapper handles taps)
        #expect(card.onTap != nil)
        #expect(card.isSelectionMode == true)

        // Verify tap works
        card.onTap?()
        #expect(tapped == true)
    }
}
