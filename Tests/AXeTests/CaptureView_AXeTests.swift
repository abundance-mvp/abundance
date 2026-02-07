// Generated from docs/view-specs/capture-view.md
// DO NOT EDIT MANUALLY — regenerate via /polish pipeline

import Foundation
import Testing

@Suite("AXe: CaptureView")
struct CaptureView_AXeTests {

    let source: SourceFile

    init() throws {
        source = try AXeTestHelpers.readSource(at: "Sources/CameraFeature/Views/CaptureView.swift")
    }

    // MARK: - Palette (camera exempt for black/white)

    @Test("No system colors in CaptureView (camera exempt for black/white)")
    func noSystemColors() {
        // Camera views are exempt for .black and .white — only check non-exempt colors
        let nonExemptColors = source.linesMatching(
            #"\.(blue|gray|purple|red|green|orange|yellow|pink|mint|cyan|indigo|teal|brown)\b"#
        )
        #expect(nonExemptColors.isEmpty,
                "System color violations at lines: \(nonExemptColors). Camera exempt for black/white only.")
    }

    // MARK: - Accessibility Labels (from view spec table)

    @Test("Cancel button has accessibility label")
    func cancelButtonA11y() {
        #expect(source.containsPattern(#"Cancel capture"#),
                "Cancel button must have .accessibilityLabel(\"Cancel capture\")")
    }

    @Test("Mode indicator has accessibility label")
    func modeIndicatorA11y() {
        #expect(source.containsPattern(#"Capture status:"#),
                "Mode indicator must have .accessibilityLabel(\"Capture status: {text}\")")
    }

    @Test("Mode indicator has updatesFrequently trait")
    func modeIndicatorTrait() {
        #expect(source.containsPattern(#"\.updatesFrequently"#),
                "Mode indicator must have .accessibilityAddTraits(.updatesFrequently)")
    }

    // MARK: - Animations

    @Test("No raw animation curves — use brand curves")
    func noRawAnimationCurves() {
        let violations = source.rawAnimationCurves()
        #expect(violations.isEmpty,
                "Raw animation curves at lines: \(violations). Use .brandDefault, .brandPress, or .brandReducedMotion.")
    }

    // MARK: - Liquid Glass

    @Test("Glass effects are properly availability-gated")
    func glassAvailabilityGated() {
        let unguarded = source.unguardedGlassEffectLines()
        #expect(unguarded.isEmpty,
                "Unguarded .glassEffect at lines: \(unguarded). Wrap in if #available(iOS 26) or use adaptiveGlass().")
    }

    @Test("Reduce transparency fallback exists for glass")
    func reduceTransparencyFallback() {
        if source.containsPattern(#"\.glassEffect"#) {
            #expect(source.containsPattern(#"accessibilityReduceTransparency"#),
                    "Glass effects must have accessibilityReduceTransparency fallback")
        }
    }

    // MARK: - Touch Targets

    @Test("Cancel button has adequate padding for touch target")
    func cancelButtonTouchTarget() {
        // Cancel button uses padding(16) on all sides — exceeds 44pt with icon
        #expect(source.containsPattern(#"\.padding\(16\)"#) ||
                source.containsPattern(#"\.padding\(\)"#),
                "Cancel button must have sufficient padding for 44pt touch target")
    }
}
