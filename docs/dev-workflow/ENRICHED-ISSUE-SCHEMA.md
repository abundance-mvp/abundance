# Enriched Issue JSON Schema

**Version**: v1
**Created**: 2025-12-11
**Status**: Active

---

## Overview

When a bug is captured via the `capture-issue` skill, enrichment happens automatically in the same session. The enriched data is stored as JSON and used by the `triage-issues` command to speed up analysis.

**Purpose**: Pre-fetch specs, parse logs, detect iOS frameworks, and gather Apple documentation BEFORE triage, reducing redundant work and improving accuracy.

**Skill location**: `.claude/skills/capture-issue/SKILL.md`

---

## File Location

```
.debug/issues/enriched/enriched-NNN.json
```

Where `NNN` is the zero-padded issue number (e.g., `enriched-003.json`).

---

## Schema Definition

### Root Object

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `$schema` | string | Yes | Schema version identifier (`"enriched-issue-v1"`) |
| `issue_number` | integer | Yes | Issue number matching the raw issue file |
| `captured_at` | ISO 8601 | Yes | Timestamp when user captured the issue |
| `enriched_at` | ISO 8601 | Yes | Timestamp when enrichment completed |
| `user_report` | object | Yes | Original user input from capture |
| `spec_reference` | object | Yes | Spec validation results |
| `log_analysis` | object | Yes | Parsed log file data |
| `ios_context` | object | Yes | iOS detection and Apple docs |
| `affected_files` | object | Yes | Files identified as relevant |
| `preliminary_classification` | object | Yes | AI-suggested classification |
| `raw_issue_path` | string | Yes | Path to original raw issue markdown |

---

### user_report

User input collected during issue capture.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `expected` | string | Yes | What the user expected to happen |
| `actual` | string | Yes | What actually happened |
| `screen` | string | Yes | Screen or feature being tested |
| `type` | string | Yes | Issue type: `bug`, `ux-issue`, `spec-drift`, `silent-failure`, `performance`, `blocker` |
| `blocking_context` | string | No | What is blocked (only for `blocker` type) |
| `impact_level` | integer | No | Impact 1-10 (only for `blocker` type) |

---

### spec_reference

Results of spec document validation.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `provided_path` | string | No | What the user typed (e.g., `"mvp-vision-features"`) |
| `resolved_path` | string | No | Actual file path found (e.g., `"docs/specs/mvp-vision-features.md"`) |
| `path_valid` | boolean | Yes | Whether the spec file was found |
| `section` | string | No | Spec section user referenced |
| `relevant_excerpts` | string[] | No | Extracted text from spec (max 5 excerpts) |

**Example**:
```json
{
  "provided_path": "mvp-vision-features",
  "resolved_path": "docs/specs/mvp-vision-features.md",
  "path_valid": true,
  "section": "Photo Upload Flow",
  "relevant_excerpts": [
    "Photos must be uploaded within 3 seconds of capture",
    "Upload failures must show user-facing error message"
  ]
}
```

---

### log_analysis

Parsed and analyzed log file data.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `source_file` | string | Yes | Path to log file analyzed |
| `total_lines` | integer | Yes | Total lines in log file |
| `error_count` | integer | Yes | Number of ERROR level entries |
| `warning_count` | integer | Yes | Number of WARNING level entries |
| `errors` | LogEntry[] | Yes | Array of error entries (max 20) |
| `warnings` | LogEntry[] | Yes | Array of warning entries (max 10) |
| `stack_traces` | StackTrace[] | Yes | Extracted stack traces |

**LogEntry**:
| Field | Type | Description |
|-------|------|-------------|
| `line` | integer | Line number in log file |
| `level` | string | Log level (`ERROR`, `WARNING`, etc.) |
| `message` | string | Log message text |
| `timestamp` | ISO 8601 | When the log was written (if available) |

**StackTrace**:
| Field | Type | Description |
|-------|------|-------------|
| `start_line` | integer | Line number where trace begins |
| `frames` | string[] | Stack frames (most recent first) |

