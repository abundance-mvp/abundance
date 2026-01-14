# Triage Issues Command

You are an expert issue triage agent for the Abundance iOS app.

## Your Task

Read all unprocessed issues from `.debug/issues/raw/` and triage them systematically.

## Pre-Enriched Data

Issues may have pre-enriched data available in `.debug/issues/enriched/enriched-NNN.json`.

**Check for enriched data FIRST** before processing each issue:

1. Look for `.debug/issues/enriched/enriched-NNN.json`
2. **If enriched JSON exists**, use pre-fetched data:
   - `spec_reference.relevant_excerpts` → Skip reading spec file
   - `log_analysis.errors` → Skip parsing log file
   - `ios_context.apple_docs_findings` → Skip Apple docs fetch (if `apple_docs_fetched: true`)
   - `affected_files` → Use directly in spec document
   - `preliminary_classification` → Starting point for triage (verify, don't blindly trust)

3. **If enriched JSON does NOT exist**, fall back to current behavior (fetch during triage)

**Schema documentation**: `docs/dev-workflow/ENRICHED-ISSUE-SCHEMA.md`

## Process

For each issue:

1. **Check for enriched data** (`.debug/issues/enriched/enriched-NNN.json`)
   - If exists: Load and use pre-fetched context
   - If not: Proceed with manual data gathering

2. **Read the issue document** (`.debug/issues/raw/issue-NNN.md`)
   - If enriched: Cross-reference with enriched JSON
   - If not enriched: Parse manually

3. **Read attached logs** (referenced in the issue)
   - If enriched: Use `log_analysis.errors` and `log_analysis.stack_traces`
   - If not enriched: Read full log file from `**Log file**` field

4. **Classify the issue**:
   - `bug`: Code is broken, produces errors
   - `ux-issue`: Works but UX is poor/confusing
   - `spec-drift`: Implementation doesn't match spec docs
   - `silent-failure`: No error but feature doesn't work
   - `performance`: Too slow, violates performance specs
   - `blocker`: Urgent showstopper blocking development/testing/deployment

5. **Determine root cause**:
   - Analyze logs for patterns (use `log_analysis` from enriched data if available)
   - Check for missing log events (silent failures)
   - Compare against spec documents if referenced (use `spec_reference.relevant_excerpts` if available)
   - Identify which code files are likely involved (use `affected_files` if available)

6. **Fetch Apple Documentation (iOS issues only)**:

   **Check enriched data first:**
   - If `ios_context.apple_docs_fetched == true` in enriched JSON:
     Use `ios_context.apple_docs_findings` directly (SKIP fetching)
   - If not enriched or `apple_docs_fetched == false`:
     Fetch Apple docs as described below

   **MANDATORY for issues involving iOS frameworks (if not already fetched).**

   Detect iOS involvement by checking:
   - Affected files are `.swift` in `Sources/` or `App/`
   - Error messages contain iOS framework names (SwiftUI, Vision, AVFoundation, etc.)
   - Logs mention `@MainActor`, `Task`, `async`, `actor`, `Sendable`

   If iOS detected and docs not already fetched:
   ```
   Tool: Skill
   Parameters:
     skill: apple-docs-fetcher
   ```

   For each iOS API in the issue (max 3-5):
   - Fetch latest documentation
   - Verify correct API usage patterns
   - Check threading/concurrency requirements
   - Identify if issue is API misuse vs actual bug
   - Note any deprecations or iOS version requirements

   Include Apple docs findings in:
   - Root cause analysis
   - Suggested fix (must follow Apple patterns)
   - Test plan (verify against docs)

7. **Create spec document** (ALWAYS include descriptive suffix in filename):
   - For `bug`: Create `docs/bugs/BUG-NNN-short-description.md` with:
     - Description of the bug
     - Expected vs actual behavior
     - Root cause analysis
     - Affected files
     - Suggested fix
     - Test plan
   - For `blocker`: Create `docs/bugs/BLOCKER-NNN-short-description.md` with:
     - Executive summary
     - Root cause analysis
     - What is blocked (development/testing/deployment)
     - Immediate workaround (if available)
     - Proper solution
     - Timeline for resolution
   - For `spec-drift`: Update existing spec with changelog
   - For `ux-issue`: Create `docs/refinements/REF-NNN-short-description.md`
   - For `performance`: Create `docs/bugs/PERF-NNN-short-description.md`

   **IMPORTANT**: File naming convention:
   - Pattern: `TYPE-NNN-short-description.md`
   - Short description: lowercase, hyphenated, max 5 words
   - Examples:
     - `BUG-001-camera-upload-hardcoded-user-id.md`
     - `BLOCKER-001-firebase-bundle-id-mismatch.md`
     - `PERF-003-image-loading-timeout.md`

   **NEVER** file bug documentation to `docs/` root - always use `docs/bugs/` or `docs/refinements/`

8. **Move issue to triaged**:
   - Move from `.debug/issues/raw/` to `.debug/issues/triaged/`
   - Create a JSON metadata file for agent dispatch

## Example Triage Output

For a bug issue:

**docs/bugs/BUG-001-catalog-button-unresponsive.md**:
```markdown
# BUG-001: Catalog Button Unresponsive After Auth Failure

**Status**: Triaged
**Severity**: High
**Type**: Silent Failure
**Created**: 2025-11-16

## Description

When user attempts to catalog an item but auth token has expired, the "Catalog Item" button becomes unresponsive. No error is shown to the user.

## Expected Behavior

Button should either:
1. Refresh auth token automatically and proceed
2. Show error message and prompt re-authentication

## Actual Behavior

Button tap has no effect. Logs show:
```
[ERROR] Auth token expired
[INFO] Button tapped: Catalog Item
```

No subsequent navigation or error handling.

## Root Cause

From logs analysis:
- `AuthViewModel.verifyToken()` fails silently
- `CatalogViewModel.startCatalog()` checks auth but doesn't communicate failure to UI
- UI button handler assumes success

## Affected Files

- `Sources/ViewModels/CatalogViewModel.swift` (lines ~45-60)
- `Sources/Views/HomeView.swift` (button handler)
- `Sources/Services/AuthService.swift` (token verification)

## Suggested Fix

1. Add error state to `CatalogViewModel`
2. Emit error event when auth fails
3. Show alert in UI when error occurs
4. Add logging for auth failure path

## Test Plan

- [ ] Unit test: `CatalogViewModel.startCatalog()` with expired token
- [ ] UI test: Tap catalog button with expired auth
- [ ] Verify error alert appears
- [ ] Verify logs show auth failure clearly

## References

- Spec: docs/specs/mvp-vision-features.md (user flow)
- Original issue: .debug/issues/triaged/issue-001.md

## Apple Documentation Verification (iOS issues)

**APIs Verified**:
- `Task.detached` - Correct usage per Apple docs, but missing @MainActor for UI updates
- `@Published` - Correct, but should use `@Observable` for iOS 17+

**Apple Docs Findings**:
- Root cause confirmed: Missing actor isolation when updating UI from background task
- Fix must wrap UI updates in `await MainActor.run { }` per Swift Concurrency docs
```

**.debug/issues/triaged/issue-001.json**:
```json
{
  "issue_id": "001",
  "type": "bug",
  "severity": "high",
  "bug_doc": "docs/bugs/BUG-001-catalog-button-unresponsive.md",
  "affected_files": [
    "Sources/ViewModels/CatalogViewModel.swift",
    "Sources/Views/HomeView.swift",
    "Sources/Services/AuthService.swift"
  ],
  "estimated_effort": "small",
  "suggested_branch": "fix/catalog-button-auth-failure",
  "ios_apis_verified": ["Task.detached", "@Published", "@MainActor"],
  "apple_docs_findings": "Missing actor isolation for UI updates"
}
```

**For a BLOCKER issue**:

**.debug/issues/triaged/blocker-001.json**:
```json
{
  "issue_id": "001",
  "type": "blocker",
  "severity": "critical",
  "bug_doc": "docs/bugs/BLOCKER-001-firebase-bundle-id-mismatch.md",
  "blocking": ["simulator-testing", "testflight-deployment"],
  "affected_files": [
    "App/GoogleService-Info.plist",
    "Package.swift"
  ],
  "estimated_effort": "medium",
  "requires_user_action": true,
  "suggested_branch": "fix/firebase-bundle-id",
  "immediate_workaround": "Download new plist with SPM bundle ID",
  "proper_solution": "Convert to Xcode project"
}
```

## Instructions

1. List all files in `.debug/issues/raw/`
2. For each issue, follow the triage process above
3. Create appropriate spec documents
4. Move issues to triaged with JSON metadata
5. Report summary of triaged issues

Start now!
