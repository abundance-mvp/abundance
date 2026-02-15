---
name: polish
description: Use when UI files need design review — audits against brand bible and Apple HIG, recommends creative UX improvements, and reconciles view spec documents with implemented code
---

# Polish

Design review that audits UI changes against the brand bible and Apple HIG, makes creative improvement recommendations, and reconciles spec documents with what was actually built.

**Complements `ios-superpowers review`** (code correctness) with **design quality** (brand, HIG, accessibility, glass, creative suggestions, spec updates).

## When to Use

- After implementing UI changes, before committing
- When `/polish` is invoked
- When user says "polish", "design review", "brand check", "audit UI"
- As part of `ios-superpowers review` when UI files are in the diff

## Pipeline

```
Phase 1         Phase 2            Phase 3            Phase 4          Phase 5
Context         Axiom Audits       Design Synthesis   Spec Recon       Apply + Build
(parallel)      (parallel agents)  (creative)         (draft/update)   (fixes → verify)
     │                │                  │                  │               │
     ▼                ▼                  ▼                  ▼               ▼
brand bible     accessibility      axiom-hig +        compare code     auto-fix safe
design system   liquid-glass       axiom-haptics +    ↔ specs          violations
view specs      (module-specific)  brand synthesis    draft missing    build verify
plans/brainstorm                   creative recs      recommend edits  report
git history
```

---

## Phase 1: Context Gathering

### Step 1.1: Diff and Classify

```bash
git diff origin/main --name-only
```

Classify changed files:

| Pattern | Category | Enters pipeline? |
|---------|----------|-----------------|
| `*View.swift`, `*Sheet.swift` | view | Yes |
| `Components/*.swift`, `*Card.swift`, `*Badge.swift`, `*Button.swift`, `*Indicator.swift`, `*Overlay.swift`, `*Bar.swift` | component | Yes |
| `DesignSystem/**` | designsystem | Yes |
| `*ViewModel.swift` | viewmodel | No (but note for spec reconciliation) |
| Other `.swift` | non-ui | No |

**No changed view/component files → report "nothing to polish" and stop.**

### Step 1.2: Parallel Context Reads

Read ALL of these in parallel:

**Brand context (always):**
1. `docs/brand/abundance-brand-bible-v3-2026-02-06.md` — design philosophy, palette, motion, mood
2. `Sources/Core/DesignSystem/Extensions/Color+Brand.swift` — token definitions
3. `Sources/Core/DesignSystem/Extensions/LiquidGlassHelpers.swift` — glass utilities
4. `Sources/Core/DesignSystem/Extensions/Animation+Brand.swift` — motion tokens

**Spec context (for each changed view):**
5. `docs/view-specs/<view-name>.md` — if exists, the current spec
6. Any `docs/view-specs/` files for related views in the same feature module

**Intent context:**
7. `docs/plans/BRAINSTORM-*.md` and `docs/plans/*.md` — match by feature area (e.g., "profile" brainstorm for ProfileFeature changes)
8. `git log --oneline origin/main..HEAD` — commit history to trace user-directed evolution

### Step 1.3: Identify Feature Story

From the commit history and plan docs, build a brief narrative:
- What was the original intent (brainstorm/plan)?
- What changed during implementation (fix: commits, user feedback)?
- What diverged from the plan and why?

This narrative grounds Phase 3 creative recommendations and Phase 4 spec reconciliation.

---

## Phase 2: Axiom Agent Audits

Launch agents in a **single message** (parallel):

```
Task(subagent_type="axiom:accessibility-auditor",
  description="Accessibility audit",
  prompt="Audit these view files for WCAG AA compliance,
    focusing on VoiceOver labels, Dynamic Type, touch targets,
    and contrast. Files: {file_list}")

Task(subagent_type="axiom:liquid-glass-auditor",
  description="Liquid Glass audit",
  prompt="Audit these view files for Liquid Glass adoption
    opportunities and violations. The project uses adaptiveGlass()
    helpers from LiquidGlassHelpers.swift. Files: {file_list}")
```

**Module-specific additions** (add to the parallel batch when detected):

