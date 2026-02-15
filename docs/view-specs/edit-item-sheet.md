# View Spec: EditItemSheet

**Source:** `Sources/CollectionFeature/EditFlow/EditItemSheet.swift`
**Module:** CollectionFeature
**Priority:** P1
**Last updated:** 2026-02-08

---

## 1. Palette

| Element | Token | Hex | Usage |
|---------|-------|-----|-------|
| Section header text | `.primary` | — | System primary text (Form section headers) |
| Text field labels | `.primary` | — | System primary (TextField title) |
| Validation error text | `Color.errorColor` | — | `.foregroundStyle(Color.errorColor)` |
| Photo error text | `Color.errorColor` | — | `.foregroundStyle(Color.errorColor)` |
| Upload progress text | `.secondary` | — | System secondary text |
| Save button tint | `successColor` | `#9DC4A8` | `.tint(Color.successColor)` — maps to `mutedSage` |
| Currency "$" prefix | `.secondary` | — | System secondary text |
| AI confidence high | `successColor` | `#9DC4A8` | `.successColor` (maps to `mutedSage`) |
| AI confidence medium | `accentSecondary` | — | `.accentSecondary` |
| AI confidence low | `errorColor` | — | `.errorColor` |
| Delete photo icon | `.white` / `Color.errorColor` | — | `.foregroundStyle(.white, Color.errorColor)` via palette rendering |
| Add photo button bg | `Color.secondary.opacity(0.1)` | — | Secondary system color at 10% opacity |
| Saving overlay bg | `black.opacity(0.3)` | — | Scrim layer |
| Saving overlay card | `cream` + `peach` | — | Via `.abundanceCardStyle()` |

**Known violations:**
- Add photo button uses `Color.secondary.opacity(0.1)` — could use `Color.cream` for brand consistency

**Previously fixed:**
- ~~Validation/photo errors~~ now use `Color.errorColor`
- ~~`confidenceColor()`~~ now uses `.successColor`, `.accentSecondary`, `.errorColor`
- ~~Delete icon~~ now uses `Color.errorColor`

## 2. Accessibility

| Element | Identifier | Trait | Min Target | Dynamic Type |
|---------|-----------|-------|------------|--------------|
| Name field | `edit.nameField` | — | 44x44pt (Form row) | Body |
| Brand field | `edit.brandField` | — | 44x44pt (Form row) | Body |
| Model field | `edit.modelField` | — | 44x44pt (Form row) | Body |
| Category field | `edit.categoryField` | — | 44x44pt (Form row) | Body |
| Sub-category field | `edit.subCategoryField` | — | 44x44pt (Form row) | Body |
| Color field | `edit.colorField` | — | 44x44pt (Form row) | Body |
| Material field | `edit.materialField` | — | 44x44pt (Form row) | Body |
| Dimensions field | `edit.dimensionsField` | — | 44x44pt (Form row) | Body |
| Condition picker | `edit.conditionPicker` | — | 44x44pt (Form row) | Body |
| Quantity stepper | `edit.quantityStepper` | — | 44x44pt (Form row) | Body |
| Value field | `edit.valueField` | — | 44x44pt (Form row) | Body |
| Add photo button | `edit.addPhotoButton` | `.isButton` | 80x80pt | Caption2 |
| Remove photo N | "Remove photo {N}" | `.isButton` | Needs 44pt frame | Callout |
| Cancel button | `edit.cancelButton` | `.isButton` | 44x44pt (toolbar) | Body |
| Save button | `edit.saveButton` | `.isButton` | 44x44pt (toolbar) | Body |

**Known violations:**
- Remove photo button: no `.frame(minWidth: 44, minHeight: 44)` — touch target may be below 44pt
- Currency field "$" prefix and text field are separate — missing `.accessibilityElement(children: .combine)`

## 3. Liquid Glass

| Element | Treatment | Tint | Fallback (< iOS 26) |
|---------|-----------|------|---------------------|
| Navigation bar | System inline | — | System |
| Primary photo badge | `.ultraThinMaterial` in `Capsule()` | — | Material stays |
| Saving overlay card | `.abundanceCardStyle()` | — | Cream bg + peach stroke |
| Form sections | System `Form` chrome | — | System grouped inset |

**Opportunities:**
- Saving overlay card could use `adaptiveGlass(radius: .large)` for glass effect
- Photo thumbnail overlay badges could use glass treatment

## 4. Layout

| Element | Constraint | Value |
|---------|-----------|-------|
| Sheet presentation | detents | `.large` only |
| Form | style | System grouped (default) |
| Validation error spacing | VStack spacing | 4pt |
| Currency input max width | frame | 100pt |
| Photo thumbnails | fixed size | 80x80pt |
| Photo thumbnail corners | radius | 8pt |
| Photo HStack spacing | spacing | 12pt |
| Photo scroll padding | vertical | 4pt |
| Primary badge padding | h/v | 4pt / 2pt |
| Delete button padding | all edges | 4pt |
| Add photo VStack spacing | spacing | 4pt |
| Saving overlay inner padding | all edges | 24pt |
| Saving overlay VStack spacing | spacing | 16pt |
| ProgressView scale (saving) | scaleEffect | 1.2x |
| Interactive dismiss | disabled when | `viewModel.state == .saving` |

## 5. Animations & Haptics

| Trigger | Animation | Haptic | Duration |
|---------|-----------|--------|----------|
| Save button tap | None (async Task) | None | — |
| Cancel button tap | Sheet dismiss | None | System |
| Photo upload | ProgressView spinner | None | Indeterminate |
| Saving state | SavingOverlay appears | None | — |

**Known violations:**
- No explicit animations on saving overlay appear/disappear
- No haptic feedback on save or photo delete

---

## Subviews (private)

### EditableTextField
- VStack: TextField + optional error Text
- Error text: `.font(.caption)`, `.foregroundStyle(Color.errorColor)`

### EditableNumberField
- Stepper(in: 1...1000) + optional error Text

### EditableCurrencyField
- HStack: "$" label + TextField with `.keyboardType(.decimalPad)`

### SavingOverlay
- Scrim (`black.opacity(0.3)`) + card with ProgressView + "Saving..." text
- Card uses `.abundanceCardStyle()`
