// Generated from docs/view-specs/profile-view.md
// DO NOT EDIT MANUALLY — regenerate via /polish pipeline

import Foundation
import Testing

@Suite("AXe: ProfileView")
struct ProfileView_AXeTests {

    let source: SourceFile

    init() throws {
        source = try AXeTestHelpers.readSource(at: "Sources/ProfileFeature/ProfileView.swift")
    }

    // MARK: - Palette

    @Test("No system colors in ProfileView")
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

    @Test("Notifications row has accessibility identifier")
    func notificationsA11y() {
        #expect(source.containsPattern(#"profile\.notifications"#),
                "Notifications row must have .accessibilityIdentifier(\"profile.notifications\")")
    }

    @Test("Privacy row has accessibility identifier")
    func privacyA11y() {
        #expect(source.containsPattern(#"profile\.privacy"#),
                "Privacy row must have .accessibilityIdentifier(\"profile.privacy\")")
    }

    @Test("Help row has accessibility identifier")
    func helpA11y() {
        #expect(source.containsPattern(#"profile\.help"#),
                "Help row must have .accessibilityIdentifier(\"profile.help\")")
    }

    @Test("Export CSV button has accessibility identifier")
    func exportCSVA11y() {
        #expect(source.containsPattern(#"profile\.exportCSV"#),
                "Export CSV button must have .accessibilityIdentifier(\"profile.exportCSV\")")
    }

    @Test("Sign Out button has accessibility identifier")
    func signOutButtonA11y() {
        #expect(source.containsPattern(#"profile\.signOutButton"#),
                "Sign Out button must have .accessibilityIdentifier(\"profile.signOutButton\")")
    }

    // MARK: - Accessibility Labels

    @Test("Export CSV button has accessibility label")
    func exportCSVLabel() {
        #expect(source.containsPattern(#"accessibilityLabel\("Export as CSV"\)"#),
                "Export CSV button must have .accessibilityLabel(\"Export as CSV\")")
    }

    @Test("Sign Out button has accessibility label")
    func signOutLabel() {
        #expect(source.containsPattern(#"accessibilityLabel\("Sign out"\)"#),
                "Sign Out button must have .accessibilityLabel(\"Sign out\")")
    }

    @Test("Settings rows have accessibility labels")
    func settingsRowLabels() {
        #expect(source.containsPattern(#"accessibilityLabel\(title\)"#),
                "Settings rows must have .accessibilityLabel(title)")
    }

    @Test("Settings rows have isButton trait")
    func settingsRowButtonTrait() {
        #expect(source.containsPattern(#"accessibilityAddTraits\(\.isButton\)"#),
                "Settings rows must have .accessibilityAddTraits(.isButton)")
    }

    // MARK: - Accessibility Hints

    @Test("Export CSV button has accessibility hint")
    func exportCSVHint() {
        #expect(source.containsPattern(#"accessibilityHint.*export"#),
                "Export CSV button must have an accessibility hint")
    }

    @Test("Sign Out button has accessibility hint")
    func signOutHint() {
        #expect(source.containsPattern(#"accessibilityHint.*sign out"#),
                "Sign Out button must have an accessibility hint")
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

    // MARK: - Touch Targets

    @Test("Export CSV button has minimum 44pt height")
    func exportMinHeight() {
        #expect(source.containsPattern(#"minHeight:\s*44"#),
                "Export button must have .frame(minHeight: 44) for touch target.")
    }

    // MARK: - Animation

    @Test("No raw animation curves")
    func noRawAnimationCurves() {
        let violations = source.rawAnimationCurves()
        #expect(violations.isEmpty,
                "Raw animation curves at lines: \(violations). Use brand animation tokens.")
    }
}