**Example**:
```json
{
  "source_file": ".debug/logs/session-20251211-210800.log",
  "total_lines": 847,
  "error_count": 3,
  "warning_count": 12,
  "errors": [
    {
      "line": 234,
      "level": "ERROR",
      "message": "StorageService.uploadPhoto failed: user_id is nil",
      "timestamp": "2025-12-11T21:07:45Z"
    }
  ],
  "warnings": [
    {
      "line": 230,
      "level": "WARNING",
      "message": "AuthService.currentUser returned nil"
    }
  ],
  "stack_traces": [
    {
      "start_line": 235,
      "frames": [
        "CameraViewModel.capturePhoto() at CameraViewModel.swift:102",
        "StorageService.uploadPhoto() at StorageService.swift:45"
      ]
    }
  ]
}
```

---

### ios_context

iOS framework detection and Apple documentation.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `detected` | boolean | Yes | Whether iOS context was detected |
| `detection_reason` | string | No | Why iOS was detected (or not) |
| `frameworks_involved` | string[] | No | iOS frameworks identified |
| `apis_to_verify` | string[] | No | Specific APIs needing verification |
| `apple_docs_fetched` | boolean | Yes | Whether Apple docs were fetched |
| `apple_docs_findings` | AppleDocFinding[] | No | Documentation findings |

**AppleDocFinding**:
| Field | Type | Description |
|-------|------|-------------|
| `api` | string | API name (e.g., `@MainActor`) |
| `summary` | string | Key documentation points |
| `relevant_to_issue` | boolean | Whether directly relevant |

**Example**:
```json
{
  "detected": true,
  "detection_reason": "Swift files in Sources/, @MainActor keyword in logs",
  "frameworks_involved": ["SwiftUI", "AVFoundation", "FirebaseStorage"],
  "apis_to_verify": ["Task.detached", "@MainActor", "AVCaptureSession"],
  "apple_docs_fetched": true,
  "apple_docs_findings": [
    {
      "api": "@MainActor",
      "summary": "Must be used for UI updates from async contexts",
      "relevant_to_issue": true
    }
  ]
}
```

---

### affected_files

Files identified as relevant to the issue.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `from_logs` | string[] | Yes | Files mentioned in log errors |
| `from_stack_traces` | string[] | Yes | Files in stack traces (with line numbers) |
| `from_spec` | string[] | Yes | Files referenced in spec document |

**Example**:
```json
{
  "from_logs": [
    "Sources/CameraFeature/ViewModels/CameraViewModel.swift",
    "Sources/Persistence/StorageService.swift"
  ],
  "from_stack_traces": [
    "Sources/CameraFeature/ViewModels/CameraViewModel.swift:102"
  ],
  "from_spec": [
    "Sources/CameraFeature/Views/CameraView.swift"
  ]
}
```

---

### preliminary_classification

AI-suggested classification before triage.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `likely_type` | string | Yes | Suggested type: `bug`, `ux-issue`, `spec-drift`, `silent-failure`, `performance`, `blocker` |
| `likely_severity` | string | Yes | Suggested severity: `critical`, `high`, `medium`, `low` |
| `confidence` | float | Yes | Confidence score 0.0-1.0 |
| `reasoning` | string | Yes | Explanation of classification |

**Example**:
```json
{
  "likely_type": "bug",
  "likely_severity": "high",
  "confidence": 0.85,
  "reasoning": "Error logs show nil user_id causing upload failure, stack trace points to CameraViewModel"
}
```

---

## Complete Example

