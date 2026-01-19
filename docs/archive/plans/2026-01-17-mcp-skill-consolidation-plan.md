# MCP Skill Consolidation Plan

**Created:** 2026-01-17
**Status:** Draft
**Author:** Claude (Opus 4.5)

## Executive Summary

This plan consolidates Firebase and GCP skills to leverage ALL available MCP capabilities, while keeping iOS skills focused on their Axiom-powered workflows.

### Key Decisions

| Skill | Decision | Rationale |
|-------|----------|-----------|
| `firebase-superpowers` | **DEPRECATE** | Merge into backend-superpowers |
| `gcp-superpowers` | **DEPRECATE** | Merge into backend-superpowers |
| `ios-superpowers` | **KEEP (minor update)** | Add backend verification step |
| `device-tester` | **KEEP (minor update)** | Add Cloud Functions log checking |
| `gcp-deploy` | **ENHANCE** | Full MCP integration |
| `gemini-integration` | **KEEP** | Domain-specific, no changes needed |

---

## Part 1: Current MCP Capabilities Audit

### Firebase MCP Tools (Complete Inventory)

| Tool | Category | Current Skill Coverage |
|------|----------|----------------------|
| `firebase_login`, `firebase_logout` | Auth | ✅ firebase-superpowers |
| `firebase_validate_security_rules` | Security | ✅ firebase-superpowers |
| `firebase_get_project` | Project | ✅ firebase-superpowers |
| `firebase_list_apps` | Project | ✅ firebase-superpowers |
| `firebase_list_projects` | Project | ❌ MISSING |
| `firebase_get_sdk_config` | Project | ❌ MISSING |
| `firebase_create_project` | Project | ❌ MISSING |
| `firebase_create_app` | Project | ❌ MISSING |
| `firebase_create_android_sha` | Project | ❌ MISSING |
| `firebase_get_environment` | Environment | ✅ firebase-superpowers |
| `firebase_update_environment` | Environment | ❌ MISSING |
| `firebase_init` | Setup | ❌ MISSING |
| `firebase_get_security_rules` | Security | ✅ firebase-superpowers |
| `firebase_read_resources` | Resources | ❌ MISSING |
| `firestore_delete_document` | Firestore | ✅ firebase-superpowers |
| `firestore_get_documents` | Firestore | ✅ firebase-superpowers |
| `firestore_list_collections` | Firestore | ✅ firebase-superpowers |
| `firestore_query_collection` | Firestore | ✅ firebase-superpowers |
| `storage_get_object_download_url` | Storage | ✅ firebase-superpowers |
| `auth_get_users` | Auth | ✅ firebase-superpowers |
| `auth_update_user` | Auth | ✅ firebase-superpowers |
| `auth_set_sms_region_policy` | Auth | ❌ MISSING |
| `messaging_send_message` | FCM | ❌ MISSING |
| `functions_get_logs` | Functions | ✅ firebase-superpowers |
| `functions_list_functions` | Functions | ✅ firebase-superpowers |
| `remoteconfig_get_template` | Remote Config | ❌ MISSING |
| `remoteconfig_update_template` | Remote Config | ❌ MISSING |
| `realtimedatabase_get_data` | RTDB | ❌ MISSING |
| `realtimedatabase_set_data` | RTDB | ❌ MISSING |

**Coverage:** 15/29 tools (52%) - Missing critical features like FCM, Remote Config, RTDB

### GCloud MCP Tools

| Tool | Category | Current Skill Coverage |
|------|----------|----------------------|
| `mcp__gcloud__run_gcloud_command` | General | ✅ gcp-superpowers |

### Observability MCP Tools

| Tool | Category | Current Skill Coverage |
|------|----------|----------------------|
| `list_log_entries` | Logging | ✅ gcp-superpowers |
| `list_log_names` | Logging | ✅ gcp-superpowers |
| `list_buckets` | Logging | ✅ gcp-superpowers |
| `list_views` | Logging | ❌ MISSING |
| `list_sinks` | Logging | ✅ gcp-superpowers |
| `list_log_scopes` | Logging | ❌ MISSING |
| `list_metric_descriptors` | Metrics | ✅ gcp-superpowers |
| `list_time_series` | Metrics | ✅ gcp-superpowers |
| `list_alert_policies` | Alerts | ✅ gcp-superpowers |
| `list_alerts` | Alerts | ✅ gcp-superpowers |
| `list_traces` | Tracing | ✅ gcp-superpowers |
| `get_trace` | Tracing | ✅ gcp-superpowers |
| `list_group_stats` | Errors | ❌ MISSING |

**Coverage:** 10/13 tools (77%)

### Storage MCP Tools (GCS)

