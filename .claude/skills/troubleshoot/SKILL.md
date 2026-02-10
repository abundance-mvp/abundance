---
name: troubleshoot
description: Use when diagnosing build failures, runtime crashes, test failures, or production errors across iOS, backend, and Gemini domains — end-to-end pipeline with fix verification, regression testing, and code review
---

# Troubleshoot

End-to-end troubleshooting pipeline: classify the issue, gather context, debug via the right superpowers skill, verify the fix, write a regression test, run code review, and report.

```
triage → context → debug → verify → test → review → report
                     ↑        │
                     └─ retry ─┘ (max 3)
```

**Unique value:** No other skill provides the full `debug → verify → test → review` loop. Individual skills handle one phase; this orchestrates all seven.

## When to Use

- Issue reported (bug, crash, error, unexpected behavior)
- Build or test failure
- Device crash or unexpected runtime behavior
- Production error (Cloud Function failure, Firestore issue, Gemini pipeline error)
- When `/troubleshoot` is invoked
- When user says "troubleshoot", "debug this", "fix this", "why is this broken"

## Phase 1: TRIAGE

### 1a. Project Health Check

Run `/axiom:status` to establish baseline project health before investigating the specific issue.

If health check reveals environment issues (dead simulators, stale Derived Data, SPM cache corruption), fix those first — they may be the root cause.

### 1b. Classify Domain

Match the issue description to one of three top-level domains. First match wins.

| Domain      | Patterns                                                                                                                                                                                                          | Delegates To                                   |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| **gemini**  | Gemini, thought signature, tool calling, 400/429 error, cataloging failed, JSON parse, truncated, AI pipeline, Layer 1, Layer 2, detection, rate limit, prompt, token                                             | `gemini-integration` via `backend-superpowers` |
| **backend** | Firestore, Cloud Function, deploy, trigger, timeout, cold start, 403, 500, auth, permission denied, token, sign-in, Storage, upload, download URL, bucket, CORS, Firebase, GCP                                    | `backend-superpowers`                          |
| **ios**     | Swift, iOS, SwiftUI, camera, AVCapture, BUILD FAILED, module not found, compile, linker, @MainActor, Sendable, data race, layout, navigation, accessibility, memory leak, slow, frame drop, crash, EXC_BAD_ACCESS | `ios-superpowers`                              |

**Multi-domain detection:** If the issue spans multiple domains (e.g., "upload 403 on client, Cloud Function never fires"), classify ALL matching domains and dispatch parallel agents in Phase 3.

**Cannot classify:** Ask user for a more specific description. Do not guess.

## Phase 2: CONTEXT

Gather domain-appropriate logs and artifacts before debugging. This phase is read-only — no fixes yet.

### iOS Context

```
# Build diagnostics (prefer mcpbridge when Xcode is open)
IF mcpbridge available:
  mcp__xcode__XcodeListNavigatorIssues          # All current issues from Issue Navigator
  mcp__xcode__XcodeRefreshCodeIssuesInFile      # Live diagnostics for specific file
  mcp__xcode__GetBuildLog(severity: "error")    # Filtered build log
ELSE:
  swift build 2>&1 | tail -50

# Latest screenshots (if UI issue)
ls -lt screenshots/ | head -5

# Recent device/sim logs (if runtime issue)
XcodeBuildMCP: start_sim_log_cap or start_device_log_cap

# Build settings (if build issue)
XcodeBuildMCP: show_build_settings
```

### Backend Context

```bash
# Cloud Function logs (last 30 min)
MCP: functions_get_logs(function_names=["<relevant-function>"], min_severity="WARNING", page_size=50)

# Error groups
MCP: list_group_stats(projectName="projects/abundance-mvp", timeRangePeriod="PERIOD_1_HOUR")

# Firestore document state (if data issue)
MCP: firestore_get_documents(paths=["<relevant-doc-path>"])
```

### Gemini Context

