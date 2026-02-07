---
name: troubleshoot
description: Route troubleshooting agents to the correct skill (ios-superpowers, backend-superpowers, gemini-integration) based on the issue domain. Combines log gathering, agent dispatch, and fix verification.
---

# Troubleshoot Command

Automatically classifies an issue by domain, gathers relevant logs/context, then dispatches the appropriate troubleshooting agent routed to the correct skill.

## Usage

```
/troubleshoot <issue-description>
/troubleshoot <error-message>
/troubleshoot                      # Interactive — asks for issue description
```

## How It Works

### Step 1: Classify Issue Domain

Match the issue description against patterns. First match wins.

| Priority | Domain | Patterns | Skill | Log Source |
|----------|--------|----------|-------|------------|
| 1 | **gemini** | Gemini, thought signature, tool calling, 400 error, cataloging failed, JSON parse, truncated, AI pipeline, Layer 1, Layer 2, detection, rate limit 429 | `gemini-integration` | Cloud Function logs |
| 2 | **ios-camera** | camera, AVCapture, preview, capture session, photo output | `ios-superpowers` + `axiom-camera-capture` | Device logs |
| 3 | **ios-build** | BUILD FAILED, module not found, compile error, linker | `ios-superpowers` + `axiom-xcode-debugging` | Xcode build output |
| 4 | **ios-concurrency** | @MainActor, actor-isolated, Sendable, data race, Swift 6 | `ios-superpowers` + `axiom-swift-concurrency` | Build warnings |
| 5 | **ios-ui** | SwiftUI, layout, navigation, accessibility, VoiceOver, AsyncImage | `ios-superpowers` + `axiom-ios-ui` | Screenshots |
| 6 | **ios-performance** | slow, memory leak, battery, janky, frame drop | `ios-superpowers` + `axiom-ios-performance` | Instruments/profiler |
| 7 | **backend-firestore** | Firestore, document, collection, query, transaction, security rules | `backend-superpowers` | Cloud Function logs |
| 8 | **backend-functions** | Cloud Function, deploy, trigger, timeout, cold start, 403, 500 | `backend-superpowers` | Cloud Function logs |
| 9 | **backend-auth** | auth, permission denied, token, sign-in, user | `backend-superpowers` | Auth logs |
| 10 | **backend-storage** | Storage, upload, download URL, bucket, 403 Forbidden, CORS | `backend-superpowers` | Storage logs |
| 11 | **ios-general** | Swift, iOS, app crash, EXC_BAD_ACCESS | `ios-superpowers` | Crash logs |
| 12 | **backend-general** | Firebase, GCP, deploy, backend | `backend-superpowers` | Cloud Logging |

**Multi-domain detection:** If the issue spans multiple domains (e.g., "image upload fails — 403 on client, Cloud Function never fires"), classify ALL matching domains and dispatch parallel agents.

### Step 2: Gather Context by Domain

Before dispatching agents, gather domain-appropriate logs/context:

#### iOS Context
```bash
# Recent device logs (if device-tester active)
XcodeBuildMCP: start_sim_log_cap or start_device_log_cap

# Latest screenshots
ls -lt screenshots/ | head -5

# Build output
swift build 2>&1 | tail -50

# Xcode build settings (if build issue)
XcodeBuildMCP: show_build_settings
```

#### Backend Context
```bash
# Cloud Function logs (last 30 min)
MCP: functions_get_logs(function_names=["<relevant-function>"], min_severity="WARNING", page_size=50)

# Error groups
MCP: list_group_stats(projectName="projects/abundance-mvp", timeRangePeriod="PERIOD_1_HOUR")

# Firestore document state
MCP: firestore_get_documents(paths=["<relevant-doc-path>"])
```

#### Gemini Context
```bash
# AI pipeline function logs
MCP: functions_get_logs(function_names=["onSessionCreated", "onItemFromSession", "onItemCreatedGemini3"], min_severity="INFO", page_size=100)

# Check rate limiting
MCP: list_log_entries(resourceNames=["projects/abundance-mvp"], filter="severity=\"WARNING\" AND jsonPayload.message=~\"429|RESOURCE_EXHAUSTED\"")

# Read current prompt/config
Read: functions/src/ai-pipeline/gemini/prompts.ts
Read: functions/src/ai-pipeline/layer1/prompts.ts
```