| Tool | Category | Current Skill Coverage |
|------|----------|----------------------|
| `list_buckets` | Buckets | ✅ gcp-superpowers |
| `get_bucket_location` | Buckets | ❌ MISSING |
| `get_bucket_metadata` | Buckets | ❌ MISSING |
| `view_iam_policy` | IAM | ❌ MISSING |
| `check_iam_permissions` | IAM | ❌ MISSING |
| `create_bucket` | Buckets | ❌ MISSING |
| `list_objects` | Objects | ✅ gcp-superpowers |
| `read_object_content` | Objects | ✅ gcp-superpowers |
| `read_object_metadata` | Objects | ❌ MISSING |
| `download_object` | Objects | ✅ gcp-superpowers |
| `delete_object` | Objects | ✅ gcp-superpowers |
| `write_object_safe` | Objects | ❌ MISSING |
| `upload_object_safe` | Objects | ✅ gcp-superpowers |
| `copy_object_safe` | Objects | ❌ MISSING |
| `get_metadata_table_schema` | Insights | ❌ MISSING |
| `execute_insights_query` | Insights | ❌ MISSING |
| `list_insights_configs` | Insights | ❌ MISSING |

**Coverage:** 7/17 tools (41%)

### Apple Developer Docs MCP Tools

| Tool | Category | Notes |
|------|----------|-------|
| `searchAppleDocumentation` | Search | Used by Axiom skills |
| `fetchAppleDocumentation` | Fetch | Used by Axiom skills |

---

## Part 2: Recommended Architecture

### New Unified Backend Skill: `backend-superpowers`

Replace both `firebase-superpowers` and `gcp-superpowers` with a single router skill.

```
┌─────────────────────────────────────────────────────────────────┐
│                     backend-superpowers                          │
├─────────────────────────────────────────────────────────────────┤
│  Context Detection → Domain Routing                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │  Firebase   │  │ Observability│  │   Storage   │              │
│  │   Domain    │  │    Domain   │  │   Domain    │              │
│  ├─────────────┤  ├─────────────┤  ├─────────────┤              │
│  │ Firestore   │  │ Logging     │  │ GCS Buckets │              │
│  │ Functions   │  │ Metrics     │  │ Objects     │              │
│  │ Auth        │  │ Tracing     │  │ IAM         │              │
│  │ FCM         │  │ Alerts      │  │ Insights    │              │
│  │ Remote Cfg  │  │ Errors      │  └─────────────┘              │
│  │ RTDB        │  └─────────────┘                               │
│  │ Security    │                                                │
│  └─────────────┘                                                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Domain Detection Patterns

| Domain | Trigger Patterns | MCP Tools |
|--------|------------------|-----------|
| `firebase-firestore` | Firestore, document, collection, query | `firestore_*` |
| `firebase-functions` | Cloud Function, deploy, logs | `functions_*` |
| `firebase-auth` | user, auth, login, permissions | `auth_*` |
| `firebase-fcm` | notification, push, message, FCM | `messaging_*` |
| `firebase-remote-config` | feature flag, remote config, A/B | `remoteconfig_*` |
| `firebase-rtdb` | realtime database, RTDB, sync | `realtimedatabase_*` |
| `firebase-security` | security rules, rules validation | `firebase_*_security_*` |
| `firebase-storage` | Firebase Storage, download URL | `storage_get_object_download_url` |
| `gcp-logging` | logs, Cloud Logging, log entries | `mcp__observability__list_log_*` |
| `gcp-metrics` | metrics, monitoring, time series | `mcp__observability__list_metric_*`, `list_time_series` |
| `gcp-tracing` | trace, latency, spans | `mcp__observability__*_trace*` |
| `gcp-alerts` | alert, alert policy, incident | `mcp__observability__list_alert*` |
| `gcp-errors` | error reporting, stack trace | `mcp__observability__list_group_stats` |
| `gcp-storage` | GCS, bucket, Cloud Storage | `mcp__storage__*` |
| `gcp-general` | gcloud, GCP, Google Cloud | `mcp__gcloud__run_gcloud_command` |

---

## Part 3: Skill Updates

### 3.1 New Skill: `backend-superpowers`

**Location:** `.claude/skills/backend-superpowers/SKILL.md`

**Content:** (See implementation section)

### 3.2 Update: `ios-superpowers`

**Change:** Add optional backend verification after deployment

```diff
## 4. Verification Checklist

After every execution, verify:

- [ ] No deprecated APIs introduced (check via `axiom-apple-docs-research`)
- [ ] Swift 6 concurrency satisfied (actor isolation, Sendable)
- [ ] API signatures match Apple documentation
- [ ] Tests pass (if applicable): `swift test`
+ - [ ] If deploying backend changes: verify Cloud Functions via `backend-superpowers`
```

### 3.3 Update: `device-tester`

**Change:** Add Cloud Functions log checking for backend issues

```diff
### If app communicates with backend, check Cloud Functions logs:

+ #### Check Cloud Functions Logs
+ ```
+ Use mcp__plugin_firebase_firebase__functions_get_logs with:
+ - function_names: ["ai-pipeline-orchestrator", "gemini-service"]
+ - min_severity: "WARNING"
+ - Order: "desc"
+ - page_size: 20
+ ```
```

### 3.4 Update: `gcp-deploy`

**Changes:**
1. Add FCM notification for deployment status
2. Add Remote Config toggle for feature flags
3. Add observability verification

---

## Part 4: Implementation Steps

### Phase 1: Create backend-superpowers (New Skill)

```bash
mkdir -p .claude/skills/backend-superpowers
# Create SKILL.md with complete MCP tool inventory
```

### Phase 2: Update Existing Skills

1. Update `ios-superpowers` with backend verification step
2. Update `device-tester` with Cloud Functions log checking
3. Update `gcp-deploy` with full MCP integration

### Phase 3: Deprecate Old Skills

```bash
# Add deprecation notice to firebase-superpowers
# Add deprecation notice to gcp-superpowers
# After 30 days, delete files
```

### Phase 4: Update Documentation

1. Update `CLAUDE.md` to reference `backend-superpowers`
2. Update `.claude/README.md` with new skill structure

---

## Part 5: Detailed Skill Implementations

### 5.1 backend-superpowers SKILL.md

```markdown
---
name: backend-superpowers
description: Unified Firebase and GCP operations using official MCP servers. Replaces firebase-superpowers and gcp-superpowers.
---

# Backend Superpowers

Unified skill for all Firebase and GCP backend operations.

## Domain Detection

| Domain | Patterns | Primary MCP |
|--------|----------|-------------|
| firestore | document, collection, query, Firestore | Firebase |
| functions | Cloud Function, deploy, logs | Firebase |
| auth | user, authentication, permissions | Firebase |
| fcm | notification, push message | Firebase |
| remote-config | feature flag, A/B test | Firebase |
| rtdb | realtime database, sync | Firebase |
| security-rules | rules, validation | Firebase |
| logging | logs, Cloud Logging | Observability |
| metrics | monitoring, metrics | Observability |
| tracing | trace, latency | Observability |
| alerts | alert, incident | Observability |
| errors | error reporting, stack trace | Observability |
| storage | GCS, bucket, object | Storage |
| general-gcp | gcloud, GCP resource | GCloud |

## Firebase Operations

### Firestore
| Operation | Tool |
|-----------|------|
| List collections | `firestore_list_collections` |
| Query documents | `firestore_query_collection` |
| Get documents | `firestore_get_documents` |
| Delete document | `firestore_delete_document` |

### Cloud Functions
| Operation | Tool |
|-----------|------|
| List functions | `functions_list_functions` |
| Get logs | `functions_get_logs` |

### Authentication
| Operation | Tool |
|-----------|------|
| Get users | `auth_get_users` |
| Update user | `auth_update_user` |
| Set SMS policy | `auth_set_sms_region_policy` |

### FCM (Cloud Messaging)
| Operation | Tool |
|-----------|------|
| Send notification | `messaging_send_message` |

### Remote Config
| Operation | Tool |
|-----------|------|
| Get template | `remoteconfig_get_template` |
| Update template | `remoteconfig_update_template` |

### Realtime Database
| Operation | Tool |
|-----------|------|
| Get data | `realtimedatabase_get_data` |
| Set data | `realtimedatabase_set_data` |

### Security Rules
| Operation | Tool |
|-----------|------|
| Get rules | `firebase_get_security_rules` |
| Validate rules | `firebase_validate_security_rules` |

### Project Management
| Operation | Tool |
|-----------|------|
| Get project | `firebase_get_project` |
| List projects | `firebase_list_projects` |
| List apps | `firebase_list_apps` |
| Get SDK config | `firebase_get_sdk_config` |
| Create project | `firebase_create_project` |
| Create app | `firebase_create_app` |
| Get environment | `firebase_get_environment` |
| Update environment | `firebase_update_environment` |
| Initialize | `firebase_init` |
| Read resources | `firebase_read_resources` |

## GCP Operations

### Cloud Logging
| Operation | Tool |
|-----------|------|
| List log entries | `list_log_entries` |
| List log names | `list_log_names` |
| List buckets | `list_buckets` |
| List views | `list_views` |
| List sinks | `list_sinks` |
| List log scopes | `list_log_scopes` |

### Cloud Monitoring
| Operation | Tool |
|-----------|------|
| List metric descriptors | `list_metric_descriptors` |
| Get time series | `list_time_series` |
| List alert policies | `list_alert_policies` |
| List alerts | `list_alerts` |

### Cloud Trace
| Operation | Tool |
|-----------|------|
| List traces | `list_traces` |
| Get trace | `get_trace` |