```bash
# AI pipeline function logs
MCP: functions_get_logs(function_names=["onSessionCreated", "onItemFromSession", "onItemCreatedGemini3"], min_severity="INFO", page_size=100)

# Rate limiting check
MCP: list_log_entries(resourceNames=["projects/abundance-mvp"], filter="severity=\"WARNING\" AND jsonPayload.message=~\"429|RESOURCE_EXHAUSTED\"")

# Current prompt/config
Read: functions/src/ai-pipeline/gemini/prompts.ts
Read: functions/src/ai-pipeline/layer1/prompts.ts
```

## Phase 2.5: DOC STATUS UPDATE (if working from a filed issue)

If the issue being debugged has a corresponding doc in `docs/issues/`, update its status:

1. Update frontmatter `status: In Progress` in the `.md` file
2. Run: `uv run scripts/update_doc_index.py update docs/issues/<filename>.md --status "In Progress"`

This keeps both frontmatter and index in sync as work begins.

## Phase 3: DEBUG

Delegate to the appropriate superpowers skill with the gathered context. Do NOT maintain your own sub-domain routing — the superpowers skills handle that.

### Single iOS Domain

```
Skill(skill="ios-superpowers", args="debug <issue-description>")
```

`ios-superpowers` handles 28 sub-domains and 25+ Axiom agents internally. Pass the issue description and gathered context; it routes to the correct agent.

### Single Backend Domain

```
Skill(skill="backend-superpowers")
```

Then describe the issue with gathered context. `backend-superpowers` handles 17 sub-domains and 59 MCP tools.

### Gemini Domain

```
Skill(skill="backend-superpowers")
```

`backend-superpowers` auto-routes Gemini patterns to `gemini-integration`. Pass the issue and gathered context.

### Multi-Domain (Parallel)

Dispatch one Task agent per domain, running in parallel:

```
Task(
  subagent_type="general-purpose",
  description="Troubleshoot iOS: <summary>",
  prompt="Load Skill ios-superpowers with args 'debug <issue>'. Context: <ios-context>.
    VERIFICATION REQUIRED: Before claiming the fix is complete, you MUST run the verification
    gate function — execute build/test commands, read full output, and report results WITH
    evidence (exit codes, test counts). No 'should work' or 'looks good' claims."
)

Task(
  subagent_type="general-purpose",
  description="Troubleshoot backend: <summary>",
  prompt="Load Skill backend-superpowers. Issue: <issue>. Context: <backend-context>.
    VERIFICATION REQUIRED: Before claiming the fix is complete, you MUST run the verification
    gate function — execute build/test commands, read full output, and report results WITH
    evidence (exit codes, test counts). No 'should work' or 'looks good' claims."
)
```

**CRITICAL:** Multi-domain agents must run in a SINGLE message with parallel Task calls.
**CRITICAL:** Every dispatched agent MUST include the verification instruction in its prompt. Agents that report success without evidence are unverified — treat their results as unconfirmed.

## Phase 4: VERIFY

After a fix is applied, verify it works. This is a bounded retry loop.

**REQUIRED:** Follow the `superpowers:verification-before-completion` gate function. No completion claims without fresh verification evidence.

### Gate Function (applied at each attempt)

```
1. IDENTIFY: What command proves the fix works?
2. RUN: Execute the FULL command (fresh, not cached)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the fix?
   - If NO: Feed failure back to Phase 3 (do NOT claim progress)
   - If YES: State result WITH evidence (exit code, test count, build log)

Skip any step = unverified claim. Do not proceed.
```

### Verification Commands

| Domain  | Verify Build                                | Verify Tests                              | Verify Runtime                                                        |
| ------- | ------------------------------------------- | ----------------------------------------- | --------------------------------------------------------------------- |
| iOS     | `mcp__xcode__BuildProject` or `swift build` | `mcp__xcode__RunAllTests` or `swift test` | Optional: `Skill(skill="sim-test")` or `Skill(skill="device-tester")` |
| Backend | `cd functions && npx tsc --noEmit`          | `cd functions && npm test`                | Optional: deploy + `functions_get_logs`                               |
| Gemini  | Same as Backend                             | Same as Backend                           | Optional: test with sample input                                      |

