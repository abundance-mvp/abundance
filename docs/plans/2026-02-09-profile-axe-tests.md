# Profile Phase 1 AXe Tests Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add static AXe source-analysis tests for every Profile Phase 1 view file introduced on the `feature/profile-phase1` branch, matching existing AXe test conventions.

**Architecture:** Each new view file gets a corresponding `*_AXeTests.swift` file in `Tests/AXeTests/`. Tests use the `SourceFile` helper from `AXeTestHelpers.swift` to read Swift source files and assert accessibility identifiers, labels, palette compliance, Dynamic Type, animation curves, and Liquid Glass patterns are present. Tests also update `docs/testing/AXE-TEST-SCENARIOS.md` Scenario 9 with expanded sub-screen verification steps.

**Tech Stack:** Swift Testing (`@Suite`, `@Test`, `#expect`), `AXeTestHelpers.swift` (`SourceFile` struct), SPM test target `AXeTests`

**Branch:** Work on `feature/profile-phase1` (checkout first — current branch is `claude/pedantic-bhabha`)

---

## Existing AXe Test Pattern Reference

Every AXe test file follows this structure (see `ProfileView_AXeTests.swift`, `CollectionView_AXeTests.swift`):

```swift
import Foundation
import Testing

@Suite("AXe: <ViewName>")
struct <ViewName>_AXeTests {
    let source: SourceFile

    init() throws {
        source = try AXeTestHelpers.readSource(at: "Sources/<Module>/<Path>.swift")
    }

    // MARK: - Palette
    // noSystemColors, noDeprecatedForegroundColor

    // MARK: - Accessibility Identifiers
    // One test per identifier from AXE-TEST-SCENARIOS.md

    // MARK: - Accessibility Labels
    // Labels for interactive elements

    // MARK: - Dynamic Type
    // noFixedFontSizes

    // MARK: - Navigation
    // hasNavigationTitle (if applicable)

    // MARK: - Animation
    // noRawAnimationCurves (if view has animations)
}
```

**Key conventions:**
- File header: `// Generated from docs/view-specs/<view>.md` (or `docs/testing/AXE-TEST-SCENARIOS.md` for profile sub-screens)
- Suite name: `"AXe: <ViewName>"`
- Struct name: `<ViewName>_AXeTests`
- Each identifier from the Identifier Reference table in `AXE-TEST-SCENARIOS.md` gets its own `@Test`
- Use `source.containsPattern(#"..."#)` for identifier/label checks
- Use `source.systemColorViolations()` / `source.deprecatedForegroundColorLines()` for palette
- Use `source.fixedFontSizeLines()` for Dynamic Type
- Use `source.rawAnimationCurves()` for animation

---

## Task 1: Update existing ProfileView AXe tests for Phase 1 changes

The `feature/profile-phase1` branch changes `ProfileView.swift` significantly:
- `SettingsRow` struct removed, replaced with `NavigationLink` + `settingsRowContent()`
- Export section now has conditional `ShareLink` (with `profile.shareCSV` identifier)
- Edit profile sheet wired via `showingEditProfile` state
- Settings rows no longer have `.accessibilityLabel(title)` or `.accessibilityAddTraits(.isButton)` (NavigationLinks handle this natively)

**Files:**
- Modify: `Tests/AXeTests/ProfileView_AXeTests.swift`

**Step 1: Read the current test file and the Phase 1 ProfileView source**

Verify which tests will break on the Phase 1 branch:
- `settingsRowLabels` — checks for `accessibilityLabel(title)` — **WILL BREAK** (NavigationLink provides label automatically)
- `settingsRowButtonTrait` — checks for `accessibilityAddTraits(.isButton)` — **WILL BREAK** (NavigationLink is already a button)
- `exportCSVHint` — checks for `accessibilityHint.*export` — **STILL PASSES** (hint text changed but still contains "export")
- `exportMinHeight` — checks for `minHeight:\s*44` — **STILL PASSES** (in `exportButtonLabel`)

**Step 2: Update ProfileView_AXeTests.swift**

Replace the full file with this content:

```swift
// Generated from docs/testing/AXE-TEST-SCENARIOS.md — Profile Screen section
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

    // MARK: - Accessibility Identifiers (from AXE-TEST-SCENARIOS.md)

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

    @Test("Share CSV has accessibility identifier")
    func shareCSVA11y() {
        #expect(source.containsPattern(#"profile\.shareCSV"#),
                "Share CSV link must have .accessibilityIdentifier(\"profile.shareCSV\")")
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

    @Test("Share CSV has accessibility label")
    func shareCSVLabel() {
        #expect(source.containsPattern(#"accessibilityLabel\("Share CSV export"\)"#),
                "Share CSV link must have .accessibilityLabel(\"Share CSV export\")")
    }

    @Test("Sign Out button has accessibility label")
    func signOutLabel() {
        #expect(source.containsPattern(#"accessibilityLabel\("Sign out"\)"#),
                "Sign Out button must have .accessibilityLabel(\"Sign out\")")
    }

    // MARK: - Accessibility Hints

    @Test("Export CSV button has accessibility hint")
    func exportCSVHint() {
        #expect(source.containsPattern(#"accessibilityHint.*CSV"#),
                "Export CSV button must have an accessibility hint mentioning CSV")
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

    @Test("Export button has minimum 44pt height")
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
```

**Step 3: Run tests to verify they pass against the Phase 1 ProfileView**

Run: `swift test --filter AXeTests.ProfileView_AXeTests 2>&1 | tail -20`
Expected: All 16 tests PASS

**Step 4: Commit**

```bash
git add Tests/AXeTests/ProfileView_AXeTests.swift
git commit -m "test(axe): update ProfileView AXe tests for Phase 1 changes

- Remove SettingsRow trait/label checks (replaced by NavigationLink)
- Add shareCSV identifier and label tests
- Update hint patterns for new copy"
```

---

## Task 2: Add UserInfoCard AXe tests

The Phase 1 `UserInfoCard` adds an edit button with `profile.editButton` identifier. The card has accessibility grouping and a combined label.

**Files:**
- Create: `Tests/AXeTests/UserInfoCard_AXeTests.swift`

**Step 1: Write the test file**

```swift
// Generated from docs/testing/AXE-TEST-SCENARIOS.md — Profile Screen section
// DO NOT EDIT MANUALLY — regenerate via /polish pipeline

import Foundation
import Testing

@Suite("AXe: UserInfoCard")
struct UserInfoCard_AXeTests {

    let source: SourceFile

    init() throws {
        source = try AXeTestHelpers.readSource(at: "Sources/ProfileFeature/Components/UserInfoCard.swift")
    }

    // MARK: - Palette

    @Test("No system colors in UserInfoCard")
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

    // MARK: - Accessibility Identifiers

    @Test("User info card has accessibility identifier")
    func userInfoCardA11y() {
        #expect(source.containsPattern(#"profile\.userInfoCard"#),
                "Card must have .accessibilityIdentifier(\"profile.userInfoCard\")")
    }

    @Test("Edit button has accessibility identifier")
    func editButtonA11y() {
        #expect(source.containsPattern(#"profile\.editButton"#),
                "Edit button must have .accessibilityIdentifier(\"profile.editButton\")")
    }

    // MARK: - Accessibility Labels

    @Test("Card uses combined accessibility element")
    func cardCombinedA11y() {
        #expect(source.containsPattern(#"accessibilityElement\(children:\s*\.combine\)"#),
                "Card must use .accessibilityElement(children: .combine) for VoiceOver grouping")
    }

    @Test("Card has descriptive accessibility label")
    func cardA11yLabel() {
        #expect(source.containsPattern(#"accessibilityLabel\("User profile:"#),
                "Card must have .accessibilityLabel starting with \"User profile:\"")
    }

    @Test("Avatar is hidden from accessibility")
    func avatarHidden() {
        #expect(source.containsPattern(#"accessibilityHidden\(true\)"#),
                "Avatar must be accessibilityHidden(true) since initials are decorative")
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
}
```

**Step 2: Run test to verify it passes**

