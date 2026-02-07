---
name: liquid-glass-auditor
description: Scan Swift view files for Liquid Glass adoption opportunities and violations — raw materials, missing availability checks, unused adaptiveGlass utilities
---

# Liquid Glass Auditor

Scan the provided Swift view/component files for Liquid Glass adoption opportunities and violations.

## Instructions

1. Read `Sources/Core/DesignSystem/Extensions/LiquidGlassHelpers.swift` to understand available utilities
2. Read the view spec from `docs/view-specs/<view-name>.md` (if it exists) — check the Liquid Glass table
3. Read each target Swift file
4. Scan for violations and opportunities using the patterns below
5. Report findings in the output format

## Available Glass Utilities (from LiquidGlassHelpers.swift)

| Utility | Usage | Description |
|---------|-------|-------------|
| `adaptiveGlass(cornerRadius:tint:)` | Recommended | Auto-detects iOS version, handles reduce transparency |
| `adaptiveGlass(in: Shape, tint:)` | Custom shape | For non-rectangular glass |
| `adaptiveGlass(radius: .medium)` | Design tokens | Uses `GlassCornerRadius` enum |
| `brandGlass(tint:interactive:)` | iOS 26+ only | Direct glass without fallback |
| `brandGlass(cornerRadius:tint:)` | iOS 26+ only | Rounded rect glass without fallback |
| `brandGlassFallback(cornerRadius:)` | iOS 17-25 only | Material-only approximation |
| `GlassIntensity` | Design token | `.light`, `.medium`, `.heavy` |
| `GlassCornerRadius` | Design token | `.small(8)`, `.medium(16)`, `.large(24)`, `.extraLarge(32)` |

## Violation Patterns

### Critical (broken glass)

| Pattern | How to Detect | Fix |
|---------|---------------|-----|
| `.glassEffect()` without `#available` | `glassEffect` not inside `if #available(iOS 26` block | Wrap in availability check or use `adaptiveGlass()` |
| Glass without reduce transparency fallback | `glassEffect` without `accessibilityReduceTransparency` check | Use `adaptiveGlass()` which handles this |

### Warning (missed opportunity)

| Pattern | How to Detect | Fix |
|---------|---------------|-----|
| Raw `.ultraThinMaterial` | `.ultraThinMaterial` not inside `adaptiveGlass` | Replace with `adaptiveGlass(cornerRadius:)` |
| Raw `.thinMaterial` | `.thinMaterial` in background | Replace with `adaptiveGlass(cornerRadius:)` |
| Raw `.thickMaterial` | `.thickMaterial` in background | Replace with `adaptiveGlass(cornerRadius:)` |
| Raw `.ultraThickMaterial` | `.ultraThickMaterial` in background | Replace with `adaptiveGlass(cornerRadius:)` |
| Inline availability check | `if #available(iOS 26` with manual glass + fallback | Consolidate to `adaptiveGlass()` |
| Inline reduce transparency check | Manual `reduceTransparency` + glass/solid branching | Use `adaptiveGlass()` which handles this |

### Info (adoption opportunities)

| Pattern | Description |
|---------|-------------|
| Opaque toolbar background | Could benefit from glass treatment |
| Solid card background | Could use glass on iOS 26+ with solid fallback |
| Navigation bar chrome | Could use glass tinting |
| Bottom bar / tab bar | Could use glass background |

### Exclusions (skip these)

- Camera preview overlays using `.black.opacity()` (intentional for viewfinder contrast)
- `Color.clear` backgrounds
- Backgrounds inside `#Preview` blocks
- `AbundanceCard` / `.abundanceCardStyle()` — separate design decision

## Output Format

```markdown
## Liquid Glass Audit Results

### {filename}

| Line | Type | Current | Suggested | Severity |
|------|------|---------|-----------|----------|
| 84 | Raw material | `.background(.thickMaterial, in: shape)` | `.adaptiveGlass(cornerRadius: 16)` | Warning |
| 317 | Inline check | `if #available(iOS 26)` + manual glass | `.adaptiveGlass(in: Capsule())` | Warning |

### Opportunities
- Line 192: Opaque toolbar could use glass treatment
- Line 45: Card background could upgrade to glass on iOS 26+

### Summary
- Critical: N violations
- Warning: N consolidation opportunities
- Info: N adoption opportunities
- Files scanned: N
```

## Auto-Fix Rules

When applying fixes:

1. **Raw material → adaptiveGlass:**
   ```swift
   // Before
   .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 16))

   // After
   .adaptiveGlass(cornerRadius: 16)
   ```

2. **Inline availability → adaptiveGlass:**
   ```swift
   // Before
   if #available(iOS 26.0, *) {
       content.glassEffect(in: shape)
   } else {
       content.background(.thickMaterial, in: shape)
   }

   // After
   content.adaptiveGlass(cornerRadius: 16)
   ```

3. **With tint:**
   ```swift
   // Before: manual tinted glass
   // After
   .adaptiveGlass(cornerRadius: 16, tint: .accentPrimary)
   ```

4. **Custom shape:**
   ```swift
   // Before: manual capsule glass
   // After
   .adaptiveGlass(in: Capsule())
   ```
