# Polish Branch Design: `feature/brand-design-system`

**Status:** Active
**Created:** 2026-02-06
**Branch:** `feature/brand-design-system`
**Depends On:** `docs/plans/2026-02-06-brand-bible-revision-design-system-specs.md`

---

## 1. Architecture Overview

The polish branch operates as a 6-layer system that transforms raw functional code from `main` into brand-aligned, accessible, HIG-compliant UI.

```
┌─────────────────────────────────────────────┐
│  Layer 6: Pre-Commit Guard Hook             │  ← Rejects violations before commit
│  Layer 5: aXe Test Generation & Validation  │  ← Spec-driven UI tests
│  Layer 4: Auditor Agents (4 parallel)       │  ← Palette, A11y, Glass, HIG
│  Layer 3: /polish Command (7-step pipeline) │  ← Orchestration
│  Layer 2: Living View Specs                 │  ← Per-view truth documents
│  Layer 1: Sync & Diff                       │  ← Fetch, rebase, classify changes
└─────────────────────────────────────────────┘
```

**Data flow:** `main` pushes new code → Layer 1 syncs and diffs → Layer 2 specs define expected state → Layer 3 orchestrates the pipeline → Layer 4 auditors find violations → Layer 5 generates/runs tests → Layer 6 guards commits.

**Key principle:** The polish branch never adds features. It only transforms how existing features look, feel, and comply with brand/accessibility/HIG standards.

---

## 2. Living View Specs

Each SwiftUI view gets a companion markdown spec in `docs/view-specs/`. These specs are the single source of truth for how a view should look and behave from a brand/UX perspective.

### File naming convention

```
docs/view-specs/
├── camera-view.md
├── capture-view.md
├── detection-results-view.md
├── inventory-view.md
├── item-detail-view.md
├── photo-carousel-view.md
├── edit-item-sheet.md
├── rescan-comparison-sheet.md
├── sign-in-view.md
├── profile-view.md
└── main-tab-view.md
```

### Spec format

Each spec contains 5 tables:

#### Table 1: Palette

| Element | Token | Hex | Usage |
|---------|-------|-----|-------|
| Background | `backgroundDefault` | `#FCFCFF` | View background |
| Primary CTA | `accentPrimary` | `#4381DF` | Main action button |
| Error text | `errorColor` | `#CC5D3A` | Validation messages |

**Rule:** Every color in the view must map to a token from `Color+Brand.swift`. System colors (`.blue`, `.gray`, `.purple`) are violations.

#### Table 2: Accessibility

| Element | Label | Trait | Min Target | Dynamic Type |
|---------|-------|-------|------------|--------------|
| Capture button | "Take photo" | `.isButton` | 44×44pt | Fixed |
| Item name | item.displayName | `.isHeader` | — | Title1 |
| Delete action | "Delete item" | `.isButton` | 44×44pt | Body |

**Rule:** Every interactive element must have an explicit accessibility label, correct trait, and 44×44pt minimum touch target.

#### Table 3: Liquid Glass

| Element | Treatment | Tint | Fallback (< iOS 26) |
|---------|-----------|------|---------------------|
| Navigation bar | `.glassEffect()` | `accentPrimary` | `.ultraThinMaterial` |
| Tab bar | `.glassEffect()` | none | `.regularMaterial` |
| Card overlay | `.glassEffect(.regular)` | `backgroundDefault` | `.thickMaterial` |

**Rule:** Glass treatments are progressive — always specify a pre-iOS 26 fallback.

#### Table 4: Layout Constraints

| Element | Constraint | Value |
|---------|-----------|-------|
| Content padding | horizontal | 16pt |
| Card spacing | vertical | 12pt |
| Hero image | aspect ratio | 4:3 |
| Grid columns | adaptive min | 160pt |

#### Table 5: Animations & Haptics

| Trigger | Animation | Haptic | Duration |
|---------|-----------|--------|----------|
| Item appears | `.spring(duration: 0.3)` | none | 300ms |
| Capture | `.easeOut(duration: 0.15)` | `.impact(.medium)` | 150ms |
| Error | `.shake` | `.notification(.error)` | — |

