---
name: accessibility-auditor
description: Scan Swift view files for WCAG AA accessibility violations — missing labels, traits, touch targets, Dynamic Type, contrast
---

# Accessibility Auditor

Scan the provided Swift view/component files for accessibility violations against WCAG AA and Apple HIG accessibility requirements.

## Instructions

1. Read the view spec from `docs/view-specs/<view-name>.md` (if it exists) — check the Accessibility table
2. Read each target Swift file
3. Scan for violations using the patterns below
4. Cross-reference against the view spec's accessibility table for missing entries
5. Report findings in the output format

## Violation Patterns

### Critical (blocks App Store / breaks VoiceOver)

| Pattern | How to Detect | Auto-fix |
|---------|---------------|----------|
| Button without label | `Button {` or `Button(action:` not followed by `.accessibilityLabel` within 10 lines | Add `.accessibilityLabel("descriptive label")` |
| Image without a11y | `Image(systemName:` or `Image(` not followed by `.accessibilityLabel` or `.accessibilityHidden(true)` | Add appropriate modifier |
| Touch target < 44pt | Interactive element without `.frame(minWidth: 44, minHeight: 44)` | Add frame modifier |
| Color-only meaning | Information conveyed only by color (no text/icon alternative) | Add text label |
| Missing contrast | Body text on colored background below 4.5:1 ratio | Use text-safe variant |

### Warning (accessibility degradation)

| Pattern | How to Detect | Auto-fix |
|---------|---------------|----------|
| Fixed font size | `.font(.system(size: N))` | → `.font(.body)` or appropriate Dynamic Type style |
| Missing traits | Interactive element without `.accessibilityAddTraits` | Add appropriate trait |
| Ungrouped compound | Related elements not wrapped in `.accessibilityElement(children: .combine)` | Add combining modifier |
| Missing hint | Complex interaction without `.accessibilityHint` | Add hint text |
| Decorative image | Meaningful image marked `.accessibilityHidden(true)` | Remove hidden or add label |
| Missing identifier | Testable element without `.accessibilityIdentifier` | Add identifier |

### Info (best practice)

| Pattern | Description |
|---------|-------------|
| `@ScaledMetric` not used | Fixed dimensions that should scale with Dynamic Type |
| `.accessibilityReduceMotion` not checked | Animations without reduce motion support |
| `.accessibilityReduceTransparency` not checked | Glass/blur effects without solid fallback |
| Custom rotor | Complex content that would benefit from custom accessibility rotor |

## Touch Target Rules

Per Apple HIG, minimum touch target is 44×44 points:

- Buttons: Must have `.frame(minWidth: 44, minHeight: 44)` OR be large enough intrinsically
- Tab bar items: System-handled (OK)
- Navigation bar items: System-handled (OK)
- List rows: System-handled (OK)
- Custom interactive views: Must enforce 44pt minimum

**Exceptions:**
- Elements inside `ScrollView` that are part of a continuous content area
- Inline text links (covered by text selection)
- System controls (Switch, Slider, Stepper) — system-handled

## Dynamic Type Rules

| Style | Usage | When to use |
|-------|-------|-------------|
| `.largeTitle` | Screen headers | Main screen title (rare) |
| `.title` / `.title2` / `.title3` | Section headers | Section headings, item names |
| `.headline` | Emphasized body | Important labels |
| `.body` | Default text | Most content |
| `.callout` | Secondary content | Supporting text |
| `.subheadline` | Smaller emphasis | Metadata labels |
| `.footnote` | Small detail | Timestamps, counts |
| `.caption` / `.caption2` | Smallest | Badges, tags |

**Violation:** `.font(.system(size: N))` — hardcoded size doesn't scale with Dynamic Type.
**Exception:** `.font(.system(.body, design: .rounded))` is OK — uses Dynamic Type size.

## Output Format

```markdown
## Accessibility Audit Results

### {filename}

| Line | Violation | Element | Issue | Fix | Severity |
|------|-----------|---------|-------|-----|----------|
| 42 | Missing label | Button | No accessibilityLabel | Add `.accessibilityLabel("Delete item")` | Critical |
| 88 | Fixed font | Text | `.system(size: 24)` | Use `.title` | Warning |

### Summary
- Critical: N violations
- Warning: N violations
- Info: N suggestions
- Files scanned: N
- WCAG AA compliance: PASS / FAIL
```

## Cross-Reference with View Spec

If the view spec's accessibility table exists:
1. Verify every element in the table has the documented label, trait, and target
2. Flag elements present in code but missing from the spec table
3. Flag elements in the spec table but not found in code (stale spec)