### Retry Loop

```
attempt = 1
while attempt <= 3:
  run verification commands (gate function: RUN → READ → VERIFY)
  if ALL pass (with evidence — exit codes, test counts):
    → proceed to Phase 5
  else:
    feed failure output back to Phase 3 (debug)
    include: attempt number, error output, what was already tried
    attempt += 1

if attempt > 3:
  → STOP debugging
  → file issue via Skill(skill="file-issue") with:
    - all 3 attempts documented
    - error outputs from each attempt
    - files modified
  → proceed to Phase 7 (report) with status "UNRESOLVED"
```

**Do NOT retry infinitely.** 3 attempts maximum. After that, the issue needs human investigation.

### Post-Verify Doc Status Update

If verification passes and the issue has a corresponding doc in `docs/issues/`:

1. Update frontmatter `status: Fixed` in the `.md` file
2. Run: `uv run scripts/update_doc_index.py update docs/issues/<filename>.md --status Fixed`
3. Set `related_branch` if known: `--branch <current-branch-name>`

### Runtime Verification (Optional)

Only run sim/device testing when the issue is runtime-observable (UI bugs, crashes, interaction failures):

- Simulator: `Skill(skill="sim-test")` with relevant scenario numbers
- Physical device: `Skill(skill="device-tester")`

Skip runtime verification for pure build errors, type errors, or backend-only issues.

## Phase 5: TEST

Write a regression test that would have caught the original bug.

### iOS

```
Skill(skill="ios-superpowers", args="tdd <description-of-what-was-fixed>")
```

This invokes `superpowers:test-driven-development` with Apple docs grounding. The test should:

- Reproduce the original failure condition
- Verify the fix handles it correctly
- Live in the appropriate `Tests/` directory

### Backend

Write a test in `functions/src/**/__tests__/` that:

- Sets up the failure condition
- Verifies the fix handles it
- Uses existing test patterns from the codebase

### Skip Conditions

Skip test writing when:

- The fix is a configuration change (not testable in code)
- The fix is in a `.md` or non-code file
- The original issue was environmental (Derived Data, SPM cache)
- Time budget is exhausted (note in report that test is TODO)

## Phase 6: REVIEW

Run code review on the fix to catch secondary issues.

### Single iOS Domain

```
Skill(skill="ios-superpowers", args="review")
```

This dispatches relevant Axiom auditors (concurrency, accessibility, security, memory, architecture) based on what files changed.

### Backend or Multi-Domain

```
Skill(skill="review-commit")
```

This handles cross-domain review with the appropriate skill routing.

### Skip Conditions

Skip review when:

- Fix is a single-line change (typo, config value)
- Fix is reverting a previous change
- All 3 retry attempts failed (Phase 4 → issue filed, nothing to review)

## Phase 7: REPORT

Generate a structured report summarizing all phases to docs/issues/reports/<date mm-dd-yy>_troubleshoot_report_<0-9><0-9><0-9>.md

```
docs/issues/reports/02-09-26_troubleshoot_report_001.md
docs/issues/reports/02-09-26_troubleshoot_report_002.md
docs/issues/reports/02-10-26_troubleshoot_report_001.md
docs/issues/reports/02-10-26_troubleshoot_report_002.md
...
```

```markdown
## Troubleshooting Report

### Issue

<original description>

### Domain Classification

<domain(s)> — routed to <skill(s)>

### Health Check

<axiom:status results — PASS/issues found>

### Root Cause

<what caused the issue>

### Fix Applied

<files changed and what was done>

### Verification (evidence required — `superpowers:verification-before-completion`)

- Build: PASS/FAIL — exit code, command used
- Tests: PASS/FAIL — N/N passed, command used
- Runtime: PASS/FAIL/SKIPPED — observation details
- Attempts: N/3

### Regression Test

<test file and what it covers, or SKIPPED with reason>

### Code Review

<review summary — clean/findings, or SKIPPED with reason>

### Status

RESOLVED / UNRESOLVED (issue filed: <path>)
```

