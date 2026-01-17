# Abundance Development System - Quick Reference

## Architecture Overview

```
┌────────────────────────────────────────────────────────────────────┐
│                       iOS Development                               │
│  ┌─────────────────────┐     ┌─────────────────────┐               │
│  │   ios-superpowers   │     │    device-tester    │               │
│  │   (Axiom router)    │     │  (devicectl + logs) │               │
│  │                     │     │                     │               │
│  │ Actions:            │     │ Workflows:          │               │
│  │ - debug             │     │ - Build & deploy    │               │
│  │ - tdd               │     │ - Crash analysis    │               │
│  │ - review            │     │ - Performance       │               │
│  │ - plan              │     │ - Screenshot debug  │               │
│  │ - execute           │     │ - Backend logs      │               │
│  │ - brainstorm        │     │                     │               │
│  │ - parallel          │     │                     │               │
│  └─────────────────────┘     └─────────────────────┘               │
└────────────────────────────────────────────────────────────────────┘
                              ↕ (backend verification)
┌────────────────────────────────────────────────────────────────────┐
│                      Backend Operations                             │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                   backend-superpowers                         │  │
│  │          Unified Firebase + GCP MCP Integration               │  │
│  ├──────────────────────────────────────────────────────────────┤  │
│  │ Firebase MCP   │ Observability │ Storage MCP  │ GCloud CLI   │  │
│  │ (29 tools)     │ (13 tools)    │ (17 tools)   │ (1 tool)     │  │
│  │                │               │              │              │  │
│  │ - Firestore    │ - Logging     │ - Buckets    │ - Any gcloud │  │
│  │ - Functions    │ - Metrics     │ - Objects    │   command    │  │
│  │ - Auth         │ - Tracing     │ - IAM        │              │  │
│  │ - FCM          │ - Alerts      │ - Insights   │              │  │
│  │ - RemoteConfig │ - Errors      │              │              │  │
│  │ - RTDB         │               │              │              │  │
│  │ - Rules        │               │              │              │  │
│  │ - Projects     │               │              │              │  │
│  └──────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────┘
```

---

## Quick Commands

### iOS Development

| Command | Purpose |
|---------|---------|
| `/project:ios-superpowers debug <issue>` | Debug with Axiom agents |
| `/project:ios-superpowers tdd <feature>` | Test-driven development |
| `/project:ios-superpowers review` | Code review with audits |
| `/project:ios-superpowers plan <feature>` | Plan implementation |
| `/project:ios-superpowers execute <plan>` | Execute a plan |
| `/project:ios-superpowers brainstorm <topic>` | Design exploration |
| `/project:ios-debug <issue>` | Quick debug shortcut |
| `/project:device-tester` | Physical device testing |
| `/axiom:fix-build` | Fix build failures |
| `/axiom:screenshot` | Capture simulator screenshot |

### Backend Operations

| Command | Purpose |
|---------|---------|
| `/project:backend-superpowers` | Load unified backend skill |
| `/project:gcp-deploy <function>` | Deploy Cloud Function |
| `/project:gcp-deploy <fn> --verify` | Deploy with verification |
| `/project:gcp-deploy <fn> --notify` | Deploy with FCM notification |

---

## Skill Reference

### ios-superpowers

**Purpose:** Deterministic iOS orchestrator that routes to Axiom agents and skills.

**When to Use:** ALL iOS/Swift development work.

**Actions:**

| Action | What It Does |
|--------|--------------|
| `debug` | Routes to appropriate Axiom agent based on error patterns |
| `tdd` | Test-driven development with `axiom-ui-testing` |
| `review` | Parallel Axiom auditors + code review |
| `plan` | Apple docs research + implementation planning |
| `execute` | Run tests + execute implementation |
| `brainstorm` | HIG + architecture exploration |
| `parallel` | Multi-agent dispatch for independent tasks |

**Domain Detection:**

