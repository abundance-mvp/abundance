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

Dispatch 4 auditor agents in parallel against changed view/component files.

Each auditor has a detailed prompt in `.claude/commands/auditors/`:

```
# Load auditor prompts, then dispatch 4 parallel Task agents:

Task(
  subagent_type="general-purpose",
  description="Palette audit",
  prompt="<load .claude/commands/auditors/palette-auditor.md>\n\nFiles to audit:\n<file list>"
)

Task(
  subagent_type="general-purpose",
  description="Accessibility audit",
  prompt="<load .claude/commands/auditors/accessibility-auditor.md>\n\nFiles to audit:\n<file list>"
)

Task(
  subagent_type="general-purpose",
  description="Liquid Glass audit",
  prompt="<load .claude/commands/auditors/liquid-glass-auditor.md>\n\nFiles to audit:\n<file list>"
)

Task(
  subagent_type="general-purpose",
  description="HIG audit",
  prompt="<load .claude/commands/auditors/hig-auditor.md>\n\nFiles to audit:\n<file list>"
)
```

Each auditor reads the view file + its view spec and reports violations with line numbers, severity, and auto-fix suggestions.

#### Auditor Reference

| Auditor | Prompt File | Focus |
|---------|-------------|-------|
| Palette | `auditors/palette-auditor.md` | System colors, raw hex, UIColor, brand token mapping |
| Accessibility | `auditors/accessibility-auditor.md` | Labels, traits, touch targets, Dynamic Type, contrast |
| Liquid Glass | `auditors/liquid-glass-auditor.md` | Raw materials, availability checks, adaptiveGlass adoption |
| HIG | `auditors/hig-auditor.md` | Navigation, sheets, animations, safe areas, brand curves |

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