### Issue Filing

If status is UNRESOLVED (3 retries exhausted), the issue was already filed in Phase 4. Reference it in the report.

If review reveals additional issues beyond the original fix, offer to file them:

```
"Review found N additional issues. File them? (Y/n)"
→ Yes: Skill(skill="file-issue") for each
→ No: List in report under "Additional Findings"
```

## Error Handling

| Condition                    | Action                                                        |
| ---------------------------- | ------------------------------------------------------------- |
| Domain not detected          | Ask user for more specific description                        |
| `/axiom:status` fails        | Note in report, proceed with Phase 2                          |
| Logs unavailable (MCP error) | Proceed with code-only analysis, note missing context         |
| Multi-domain conflict        | Dispatch agents for ALL matching domains in parallel          |
| Fix verification fails 3x    | File issue, report as UNRESOLVED                              |
| Agent returns no fix         | Escalate with full context dump, suggest manual investigation |
| Test writing fails           | Note as TODO in report, do not block pipeline                 |
| Review finds critical issues | Report them, offer to file as separate issues                 |

## Red Flags — STOP and Re-read This Skill

| Thought                                               | Reality                                                                                                           |
| ----------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| "I'll route to specific Axiom agents myself"          | Delegate to `ios-superpowers debug`. It handles agent selection for 28 domains.                                   |
| "Skip the health check, the user described the issue" | Health check catches environmental issues that masquerade as code bugs. Always run it.                            |
| "Fix looks good, skip verification"                   | The verify loop is the whole point. `BuildProject` + `RunAllTests` (or `swift build && swift test`) minimum.      |
| "No test needed, it's a simple fix"                   | Simple fixes regress. Write the test unless skip conditions apply.                                                |
| "Skip review, I already reviewed while fixing"        | Fresh review catches what tunnel vision misses. Run it.                                                           |
| "Fix looks good, should work now"                     | "Should" is not evidence. Run the command. Read the output. THEN claim it works.                                  |
| "Agent reported success"                              | Agent reports are unverified claims. Check the VCS diff. Run build/test yourself.                                 |
| "Retry a 4th time, I'm close"                         | 3 attempts max. File the issue. Fresh eyes will solve it faster.                                                  |
| "I'll investigate all domains sequentially"           | Multi-domain issues get parallel agents. One message, multiple Task calls.                                        |
| "Backend issue, no need for Apple docs"               | Correct — only iOS issues need Apple docs. But iOS issues ALWAYS go through `ios-superpowers` which handles that. |

## Token Budget

| Phase      | Budget    | Notes                          |
| ---------- | --------- | ------------------------------ |
| 1. Triage  | ~5K       | Health check + classification  |
| 2. Context | ~10K      | Log gathering, file reads      |
| 3. Debug   | ~40K      | Delegated to superpowers skill |
| 4. Verify  | ~15K      | Build/test output (×3 max)     |
| 5. Test    | ~20K      | Test writing via TDD workflow  |
| 6. Review  | ~20K      | Delegated to review skill      |
| 7. Report  | ~5K       | Structured output              |
| **Total**  | **~115K** | Well under 128K context limit  |

If context is running low (>100K used), skip Phase 5 (test) and Phase 6 (review), note as TODO in report.

## What This Skill Does NOT Do

- Replace `ios-superpowers` or `backend-superpowers` (it delegates to them)
- Maintain its own sub-domain routing (superpowers skills handle that)
- Deploy to production (verification uses staging/local only)
- Fix issues automatically without user awareness (reports everything)
- Run more than 3 retry attempts (files issue instead)