Run: `swift test --filter AXeTests.UserInfoCard_AXeTests 2>&1 | tail -20`
Expected: All 9 tests PASS

**Step 3: Commit**

```bash
git add Tests/AXeTests/UserInfoCard_AXeTests.swift
git commit -m "test(axe): add UserInfoCard AXe tests

- Palette: no system colors, no deprecated foregroundColor
- Identifiers: profile.userInfoCard, profile.editButton
- Labels: combined element, descriptive label, avatar hidden
- Dynamic Type: no fixed font sizes
- Animation: no raw curves"
```

---

## Task 3: Add EditProfileSheet AXe tests

The `EditProfileSheet` has a name text field and a save button in the toolbar.

**Files:**
- Create: `Tests/AXeTests/EditProfileSheet_AXeTests.swift`

**Step 1: Write the test file**

```swift
// Generated from docs/testing/AXE-TEST-SCENARIOS.md — Edit Profile section
// DO NOT EDIT MANUALLY — regenerate via /polish pipeline

import Foundation
import Testing

@Suite("AXe: EditProfileSheet")
struct EditProfileSheet_AXeTests {

    let source: SourceFile

    init() throws {
        source = try AXeTestHelpers.readSource(at: "Sources/ProfileFeature/Views/EditProfileSheet.swift")
    }

    // MARK: - Palette

    @Test("No system colors in EditProfileSheet")
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

    // MARK: - Accessibility Identifiers

    @Test("Name field has accessibility identifier")
    func nameFieldA11y() {
        #expect(source.containsPattern(#"editProfile\.nameField"#),
                "Name field must have .accessibilityIdentifier(\"editProfile.nameField\")")
    }

    @Test("Save button has accessibility identifier")
    func saveButtonA11y() {
        #expect(source.containsPattern(#"editProfile\.save"#),
                "Save button must have .accessibilityIdentifier(\"editProfile.save\")")
    }

    // MARK: - Dynamic Type

    @Test("No fixed font sizes")
    func noFixedFontSizes() {
        let violations = source.fixedFontSizeLines()
        #expect(violations.isEmpty,
                "Fixed font sizes at lines: \(violations). Use Dynamic Type styles (.body, .title, etc.).")
    }

    // MARK: - Navigation

    @Test("Has navigation title")
    func hasNavigationTitle() {
        #expect(source.containsPattern(#"\.navigationTitle"#),
                "EditProfileSheet must have .navigationTitle set.")
    }

    @Test("Has inline title display mode")
    func hasInlineTitleDisplayMode() {
        #expect(source.containsPattern(#"\.navigationBarTitleDisplayMode\(\.inline\)"#),
                "EditProfileSheet must use .inline title display mode.")
    }

    // MARK: - Form

    @Test("Name field uses textContentType name")
    func nameFieldContentType() {
        #expect(source.containsPattern(#"\.textContentType\(\.name\)"#),
                "Name field must have .textContentType(.name) for autofill support")
    }

    // MARK: - Animation

    @Test("No raw animation curves")
    func noRawAnimationCurves() {
        let violations = source.rawAnimationCurves()
        #expect(violations.isEmpty,
                "Raw animation curves at lines: \(violations). Use brand animation tokens.")
    }
}
```

**Step 2: Run test to verify it passes**

Run: `swift test --filter AXeTests.EditProfileSheet_AXeTests 2>&1 | tail -20`
Expected: All 9 tests PASS

**Step 3: Commit**

```bash
git add Tests/AXeTests/EditProfileSheet_AXeTests.swift
git commit -m "test(axe): add EditProfileSheet AXe tests

- Palette: no system colors, no deprecated foregroundColor
- Identifiers: editProfile.nameField, editProfile.save
- Dynamic Type: no fixed font sizes
- Navigation: title set, inline display mode
- Form: textContentType(.name) for autofill"
```

---

## Task 4: Add NotificationsSettingsView AXe tests

Small view with a single toggle. Key checks: identifier, palette, Dynamic Type, navigation title.

**Files:**
- Create: `Tests/AXeTests/NotificationsSettingsView_AXeTests.swift`

