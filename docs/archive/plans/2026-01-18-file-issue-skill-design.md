# File-Issue Skill Design

**Date:** 2026-01-18
**Status:** Approved
**Author:** Claude + User

---

## Overview

A standardized skill for filing issues discovered during development, device testing, or code review. Integrates with the dispatch coordinator to route issues to appropriate Axiom agents and superpowers skills.

## Entry Points

| Source | Trigger | Auto-populated Context |
|--------|---------|----------------------|
| Manual | `/project:file-issue [description]` | None - gathered interactively |
| device-tester | Skill invocation during testing | Console logs, device info, screenshots |
| code-review | `ios-superpowers review` findings | File, line, severity, finding description |

## Issue Types

| Type | Triggers Brainstorming | Example |
|------|----------------------|---------|
| `bug` | No | Crash, broken feature, incorrect behavior |
| `regression` | No | Something that worked before now broken |
| `performance` | No | Slow, laggy, memory leak |
| `feature` | Yes | New capability |
| `enhancement` | Yes | Improve existing feature |
| `ux` | Yes | UI/UX change |
| `architecture` | Yes | Refactor, restructure |
| `optimization` | Depends on scope | Code improvement |
| `security` | No | Vulnerability, hardening |
| `test` | No | Missing/flaky tests |

## Component Routing

| Signal | Routes To |
|--------|-----------|
| Swift files (`.swift`) | ios-superpowers |
| SwiftUI, UIKit, AVFoundation, CoreData | ios-superpowers |
| Xcode build errors | ios-superpowers |
| Device/simulator issues | ios-superpowers |
| TypeScript files (`.ts`) | backend-superpowers |
| Firebase, Firestore, Cloud Functions | backend-superpowers |
| Cloud Logging, GCP, deployment | backend-superpowers |
| Gemini, AI pipeline, tool calling | backend-superpowers → gemini-integration |
| **Ambiguous** | Default to ios-superpowers |

## Workflow

```
┌─────────────────────────────────────────────────────────────────────┐
│                         FILE-ISSUE SKILL                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. GATHER INFO (hybrid approach)                                    │
│     ├─ If description provided → extract details                     │
│     ├─ If missing critical info → ask follow-up questions            │
│     └─ Auto-populate technical context from source                   │
│                                                                      │
│  2. CLASSIFY (guided with defaults)                                  │
│     ├─ Analyze content → propose: type, priority, component          │
│     ├─ Detect iOS vs Backend signals → route accordingly             │
│     ├─ Default to iOS when ambiguous                                 │
│     └─ Present to user: "I'd classify this as P1 bug (iOS). OK?"     │
│                                                                      │
│  3. WRITE ISSUE                                                      │
│     ├─ Generate slug from summary                                    │
│     ├─ Write to docs/issues/YYYY-MM-DD-<slug>.md                     │
│     └─ Confirm: "Issue filed: docs/issues/2026-01-18-camera-freeze"  │
│                                                                      │
│  4. ROUTE NEXT ACTION (by type + source)                             │
│     ├─ Bug/perf/security/test/regression:                            │
│     │   └─ "Ready for dispatch. Run /project:dispatch when ready."   │
│     ├─ Feature/enhancement/ux/architecture:                          │
│     │   └─ Invoke brainstorming with ios-superpowers or backend-*    │
│     └─ Smart continuation by source:                                 │
│         ├─ device-tester → return to testing loop                    │
│         ├─ code-review → continue review                             │
│         └─ manual → offer options                                    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Issue File Format

**Filename:** `docs/issues/YYYY-MM-DD-<slug>.md`

### Metadata (YAML Frontmatter)

```yaml
---
date: 2026-01-18
status: open           # open | in-progress | designed | blocked | resolved | wontfix
priority: P1           # P0 (critical) | P1 (high) | P2 (medium) | P3 (low)
type: bug              # bug | regression | feature | enhancement | ux | architecture | optimization | performance | security | test
component: ios         # ios | backend | shared
source: device-tester  # manual | device-tester | code-review
related-files:
  - Sources/Features/Camera/CameraViewModel.swift
screenshots:
  - IMG_1234.png       # Files in ./screenshots/
axiom-agent: null      # Assigned when dispatched
branch: null           # Assigned when dispatched
design-doc: null       # Populated after brainstorming (for feature types)
implementation-plan: null  # Populated after planning
---
```

### Body Sections

```markdown
## Summary
One-line description of the issue.

## Description
Detailed explanation of what's happening. Should be verbose enough
to understand reproduction steps without a separate section.

## Expected Behavior
What should happen.

## Actual Behavior
What actually happens.

## Technical Context
- Device: w-16e (iPhone 16e)
- iOS: 18.2
- Source: device-tester
- Console logs:
  ```
  [Relevant log lines]
  ```

## Proposed Solution (optional)
Initial thoughts on how to fix, if known.

## Related Issues (optional)
Links to related issues if any.
```

## Dispatch Coordinator Updates

```
┌─────────────────────────────────────────────────────────────────────┐
│                    UPDATED DISPATCH COORDINATOR                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. PARSE ISSUES                                                     │
│     └─ Read all open issues from docs/issues/                        │
│                                                                      │
│  2. CLASSIFY & ROUTE                                                 │
│     ├─ component: ios → ios-superpowers + Axiom agent                │
│     ├─ component: backend → backend-superpowers + MCP tools          │
│     └─ component: shared → ios-superpowers (primary) + flag backend  │
│                                                                      │
│  3. SELECT AGENT (existing Axiom routing matrix)                     │
│     ├─ iOS bugs → axiom:build-fixer, axiom:camera-auditor, etc.      │
│     └─ Backend issues → backend-superpowers handles internally       │
│                                                                      │
│  4. CREATE WORKTREES                                                 │
│     └─ git worktree add ../abundance-worktrees/<branch>              │
│                                                                      │
│  5. DISPATCH IN PARALLEL                                             │
│     ├─ iOS issues: Task(ios-superpowers debug <issue>)               │
│     └─ Backend issues: Task(backend-superpowers <issue>)             │
│                                                                      │
│  6. UPDATE ISSUE METADATA                                            │
│     ├─ Set axiom-agent field                                         │
│     ├─ Set branch field                                              │
│     └─ Set status: in-progress                                       │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Backend Routing Within backend-superpowers

