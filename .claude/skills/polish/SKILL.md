---
name: polish
description: Use when UI files need brand compliance audit — system colors, missing accessibility, raw materials without glass helpers, non-brand animation curves, HIG violations
---

# Polish

Run 4 parallel UI auditors against changed view files, auto-fix safe violations, build-verify, and report.

**Complements `ios-superpowers review`** (code correctness) with **visual/UX quality** (brand palette, accessibility, glass, HIG).

## When to Use

- After implementing UI changes, before committing
- When `/polish` is invoked
- When user says "polish", "audit UI", "brand compliance", "check accessibility"
- As part of `ios-superpowers review` when UI files are in the diff

## Pipeline

```
diff → audit (4 parallel) → fix → build → report
         ↑                              │
         └──── retry (max 2) ───────────┘
```

### Step 1: Diff

```bash
git diff origin/main --name-only
```

Classify changed files:

| Pattern | Category | Enters pipeline? |
|---------|----------|-----------------|
| `*View.swift`, `*Sheet.swift` | view | Yes |
| `Components/*.swift`, `*Card.swift`, `*Badge.swift`, `*Button.swift`, `*Indicator.swift`, `*Overlay.swift`, `*Bar.swift` | component | Yes |
| `DesignSystem/**` | designsystem | Yes |
| `*ViewModel.swift` | viewmodel | No |
| Other `.swift` | non-ui | No |

**No changed view/component files → report "nothing to polish" and stop.**

### Step 2: Load Design System Context

Read these 3 files (parallel) — they define "correct":

1. `Sources/Core/DesignSystem/Extensions/Color+Brand.swift`
2. `Sources/Core/DesignSystem/Extensions/LiquidGlassHelpers.swift`
3. `Sources/Core/DesignSystem/Extensions/Animation+Brand.swift`

### Step 3: Dispatch 4 Auditors (Parallel)

Launch 4 Task agents simultaneously. Each gets the file list + design system context.

**CRITICAL: All 4 must run in a SINGLE message with 4 parallel Task calls.**

```
Task(subagent_type="general-purpose", description="Palette audit",
  prompt=<PALETTE_AUDITOR_PROMPT> + file list + Color+Brand.swift content)

Task(subagent_type="axiom:accessibility-auditor", description="Accessibility audit",
  prompt="Audit these files for WCAG AA compliance: " + file list)

Task(subagent_type="axiom:liquid-glass-auditor", description="Liquid Glass audit",
  prompt="Audit these files for glass adoption: " + file list)

Task(subagent_type="general-purpose", description="HIG audit",
  prompt=<HIG_AUDITOR_PROMPT> + file list + Animation+Brand.swift content)
```

**Why 2 Axiom agents + 2 general-purpose:**
- Accessibility and Liquid Glass have dedicated Axiom agents with deep built-in knowledge
- Palette and HIG need project-specific context (brand tokens, brand curves) that Axiom agents don't have

#### Palette Auditor Prompt

Include the full content of `.claude/commands/auditors/palette-auditor.md` in the prompt. This auditor checks:

| Severity | Pattern | Auto-fix |
|----------|---------|----------|
| Critical | `.blue` | → `.accentPrimary` |
| Critical | `.red` | → `.errorColor` |
| Critical | `.green` | → `.successColor` |
| Critical | `.orange` | → `.accentSecondary` |
| Critical | `.gray` | → `.textPrimary.opacity(0.6)` |
| Critical | `.purple`, `.indigo` | → `.accentPrimary` |
| Critical | `.yellow` | → `.cream` |
| Critical | `.pink` | → `.salmon` |
| Critical | `.mint`, `.teal` | → `.softTeal` |
| Critical | `.cyan` | → `.backgroundTeal` |
| Critical | `.brown` | → `.peach` |
| Critical | `UIColor.system*` | ADR-010 violation |
| Warning | `Color(hex:`, `Color(uiColor:`, `Color(red:green:blue:` | Review against palette |
| Warning | `foregroundColor(` | → `foregroundStyle(` |

