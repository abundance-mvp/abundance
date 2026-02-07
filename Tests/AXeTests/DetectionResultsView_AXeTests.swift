// Generated from docs/view-specs/detection-results-view.md
// DO NOT EDIT MANUALLY — regenerate via /polish pipeline

import Foundation
import Testing

@Suite("AXe: DetectionResultsView")
struct DetectionResultsView_AXeTests {

    let source: SourceFile

    init() throws {
        source = try AXeTestHelpers.readSource(at: "Sources/CameraFeature/Views/DetectionResultsView.swift")
    }

    // MARK: - Palette

    @Test("No deprecated foregroundColor API")
    func noDeprecatedForegroundColor() {
        let violations = source.deprecatedForegroundColorLines()
        #expect(violations.isEmpty,
                "Deprecated .foregroundColor at lines: \(violations). Use .foregroundStyle instead.")
    }

    // MARK: - Accessibility Identifiers (from view spec table)

    @Test("Retake overlay button has accessibility identifier")
    func retakeOverlayA11y() {
        #expect(source.containsPattern(#"detection\.retakeOverlayButton"#),
                "Retake overlay button must have .accessibilityIdentifier(\"detection.retakeOverlayButton\")")
    }

    @Test("Catalog All button has accessibility identifier")
    func catalogAllA11y() {
        #expect(source.containsPattern(#"detection\.catalogAllButton"#),
                "Catalog All button must have .accessibilityIdentifier(\"detection.catalogAllButton\")")
    }

    @Test("Object cards have accessibility identifiers")
    func objectCardA11y() {
        #expect(source.containsPattern(#"detection\.object\."#),
                "Object cards must have .accessibilityIdentifier(\"detection.object.{groupId}\")")
    }

    @Test("Catalog buttons have accessibility identifiers")
    func catalogButtonA11y() {
        #expect(source.containsPattern(#"detection\.catalogButton\."#),
                "Catalog buttons must have .accessibilityIdentifier(\"detection.catalogButton.{groupId}\")")
    }

    @Test("Retake bottom button has accessibility identifier")
    func retakeBottomA11y() {
        #expect(source.containsPattern(#"detection\.retakeButton"#),
                "Retake bottom button must have .accessibilityIdentifier(\"detection.retakeButton\")")
    }

    @Test("Done button has accessibility identifier")
    func doneButtonA11y() {
        #expect(source.containsPattern(#"detection\.doneButton"#),
                "Done button must have .accessibilityIdentifier(\"detection.doneButton\")")
    }

    // MARK: - Accessibility Labels

    @Test("Retake overlay button has accessibility label")
    func retakeOverlayLabel() {
        #expect(source.containsPattern(#"accessibilityLabel\("Retake photo"\)"#),
                "Retake overlay button must have .accessibilityLabel(\"Retake photo\")")
    }

    @Test("Bounding box overlays have accessibility labels")
    func boundingBoxLabels() {
        #expect(source.containsPattern(#"accessibilityLabel\("Detected:"#),
                "Bounding box overlays must have .accessibilityLabel(\"Detected: {label}\")")
    }

    @Test("Bounding box overlays have accessibility hints")
    func boundingBoxHints() {
        #expect(source.containsPattern(#"accessibilityHint.*Double tap to"#),
                "Bounding box overlays must have accessibility hints.")
    }

    @Test("Bounding box overlays have button trait")
    func boundingBoxButtonTrait() {
        #expect(source.containsPattern(#"accessibilityAddTraits\(\.isButton\)"#),
                "Bounding box overlays must have .accessibilityAddTraits(.isButton)")
    }

    @Test("Object cards have combined accessibility")
    func objectCardCombined() {
        #expect(source.containsPattern(#"accessibilityElement\(children:\s*\.combine\)"#),
                "Object cards must use .accessibilityElement(children: .combine)")
    }

    @Test("Object cards have accessibility labels")
    func objectCardLabels() {
        #expect(source.containsPattern(#"accessibilityLabel\(.*label.*category"#),
                "Object cards must have .accessibilityLabel with label and category.")
    }

    // MARK: - Dynamic Type

    @Test("No fixed font sizes")
    func noFixedFontSizes() {
        let violations = source.fixedFontSizeLines()
        #expect(violations.isEmpty,
                "Fixed font sizes at lines: \(violations). Use Dynamic Type styles (.body, .title, etc.).")
    }

    @Test("Empty state icon uses ScaledMetric")
    func emptyStateScaledMetric() {
        #expect(source.containsPattern(#"@ScaledMetric.*emptyIconSize"#),
                "Empty state icon must use @ScaledMetric for Dynamic Type support.")
    }

    @Test("No-objects icon uses ScaledMetric")
    func noObjectsScaledMetric() {
        #expect(source.containsPattern(#"@ScaledMetric.*noObjectsIconSize"#),
                "No-objects icon must use @ScaledMetric for Dynamic Type support.")
    }

    // MARK: - Reduce Transparency

    @Test("Checks accessibilityReduceTransparency")
    func checksReduceTransparency() {
        #expect(source.containsPattern(#"accessibilityReduceTransparency"#),
                "DetectionResultsView must check @Environment(\\.accessibilityReduceTransparency).")
    }

    @Test("Bottom action bar has reduce-transparency fallback")
    func bottomBarReduceTransparencyFallback() {
        #expect(source.containsPattern(#"reduceTransparency"#),
                "Bottom action bar must check reduceTransparency and provide opaque fallback.")
    }

    // MARK: - Bounding Box Accessibility

    @Test("Bounding boxes ignore children for accessibility")
    func boundingBoxIgnoreChildren() {
        #expect(source.containsPattern(#"accessibilityElement\(children:\s*\.ignore\)"#),
                "Bounding boxes must ignore children and provide a custom accessibility label.")
    }
}