| Module in diff | Additional Agent |
|----------------|-----------------|
| `CameraFeature/Views/` | `axiom:camera-auditor` |
| `CollectionFeature/` | `axiom:swiftui-performance-analyzer` |
| Any `NavigationStack` usage | `axiom:swiftui-nav-auditor` |

---

## Phase 3: Design Synthesis

This is the creative core. After agents return, load Axiom skills for design context:

```
Skill(skill="axiom-hig")        # Always — HIG principles
Skill(skill="axiom-haptics")    # Always — haptic feedback recommendations
```

**Load conditionally based on changed files:**
- Typography changes → `Skill(skill="axiom-typography-ref")`
- SF Symbol usage → `Skill(skill="axiom-sf-symbols-ref")`
- Navigation changes → `Skill(skill="axiom-swiftui-nav")`
- Animation changes → `Skill(skill="axiom-swiftui-animation-ref")`

### Synthesis Process

With brand bible + design system + Axiom audit results + Axiom HIG/haptics skills loaded, perform a holistic design review of each changed view file:

**1. Brand Palette Compliance**
Read Color+Brand.swift. For each view, check:
- System colors (`.blue`, `.red`, `.green`, etc.) → map to brand tokens
- Raw hex/RGB colors → verify against brand palette
- `foregroundColor(` → should be `foregroundStyle(`
- `UIColor.system*` → ADR-010 violation
- `.primary`/`.secondary`/`.tertiary` are acceptable for tertiary chrome

**Exclusions:** comments, strings, `Color+Brand.swift` itself, `.black`/`.white` in camera views, `.clear`.

**2. Brand Animation Compliance**
Read Animation+Brand.swift. Check:
- Raw `.easeInOut(duration:)` → should use `.brandDefault`, `.brandPress`, `.brandReducedMotion`
- Missing `@Environment(\.accessibilityReduceMotion)` check near animations
- System-driven animations (`.transition`, `matchedGeometryEffect`) are exempt

**3. Creative Recommendations**

Go beyond compliance. For each view, consider:

- **Visual hierarchy:** Does the information architecture serve the user's primary task? Would reordering, regrouping, or adding visual weight help?
- **Glass opportunities:** Which elements would benefit from `adaptiveGlass()` on iOS 26+? Consider hero elements, floating UI, toolbar chrome.
- **Haptic moments:** Where would tactile feedback improve the interaction? (confirmations, destructive actions, mode changes, successful operations)
- **Motion design:** Would a subtle entrance animation, transition, or micro-interaction enhance the experience? Always with `.brandDefault`/`.brandReducedMotion`.
- **Spacing and density:** Does the layout breathe? Is information density appropriate for the content type?
- **SF Symbol choices:** Are icons semantically correct? Would filled/outlined variants work better?
- **Accessibility enhancements:** Beyond compliance — would VoiceOver custom actions, rotor items, or enhanced descriptions improve the experience for all users?

**Ground every recommendation in the brand bible's design philosophy** ("playful, stylish, premium, approachable") and the Axiom HIG skill's principles. Cite specific brand bible sections when relevant.

**Be generous with suggestions.** The user wants creative direction, not just compliance checking. Think like a design reviewer who cares deeply about the product.

---

## Phase 4: Spec Reconciliation

For each changed view file:

### If view spec exists (`docs/view-specs/<name>.md`):

1. Compare each spec section against actual code:
   - **Palette table:** Are all color usages documented? New colors added? Old colors removed?
   - **Accessibility table:** Are all interactive elements documented with labels, traits, targets?
   - **Liquid Glass table:** Does the glass treatment match code?
   - **Layout table:** Do spacing/sizing values match?
   - **Animations table:** Do triggers, curves, and haptics match?

2. Identify divergences:
   - **Code has elements not in spec** → draft additions to spec
   - **Spec has elements not in code** → flag as potential regression or intentional removal
   - **Values differ** → note the change, recommend spec update

3. Cross-reference against Phase 1.3 feature story:
   - If divergence appears in `fix:` commits → likely user-directed improvement → update spec to match code
   - If divergence is unexplained → flag for discussion

4. **Draft the updated spec sections** as a concrete markdown diff the user can review and apply.

### If view spec does NOT exist:

Draft a complete new view spec following the standard template:

```markdown
# View Spec: {ViewName}

**Source:** `{file_path}`
**Module:** {module}
**Priority:** P1
**Last updated:** {today}

## 1. Palette
| Element | Token | Hex | Usage |

## 2. Accessibility
| Element | Label | Trait | Min Target | Dynamic Type |

## 3. Liquid Glass
| Element | Treatment | Tint | Fallback (< iOS 26) |

## 4. Layout
| Element | Constraint | Value |

## 5. Animations & Haptics
| Trigger | Animation | Haptic | Duration |
```

Populate from the actual code, brand bible, and Phase 3 creative recommendations.

### Plan/Brainstorm Reconciliation

If brainstorm or plan docs were loaded in Phase 1:
- Note which planned features were implemented, modified, or dropped
- Recommend plan doc status updates (if implementation is complete)
- Flag spec gaps where planned features aren't reflected in view specs

---

## Phase 5: Apply and Build

### Auto-Fix Rules

1. **Auto-fix safe violations** — brand palette swaps, `foregroundColor` → `foregroundStyle`, raw materials → `adaptiveGlass()` wrapper
2. **Flag for manual review** — HIG changes, accessibility enhancements, creative recommendations, layout changes
3. Use `Edit` tool with exact `old_string` → `new_string`
4. Never fix multiple violations on the same line in separate edits — combine them

### Build Verify

```
IF mcpbridge available:
  mcp__xcode__BuildProject
ELSE:
  swift build
```

- **Success:** proceed to report
- **Failure:** revert last batch of fixes, identify which fix broke build, re-apply others, rebuild (max 2 retries)

---

## Report

```markdown
## Polish Report

**Branch:** {branch}
**Files audited:** {N}
**Feature story:** {1-2 sentence summary of what was built and how it evolved}

### Audit Findings

| Auditor | Findings | Auto-fixed | Manual Review |
|---------|----------|------------|---------------|
| Accessibility | N | N | N |
| Liquid Glass | N | N | N |
| Brand Palette | N | N | N |
| Brand Animation | N | N | N |
| HIG | N | N | N |

### Auto-Fixed
| File:Line | Before | After | Category |
|-----------|--------|-------|----------|

### Design Recommendations
Creative suggestions grounded in brand bible + Apple HIG:
1. **{View}:** {recommendation} — {brand bible / HIG justification}
2. ...

### Spec Updates
| View | Spec Status | Action |
|------|-------------|--------|
| ProfileView | Exists, 5 updates needed | [see draft below] |
| HelpView | Missing | [new spec drafted] |

{Inline spec diffs or links to drafted specs}

### Plan Reconciliation
- Features implemented: {list}
- Features modified from plan: {list with explanation}
- Features not yet implemented: {list}
- Recommended plan status: {In Progress / Completed}

### Build Status
{pass/fail with errors if applicable}
```

---

## Error Handling

| Condition | Action |
|-----------|--------|
| Not a git repo | Stop, explain |
| No changed view files | Report "nothing to polish", stop |
| Axiom agent fails | Report which agent failed, continue with others |
| Brand bible not found | Warn, continue with design system files only |
| No brainstorm/plan docs | Skip intent tracking, note in report |
| Build fails after fixes | Retry cycle (max 2), then report |

## Red Flags

| Thought | Reality |
|---------|---------|
| "Just check colors, skip the creative stuff" | Creative recommendations are the primary value. Brand compliance is table stakes. |
| "Skip spec reconciliation, it's extra work" | Spec drift is the #1 source of design regression. Always reconcile. |
| "I don't need the brand bible, I know the palette" | The brand bible has design philosophy, mood, motion principles — not just colors. Read it. |
| "Skip the git history, just look at current code" | Intent matters. A divergence from plan might be an improvement or a regression. |
| "I'll draft specs later" | If a view has no spec, draft it now. Specs created close to implementation are the most accurate. |

## What This Skill Does NOT Do

- Sync from main or rebase
- Run aXe / XCUITest automation
- Touch non-UI files (ViewModels, services, etc.)
- Make code correctness judgments (that's `ios-superpowers review`)
- Deploy or push changes
