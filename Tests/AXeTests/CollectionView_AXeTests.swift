// Generated from docs/view-specs/collection-view.md
// DO NOT EDIT MANUALLY — regenerate via /polish pipeline

import Foundation
import Testing

@Suite("AXe: CollectionView")
struct CollectionView_AXeTests {

    let source: SourceFile

    init() throws {
        source = try AXeTestHelpers.readSource(at: "Sources/CollectionFeature/CollectionView.swift")
    }

    // MARK: - Palette

    @Test("No system colors in CollectionView")
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
        #expect(source.containsPattern(#"collection\.selectButton"#),
                "Select button must have .accessibilityIdentifier(\"collection.selectButton\")")
    }

    @Test("Loading indicator has accessibility identifier")
    func loadingA11y() {
        #expect(source.containsPattern(#"collection\.loading"#),
                "Loading indicator must have .accessibilityIdentifier(\"collection.loading\")")
    }

    @Test("Empty state has accessibility identifier")
    func emptyStateA11y() {
        #expect(source.containsPattern(#"collection\.emptyState"#),
                "Empty state must have .accessibilityIdentifier(\"collection.emptyState\")")
    }

    @Test("Item grid has accessibility identifier")
    func gridA11y() {
        #expect(source.containsPattern(#"collection\.grid"#),
                "Item grid must have .accessibilityIdentifier(\"collection.grid\")")
    }

    @Test("Retry button has accessibility identifier")
    func retryButtonA11y() {
        #expect(source.containsPattern(#"collection\.retryButton"#),
                "Retry button must have .accessibilityIdentifier(\"collection.retryButton\")")
    }

    @Test("Deselect All button has accessibility identifier")
    func deselectAllA11y() {
        #expect(source.containsPattern(#"collection\.deselectAllButton"#),
                "Deselect All button must have .accessibilityIdentifier(\"collection.deselectAllButton\")")
    }

    @Test("Bulk Delete button has accessibility identifier")
    func bulkDeleteA11y() {
        #expect(source.containsPattern(#"collection\.bulkDeleteButton"#),
                "Bulk Delete button must have .accessibilityIdentifier(\"collection.bulkDeleteButton\")")
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