**Rule:** All animations must use brand-defined curves from `Animation+Brand.swift`. Raw `withAnimation {}` without a named curve is a violation.

### When specs update

- **New view from main:** Create a new spec during polish
- **Changed view from main:** Review and update the existing spec
- **New feature from main:** Update all affected view specs (may touch multiple views)
- **Deleted view from main:** Archive the spec

---

## 3. The `/polish` Command

**File:** `.claude/commands/polish.md`

A 7-step deterministic pipeline that runs on the `feature/brand-design-system` branch.

### Step 1: Sync

```bash
git fetch origin main
git rebase origin/main
```

If rebase conflicts occur, report them and stop — manual resolution required.

### Step 2: Diff

```bash
git diff origin/main...HEAD --name-only     # Already polished files
git diff main --name-only                     # New changes from main
```

Classify changed files:

| Pattern | Category |
|---------|----------|
| `Sources/**/*View.swift` | view |
| `Sources/**/*Sheet.swift` | view |
| `App/*TabView.swift` | view |
| `Sources/**/Components/*.swift` | component |
| `Sources/**/ViewModels/*.swift` | viewmodel |
| `Sources/Core/DesignSystem/**` | designsystem |
| Other `.swift` | skip (not UI) |

Only `view`, `component`, and `designsystem` files enter the pipeline.

### Step 3: Spec Reconciliation

For each changed view/component file:

1. Check if `docs/view-specs/<view-name>.md` exists
2. If **missing** → create a new spec from the view's current state
3. If **exists** → diff the view against its spec to find new elements that need spec entries

Output: list of specs needing updates + list of views ready for audit.

### Step 4: Parallel Auditors

Dispatch 4 auditor agents in parallel against only the changed files:

```
┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  Palette     │  │ Accessibility│  │ Liquid Glass  │  │     HIG      │
│  Auditor     │  │   Auditor    │  │   Auditor     │  │   Auditor    │
└──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘
```

Each auditor reads the view file + its view spec and reports violations. See Section 4 for details.

### Step 5: Apply Fixes

For each violation:
1. Auto-fixable → apply the fix directly
2. Ambiguous → report for manual review
3. Spec conflict → flag the spec for update

### Step 6: Build & aXe Tests

```bash
swift build                    # Verify fixes compile
# Generate/update aXe tests from view specs (see Section 5)
swift test --filter AXeTests   # Run accessibility tests
```

### Step 7: Report

```markdown
## Polish Report

### Synced from main
- N new/changed view files
- N view specs created/updated

### Violations Found
| Auditor | Critical | Warning | Auto-fixed |
|---------|----------|---------|------------|
| Palette | 2 | 5 | 6 |
| A11y | 1 | 3 | 3 |
| Glass | 0 | 2 | 2 |
| HIG | 0 | 1 | 0 |

### aXe Test Results
- N tests generated, N passed, N failed

### Manual Review Required
- [ ] ProfileView: ambiguous color on custom gradient
- [ ] ItemDetailView: HIG violation needs design decision
```

---

## 4. Auditor Agent Definitions

### 4.1 Palette Auditor

**Purpose:** Ensure every color reference uses a brand token.

**Violation patterns:**

| Pattern | Severity | Auto-fix |
|---------|----------|----------|
| `.blue`, `.gray`, `.purple`, `.red`, `.green`, `.orange` | Critical | Replace with nearest brand token |
| `.foregroundColor(Color(...))` with raw hex | Warning | Map to brand token |
| `Color(uiColor: ...)` | Warning | Replace with brand equivalent |
| `UIColor.systemBlue` (in views) | Critical | ADR-010 + palette violation |

**Auto-fix rules:**
- `.blue` → `.accentPrimary`
- `.gray` → `.textPrimary.opacity(0.6)`
- `.red` → `.errorColor`
- `.green` → `.successColor`
- `.orange` → `.warningColor`
- `.purple` → `.accentPrimary` (closest brand match)

**Input:** View file + view spec palette table
**Output:** List of violations with line numbers and suggested fixes

