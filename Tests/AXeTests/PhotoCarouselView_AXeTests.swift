// Generated from docs/view-specs/photo-carousel-view.md
// DO NOT EDIT MANUALLY — regenerate via /polish pipeline

import Foundation
import Testing

@Suite("AXe: PhotoCarouselView")
struct PhotoCarouselView_AXeTests {

    let source: SourceFile

    init() throws {
        source = try AXeTestHelpers.readSource(at: "Sources/InventoryFeature/Components/PhotoCarouselView.swift")
    }

    // MARK: - Palette

    @Test("No system colors in PhotoCarouselView")
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

    // MARK: - Accessibility Labels

    @Test("Delete button has accessibility label")
    func deleteButtonLabel() {
        #expect(source.containsPattern(#"accessibilityLabel\("Delete photo"#),
                "Delete button must have .accessibilityLabel(\"Delete photo {N}\")")
    }

    @Test("Root container has accessibility label with position")
    func rootAccessibilityLabel() {
        #expect(source.containsPattern(#"accessibilityLabel\("Photo .* of"#),
                "Root container must have .accessibilityLabel(\"Photo {N} of {total}\")")
    }

    @Test("Root uses contain children accessibility")
    func rootContainChildren() {
        #expect(source.containsPattern(#"accessibilityElement\(children:\s*\.contain\)"#),
                "Root view must use .accessibilityElement(children: .contain)")
    }

    // MARK: - Touch Targets

    @Test("Delete button has 44pt minimum touch target")
    func deleteButtonTouchTarget() {
        #expect(source.containsPattern(#"minWidth:\s*44,\s*minHeight:\s*44"#),
                "Delete button must have .frame(minWidth: 44, minHeight: 44).")
    }

    // MARK: - Dynamic Type

    @Test("No fixed font sizes")
    func noFixedFontSizes() {
        let violations = source.fixedFontSizeLines()
        #expect(violations.isEmpty,
                "Fixed font sizes at lines: \(violations). Use Dynamic Type styles (.body, .title, etc.).")
    }

    // MARK: - Animation

    @Test("No raw animation curves")
    func noRawAnimationCurves() {
        let violations = source.rawAnimationCurves()
        #expect(violations.isEmpty,
                "Raw animation curves at lines: \(violations). Use brand animation tokens.")
    }

    // MARK: - Confirmation Dialog

    @Test("Delete has confirmation dialog")
    func deleteConfirmationDialog() {
        #expect(source.containsPattern(#"confirmationDialog"#),
                "Delete action must show a confirmation dialog before proceeding.")
    }

    @Test("Delete dialog has destructive action")
    func deleteDestructiveRole() {
        #expect(source.containsPattern(#"role:\s*\.destructive"#),
                "Delete button in confirmation dialog must have .destructive role.")
    }
}