| Domain | Trigger Patterns | Axiom Agent |
|--------|------------------|-------------|
| build | BUILD FAILED, module not found | `axiom:build-fixer` |
| concurrency | @MainActor, Sendable, actor | `axiom:concurrency-auditor` |
| memory | leak, retain cycle | `axiom:memory-auditor` |
| ui-arch | @State, MVVM, view model | `axiom:swiftui-architecture-auditor` |
| ui-nav | NavigationStack, deep link | `axiom:swiftui-nav-auditor` |
| ui-perf | janky, frame drop | `axiom:swiftui-performance-analyzer` |
| ui-access | VoiceOver, accessibility | `axiom:accessibility-auditor` |
| test | XCUITest, flaky | `axiom:test-failure-analyzer` |

---

### device-tester

**Purpose:** Iterative testing on physical iOS device.

**Device:** w-16e (iPhone)
**Bundle ID:** com.abundance.mvp

**Workflows:**

| Trigger | Action |
|---------|--------|
| App crashed | Launch `axiom:crash-analyzer` |
| Tests failing | Launch `axiom:test-debugger` |
| Performance issues | Launch `axiom:performance-profiler` |
| Build failed | Launch `axiom:build-fixer` |
| Backend errors | Check Cloud Functions logs via MCP |
| UI bug | Read screenshot from `./screenshots/` |

**Key Commands:**

```bash
# Build and install
xcodebuild -scheme Abundance -destination "platform=iOS,name=w-16e" build
xcrun devicectl device install app --device w-16e /path/to/App.app

# Launch with console
xcrun devicectl device process launch --device w-16e --console com.abundance.mvp

# Check crash logs
ls -lt ~/Library/Logs/CrashReporter/MobileDevice/w-16e/*.ips | head -5

# Check screenshots (synced via iCloud)
ls -lt screenshots/ | head -5
```

---

### backend-superpowers

**Purpose:** Unified Firebase and GCP operations with Gemini/AI pipeline routing.

**Replaces:** `firebase-superpowers` (deprecated), `gcp-superpowers` (deprecated)

**Domain Detection (First Match Wins):**

| Priority | Domain | Patterns | Action |
|----------|--------|----------|--------|
| 1 | gemini | Gemini, tool calling, thought signature, AI pipeline | Route to `gemini-integration` skill |
| 2-17 | firebase/gcp | Firestore, Functions, Logging, etc. | Use MCP tools directly |

**MCP Tool Inventory (59 tools):**

#### Firebase MCP (29 tools)

| Category | Tools | Key Operations |
|----------|-------|----------------|
| Firestore | 4 | `firestore_query_collection`, `firestore_get_documents` |
| Functions | 2 | `functions_list_functions`, `functions_get_logs` |
| Auth | 3 | `auth_get_users`, `auth_update_user` |
| FCM | 1 | `messaging_send_message` |
| Remote Config | 2 | `remoteconfig_get_template`, `remoteconfig_update_template` |
| RTDB | 2 | `realtimedatabase_get_data`, `realtimedatabase_set_data` |
| Security | 2 | `firebase_validate_security_rules`, `firebase_get_security_rules` |
| Project | 12 | `firebase_init`, `firebase_create_app`, `firebase_get_environment` |

#### Observability MCP (13 tools)

| Category | Tools | Key Operations |
|----------|-------|----------------|
| Logging | 6 | `list_log_entries`, `list_log_names`, `list_sinks` |
| Metrics | 2 | `list_metric_descriptors`, `list_time_series` |
| Alerts | 2 | `list_alert_policies`, `list_alerts` |
| Tracing | 2 | `list_traces`, `get_trace` |
| Errors | 1 | `list_group_stats` |

#### Storage MCP (17 tools)

| Category | Tools | Key Operations |
|----------|-------|----------------|
| Buckets | 6 | `list_buckets`, `create_bucket`, `view_iam_policy` |
| Objects | 8 | `list_objects`, `read_object_content`, `upload_object_safe` |
| Insights | 3 | `execute_insights_query`, `get_metadata_table_schema` |

---

## Common Workflows

### Debug iOS Issue

```
1. /project:ios-superpowers debug "<error message>"
2. Skill detects domain (build, concurrency, memory, etc.)
3. Routes to appropriate Axiom agent
4. Agent provides fix with Apple docs verification
```

### Deploy Cloud Function

```
1. /project:gcp-deploy ai-pipeline-orchestrator --staging
2. Runs local tests
3. Deploys to staging
4. Verifies deployment via MCP tools
5. Checks logs for errors
6. (Optional) --production --verify --notify for prod
```