**Step 1: Write the test file**

```swift
// Generated from docs/testing/AXE-TEST-SCENARIOS.md — Notifications Settings section
// DO NOT EDIT MANUALLY — regenerate via /polish pipeline

import Foundation
import Testing

@Suite("AXe: NotificationsSettingsView")
struct NotificationsSettingsView_AXeTests {

    let source: SourceFile

    init() throws {
        source = try AXeTestHelpers.readSource(at: "Sources/ProfileFeature/Views/NotificationsSettingsView.swift")
    }

    // MARK: - Palette

    @Test("No system colors in NotificationsSettingsView")
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

    // MARK: - Accessibility Identifiers

    @Test("Item ready toggle has accessibility identifier")
    func itemReadyToggleA11y() {
        #expect(source.containsPattern(#"notifications\.itemReady"#),
                "Toggle must have .accessibilityIdentifier(\"notifications.itemReady\")")
    }

    // MARK: - Dynamic Type

    @Test("No fixed font sizes")
    func noFixedFontSizes() {
        let violations = source.fixedFontSizeLines()
        #expect(violations.isEmpty,
                "Fixed font sizes at lines: \(violations). Use Dynamic Type styles (.body, .title, etc.).")
    }

    // MARK: - Navigation

    @Test("Has navigation title")
    func hasNavigationTitle() {
        #expect(source.containsPattern(#"\.navigationTitle"#),
                "NotificationsSettingsView must have .navigationTitle set.")
    }
}
```

**Step 2: Run test to verify it passes**

Run: `swift test --filter AXeTests.NotificationsSettingsView_AXeTests 2>&1 | tail -20`
Expected: All 5 tests PASS

**Step 3: Commit**

```bash
git add Tests/AXeTests/NotificationsSettingsView_AXeTests.swift
git commit -m "test(axe): add NotificationsSettingsView AXe tests

- Palette: no system colors, no deprecated foregroundColor
- Identifier: notifications.itemReady toggle
- Dynamic Type: no fixed font sizes
- Navigation: title set"
```

---

## Task 5: Add PrivacySettingsView AXe tests

View has a privacy policy link, delete account button with confirmation alert, and a navigation title.

**Files:**
- Create: `Tests/AXeTests/PrivacySettingsView_AXeTests.swift`

**Step 1: Write the test file**

```swift
// Generated from docs/testing/AXE-TEST-SCENARIOS.md — Privacy Settings section
// DO NOT EDIT MANUALLY — regenerate via /polish pipeline

import Foundation
import Testing

@Suite("AXe: PrivacySettingsView")
struct PrivacySettingsView_AXeTests {

    let source: SourceFile

    init() throws {
        source = try AXeTestHelpers.readSource(at: "Sources/ProfileFeature/Views/PrivacySettingsView.swift")
    }

    // MARK: - Palette

    @Test("No system colors in PrivacySettingsView")
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

    // MARK: - Accessibility Identifiers

    @Test("Privacy policy link has accessibility identifier")
    func privacyPolicyA11y() {
        #expect(source.containsPattern(#"privacy\.policy"#),
                "Privacy policy link must have .accessibilityIdentifier(\"privacy.policy\")")
    }

    @Test("Delete account button has accessibility identifier")
    func deleteAccountA11y() {
        #expect(source.containsPattern(#"privacy\.deleteAccount"#),
                "Delete account button must have .accessibilityIdentifier(\"privacy.deleteAccount\")")
    }

    // MARK: - Destructive Action Safety

    @Test("Delete account has confirmation alert")
    func deleteConfirmationAlert() {
        #expect(source.containsPattern(#"alert.*Delete Account"#),
                "Delete account must show confirmation alert before proceeding")
    }

    @Test("Delete button uses destructive role")
    func deleteButtonDestructiveRole() {
        #expect(source.containsPattern(#"role:\s*\.destructive"#),
                "Delete account button must use role: .destructive for clear visual warning")
    }

    // MARK: - Dynamic Type

    @Test("No fixed font sizes")
    func noFixedFontSizes() {
        let violations = source.fixedFontSizeLines()
        #expect(violations.isEmpty,
                "Fixed font sizes at lines: \(violations). Use Dynamic Type styles (.body, .title, etc.).")
    }

    // MARK: - Navigation

    @Test("Has navigation title")
    func hasNavigationTitle() {
        #expect(source.containsPattern(#"\.navigationTitle"#),
                "PrivacySettingsView must have .navigationTitle set.")
    }
}
```

