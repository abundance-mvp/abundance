---
name: palette-auditor
description: Scan Swift view files for system color usage and map violations to brand tokens from Color+Brand.swift
---

# Palette Auditor

Scan the provided Swift view/component files for color violations against the Abundance brand palette.

## Instructions

1. Read `Sources/Core/DesignSystem/Extensions/Color+Brand.swift` to load the current brand palette
2. Read the view spec from `docs/view-specs/<view-name>.md` (if it exists) — check the Palette table
3. Read each target Swift file
4. Scan for violations using the patterns below
5. Report findings in the output format

## Violation Patterns

### Critical (must fix)

| Pattern | Regex | Auto-fix |
|---------|-------|----------|
| System color `.blue` | `\.blue\b` (not in comments/strings) | → `.accentPrimary` |
| System color `.red` | `\.red\b` | → `.errorColor` |
| System color `.green` | `\.green\b` | → `.successColor` |
| System color `.orange` | `\.orange\b` | → `.accentSecondary` |
| System color `.purple` | `\.purple\b` | → `.accentPrimary` |
| System color `.gray` | `\.gray\b` | → `.textPrimary.opacity(0.6)` |
| System color `.yellow` | `\.yellow\b` | → `.cream` |
| System color `.pink` | `\.pink\b` | → `.salmon` |
| System color `.mint` | `\.mint\b` | → `.softTeal` |
| System color `.cyan` | `\.cyan\b` | → `.backgroundTeal` |
| System color `.indigo` | `\.indigo\b` | → `.accentPrimary` |
| System color `.teal` | `\.teal\b` | → `.softTeal` |
| System color `.brown` | `\.brown\b` | → `.peach` |
| `UIColor.system*` | `UIColor\.system` | → ADR-010 + palette violation |
| `import UIKit` in view | `^import UIKit$` | → Remove (ADR-010) |

### Warning (review needed)

| Pattern | Description |
|---------|-------------|
| `Color(hex:` | Raw hex not from brand palette — verify against Color+Brand.swift |
| `Color(uiColor:` | UIColor bridge — should use brand token |
| `Color(red:green:blue:` | Raw RGB — should use brand token |
| `foregroundColor(` | Deprecated API — should use `foregroundStyle(` |

### Exclusions (skip these)

- Lines that are comments (`//` or `///` or `/*`)
- Lines inside string literals (`"..."`)
- Lines in `Color+Brand.swift` itself (definitions)
- `Color.black` and `Color.white` in camera views (viewfinder exemption)
- `Color.clear` (transparent, no brand impact)
- `.primary`, `.secondary`, `.tertiary` (system semantic colors, acceptable)

## Output Format

```markdown
## Palette Audit Results

### {filename}

| Line | Violation | Current | Suggested Fix | Severity |
|------|-----------|---------|---------------|----------|
| 42 | System color | `.foregroundStyle(.red)` | `.foregroundStyle(.errorColor)` | Critical |
| 18 | Deprecated API | `.foregroundColor(.blue)` | `.foregroundStyle(.accentPrimary)` | Warning |

### Summary
- Critical: N violations (auto-fixable)
- Warning: N violations (review needed)
- Files scanned: N
- Files clean: N
```

## Auto-Fix Instructions

When applying fixes:
1. Use the Edit tool with exact `old_string` → `new_string` replacement
2. Only fix Critical violations automatically
3. Flag Warning violations for manual review
4. After fixing, verify the file still compiles by checking for obvious syntax issues
5. Update the view spec palette table if a new color mapping was introduced