**Exclusions:** Comments, string literals, `Color+Brand.swift` itself, `.black`/`.white` in camera views, `.clear`, `.primary`/`.secondary`/`.tertiary`.

#### HIG Auditor Prompt

Include the full content of `.claude/commands/auditors/hig-auditor.md` in the prompt. This auditor checks:

| Severity | Pattern |
|----------|---------|
| Critical | Custom back button replacing system, tab bar > 5 items, alert > 3 actions |
| Warning | Missing `.navigationTitle`, sheet without `.presentationDetents`, raw animation curves (not `.brandPress`/`.brandDefault`/`.brandReducedMotion`), missing reduce motion check |

### Step 4: Collect and Merge Results

Wait for all 4 auditors. Merge into a single violation list:

```markdown
| File | Line | Auditor | Violation | Current | Fix | Severity |
```

Sort by: file → line number.

### Step 5: Apply Fixes

**Rules:**
1. Only auto-fix **Critical** violations from Palette and Liquid Glass auditors (mechanical, safe)
2. Auto-fix **Warning** palette violations (`foregroundColor` → `foregroundStyle`)
3. Flag all HIG and Accessibility violations for manual review (require human judgment)
4. Use Edit tool with exact `old_string` → `new_string`
5. Never fix multiple violations on the same line in separate edits — combine them

### Step 6: Build Verify

```
IF mcpbridge available:
  mcp__xcode__BuildProject
  IF failure:
    mcp__xcode__GetBuildLog(severity: "error")    # Structured error details
ELSE:
  swift build
```

- **Success:** proceed to report
- **Failure:** revert last batch of fixes, identify which fix broke the build, re-apply others, rebuild (max 2 retries)
- **Still failing after 2 retries:** report build errors as part of output

### Step 7: Report

```markdown
## Polish Report

**Branch:** {branch}
**Files audited:** {N}

### Violations Found

| Auditor | Critical | Warning | Auto-fixed | Manual |
|---------|----------|---------|------------|--------|
| Palette | — | — | — | — |
| A11y | — | — | — | — |
| Glass | — | — | — | — |
| HIG | — | — | — | — |

### Auto-Fixed
| File:Line | Before | After | Auditor |
|-----------|--------|-------|---------|

### Manual Review Required
- [ ] File:Line — Description (auditor)

### Build Status
{pass/fail with errors if applicable}
```

## Optional: Spec Reconciliation

When invoked with `--with-specs` or when view specs exist for audited files:

1. For each audited view, check `docs/view-specs/<view-name>.md`
2. If spec exists: cross-reference violations against spec tables (palette, a11y, glass, layout, animations)
3. If spec is stale (elements in code not in spec): flag for spec update
4. If spec has elements not in code: flag as potential regression

## Error Handling

| Condition | Action |
|-----------|--------|
| Not a git repo | Stop, explain |
| No changed view files | Report "nothing to polish", stop |
| Auditor agent fails | Report which auditor failed, continue with others |
| Build fails after fixes | Retry cycle (max 2), then report |
| All violations are manual-review | Skip fix step, report only |

## Red Flags — STOP and Re-read This Skill

| Thought | Reality |
|---------|---------|
| "I'll read files one by one, context builds" | Auditors are independent. Parallel is mandatory. |
| "Skip accessibility, nobody uses VoiceOver" | WCAG AA is non-negotiable. Audit runs; findings go to Manual Review. |
| "I'll fix as I audit" | Audit ALL first (Step 3-4), then fix ALL (Step 5). No mixing. |
| "Quick pass, just check colors" | All 4 auditors run. Always. The parallelism makes it fast. |
| "Build passed, skip the report" | The report is the deliverable. No report = no polish. |

## What This Skill Does NOT Do

- Sync from main or rebase (that's the developer's job)
- Create or update view specs (use `--with-specs` for cross-reference only)
- Generate aXe tests
- Restrict to specific branch names
- Touch non-UI files