### Error Reporting
| Operation | Tool |
|-----------|------|
| List error groups | `list_group_stats` |

### Cloud Storage (GCS)
| Operation | Tool |
|-----------|------|
| List buckets | `list_buckets` |
| Get bucket location | `get_bucket_location` |
| Get bucket metadata | `get_bucket_metadata` |
| View IAM policy | `view_iam_policy` |
| Check IAM permissions | `check_iam_permissions` |
| Create bucket | `create_bucket` |
| List objects | `list_objects` |
| Read object content | `read_object_content` |
| Read object metadata | `read_object_metadata` |
| Download object | `download_object` |
| Delete object | `delete_object` |
| Write object | `write_object_safe` |
| Upload object | `upload_object_safe` |
| Copy object | `copy_object_safe` |
| Get insights schema | `get_metadata_table_schema` |
| Execute insights query | `execute_insights_query` |
| List insights configs | `list_insights_configs` |

### General GCP
| Operation | Tool |
|-----------|------|
| Run gcloud command | `run_gcloud_command` |

## Common Workflows

### Deploy Cloud Function with Verification
1. Deploy: `firebase deploy --only functions:<name>`
2. Verify status: `functions_list_functions`
3. Check logs: `functions_get_logs`
4. Monitor errors: `list_group_stats`
5. Notify team: `messaging_send_message` (optional)

### Debug Production Issue
1. Check logs: `list_log_entries` with severity filter
2. Check traces: `list_traces` for latency issues
3. Check errors: `list_group_stats` for stack traces
4. Check metrics: `list_time_series` for resource usage
5. Check alerts: `list_alerts` for triggered policies

### Manage Feature Flags
1. Get current: `remoteconfig_get_template`
2. Update template: `remoteconfig_update_template`
3. Verify: `remoteconfig_get_template` with version

## Error Handling

### Not logged in
→ Use `firebase_login` or run `firebase login` in terminal

### Wrong project
→ Use `firebase_update_environment` to set active project

### Permission denied
→ Check IAM: `view_iam_policy` or `check_iam_permissions`
```

### 5.2 Deprecation Notice for firebase-superpowers

```markdown
---
name: firebase-superpowers
description: DEPRECATED - Use backend-superpowers instead
deprecated: true
deprecated_by: backend-superpowers
---

# ⚠️ DEPRECATED

**This skill is deprecated.** Use `backend-superpowers` instead.

## Migration

Replace:
```
Skill(skill="firebase-superpowers")
```

With:
```
Skill(skill="backend-superpowers")
```

The new skill covers ALL Firebase and GCP operations in a unified interface.
```

### 5.3 Deprecation Notice for gcp-superpowers

```markdown
---
name: gcp-superpowers
description: DEPRECATED - Use backend-superpowers instead
deprecated: true
deprecated_by: backend-superpowers
---

# ⚠️ DEPRECATED

**This skill is deprecated.** Use `backend-superpowers` instead.

## Migration

Replace:
```
Skill(skill="gcp-superpowers")
```

With:
```
Skill(skill="backend-superpowers")
```

The new skill covers ALL Firebase and GCP operations in a unified interface.
```

---

## Part 6: Files to Create/Modify

### Create
- [ ] `.claude/skills/backend-superpowers/SKILL.md`

### Modify
- [ ] `.claude/skills/ios-superpowers/SKILL.md` (add backend verification)
- [ ] `.claude/skills/device-tester.md` (add Cloud Functions logs)
- [ ] `.claude/commands/gcp-deploy.md` (full MCP integration)
- [ ] `CLAUDE.md` (update skill references)

### Deprecate (add notice, then delete after 30 days)
- [ ] `.claude/skills/firebase-superpowers/SKILL.md`
- [ ] `.claude/skills/gcp-superpowers/SKILL.md`

---

## Part 7: Verification Checklist

After implementation:

- [ ] `backend-superpowers` skill loads correctly
- [ ] All 29 Firebase MCP tools documented
- [ ] All 13 Observability MCP tools documented
- [ ] All 17 Storage MCP tools documented
- [ ] `ios-superpowers` still routes correctly
- [ ] `device-tester` can check Cloud Functions logs
- [ ] `gcp-deploy` uses FCM for notifications
- [ ] Deprecation notices in place
- [ ] `CLAUDE.md` updated

---

## Appendix: Quick Reference

### When to Use Each Skill

| Task | Skill |
|------|-------|
| iOS/Swift development | `ios-superpowers` |
| Physical device testing | `device-tester` |
| Any Firebase operation | `backend-superpowers` |
| Any GCP operation | `backend-superpowers` |
| Deploy Cloud Functions | `gcp-deploy` or `backend-superpowers` |
| AI pipeline work | `gemini-integration` |