### Device Testing Loop

```
1. /project:device-tester
2. Build and deploy to w-16e
3. Launch with console output
4. Test the feature
5. If crash → axiom:crash-analyzer
6. If slow → axiom:performance-profiler
7. If UI bug → check ./screenshots/
8. If backend error → check Cloud Functions logs
9. Fix and repeat
```

### Code Review

```
1. /project:ios-superpowers review
2. Launches parallel Axiom auditors:
   - concurrency-auditor
   - accessibility-auditor
   - swiftui-architecture-auditor
   - memory-auditor
   - security-privacy-scanner
3. Combines results with code review
```

---

## MCP Tool Quick Reference

### Check Cloud Functions Status

```
mcp__plugin_firebase_firebase__functions_list_functions
```

### Get Function Logs

```
mcp__plugin_firebase_firebase__functions_get_logs
  function_names: ["ai-pipeline-orchestrator"]
  min_severity: "WARNING"
  order: "desc"
```

### Query Firestore

```
mcp__plugin_firebase_firebase__firestore_query_collection
  collection_path: "users"
  filters: [{"field": "status", "op": "EQUAL", "compare_value": {"string_value": "active"}}]
```

### Send FCM Notification

```
mcp__plugin_firebase_firebase__messaging_send_message
  title: "Deployment Complete"
  body: "Function deployed successfully"
  topic: "dev-notifications"
```

### Check Error Reporting

```
mcp__observability__list_group_stats
  projectName: "projects/abundance-mvp"
  timeRangePeriod: "PERIOD_1_HOUR"
```

### Query Cloud Logging

```
mcp__observability__list_log_entries
  resourceNames: ["projects/abundance-mvp"]
  filter: "severity>=ERROR"
  orderBy: "timestamp desc"
```

---

## File Locations

| Purpose | Location |
|---------|----------|
| Skills | `.claude/skills/` |
| Commands | `.claude/commands/` |
| Hooks | `.claude/hooks/` |
| Device screenshots | `./screenshots/` (iCloud symlink) |
| Plans | `docs/plans/` |
| Specs | `docs/specs/` |
| Issues | `docs/issues/` |

---

### gemini-integration

**Purpose:** Gemini 3 Pro tool calling patterns for AI pipeline.

**Routed From:** `backend-superpowers` (auto-detected via Gemini patterns)

**Key Concepts:**

| Concept | Description |
|---------|-------------|
| Thought Signatures | **MANDATORY** for Gemini 3 - encrypted reasoning state |
| Function Declarations | Tool definitions with parameters schema |
| Tool Calling Loop | Send prompt → get function call → execute → return result |

**Thought Signature Handling:**

| Scenario | Signature Location | Requirement |
|----------|-------------------|-------------|
| Single function call | On `functionCall` part | Must return |
| Parallel calls | Only on **first** part | Must preserve order |
| Sequential calls | Each call has own | Must return all |

**Common Error:**
```
400 Bad Request: Function call is missing a thought_signature
```
**Fix:** Preserve complete model response parts in conversation history.

**Reference Implementation:** `functions/src/ai-pipeline/gemini/`

**Documentation:**
- Function Calling: https://ai.google.dev/gemini-api/docs/function-calling
- Thought Signatures: https://ai.google.dev/gemini-api/docs/thought-signatures

---

## Deprecated Skills

| Skill | Replacement | Removal Date |
|-------|-------------|--------------|
| `firebase-superpowers` | `backend-superpowers` | 2026-02-17 |
| `gcp-superpowers` | `backend-superpowers` | 2026-02-17 |
| `verified-stage-development` | (removed) | 2026-01-17 |

---

## Related Documentation

- **Full MCP Plan:** `docs/plans/2026-01-17-mcp-skill-consolidation-plan.md`
- **iOS Superpowers Details:** `.claude/skills/ios-superpowers/SKILL.md`
- **Backend Superpowers Details:** `.claude/skills/backend-superpowers/SKILL.md`
- **Device Tester Details:** `.claude/skills/device-tester.md`
- **GCP Deploy Command:** `.claude/commands/gcp-deploy.md`