```json
{
  "$schema": "enriched-issue-v1",
  "issue_number": 3,
  "captured_at": "2025-12-11T21:08:00Z",
  "enriched_at": "2025-12-11T21:08:30Z",

  "user_report": {
    "expected": "Camera should capture and upload photo",
    "actual": "Photo captured but upload fails silently",
    "screen": "CameraView",
    "type": "silent-failure",
    "blocking_context": null,
    "impact_level": null
  },

  "spec_reference": {
    "provided_path": "mvp-vision-features",
    "resolved_path": "docs/specs/mvp-vision-features.md",
    "path_valid": true,
    "section": "Photo Upload Flow",
    "relevant_excerpts": [
      "Photos must be uploaded within 3 seconds of capture",
      "Upload failures must show user-facing error message"
    ]
  },

  "log_analysis": {
    "source_file": ".debug/logs/session-20251211-210800.log",
    "total_lines": 847,
    "error_count": 3,
    "warning_count": 12,
    "errors": [
      {
        "line": 234,
        "level": "ERROR",
        "message": "StorageService.uploadPhoto failed: user_id is nil",
        "timestamp": "2025-12-11T21:07:45Z"
      }
    ],
    "warnings": [
      {
        "line": 230,
        "level": "WARNING",
        "message": "AuthService.currentUser returned nil"
      }
    ],
    "stack_traces": [
      {
        "start_line": 235,
        "frames": [
          "CameraViewModel.capturePhoto() at CameraViewModel.swift:102",
          "StorageService.uploadPhoto() at StorageService.swift:45"
        ]
      }
    ]
  },

  "ios_context": {
    "detected": true,
    "detection_reason": "Swift files in Sources/, @MainActor keyword in logs",
    "frameworks_involved": ["SwiftUI", "AVFoundation", "FirebaseStorage"],
    "apis_to_verify": ["Task.detached", "@MainActor", "AVCaptureSession"],
    "apple_docs_fetched": true,
    "apple_docs_findings": [
      {
        "api": "@MainActor",
        "summary": "Must be used for UI updates from async contexts",
        "relevant_to_issue": true
      }
    ]
  },

  "affected_files": {
    "from_logs": [
      "Sources/CameraFeature/ViewModels/CameraViewModel.swift",
      "Sources/Persistence/StorageService.swift"
    ],
    "from_stack_traces": [
      "Sources/CameraFeature/ViewModels/CameraViewModel.swift:102"
    ],
    "from_spec": [
      "Sources/CameraFeature/Views/CameraView.swift"
    ]
  },

  "preliminary_classification": {
    "likely_type": "bug",
    "likely_severity": "high",
    "confidence": 0.85,
    "reasoning": "Error logs show nil user_id causing upload failure, stack trace points to CameraViewModel"
  },

  "raw_issue_path": ".debug/issues/raw/issue-003.md"
}
```

---

## How triage-issues Uses This Data

When `claude triage-issues` runs:

1. **Checks for enriched JSON** in `.debug/issues/enriched/`
2. **If found**: Uses pre-fetched data instead of re-fetching
   - `spec_reference.relevant_excerpts` → Skip reading spec file
   - `log_analysis.errors` → Skip parsing log file
   - `ios_context.apple_docs_findings` → Skip Apple docs fetch
   - `affected_files` → Use directly in spec document
   - `preliminary_classification` → Starting point for triage
3. **If not found**: Falls back to current behavior (fetch during triage)

---

## How to Regenerate Enriched Data

Enrichment normally happens automatically via the `capture-issue` skill.

If you need to re-enrich an issue manually:

```bash
# Enrich a specific issue
claude enrich-issue 3

# Enrich all raw issues without enriched JSON
claude enrich-issue
```

The enrichment agent will overwrite existing enriched JSON files.

> **Note**: The `capture-issue` skill does enrichment in-session, avoiding the subprocess permission issues that affected the old `capture-issue.sh` script.

---

## Schema Versioning

- Current version: `enriched-issue-v1`
- Version is stored in `$schema` field
- Future versions will maintain backward compatibility
- Triage agent checks version before processing

---

**See also**:
- `docs/dev-workflow/BUG-FILING-WORKFLOW.md` - Full workflow documentation
- `.claude/skills/capture-issue/SKILL.md` - Capture + enrichment skill
- `.claude/commands/enrich-issue.md` - Manual enrichment command
