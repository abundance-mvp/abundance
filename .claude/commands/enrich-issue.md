# Enrich Issue Command

You are a post-capture enrichment agent. Your job is to analyze a raw issue and gather additional context BEFORE triage. This pre-processing speeds up triage and improves accuracy.

## Input

**With argument**: Process specific issue
```
claude enrich-issue 3
```
Raw issue file: `.debug/issues/raw/issue-003.md`

**Without argument**: Process ALL raw issues that don't have enriched JSON
```
claude enrich-issue
```

## Output

Enriched JSON file: `.debug/issues/enriched/enriched-NNN.json`

Schema documented in: `docs/dev-workflow/ENRICHED-ISSUE-SCHEMA.md`

---

## Process

### Step 1: Parse Raw Issue

Read the raw issue markdown and extract:
- **Metadata**: issue number, timestamp, type, screen, status
- **User input**: expected behavior, actual behavior
- **Spec reference**: document name, section (if provided)
- **Log file reference**: basename from "Latest log" field
- **Blocker info**: blocking context, impact level (if type is blocker)

### Step 2: Validate Spec Reference

If the user provided a spec reference:

1. Search for matching file using glob patterns:
   ```
   docs/**/*{SPEC_NAME}*.md
   docs/specs/*{SPEC_NAME}*.md
   docs/design/*{SPEC_NAME}*.md
   ```

2. If found:
   - Set `path_valid: true`
   - Set `resolved_path` to actual file path
   - Read the file and extract relevant sections
   - Look for section heading matching user's section reference
   - Extract 3-5 relevant excerpts (quotes from spec)

3. If not found:
   - Set `path_valid: false`
   - Note in `resolved_path`: "File not found"

### Step 3: Analyze Full Log File

**IMPORTANT**: Read the FULL log file, not just the 50 lines embedded in the issue.

1. Locate log file:
   - Get basename from raw issue's "Latest log" field
   - Full path: `.debug/logs/{basename}`

2. Count log levels:
   - Count lines containing `ERROR`, `WARNING`, `INFO`, `DEBUG`
   - Store counts in `log_analysis`

3. Extract ERROR entries (max 20):
   - Line number
   - Full message
   - Timestamp (if present in log format)

4. Extract WARNING entries (max 10):
   - Line number
   - Message

5. Identify stack traces:
   - Look for patterns: `at FileName.swift:LineNumber`
   - Look for crash indicators: `Fatal error`, `EXC_`, `SIGABRT`
   - Collect frame sequences
   - Note start line number

6. Extract file references from logs:
   - Parse `FileName.swift:123` patterns
   - Validate files exist in `Sources/` or `App/`

### Step 4: Detect iOS Context

Check for iOS indicators:

**Keywords in logs or error messages**:
- `@MainActor`, `Task`, `async`, `await`, `actor`, `Sendable`
- `nonisolated`, `@Observable`, `@Published`

**Framework names**:
- SwiftUI, UIKit, AVFoundation, Vision, CoreML
- Combine, CoreData, CloudKit, HealthKit
- ARKit, MapKit, StoreKit, GameKit

**File patterns**:
- Files in `Sources/*.swift` or `App/*.swift`
- Import statements: `import SwiftUI`, `import AVFoundation`, etc.

**iOS-specific error codes**:
- `EXC_BREAKPOINT`, `EXC_BAD_ACCESS`
- Error codes like `0xe8000067`
- `NSError` domain patterns

If iOS detected, set:
- `detected: true`
- `detection_reason`: Why iOS was detected
- `frameworks_involved`: List of frameworks found
- `apis_to_verify`: Specific APIs from errors/stack traces (3-5 max)

### Step 5: Fetch Apple Documentation (iOS only)

**Only if `ios_context.detected == true`**

1. Invoke the apple-docs-fetcher skill:
   ```
   Tool: Skill
   Parameters:
     skill: apple-docs-fetcher
   ```

2. For each API in `apis_to_verify` (max 3-5):
   - Search for the API documentation
   - Fetch relevant documentation page
   - Extract key usage requirements
   - Note threading/concurrency requirements
   - Check for deprecations

3. For each API, record:
   - `api`: API name
   - `summary`: Key points (2-3 sentences)
   - `relevant_to_issue`: Whether it relates to the error

4. Set `apple_docs_fetched: true`

### Step 6: Identify Affected Files

Collect files from multiple sources:

**From log errors**:
- Extract file paths mentioned in error messages
- Validate paths exist

**From stack traces**:
- Extract files with line numbers
- Format: `path/to/File.swift:123`

**From spec document** (if valid):
- Look for file references in spec
- Check "Affected Files" or similar sections

Deduplicate and validate all paths exist before including.

### Step 7: Preliminary Classification

Based on all gathered data, suggest:

**Type** (one of):
- `bug`: Code is broken, errors in logs
- `ux-issue`: No errors, behavior issue
- `spec-drift`: Implementation doesn't match spec
- `silent-failure`: No errors but feature doesn't work
- `performance`: Slow, timeouts
- `blocker`: User marked as blocker

**Severity**:
- `critical`: App crash, data loss, security issue
- `high`: Feature completely broken
- `medium`: Feature partially broken
- `low`: Minor issue, workaround exists

**Confidence**: 0.0 - 1.0 based on:
- Amount of evidence (logs, stack traces)
- Clarity of error messages
- Spec validation success

**Reasoning**: 1-2 sentences explaining classification

### Step 8: Output Enriched JSON

Write JSON to: `.debug/issues/enriched/enriched-NNN.json`

Ensure directory exists:
```bash
mkdir -p .debug/issues/enriched
```

Follow schema exactly as documented in `docs/dev-workflow/ENRICHED-ISSUE-SCHEMA.md`

---

## Output Summary

After enrichment, report:

```
Issue NNN enriched successfully

Summary:
- Spec: [valid/invalid/not provided]
- iOS: [detected/not detected]
- Apple docs: [fetched N APIs / not needed]
- Errors found: N
- Warnings found: N
- Stack traces: N
- Affected files: N
- Preliminary: [type] / [severity] (confidence%)

Output: .debug/issues/enriched/enriched-NNN.json
```

---

## Error Handling

**Log file not found**:
- Set `log_analysis.source_file` to the expected path
- Set all counts to 0
- Set `errors`, `warnings`, `stack_traces` to empty arrays
- Note in output: "Log file not found"

**Spec file not found**:
- Set `spec_reference.path_valid: false`
- Continue with other enrichment steps

**Apple docs fetch fails**:
- Set `apple_docs_fetched: false`
- Set `apple_docs_findings` to empty array
- Triage agent will fetch during triage as fallback

**Raw issue not found**:
- Report error and exit
- Do not create enriched JSON

---

## Processing Multiple Issues

When called without arguments:

1. List all files in `.debug/issues/raw/`
2. For each `issue-NNN.md`:
   - Check if `.debug/issues/enriched/enriched-NNN.json` exists
   - If not exists: enrich the issue
   - If exists: skip (already enriched)
3. Report summary of all enriched issues

---

## Integration

This command can be run manually to re-enrich issues or batch process multiple issues. Note: The `capture-issue` skill automatically enriches issues in-session, so manual enrichment is typically only needed for re-processing.

The enriched JSON is consumed by `triage-issues` to speed up triage.
