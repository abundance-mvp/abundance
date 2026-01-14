---
name: capture-issue
description: Use when capturing bugs, UX issues, or spec drift during testing - unified workflow that gathers issue details, creates raw issue file, enriches with log analysis and Apple docs, and writes enriched JSON all in-session (avoids subprocess permission failures)
---

## Overview

Captures and enriches issues in a single Claude session. Replaces `capture-issue.sh` + subprocess `enrich-issue` pattern that fails due to nested Claude invocation.

**Why this exists**: When Claude runs `capture-issue.sh`, the script spawns `claude enrich-issue` as subprocess. That subprocess cannot get file write approval because parent Claude owns the terminal. This skill does everything in-session.

## When to Use

- User reports a bug during testing session
- You observe unexpected behavior while testing
- User says "file a bug", "capture this issue", "log this problem"
- After reproducing a bug and wanting to document it

## Quick Reference

| Issue Type | Output |
|------------|--------|
| `bug` | `docs/bugs/BUG-NNN-*.md` |
| `blocker` | `docs/bugs/BLOCKER-NNN-*.md` |
| `silent-failure` | `docs/bugs/BUG-NNN-*.md` |
| `performance` | `docs/bugs/PERF-NNN-*.md` |
| `ux-issue` | `docs/refinements/REF-NNN-*.md` |
| `spec-drift` | Update existing spec |

## Workflow

### Step 1: Gather Issue Details

Use AskUserQuestion to collect:

```
Question 1: "What did you expect to happen?"
Question 2: "What actually happened?"
Question 3: "Which screen or feature?"
Question 4: "Issue type?" (bug, ux-issue, spec-drift, silent-failure, performance, blocker)
Question 5 (optional): "Related spec document?" (e.g., mvp-vision-features)
```

For `blocker` type, also ask:
- "What is this blocking?" (testing/deployment/development)
- "Impact level 1-10?"

### Step 2: Get Next Issue Number

```bash
COUNTER_FILE=".debug/issues/.next-issue-number"
if [ -f "$COUNTER_FILE" ]; then
    ISSUE_NUM=$(cat "$COUNTER_FILE")
else
    ISSUE_NUM=1
fi
echo $((ISSUE_NUM + 1)) > "$COUNTER_FILE"
```

### Step 3: Create Raw Issue File

Write to `.debug/issues/raw/issue-NNN.md`:

```markdown
# Issue #NNN: [Actual behavior, truncated to 60 chars]

**Captured**: [ISO 8601 timestamp]
**Type**: [type]
**Screen**: [screen]
**Status**: raw

---

## Description

**Expected**: [user input]

**Actual**: [user input]

---

## Spec Reference

- **Document**: docs/specs/[spec].md (or "not specified")
- **Section**: [section if provided]

---

## Context

**Log file**: [path to latest log in .debug/logs/]
**Log basename**: [filename]

**Recent log entries** (last 50 lines):
[tail of log file]

---

## Notes

[Any additional context from conversation]
```

### Step 4: Enrich the Issue

**4a. Validate Spec Reference**

If user provided spec name:
```
Search: docs/**/*{SPEC_NAME}*.md
If found: Extract 3-5 relevant excerpts
If not found: Mark path_valid: false
```

**4b. Analyze Full Log File**

Read entire log file (not just 50 lines). Count and extract:
- ERROR entries (max 20)
- WARNING entries (max 10)
- Stack traces (look for `at FileName.swift:LineNumber`)
- File references from error messages

**4c. Detect iOS Context**

Look for indicators:
- Keywords: `@MainActor`, `Task`, `async`, `await`, `Sendable`
- Frameworks: SwiftUI, AVFoundation, Vision, CoreML, Combine
- File patterns: `Sources/*.swift`, `import SwiftUI`
- Error codes: `EXC_BREAKPOINT`, `NSError`

If iOS detected, set `apis_to_verify` (3-5 APIs from errors/stack traces).

**4d. Fetch Apple Documentation (iOS only)**

If `ios_context.detected == true`:
1. Use `apple-docs-fetcher` skill for each API in `apis_to_verify`
2. Extract key usage requirements, threading notes, deprecations
3. Record findings in `apple_docs_findings`

**4e. Identify Affected Files**

Collect from:
- Log error messages
- Stack trace frames
- Spec document references

Validate paths exist before including.

**4f. Preliminary Classification**

Based on evidence, suggest:
- `likely_type`: bug, ux-issue, spec-drift, silent-failure, performance, blocker
- `likely_severity`: critical, high, medium, low
- `confidence`: 0.0-1.0
- `reasoning`: 1-2 sentences

### Step 5: Write Enriched JSON

Write to `.debug/issues/enriched/enriched-NNN.json`

Schema: See `docs/dev-workflow/ENRICHED-ISSUE-SCHEMA.md`

Required fields:
- `$schema`: "enriched-issue-v1"
- `issue_number`, `captured_at`, `enriched_at`
- `user_report`, `spec_reference`, `log_analysis`
- `ios_context`, `affected_files`, `preliminary_classification`
- `raw_issue_path`

### Step 6: Report Summary

```
Issue #NNN captured and enriched

Summary:
- Spec: [valid/invalid/not provided]
- iOS: [detected/not detected]
- Apple docs: [fetched N APIs / not needed]
- Errors found: N
- Warnings found: N
- Stack traces: N
- Affected files: N
- Preliminary: [type] / [severity] (confidence%)

Files created:
- .debug/issues/raw/issue-NNN.md
- .debug/issues/enriched/enriched-NNN.json

Next: Run `claude triage-issues` to process
```

## Error Handling

| Situation | Action |
|-----------|--------|
| No logs in `.debug/logs/` | Set log_analysis counts to 0, note "No logs found" |
| Spec file not found | Set `path_valid: false`, continue enrichment |
| Apple docs fetch fails | Set `apple_docs_fetched: false`, triage will retry |
| Counter file missing | Initialize to 1 |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Running `capture-issue.sh` instead of skill | Use this skill for in-session capture |
| Skipping enrichment | Always enrich - it speeds up triage |
| Manual issue numbers | Always read/increment counter file |
| Writing to wrong directory | Raw → `.debug/issues/raw/`, Enriched → `.debug/issues/enriched/` |

## Integration

After capture, user runs:
```bash
claude triage-issues
```

Triage uses enriched JSON to skip redundant fetches.
