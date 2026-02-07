---
name: polish
description: Deterministic polish pipeline for feature/brand-* branches. Syncs main, diffs changed views, reconciles view specs, runs 4 parallel auditors, applies fixes, builds, runs aXe tests, and reports.
---

# Polish Command

Deterministic 7-step pipeline that transforms functional code from `main` into brand-aligned, accessible, HIG-compliant UI.

**Branch requirement:** Must be on a `feature/brand-*` branch.

## Usage

```
/polish                    # Full pipeline: sync + diff + audit + fix + test
/polish --audit-only       # Skip sync, audit current state
/polish --spec-only        # Only reconcile view specs (no fixes)
```

## Pipeline

### Step 1: Sync

```bash
git fetch origin main
git rebase origin/main
```

If rebase conflicts occur, report them and stop — manual resolution required.

### Step 2: Diff

```bash
# Find what changed from main
git diff origin/main --name-only
```

Classify changed files into categories:

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
2. If **missing** → flag for spec creation (present what the view contains)
3. If **exists** → diff the view against its spec to find new elements needing spec entries

Report which specs need creation or updates.

### Step 4: Parallel Auditors

Dispatch 4 auditor agents in parallel against changed view/component files:

```
Task(subagent_type="general-purpose", description="Palette audit")
Task(subagent_type="general-purpose", description="Accessibility audit")
Task(subagent_type="general-purpose", description="Liquid Glass audit")
Task(subagent_type="general-purpose", description="HIG audit")
```

Each auditor reads the view file + its view spec and reports violations.

#### Palette Auditor

**Violation patterns:**
- System colors (`.blue`, `.gray`, `.purple`, `.red`, `.green`, `.orange`, etc.)
- Raw hex colors not from `Color+Brand.swift`
- `Color(uiColor: ...)` in view files
- `UIColor.system*` in view files (ADR-010 + palette violation)

**Auto-fix mapping:**
- `.blue` → `.accentPrimary`
- `.gray` → `.textPrimary.opacity(0.6)`
- `.red` → `.errorColor`
- `.green` → `.successColor`
- `.orange` → `.accentSecondary`
- `.purple` → `.accentPrimary`

#### Accessibility Auditor

**Violation patterns:**
- `Button` without `.accessibilityLabel`
- `Image` without `.accessibilityLabel` or `.accessibilityHidden(true)`
- Touch target < 44×44pt (missing `.frame(minWidth: 44, minHeight: 44)`)
- Missing `.accessibilityAddTraits` on interactive elements
- Fixed font sizes (`.font(.system(size:))`) instead of Dynamic Type
- Color contrast below 4.5:1 for body text
- Missing `.accessibilityElement(children: .combine)` on compound views

#### Liquid Glass Auditor

**Violation patterns:**
- `.ultraThinMaterial` / `.thinMaterial` / `.thickMaterial` without `adaptiveGlass()` upgrade
- `.glassEffect()` without pre-iOS 26 availability check
- Opaque toolbar/tab bar that spec says should be glass
- Not using `LiquidGlassHelpers.swift` utilities (`adaptiveGlass`, `brandGlass`)

#### HIG Auditor

**Violation patterns:**
- Custom back button replacing system navigation
- Tab bar with > 5 items
- Alert with > 3 actions
- Missing `.navigationTitle`
- Missing safe area handling
- Sheet without `.presentationDetents`

### Step 5: Apply Fixes

For each violation from Step 4:
1. **Auto-fixable** → apply the fix directly using Edit tool
2. **Ambiguous** → report for manual review
3. **Spec conflict** → flag the spec for update

### Step 6: Build & aXe Tests

```bash
# Verify fixes compile
swift build

# Run accessibility tests (if they exist)
swift test --filter AXeTests
```

### Step 7: Report

Present a summary:

```markdown
## Polish Report

### Synced from main
- N new/changed view files
- N view specs created/updated

### Violations Found
| Auditor | Critical | Warning | Auto-fixed |
|---------|----------|---------|------------|
| Palette | — | — | — |
| A11y | — | — | — |
| Glass | — | — | — |
| HIG | — | — | — |

### aXe Test Results
- N tests generated, N passed, N failed

### Manual Review Required
- [ ] ...
```

---

## View Spec Format

Each view spec lives in `docs/view-specs/<view-name>.md` and contains 5 tables:

1. **Palette** — every color in the view mapped to a brand token
2. **Accessibility** — element labels, traits, touch targets, Dynamic Type
3. **Liquid Glass** — glass treatments with pre-iOS 26 fallbacks
4. **Layout** — padding, spacing, aspect ratios, grid columns
5. **Animations & Haptics** — triggers, curves, haptic types

See existing specs in `docs/view-specs/` for examples.

---

## Error Handling

- **Not on brand branch** → refuse to run, show current branch
- **Rebase conflicts** → stop at Step 1, report conflicts
- **No changed view files** → report "nothing to polish" and exit
- **Build fails after fixes** → revert fixes, report build errors
- **aXe tests fail** → feed failures back to auditors (max 2 retries)