### 4.2 Accessibility Auditor

**Purpose:** Ensure WCAG AA compliance and full VoiceOver support.

**Violation patterns:**

| Pattern | Severity | Auto-fix |
|---------|----------|----------|
| `Button` without `.accessibilityLabel` | Critical | Add label from spec |
| Image without `.accessibilityLabel` or `.accessibilityHidden(true)` | Critical | Add based on context |
| Touch target < 44×44pt | Critical | Add `.frame(minWidth: 44, minHeight: 44)` |
| Missing `.accessibilityAddTraits` on interactive elements | Warning | Add from spec |
| Text without Dynamic Type support (fixed font size) | Warning | Replace with relative size |
| Color contrast below 4.5:1 for body text | Critical | Use text-safe variant |
| Missing `.accessibilityElement(children: .combine)` on compound views | Warning | Add modifier |

**Input:** View file + view spec accessibility table
**Output:** Violations with WCAG criterion references

### 4.3 Liquid Glass Auditor

**Purpose:** Ensure correct glass effect adoption with fallbacks.

**Violation patterns:**

| Pattern | Severity | Auto-fix |
|---------|----------|----------|
| `.ultraThinMaterial` without `if #available(iOS 26, *)` glass upgrade | Warning | Add glass with fallback |
| `.glassEffect()` without pre-iOS 26 fallback | Critical | Add availability check |
| Opaque toolbar that spec says should be glass | Warning | Apply glass from spec |
| `.background(.thinMaterial)` in navigation chrome | Warning | Upgrade to glass |

**Input:** View file + view spec glass table
**Output:** Violations with before/after code

### 4.4 HIG Auditor

**Purpose:** Ensure Human Interface Guidelines compliance.

**Violation patterns:**

| Pattern | Severity | Auto-fix |
|---------|----------|----------|
| Custom back button replacing system behavior | Warning | No auto-fix |
| Tab bar with > 5 items | Critical | No auto-fix |
| Alert with > 3 actions | Warning | No auto-fix |
| Navigation title not set | Warning | Add `.navigationTitle` |
| Missing safe area handling | Warning | No auto-fix |
| Custom gesture overriding system gesture | Warning | No auto-fix |
| Sheet without `.presentationDetents` | Warning | Add `.medium` + `.large` |

**Input:** View file + HIG reference
**Output:** Violations with HIG section references

---

## 5. aXe Test Generation & Validation

### Test generation from view specs

For each view spec's accessibility table, generate a corresponding XCUITest:

**Input spec row:**

| Element | Label | Trait | Min Target | Dynamic Type |
|---------|-------|-------|------------|--------------|
| Capture button | "Take photo" | `.isButton` | 44×44pt | Fixed |

**Generated test:**

```swift
func test_captureButton_accessibility() throws {
    let button = app.buttons["Take photo"]
    XCTAssertTrue(button.exists, "Capture button must exist with label 'Take photo'")
    XCTAssertGreaterThanOrEqual(button.frame.width, 44, "Touch target width >= 44pt")
    XCTAssertGreaterThanOrEqual(button.frame.height, 44, "Touch target height >= 44pt")
}
```

### Test file naming

```
Tests/AXeTests/
├── CameraView_AXeTests.swift
├── InventoryView_AXeTests.swift
├── ItemDetailView_AXeTests.swift
├── ProfileView_AXeTests.swift
└── ...
```

### Generation pipeline

1. Parse view spec accessibility table
2. For each row, generate test method
3. Write to `Tests/AXeTests/<ViewName>_AXeTests.swift`
4. Run `swift test --filter AXeTests`
5. If failures → feed back to auditor for auto-fix (max 2 retries)

### Feedback loop

```
Spec → Generate Tests → Run Tests
                              │
                         Pass? ──Yes──→ Done
                              │
                         No ──→ Feed failures to auditor
                              │
                         Auto-fix → Re-run (max 2 retries)
                              │
                         Still failing → Report for manual review
```

---

## 6. Pre-Commit Guard Hook

**File:** `scripts/brand-guard.sh`
**Activation:** Only on `feature/brand-*` branches

