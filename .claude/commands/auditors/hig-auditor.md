---
name: hig-auditor
description: Scan Swift view files for Apple Human Interface Guidelines violations — navigation, tab bars, alerts, safe areas, sheet detents, animation curves
---

# HIG Auditor

Scan the provided Swift view/component files for Apple Human Interface Guidelines violations.

## Instructions

1. Read the view spec from `docs/view-specs/<view-name>.md` (if it exists) — check all tables for HIG-relevant entries
2. Read `Sources/Core/DesignSystem/Extensions/Animation+Brand.swift` to know valid brand animation curves
3. Read each target Swift file
4. Scan for violations using the patterns below
5. Report findings in the output format

## Violation Patterns

### Critical (App Store risk)

| Pattern | How to Detect | Fix |
|---------|---------------|-----|
| Custom back button | `navigationBarBackButtonHidden(true)` with custom back button | Use system back button |
| Tab bar > 5 items | `TabView` with more than 5 tab items | Use "More" tab or redesign |
| Alert > 3 actions | `.alert` with more than 3 buttons | Redesign as action sheet |
| Missing safe area | Content clipped by notch/home indicator without `.ignoresSafeArea()` or `.safeAreaInset` | Handle safe areas |

### Warning (UX degradation)

| Pattern | How to Detect | Fix |
|---------|---------------|-----|
| Missing navigation title | `NavigationStack` or `NavigationView` without `.navigationTitle` | Add `.navigationTitle("Title")` |
| Sheet without detents | `.sheet` without `.presentationDetents` | Add `.presentationDetents([.medium, .large])` |
| Raw animation curve | `withAnimation { }` without named curve or `.animation(.easeInOut)` without brand name | Use `Animation+Brand` curves |
| Raw animation duration | `.animation(.easeInOut(duration: N))` | Use `.brandDefault`, `.brandPress`, or `.brandReducedMotion` |
| Missing reduce motion | `withAnimation` or `.animation` without `reduceMotion` guard | Check `@Environment(\.accessibilityReduceMotion)` |
| Overriding system gesture | Custom swipe/drag that conflicts with system back gesture | Avoid leading-edge swipe conflicts |
| Non-standard tab icons | Tab bar items without SF Symbols | Use SF Symbols for tab icons |

### Info (polish opportunities)

| Pattern | Description |
|---------|-------------|
| `.navigationBarTitleDisplayMode(.inline)` | Consider `.large` for primary screens |
| Missing `.toolbar` | View could benefit from toolbar actions |
| No `.confirmationDialog` for destructive actions | Destructive operations should confirm |
| Long press without preview | Could benefit from context menu preview |
| Missing `.searchable` | List views that could benefit from search |

## Animation Rules

The app defines 3 brand animation curves in `Animation+Brand.swift`:

| Curve | Usage | When |
|-------|-------|------|
| `.brandPress` | Quick interactions | Button taps, toggles, selection |
| `.brandDefault` | Standard transitions | Screen transitions, card entrance, modal presentation |
| `.brandReducedMotion` | Accessibility fallback | When `accessibilityReduceMotion` is enabled |

**Violation:** Any `.animation(.easeIn...)` or `.animation(.spring(...))` that doesn't use a brand curve.

**Exception:** System-driven animations (`.transition`, `matchedGeometryEffect`) don't need brand curves.

## Navigation Rules

| Rule | Description |
|------|-------------|
| NavigationStack preferred | Use `NavigationStack` over deprecated `NavigationView` |
| Programmatic navigation | Use `NavigationPath` for deep linking |
| Title required | Every NavigationStack must have `.navigationTitle` |
| Back button | Never hide system back button without good reason |
| Toolbar placement | Use `.primaryAction`, `.cancellationAction`, `.confirmationAction` |

## Sheet Rules

| Rule | Description |
|------|-------------|
| Detents required | Every `.sheet` should have `.presentationDetents` |
| Drag indicator | Consider `.presentationDragIndicator(.visible)` |
| Dismiss action | Provide cancel/done in sheet toolbar |
| Full screen cover | Only for camera, onboarding, or immersive content |

## Output Format

```markdown
## HIG Audit Results

### {filename}

| Line | Violation | Description | HIG Section | Severity |
|------|-----------|-------------|-------------|----------|
| 42 | Raw animation | `.easeInOut(duration: 0.3)` | Motion | Warning |
| 88 | Missing title | NavigationStack without title | Navigation | Warning |

### Summary
- Critical: N violations
- Warning: N violations
- Info: N suggestions
- Files scanned: N
- HIG compliance: PASS / NEEDS REVIEW
```

## Auto-Fix Rules

1. **Raw animation → brand curve:**
   ```swift
   // Before
   .animation(.easeInOut(duration: 0.3), value: x)
   // After
   .animation(reduceMotion ? nil : .brandDefault, value: x)
   ```

2. **Missing navigation title:**
   ```swift
   // Add after NavigationStack opening
   .navigationTitle("Screen Name")
   ```

3. **Sheet without detents:**
   ```swift
   // Add to .sheet modifier chain
   .presentationDetents([.medium, .large])
   ```