### Step 3: Load Skill and Dispatch Agent

Load the appropriate skill, then dispatch a troubleshooting agent:

```
# Load skill for domain context
Skill(skill="<domain-skill>")

# Dispatch agent
Task(
  description: "Troubleshoot <issue-summary>",
  subagent_type: "general-purpose",  # or specific axiom agent
  prompt: """
  ## Issue
  <issue description>

  ## Domain
  <classified domain>

  ## Gathered Context
  <logs, screenshots, build output>

  ## Instructions
  1. Analyze the logs/context to identify root cause
  2. Read the relevant source files
  3. Implement the fix
  4. Verify the fix compiles/passes tests

  ## Architecture Constraints
  <domain-specific constraints from skill>
  """
)
```

#### Axiom Agent Selection (iOS)

For iOS issues, dispatch the appropriate Axiom agent instead of `general-purpose`:

| Domain | Axiom Agent |
|--------|-------------|
| ios-camera | `axiom:camera-auditor` |
| ios-build | `axiom:build-fixer` |
| ios-concurrency | `axiom:concurrency-auditor` |
| ios-ui | `axiom:swiftui-performance-analyzer` or `axiom:accessibility-auditor` |
| ios-performance | `axiom:memory-auditor` or `axiom:swift-performance-analyzer` |
| ios-general | `general-purpose` with ios-superpowers context |

### Step 4: Verify Fix

After the agent returns a fix:

```bash
# iOS: Build check
swift build

# Backend: TypeScript compile + deploy
cd functions && npx tsc --noEmit && cd ..

# If device-tester active: Rebuild and test on device
XcodeBuildMCP: build_device / build_sim → install → launch

# Backend: Deploy and verify logs
firebase deploy --only functions:<name>
MCP: functions_get_logs(min_severity="ERROR", page_size=10)
```

### Step 5: Report

```markdown
## Troubleshooting Report

### Issue
<original description>

### Domain Classification
<domain> → routed to <skill>

### Root Cause
<what caused the issue>

### Fix Applied
<files changed and what was done>

### Verification
- Build: PASS/FAIL
- Tests: PASS/FAIL (N tests)
- Deploy: PASS/FAIL (if backend)
- Device: PASS/FAIL (if device-tester active)
```

---

## Multi-Issue Dispatch

When multiple issues are reported at once, classify each independently and dispatch parallel agents:

```
/troubleshoot "3 issues: (1) 50s detection time, (2) broken thumbnails, (3) camera crash on tab switch"
```

This classifies as:
1. `gemini` — rate limiting → `gemini-integration` skill
2. `ios-ui` — AsyncImage failure → `ios-superpowers` skill
3. `ios-camera` — AVCaptureSession lifecycle → `ios-superpowers` + `axiom-camera-capture` skill

Dispatches 3 parallel agents, each with domain-appropriate logs.

---

## Examples

### Camera crash
```
/troubleshoot "Camera shows error dialog after switching tabs"
```
Domain: `ios-camera` → Skill: `ios-superpowers` → Agent: `axiom:camera-auditor`

### Cloud Function 403
```
/troubleshoot "onItemFromSession getting 403 when fetching images"
```
Domain: `backend-storage` + `gemini` → Skill: `backend-superpowers` + `gemini-integration` → Parallel agents

### Slow AI pipeline
```
/troubleshoot "Layer 1 detection taking 50 seconds instead of 5"
```
Domain: `gemini` → Skill: `gemini-integration` → Agent with Cloud Function logs

### Build failure
```
/troubleshoot "BUILD FAILED: cannot find type 'Item' in scope"
```
Domain: `ios-build` → Skill: `ios-superpowers` → Agent: `axiom:build-fixer`

---

## Error Handling

- **Domain not detected** — Ask user for more specific description
- **Logs unavailable** — Proceed with code-only analysis, note missing context
- **Multi-domain conflict** — Dispatch agents for ALL matching domains in parallel
- **Fix verification fails** — Report failure, suggest manual investigation
- **Agent returns no fix** — Escalate with full context dump for manual review