### Hook installation

```bash
# In .claude/hooks or .git/hooks/pre-commit
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$BRANCH" == feature/brand-* ]]; then
    scripts/brand-guard.sh
fi
```

### Violation patterns

The guard scans staged `.swift` files for:

| Pattern | Regex | Message |
|---------|-------|---------|
| System colors | `\.(blue|gray|purple|red|green|orange|yellow|pink|mint|cyan|indigo|teal|brown)\b` (excluding comments/strings) | "Use brand token instead of system color" |
| Fixed fonts | `\.font\(\.system\(size:` | "Use Dynamic Type (.body, .title, etc.)" |
| Ungated animations | `withAnimation\s*\{` without named curve | "Use Animation+Brand curve" |
| Raw UIColor | `UIColor\.system` in View/Component files | "ADR-010: no UIKit in views" |

### Behavior

- **Violation found:** Block commit, print violation with file:line and suggested fix
- **Clean:** Allow commit
- **Bypass:** `git commit --no-verify` (escape hatch for legitimate exceptions)

### Example output

```
🛑 Brand Guard: 2 violations found

Sources/InventoryFeature/InventoryView.swift:42
  .foregroundColor(.blue)
  → Use .foregroundColor(.accentPrimary)

Sources/ProfileFeature/ProfileView.swift:18
  .font(.system(size: 24))
  → Use .font(.title) for Dynamic Type support

Commit blocked. Fix violations or use --no-verify to bypass.
```

---

## 7. Implementation Plan

### Phase 1: Foundation (create infrastructure)

1. Create `docs/view-specs/` directory
2. Write `scripts/brand-guard.sh` pre-commit hook
3. Create `.claude/commands/polish.md` command skeleton
4. Write view specs for 3 priority views: `InventoryView`, `ItemDetailView`, `CameraView`

### Phase 2: Auditors (build the 4 auditor agents)

5. Implement Palette Auditor as a Task agent prompt
6. Implement Accessibility Auditor as a Task agent prompt
7. Implement Liquid Glass Auditor as a Task agent prompt
8. Implement HIG Auditor as a Task agent prompt
9. Wire all 4 into `/polish` command's Step 4

### Phase 3: Testing (aXe test generation)

10. Create `Tests/AXeTests/` target in `Package.swift`
11. Build spec-to-test generator (reads view spec markdown → writes XCUITest)
12. Generate initial aXe tests for Phase 1 view specs
13. Wire test generation into `/polish` command's Step 6

### Phase 4: Remaining view specs

14. Write view specs for remaining views (SignInView, ProfileView, PhotoCarouselView, EditItemSheet, etc.)
15. Run full `/polish` pipeline end-to-end
16. Fix all violations and verify aXe tests pass

### Phase 5: Automation

17. Wire pre-commit hook into `scripts/setup-hooks.sh`
18. Add branch detection logic for `feature/brand-*` gating
19. Document the full workflow in `docs/adr/` as an ADR

---

## Appendix: View Inventory

Views requiring specs (13 views + 3 sheets + 2 app-level):

| View | Module | Priority |
|------|--------|----------|
| `InventoryView` | InventoryFeature | P0 |
| `ItemDetailView` | InventoryFeature | P0 |
| `CameraView` | CameraFeature | P0 |
| `CaptureView` | CameraFeature | P1 |
| `ProfileView` | ProfileFeature | P1 |
| `SignInView` | OnboardingFeature | P1 |
| `PhotoCarouselView` | InventoryFeature | P1 |
| `DetectionResultsView` | CameraFeature | P2 |
| `ErrorRecoveryView` | CameraFeature | P2 |
| `EditItemSheet` | InventoryFeature | P2 |
| `RescanComparisonSheet` | InventoryFeature | P2 |
| `RescanPromptSheet` | InventoryFeature | P2 |
| `MainTabView` | App | P2 |
| `CameraPreviewView` | CameraFeature | P3 (UIViewRepresentable) |
| `AddPhotoCameraView` | InventoryFeature | P3 |
| `RescanCameraView` | InventoryFeature | P3 |
