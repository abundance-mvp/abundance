// Generated from docs/view-specs/edit-item-sheet.md
// DO NOT EDIT MANUALLY — regenerate via /polish pipeline

import Foundation
import Testing

@Suite("AXe: EditItemSheet")
struct EditItemSheet_AXeTests {

    let source: SourceFile

    init() throws {
        source = try AXeTestHelpers.readSource(at: "Sources/CollectionFeature/EditFlow/EditItemSheet.swift")
    }

    // MARK: - Palette

    @Test("No deprecated foregroundColor API")
    func noDeprecatedForegroundColor() {
        let violations = source.deprecatedForegroundColorLines()
        #expect(violations.isEmpty,
                "Deprecated .foregroundColor at lines: \(violations). Use .foregroundStyle instead.")
    }

    // MARK: - Accessibility Identifiers (from view spec table)

    @Test("Name field has accessibility identifier")
    func nameFieldA11y() {
        #expect(source.containsPattern(#"edit\.nameField"#),
                "Name field must have .accessibilityIdentifier(\"edit.nameField\")")
    }

    @Test("Brand field has accessibility identifier")
    func brandFieldA11y() {
        #expect(source.containsPattern(#"edit\.brandField"#),
                "Brand field must have .accessibilityIdentifier(\"edit.brandField\")")
    }

    @Test("Model field has accessibility identifier")
    func modelFieldA11y() {
        #expect(source.containsPattern(#"edit\.modelField"#),
                "Model field must have .accessibilityIdentifier(\"edit.modelField\")")
    }

    @Test("Category field has accessibility identifier")
    func categoryFieldA11y() {
        #expect(source.containsPattern(#"edit\.categoryField"#),
                "Category field must have .accessibilityIdentifier(\"edit.categoryField\")")
    }

    @Test("Sub-category field has accessibility identifier")
    func subCategoryFieldA11y() {
        #expect(source.containsPattern(#"edit\.subCategoryField"#),
                "Sub-category field must have .accessibilityIdentifier(\"edit.subCategoryField\")")
    }

    @Test("Color field has accessibility identifier")
    func colorFieldA11y() {
        #expect(source.containsPattern(#"edit\.colorField"#),
                "Color field must have .accessibilityIdentifier(\"edit.colorField\")")
    }

    @Test("Material field has accessibility identifier")
    func materialFieldA11y() {
        #expect(source.containsPattern(#"edit\.materialField"#),
                "Material field must have .accessibilityIdentifier(\"edit.materialField\")")
    }

    @Test("Dimensions field has accessibility identifier")
    func dimensionsFieldA11y() {
        #expect(source.containsPattern(#"edit\.dimensionsField"#),
                "Dimensions field must have .accessibilityIdentifier(\"edit.dimensionsField\")")
    }

    @Test("Condition picker has accessibility identifier")
    func conditionPickerA11y() {
        #expect(source.containsPattern(#"edit\.conditionPicker"#),
                "Condition picker must have .accessibilityIdentifier(\"edit.conditionPicker\")")
    }

    @Test("Quantity stepper has accessibility identifier")
    func quantityStepperA11y() {
        #expect(source.containsPattern(#"edit\.quantityStepper"#),
                "Quantity stepper must have .accessibilityIdentifier(\"edit.quantityStepper\")")
    }

    @Test("Value field has accessibility identifier")
    func valueFieldA11y() {
        #expect(source.containsPattern(#"edit\.valueField"#),
                "Value field must have .accessibilityIdentifier(\"edit.valueField\")")
    }

    @Test("Add photo button has accessibility identifier")
    func addPhotoButtonA11y() {
        #expect(source.containsPattern(#"edit\.addPhotoButton"#),
                "Add photo button must have .accessibilityIdentifier(\"edit.addPhotoButton\")")
    }

    @Test("Cancel button has accessibility identifier")
    func cancelButtonA11y() {
        #expect(source.containsPattern(#"edit\.cancelButton"#),
                "Cancel button must have .accessibilityIdentifier(\"edit.cancelButton\")")
    }

    @Test("Save button has accessibility identifier")
    func saveButtonA11y() {
        #expect(source.containsPattern(#"edit\.saveButton"#),
                "Save button must have .accessibilityIdentifier(\"edit.saveButton\")")
    }

    // MARK: - Accessibility Labels

    @Test("Remove photo buttons have accessibility labels")
    func removePhotoLabels() {
        #expect(source.containsPattern(#"accessibilityLabel\("Remove photo"#),
                "Remove photo buttons must have .accessibilityLabel(\"Remove photo {N}\")")
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
                "EditItemSheet must have .navigationTitle set.")
    }

    @Test("Has inline title display mode")
    func hasInlineTitleDisplayMode() {
        #expect(source.containsPattern(#"\.navigationBarTitleDisplayMode\(\.inline\)"#),
                "EditItemSheet must use .inline title display mode.")
    }

    // MARK: - Animation

    @Test("No raw animation curves")
    func noRawAnimationCurves() {
        let violations = source.rawAnimationCurves()
        #expect(violations.isEmpty,
                "Raw animation curves at lines: \(violations). Use brand animation tokens.")
    }

    // MARK: - Presentation

    @Test("Uses large presentation detent")
    func usesLargeDetent() {
        #expect(source.containsPattern(#"presentationDetents\(\[\.large\]\)"#),
                "EditItemSheet must present with .large detent.")
    }

    @Test("Interactive dismiss disabled when saving")
    func interactiveDismissDisabled() {
        #expect(source.containsPattern(#"interactiveDismissDisabled"#),
                "Interactive dismiss must be disabled when saving.")
    }
}
