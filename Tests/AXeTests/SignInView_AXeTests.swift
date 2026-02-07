// Generated from docs/view-specs/sign-in-view.md
// DO NOT EDIT MANUALLY — regenerate via /polish pipeline

import Foundation
import Testing

@Suite("AXe: SignInView")
struct SignInView_AXeTests {

    let source: SourceFile

    init() throws {
        source = try AXeTestHelpers.readSource(at: "Sources/OnboardingFeature/SignInView.swift")
    }

    // MARK: - Palette

    @Test("No system colors in SignInView")
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

    @Test("Offline warning has accessibility label")
    func offlineWarningLabel() {
        #expect(source.containsPattern(#"accessibilityLabel.*No internet connection"#),
                "Offline warning must have .accessibilityLabel describing the network issue.")
    }

    @Test("Leaf icon is hidden from accessibility")
    func leafIconHidden() {
        #expect(source.containsPattern(#"accessibilityHidden\(true\)"#),
                "Leaf icon must be accessibilityHidden(true) since it is decorative.")
    }

    @Test("Title section uses combined accessibility")
    func titleSectionCombined() {
        #expect(source.containsPattern(#"accessibilityElement\(children:\s*\.combine\)"#),
                "Title section must combine children for VoiceOver.")
    }

    @Test("Loading spinner has accessibility label")
    func loadingSpinnerLabel() {
        #expect(source.containsPattern(#"accessibilityLabel\("Signing in"\)"#),
                "Loading ProgressView must have .accessibilityLabel(\"Signing in\")")
    }

    @Test("Error view has combined accessibility")
    func errorViewCombined() {
        #expect(source.countPattern(#"accessibilityElement\(children:\s*\.combine\)"#) >= 2,
                "Error view must use .accessibilityElement(children: .combine)")
    }

    @Test("Error view has accessibility label")
    func errorViewLabel() {
        #expect(source.containsPattern(#"accessibilityLabel\("Error:"#),
                "Error view must have .accessibilityLabel describing the error.")
    }

    // MARK: - Dynamic Type

    @Test("No fixed font sizes")
    func noFixedFontSizes() {
        let violations = source.fixedFontSizeLines()
        #expect(violations.isEmpty,
                "Fixed font sizes at lines: \(violations). Use Dynamic Type styles (.body, .title, etc.).")
    }

    @Test("Leaf icon uses ScaledMetric")
    func leafIconScaledMetric() {
        #expect(source.containsPattern(#"@ScaledMetric"#),
                "Leaf icon size must use @ScaledMetric for Dynamic Type support.")
    }

    @Test("Leaf icon caps at accessibility2")
    func leafIconDynamicTypeCap() {
        #expect(source.containsPattern(#"dynamicTypeSize\(\.\.\.DynamicTypeSize\.accessibility2\)"#),
                "Leaf icon must cap dynamic type at .accessibility2.")
    }

    // MARK: - Reduce Transparency

    @Test("Checks accessibilityReduceTransparency")
    func checksReduceTransparency() {
        #expect(source.containsPattern(#"accessibilityReduceTransparency"#),
                "SignInView must check @Environment(\\.accessibilityReduceTransparency).")
    }

    @Test("Provides solid fallback for gradient when reduce transparency is on")
    func reduceTransparencyFallback() {
        #expect(source.containsPattern(#"reduceTransparency"#),
                "Background must check reduceTransparency and provide solid Color.backgroundDefault fallback.")
    }

    // MARK: - Liquid Glass

    @Test("Offline warning uses glassEffect on iOS 26")
    func offlineWarningGlass() {
        #expect(source.containsPattern(#"glassEffect"#),
                "Offline warning must use .glassEffect on iOS 26+.")
    }

    @Test("Glass usage has iOS 26 availability check")
    func glassAvailabilityCheck() {
        #expect(source.containsPattern(#"#available\(iOS 26"#),
                "Glass effects must be guarded with #available(iOS 26.0, *).")
    }
}
