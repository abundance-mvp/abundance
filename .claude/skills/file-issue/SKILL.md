---
name: file-issue
description: |
  Standardized issue filing for bugs, features, and improvements.
  Integrates with device-tester, code-review, and dispatch coordinator.

  Invoke manually or programmatically from other skills.

  Arguments:
  - --source: manual | device-tester | code-review
  - --context: JSON with pre-populated fields (for programmatic use)
user-invocable: false
---

# File Issue Skill

File issues with standardized format, guided classification, and smart routing.

## Entry Points

| Source | Context | Behavior |
|--------|---------|----------|
| `manual` | User description | Hybrid: accept inline, ask for missing |
| `device-tester` | Logs, device info, screenshots | Minimal questions, auto-populate |
| `code-review` | File, line, finding, severity | Minimal questions, auto-populate |

---

## 1. Gather Information

### Manual Source (Hybrid Approach)

IF user provided description:
  - Extract: summary, expected/actual behavior
  - Ask only for missing critical info

IF no description:
  - Ask: "What issue are you seeing?"
  - Then: "What did you expect to happen?"
  - Then: "Any relevant files or screenshots?"

### device-tester Source

Auto-populate from context:
- Console logs (last 50 relevant lines)
- Device: w-16e, iOS version
- Recent screenshots in `./screenshots/`
- Current test scenario

Only ask: "Brief summary of the issue?"

### code-review Source

Auto-populate from context:
- File and line number
- Finding description
- Severity from auditor

Only ask: "Confirm this should be filed as an issue?"

---

## 2. Classify (Guided with Defaults)

### Detect Component

| Signal | Component |
|--------|-----------|
| `.swift` files, SwiftUI, UIKit, AVFoundation, CoreData | `ios` |
| `.ts` files, Firebase, Firestore, Cloud Functions | `backend` |
| Gemini, AI pipeline, tool calling | `backend` |
| GCP, Cloud Logging, deployment | `backend` |
| **Ambiguous** | `ios` (default) |

### Detect Type

| Signal | Type |
|--------|------|
| "crash", "broken", "doesn't work", "error" | `bug` |
| "used to work", "regression", "broke" | `regression` |
| "slow", "lag", "memory", "battery" | `performance` |
| "add", "new", "implement", "create" | `feature` |
| "improve", "better", "enhance" | `enhancement` |
| "UI", "design", "layout", "user experience" | `ux` |
| "refactor", "restructure", "architecture" | `architecture` |
| "optimize", "faster", "cleaner" | `optimization` |
| "security", "vulnerability", "credentials" | `security` |
| "test", "coverage", "flaky" | `test` |

### Detect Priority

| Signal | Priority |
|--------|----------|
| "crash", "can't use", "blocking", security issues | `P0` |
| bugs, regressions, performance issues | `P1` |
| features, enhancements, ux | `P2` |
| tests, optimization, architecture | `P3` |

### Present Classification

```
I'd classify this as:
- **Type:** bug
- **Priority:** P1 (high)
- **Component:** ios

Is this correct? (Enter to confirm, or specify changes)
```

---

## 3. Write Issue File

### Generate Filename

```
docs/issues/YYYY-MM-DD-<slug>.md

Slug rules:
- Lowercase
- Hyphens for spaces
- Max 50 characters
- Remove articles (a, an, the)
```

### Issue Template

```markdown
---
date: YYYY-MM-DD
status: open
priority: P1
type: bug
component: ios
source: manual
related-files:
  - path/to/file.swift
screenshots:
  - filename.png
axiom-agent: null
branch: null
design-doc: null
implementation-plan: null
---

## Summary

[One-line description]

## Description

[Detailed verbose description]

## Expected Behavior

[What should happen]

## Actual Behavior

[What actually happens]

## Technical Context

- Device: [device info if available]
- iOS: [version if available]
- Source: [source]
- Console logs:
  ```
  [relevant logs if available]
  ```

## Proposed Solution (optional)

[Initial thoughts on fix]
```

### Confirm Filing

```
Issue filed: docs/issues/2026-01-18-camera-freezes-after-error.md

Type: bug | Priority: P1 | Component: ios
```

---

## 4. Route Next Action

### By Issue Type

| Type | Next Action |
|------|-------------|
| bug, regression, performance, security, test | "Ready for dispatch. Run `/project:dispatch` when ready." |
| feature, enhancement, ux, architecture | Invoke brainstorming |
| optimization | Ask: "Is this a code-level optimization (file directly) or architectural (brainstorm)?" |

### By Source (Smart Continuation)

| Source | After Filing |
|--------|--------------|
| device-tester | "Continue testing or stop to investigate?" |
| code-review | Return to review, continue with other findings |
| manual + bug type | "Ready for dispatch" |
| manual + feature type | Invoke brainstorming |

---

## 5. Brainstorming Flow

When type triggers brainstorming (feature, enhancement, ux, architecture):

```
1. Detect component (ios/backend)

2. IF component == ios:
   Skill(skill="ios-superpowers", args="brainstorm <issue-summary>")

   IF component == backend:
   Skill(skill="backend-superpowers")
   → Then invoke superpowers:brainstorming

3. Design doc written to docs/plans/YYYY-MM-DD-<topic>-design.md

4. Update issue with design-doc field

5. Ask: "Design complete. Create implementation plan?"
   - Yes → Skill(skill="superpowers:writing-plans")
   - No → "Issue ready for future dispatch"
```

---

## 6. Issue Types Reference

| Type | Triggers Brainstorming | Priority Default |
|------|----------------------|------------------|
| `bug` | No | P1 |
| `regression` | No | P1 |
| `performance` | No | P1 |
| `feature` | Yes | P2 |
| `enhancement` | Yes | P2 |
| `ux` | Yes | P2 |
| `architecture` | Yes | P3 |
| `optimization` | Depends | P3 |
| `security` | No | P0 |
| `test` | No | P3 |

---

## 7. Screenshots

Screenshots are stored in `./screenshots/` (symlinked to iCloud).

When referencing screenshots:
- Use just the filename: `screenshots: [IMG_1234.png]`
- Check for recent screenshots: `ls -lt screenshots/ | head -5`
- Read screenshot to analyze (Claude is multimodal)
