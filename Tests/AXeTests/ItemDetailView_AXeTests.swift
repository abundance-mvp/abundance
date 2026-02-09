// Generated from docs/view-specs/item-detail-view.md
// DO NOT EDIT MANUALLY — regenerate via /polish pipeline

import Foundation
import Testing

@Suite("AXe: ItemDetailView")
struct ItemDetailView_AXeTests {

    let source: SourceFile

    init() throws {
        source = try AXeTestHelpers.readSource(at: "Sources/CollectionFeature/ItemDetailView.swift")
    }

    // MARK: - Palette

    @Test("No system colors in ItemDetailView")
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

    // MARK: - Accessibility Labels (from view spec table)

    @Test("Hero image has accessibility label for single photo")
    func heroImageSingleA11y() {
        #expect(source.containsPattern(#"Detail photo of"#),
                "Single hero image must have .accessibilityLabel(\"Detail photo of {displayName}\")")
    }

    @Test("Hero image has accessibility label for multiple photos")
    func heroImageMultiA11y() {
        #expect(source.containsPattern(#"Photos of.*photos"#),
                "Multi-photo hero must have .accessibilityLabel(\"Photos of {name}, N photos\")")
    }

    @Test("Item name has accessibility identifier")
    func itemNameA11y() {
        #expect(source.containsPattern(#"detail\.itemName"#),
                "Item name must have .accessibilityIdentifier(\"detail.itemName\")")
    }

    @Test("Refresh button has accessibility label")
    func refreshButtonA11y() {
        #expect(source.containsPattern(#"Refresh item"#),
                "Refresh button must have .accessibilityLabel(\"Refresh item\")")
    }

    @Test("Edit button has accessibility label")
    func editButtonA11y() {
        #expect(source.containsPattern(#"Edit item"#),
                "Edit button must have .accessibilityLabel(\"Edit item\")")
    }

    @Test("Estimated value uses combined accessibility element")
    func estimatedValueA11y() {
        #expect(source.containsPattern(#"Estimated value:"#),
                "Estimated value must have .accessibilityLabel(\"Estimated value: $X.XX\")")
        #expect(source.containsPattern(#"accessibilityElement\(children: \.combine\)"#),
                "Estimated value must use .accessibilityElement(children: .combine)")
    }

    @Test("AI Confidence uses combined accessibility element")
    func confidenceA11y() {
        #expect(source.containsPattern(#"AI Confidence:"#),
                "AI Confidence must have .accessibilityLabel(\"AI Confidence: {level}\")")
    }

    @Test("Processing banner has accessibility identifier")
    func processingBannerA11y() {
        #expect(source.containsPattern(#"detail\.processingBanner"#),
                "Processing banner must have .accessibilityIdentifier(\"detail.processingBanner\")")
    }

    // MARK: - Touch Targets

    @Test("Action buttons have 44pt minimum touch target")
    func actionButtonTouchTargets() {
        #expect(source.containsPattern(#"minWidth: 44, minHeight: 44"#),
                "Action buttons must have .frame(minWidth: 44, minHeight: 44)")
    }

    // MARK: - Dynamic Type

    @Test("No fixed font sizes")
    func noFixedFontSizes() {
        let violations = source.fixedFontSizeLines()
        #expect(violations.isEmpty,
                "Fixed font sizes at lines: \(violations). Use Dynamic Type styles (.body, .title, etc.).")
    }

    // MARK: - Reduce Motion

    @Test("Parallax respects reduce motion")
    func parallaxReduceMotion() {
        #expect(source.hasReduceMotionCheck(),
                "Parallax scroll must check accessibilityReduceMotion")
    }
}