| Issue Pattern | Routes To |
|---------------|-----------|
| Firestore, database queries | Firestore MCP tools |
| Cloud Functions, deployment | Functions MCP + deploy workflow |
| Auth, users, permissions | Auth MCP tools |
| Gemini, AI pipeline, tool calling | gemini-integration skill |
| Logs, errors, monitoring | Observability MCP tools |
| Storage, buckets, files | Storage MCP tools |

## Integration Points

### device-tester Integration

When an issue is detected during testing:

1. **Gather context automatically:**
   - Console logs (last 50 relevant lines)
   - Device info (w-16e, iOS version)
   - Current test scenario
   - Recent screenshots in `./screenshots/`

2. **Invoke file-issue skill:**
   ```
   Skill(skill="file-issue", args="--source device-tester --context <gathered>")
   ```

3. **After issue filed:**
   - Ask: "Continue testing or stop to investigate?"
   - If continue → resume testing loop
   - If stop → offer to start debugging with ios-superpowers

### ios-superpowers review Integration

When code review finds critical issues (P0/P1):

1. **For each critical finding:**
   - Extract: file, line, issue description, severity
   - Propose filing as issue

2. **Batch or individual:**
   - "Found 3 critical issues. File all as separate issues?"
   - User confirms → invoke file-issue for each

3. **After filing:**
   - Continue with remaining review findings
   - Summary at end includes filed issue links

## Brainstorming Flow

When issue type triggers brainstorming (feature, enhancement, ux, architecture):

```
┌─────────────────────────────────────────────────────────────────────┐
│              BRAINSTORMING TRIGGER FLOW                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. ISSUE FILED (type = feature/enhancement/ux/architecture)         │
│     └─ docs/issues/2026-01-18-add-bulk-scan-mode.md                  │
│                                                                      │
│  2. DETECT COMPONENT                                                 │
│     ├─ component: ios → use ios-superpowers brainstorm               │
│     └─ component: backend → use backend-superpowers                  │
│                                                                      │
│  3. INVOKE BRAINSTORMING                                             │
│     ├─ iOS: Skill(skill="ios-superpowers", args="brainstorm <issue>")│
│     │   └─ Fetches Apple docs, explores design options               │
│     └─ Backend: Skill(skill="backend-superpowers")                   │
│         └─ Explores Firebase/GCP architecture options                │
│                                                                      │
│  4. BRAINSTORMING OUTPUT                                             │
│     └─ Design doc: docs/plans/YYYY-MM-DD-<topic>-design.md           │
│                                                                      │
│  5. LINK DESIGN TO ISSUE                                             │
│     └─ Update issue with: design-doc: docs/plans/...                 │
│                                                                      │
│  6. OFFER IMPLEMENTATION                                             │
│     └─ "Design complete. Create implementation plan?"                │
│         ├─ Yes → superpowers:writing-plans                           │
│         └─ No → done, issue ready for future dispatch                │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Complete System Overview

```
                              USER / WORKFLOW
                                    │
            ┌───────────────────────┼───────────────────────┐
            │                       │                       │
            ▼                       ▼                       ▼
    /project:file-issue      device-tester          ios-superpowers review
            │                       │                       │
            └───────────────────────┼───────────────────────┘
                                    │
                                    ▼
                        ┌───────────────────────┐
                        │    FILE-ISSUE SKILL    │
                        ├───────────────────────┤
                        │ 1. Gather info (hybrid)│
                        │ 2. Classify (guided)   │
                        │ 3. Write issue file    │
                        │ 4. Route next action   │
                        └───────────┬───────────┘
                                    │
              ┌─────────────────────┼─────────────────────┐
              │                     │                     │
              ▼                     ▼                     ▼
    bug/perf/security      feature/enhancement      Return to source
              │                     │                (device-tester,
              ▼                     ▼                 code-review)
    "Ready for dispatch"    Brainstorming
              │                     │
              ▼                     ▼
    /project:dispatch       ios-superpowers OR
              │             backend-superpowers
              ▼                     │
    ┌─────────────────┐            ▼
    │ DISPATCH COORD  │     Design doc created
    ├─────────────────┤            │
    │ iOS → ios-super │            ▼
    │ Backend → back* │     Implementation plan?
    │ Create worktrees│            │
    │ Parallel agents │            ▼
    └─────────────────┘     superpowers:writing-plans
```

## Files to Create/Modify

| Action | File | Purpose |
|--------|------|---------|
| NEW | `.claude/skills/file-issue/SKILL.md` | Core skill logic |
| NEW | `.claude/commands/file-issue.md` | User command |
| MODIFY | `.claude/skills/device-tester.md` | Add issue filing integration |
| MODIFY | `.claude/skills/ios-superpowers/SKILL.md` | Add review→file-issue flow |
| MODIFY | `.claude/commands/dispatch.md` | Add backend-superpowers routing |

## Implementation Notes

- Issue slugs generated from summary: lowercase, hyphens, max 50 chars
- Screenshots always reference files in `./screenshots/` directory
- Priority defaults: P1 for bugs/security, P2 for features/enhancements, P3 for tests
- When source is device-tester or code-review, minimize questions (context is rich)
- Manual filing uses hybrid approach: accept inline, ask only for missing info
