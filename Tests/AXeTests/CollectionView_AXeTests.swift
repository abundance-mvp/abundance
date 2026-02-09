// Generated from docs/view-specs/inventory-view.md
// DO NOT EDIT MANUALLY — regenerate via /polish pipeline

import Foundation
import Testing

@Suite("AXe: InventoryView")
struct InventoryView_AXeTests {

    let source: SourceFile

    init() throws {
        source = try AXeTestHelpers.readSource(at: "Sources/InventoryFeature/InventoryView.swift")
    }

    // MARK: - Palette

    @Test("No system colors in InventoryView")
    func noSystemColors() {
        let violations = source.systemColorViolations()
        #expect(violations.isEmpty,
                "System color violations at lines: \(violations). Use brand tokens from Color+Brand.swift.")
    }

    @Test("No deprecated foregroundColor API")
    func noDeprecatedForegroundColor() {
        let violations = source.deprecatedForegroundColorLines()
        #expect(violations.isEmpty,
                "Deprecated .foregroundColor at lines: \(violations). Use .foregroundStyle instead.")
    }

    // MARK: - Accessibility Identifiers (from view spec table)

    @Test("Select/Done button has accessibility identifier")
    func selectButtonA11y() {
        #expect(source.containsPattern(#"inventory\.selectButton"#),
                "Select button must have .accessibilityIdentifier(\"inventory.selectButton\")")
    }

    @Test("Loading indicator has accessibility identifier")
    func loadingA11y() {
        #expect(source.containsPattern(#"inventory\.loading"#),
                "Loading indicator must have .accessibilityIdentifier(\"inventory.loading\")")
    }

    @Test("Empty state has accessibility identifier")
    func emptyStateA11y() {
        #expect(source.containsPattern(#"inventory\.emptyState"#),
                "Empty state must have .accessibilityIdentifier(\"inventory.emptyState\")")
    }

    @Test("Item grid has accessibility identifier")
    func gridA11y() {
        #expect(source.containsPattern(#"inventory\.grid"#),
                "Item grid must have .accessibilityIdentifier(\"inventory.grid\")")
    }

    @Test("Retry button has accessibility identifier")
    func retryButtonA11y() {
        #expect(source.containsPattern(#"inventory\.retryButton"#),
                "Retry button must have .accessibilityIdentifier(\"inventory.retryButton\")")
    }

    @Test("Deselect All button has accessibility identifier")
    func deselectAllA11y() {
        #expect(source.containsPattern(#"inventory\.deselectAllButton"#),
                "Deselect All button must have .accessibilityIdentifier(\"inventory.deselectAllButton\")")
    }

    @Test("Bulk Delete button has accessibility identifier")
    func bulkDeleteA11y() {
        #expect(source.containsPattern(#"inventory\.bulkDeleteButton"#),
                "Bulk Delete button must have .accessibilityIdentifier(\"inventory.bulkDeleteButton\")")
    }

    // MARK: - Dynamic Type

    @Test("No fixed font sizes")
    func noFixedFontSizes() {
        let violations = source.fixedFontSizeLines()
        #expect(violations.isEmpty,
                "Fixed font sizes at lines: \(violations). Use Dynamic Type styles (.body, .title, etc.).")
    }

    // MARK: - Navigation

    @Test("Has NavigationStack with title")
    func hasNavigationTitle() {
        #expect(source.containsPattern(#"\.navigationTitle"#),
                "NavigationStack must have .navigationTitle set.")
    }
}
