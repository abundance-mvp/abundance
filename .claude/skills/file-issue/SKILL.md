---
name: file-issue
description: Use when filing a bug, feature request, or improvement - from manual reports, device-tester sessions, or code-review findings
user-invocable: false
---

# File Issue

Standardized issue filing with classification, doc-index tracking, and smart routing.

**Args:** `--source manual|device-tester|code-review [--context <json>]`

## 1. Gather Information

**Manual:** Extract from description. Ask only for gaps (summary, expected/actual, files).

**device-tester:** Auto-populate logs, device (w-16e), iOS version, screenshots from `./screenshots/`. Only ask for summary.

**code-review:** Auto-populate file, line, finding, severity from context. Only ask for confirmation.

## 2. Classify

Present classification for confirmation. User can override.

### Component

| Signal | Component |
|--------|-----------|
| `.swift`, SwiftUI, Apple frameworks | `ios` |
| `.ts`, Firebase, Firestore, Functions, Gemini, GCP | `backend` |
| Both `.swift` AND `.ts`/Firebase involved | `shared` |
| Ambiguous | `ios` (default) |

### Type and Priority

| Type | Signals | Default Priority | Triggers Brainstorm? |
|------|---------|-----------------|---------------------|
| `bug` | crash, broken, error, doesn't work | P1 | No |
| `regression` | used to work, broke | P1 | No |
| `performance` | slow, lag, memory, battery | P1 | No |
| `security` | vulnerability, credentials | P0 | No |
| `test` | flaky, coverage, CI fail | P3 | No |
| `feature` | add, new, implement | P2 | Yes |
| `enhancement` | improve, better, enhance | P2 | Yes |
| `ux` | UI, design, layout | P2 | Yes |
| `architecture` | refactor, restructure | P3 | Yes |
| `optimization` | optimize, faster | P3 | Ask |

## 3. Write Issue File

**Path:** `docs/issues/YYYY-MM-DD-<slug>.md`
**Slug:** lowercase, hyphens, max 50 chars, drop articles (a/an/the).

### Template

```markdown
---
date: YYYY-MM-DD
status: Open
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
---

## Summary

[One-line description]

## Description

[Detailed description with context]

## Expected Behavior

[What should happen]

## Actual Behavior

[What actually happens]

## Technical Context

[Device, iOS version, console logs, source info - whatever is available]

## Proposed Solution

[Optional initial thoughts]
```

### Status Schema

**CRITICAL:** Use these exact values. Archival depends on them.

| Status | Meaning | Set By |
|--------|---------|--------|
| `Open` | New, unassigned | file-issue (creation) |
| `In Progress` | Assigned, being worked on | dispatch |
| `Fixed` | Fix merged | developer (archival trigger) |
| `Closed` | Resolved without code change | developer (archival trigger) |
| `Won't Fix` | Intentionally not fixing | developer (archival trigger) |

## 4. Update Doc Index

**REQUIRED** - Run immediately after writing the issue file:

```bash
./scripts/update_doc_index.py add docs/issues/<filename>.md --status Open
```

Confirm output shows `Added: docs/issues/<filename>.md`. This enables dispatch discovery and archival tracking.

## 5. Confirm and Route

### Confirmation

```
Issue filed: docs/issues/YYYY-MM-DD-<slug>.md
Type: bug | Priority: P1 | Component: ios | Indexed: yes
```

### Routing

**By type:**
- bug, regression, performance, security, test → "Ready for dispatch. Run `/project:dispatch`."
- feature, enhancement, ux, architecture → Invoke brainstorming (see below)
- optimization → Ask: "Code-level fix or architectural redesign?"

**By source:**
- device-tester → "Continue testing or investigate this issue?"
- code-review → Return to review, continue with remaining findings
- manual → Route by type (above)

### Brainstorming Flow

When type triggers brainstorming:

```
1. IF component == ios OR shared:
   Skill(skill="ios-superpowers", args="brainstorm <summary>")
   IF component == backend:
   Skill(skill="backend-superpowers")

2. Design doc → docs/plans/YYYY-MM-DD-<topic>-design.md

3. Update issue frontmatter: design-doc: <path>

4. Ask: "Create implementation plan?"
   Yes → Skill(skill="superpowers:writing-plans")
   No → "Issue ready for future dispatch"
```

## Screenshots

Stored in `./screenshots/` (iCloud symlink). Reference by filename only. Check recent: `ls -lt screenshots/ | head -5`.