**Step 2: Run test to verify it passes**

Run: `swift test --filter AXeTests.PrivacySettingsView_AXeTests 2>&1 | tail -20`
Expected: All 8 tests PASS

**Step 3: Commit**

```bash
git add Tests/AXeTests/PrivacySettingsView_AXeTests.swift
git commit -m "test(axe): add PrivacySettingsView AXe tests

- Palette: no system colors, no deprecated foregroundColor
- Identifiers: privacy.policy, privacy.deleteAccount
- Destructive action: confirmation alert, destructive role
- Dynamic Type: no fixed font sizes
- Navigation: title set"
```

---

## Task 6: Add HelpView AXe tests

View has contact support link, version label, and build label.

**Files:**
- Create: `Tests/AXeTests/HelpView_AXeTests.swift`

**Step 1: Write the test file**

```swift
// Generated from docs/testing/AXE-TEST-SCENARIOS.md — Help section
// DO NOT EDIT MANUALLY — regenerate via /polish pipeline

import Foundation
import Testing

@Suite("AXe: HelpView")
struct HelpView_AXeTests {

    let source: SourceFile

    init() throws {
        source = try AXeTestHelpers.readSource(at: "Sources/ProfileFeature/Views/HelpView.swift")
    }

    // MARK: - Palette

    @Test("No system colors in HelpView")
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

    // MARK: - Accessibility Identifiers

    @Test("Contact support link has accessibility identifier")
    func contactSupportA11y() {
        #expect(source.containsPattern(#"help\.contactSupport"#),
                "Contact support link must have .accessibilityIdentifier(\"help.contactSupport\")")
    }

    @Test("Version label has accessibility identifier")
    func versionA11y() {
        #expect(source.containsPattern(#"help\.version"#),
                "Version label must have .accessibilityIdentifier(\"help.version\")")
    }

    @Test("Build label has accessibility identifier")
    func buildA11y() {
        #expect(source.containsPattern(#"help\.build"#),
                "Build label must have .accessibilityIdentifier(\"help.build\")")
    }

    // MARK: - Dynamic Type

    @Test("No fixed font sizes")
    func noFixedFontSizes() {
        let violations = source.fixedFontSizeLines()
        #expect(violations.isEmpty,
                "Fixed font sizes at lines: \(violations). Use Dynamic Type styles (.body, .title, etc.).")
    }

    // MARK: - Navigation

    @Test("Has navigation title")
    func hasNavigationTitle() {
        #expect(source.containsPattern(#"\.navigationTitle"#),
                "HelpView must have .navigationTitle set.")
    }
}
```

**Step 2: Run test to verify it passes**

Run: `swift test --filter AXeTests.HelpView_AXeTests 2>&1 | tail -20`
Expected: All 7 tests PASS

**Step 3: Commit**

```bash
git add Tests/AXeTests/HelpView_AXeTests.swift
git commit -m "test(axe): add HelpView AXe tests

- Palette: no system colors, no deprecated foregroundColor
- Identifiers: help.contactSupport, help.version, help.build
- Dynamic Type: no fixed font sizes
- Navigation: title set"
```

---

## Task 7: Update AXE-TEST-SCENARIOS.md documentation

Add a new Profile sub-screen scenarios section and document the test file mapping.

**Files:**
- Modify: `docs/testing/AXE-TEST-SCENARIOS.md`

**Step 1: Add AXe Static Test File Reference section**

Append before the `## Known Limitations` section:

```markdown
## AXe Static Test File Reference

Static source-analysis tests (run via `swift test --filter AXeTests`) validate accessibility patterns in source code without requiring a running app. Each view file has a corresponding test file:

| View File | Test File | Tests |
|-----------|-----------|-------|
| `Sources/ProfileFeature/ProfileView.swift` | `Tests/AXeTests/ProfileView_AXeTests.swift` | 16 |
| `Sources/ProfileFeature/Components/UserInfoCard.swift` | `Tests/AXeTests/UserInfoCard_AXeTests.swift` | 9 |
| `Sources/ProfileFeature/Views/EditProfileSheet.swift` | `Tests/AXeTests/EditProfileSheet_AXeTests.swift` | 9 |
| `Sources/ProfileFeature/Views/NotificationsSettingsView.swift` | `Tests/AXeTests/NotificationsSettingsView_AXeTests.swift` | 5 |
| `Sources/ProfileFeature/Views/PrivacySettingsView.swift` | `Tests/AXeTests/PrivacySettingsView_AXeTests.swift` | 8 |
| `Sources/ProfileFeature/Views/HelpView.swift` | `Tests/AXeTests/HelpView_AXeTests.swift` | 7 |
| `Sources/CameraFeature/Views/CaptureView.swift` | `Tests/AXeTests/CaptureView_AXeTests.swift` | 7 |
| `Sources/CollectionFeature/CollectionView.swift` | `Tests/AXeTests/CollectionView_AXeTests.swift` | 10 |
| `Sources/CollectionFeature/EditFlow/EditItemSheet.swift` | `Tests/AXeTests/EditItemSheet_AXeTests.swift` | 19 |
| `Sources/OnboardingFeature/SignInView.swift` | `Tests/AXeTests/SignInView_AXeTests.swift` | 14 |

**Test categories checked per file:**
- **Palette**: No system colors, no deprecated `foregroundColor` API
- **Accessibility Identifiers**: Every identifier from the Identifier Reference table
- **Accessibility Labels**: Descriptive labels for interactive elements
- **Dynamic Type**: No fixed font sizes (`font(.system(size:))`)
- **Navigation**: Title set where applicable
- **Animation**: No raw animation curves (use brand tokens)
- **Destructive Actions**: Confirmation alerts for destructive operations (delete, sign out)
```

**Step 2: Add Changelog entry**

Append to the Changelog table:

```markdown
| 2026-02-09 | Added AXe Static Test File Reference section documenting all static source-analysis test files and their coverage categories. Added 6 new AXe test files for Profile Phase 1 views (54 total new tests). |
```

**Step 3: Commit**

```bash
git add docs/testing/AXE-TEST-SCENARIOS.md
git commit -m "docs(testing): add AXe static test file reference to scenarios doc

- Document all 10 AXe test files with view mappings and test counts
- List test categories checked per file
- Add changelog entry for Profile Phase 1 AXe tests"
```

---

## Task 8: Run full AXe test suite and verify

**Step 1: Run all AXe tests**

Run: `swift test --filter AXeTests 2>&1 | tail -30`
Expected: All tests PASS (existing + new)

**Step 2: Run full test suite to check for regressions**

Run: `swift test 2>&1 | tail -30`
Expected: All tests PASS

**Step 3: Final commit (if any fixups needed)**

If all tests pass with no changes needed, skip this step.

---

## Summary

| Task | File | New Tests |
|------|------|-----------|
| 1 | `ProfileView_AXeTests.swift` (update) | 16 (was 17, net -1 removed stale checks, +2 new) |
| 2 | `UserInfoCard_AXeTests.swift` (new) | 9 |
| 3 | `EditProfileSheet_AXeTests.swift` (new) | 9 |
| 4 | `NotificationsSettingsView_AXeTests.swift` (new) | 5 |
| 5 | `PrivacySettingsView_AXeTests.swift` (new) | 8 |
| 6 | `HelpView_AXeTests.swift` (new) | 7 |
| 7 | `AXE-TEST-SCENARIOS.md` (update) | — |
| 8 | Verification | — |
| **Total** | | **54 tests** |

**Prerequisites:**
- Must be on `feature/profile-phase1` branch (all Profile Phase 1 view files exist there)
- `swift test --filter AXeTests` passes before starting (baseline)
