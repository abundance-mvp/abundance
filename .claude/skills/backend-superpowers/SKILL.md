---
name: backend-superpowers
description: Unified Firebase and GCP operations using official MCP servers. Complete inventory of all backend MCP tools for Firestore, Functions, Auth, FCM, Remote Config, RTDB, Logging, Metrics, Tracing, and Storage.
---

# Backend Superpowers

Unified skill for all Firebase and GCP backend operations. Replaces `firebase-superpowers` and `gcp-superpowers`.

## When This Skill Activates

- Any Firebase operation (Firestore, Functions, Auth, FCM, Remote Config, RTDB)
- Any GCP operation (Logging, Metrics, Tracing, Storage, general gcloud)
- Backend deployment and verification
- Production debugging and monitoring

---

## Domain Detection

Match context against patterns. First match wins.

| Priority | Domain | Patterns | Action |
|----------|--------|----------|--------|
| 1 | gemini | Gemini, tool calling, thought signature, AI pipeline, function declarations | Route to `gemini-integration` skill |
| 2 | firestore | Firestore, document, collection, query | Firebase MCP |
| 3 | functions | Cloud Function, deploy function, function logs | Firebase MCP |
| 4 | auth | user auth, authentication, permissions, SMS policy | Firebase MCP |
| 5 | fcm | notification, push message, FCM, messaging | Firebase MCP |
| 6 | remote-config | feature flag, remote config, A/B test, rollout | Firebase MCP |
| 7 | rtdb | realtime database, RTDB, firebase sync | Firebase MCP |
| 8 | security-rules | security rules, rules validation, firestore.rules | Firebase MCP |
| 9 | firebase-storage | Firebase Storage, download URL, storage bucket | Firebase MCP |
| 10 | project | Firebase project, app config, SDK config, init | Firebase MCP |
| 11 | logging | Cloud Logging, log entries, logs | Observability MCP |
| 12 | metrics | monitoring, metrics, time series | Observability MCP |
| 13 | tracing | trace, latency, spans, distributed trace | Observability MCP |
| 14 | alerts | alert policy, incident, alert | Observability MCP |
| 15 | errors | error reporting, stack trace, crash | Observability MCP |
| 16 | gcs | GCS, bucket, Cloud Storage, object | Storage MCP |
| 17 | general | gcloud, GCP, Google Cloud | GCloud MCP |

### Gemini/AI Pipeline Routing

When context matches Gemini patterns, **invoke the `gemini-integration` skill** via Skill tool:

```
Skill(skill="gemini-integration")
```

The `gemini-integration` skill covers:
- Gemini 3 Pro tool calling patterns
- Thought signature handling (mandatory for Gemini 3)
- Function declaration schemas
- Prompt engineering for cataloging
- Error handling (400 errors, rate limits)

**Use backend-superpowers MCP tools for:**
- Deploying functions that use Gemini (`firebase deploy`)
- Checking function logs (`functions_get_logs`)
- Monitoring AI pipeline errors (`list_group_stats`)

**Use gemini-integration skill for:**
- Writing/modifying Gemini API code in `functions/src/ai-pipeline/gemini/`
- Debugging thought signature errors
- Creating new tool definitions
- Prompt engineering

---

## Firebase MCP Tools

### Firestore (`mcp__plugin_firebase_firebase__firestore_*`)

| Operation | Tool | Parameters |
|-----------|------|------------|
| List collections | `firestore_list_collections` | `database?`, `use_emulator?` |
| Query collection | `firestore_query_collection` | `collection_path`, `filters`, `limit?`, `order?` |
| Get documents | `firestore_get_documents` | `paths[]`, `database?` |
| Delete document | `firestore_delete_document` | `path`, `database?` |

**Query Filter Example:**
```json
{
  "collection_path": "users",
  "filters": [{
    "field": "status",
    "op": "EQUAL",
    "compare_value": {"string_value": "active"}
  }],
  "limit": 10
}
```

### Cloud Functions (`mcp__plugin_firebase_firebase__functions_*`)

| Operation | Tool | Parameters |
|-----------|------|------------|
| List functions | `functions_list_functions` | (none) |
| Get logs | `functions_get_logs` | `function_names[]?`, `min_severity?`, `start_time?`, `end_time?`, `page_size?` |

**Get Logs Example:**
```json
{
  "function_names": ["ai-pipeline-orchestrator"],
  "min_severity": "WARNING",
  "order": "desc",
  "page_size": 50
}
```

### Authentication (`mcp__plugin_firebase_firebase__auth_*`)

| Operation | Tool | Parameters |
|-----------|------|------------|
| Get users | `auth_get_users` | `uids[]?`, `emails[]?`, `phone_numbers[]?`, `limit?` |
| Update user | `auth_update_user` | `uid`, `disabled?`, `claim?` |
| Set SMS region policy | `auth_set_sms_region_policy` | `policy_type` (ALLOW/DENY), `country_codes[]` |

### FCM - Cloud Messaging (`mcp__plugin_firebase_firebase__messaging_*`)

| Operation | Tool | Parameters |
|-----------|------|------------|
| Send message | `messaging_send_message` | `title?`, `body?`, `registration_token?` OR `topic?`, `image?` |

**Send Notification Example:**
```json
{
  "title": "Deployment Complete",
  "body": "ai-pipeline-orchestrator deployed successfully",
  "topic": "dev-notifications"
}
```

### Remote Config (`mcp__plugin_firebase_firebase__remoteconfig_*`)

| Operation | Tool | Parameters |
|-----------|------|------------|
| Get template | `remoteconfig_get_template` | `version_number?` |
| Update template | `remoteconfig_update_template` | `template?`, `version_number?`, `force?` |

### Realtime Database (`mcp__plugin_firebase_firebase__realtimedatabase_*`)

| Operation | Tool | Parameters |
|-----------|------|------------|
| Get data | `realtimedatabase_get_data` | `path`, `databaseUrl?` |
| Set data | `realtimedatabase_set_data` | `path`, `data` (JSON string), `databaseUrl?` |

### Security Rules (`mcp__plugin_firebase_firebase__firebase_*`)

| Operation | Tool | Parameters |
|-----------|------|------------|
| Get rules | `firebase_get_security_rules` | `type` (firestore/rtdb/storage) |
| Validate rules | `firebase_validate_security_rules` | `type`, `source?` OR `source_file?` |

### Firebase Storage

| Operation | Tool | Parameters |
|-----------|------|------------|
| Get download URL | `storage_get_object_download_url` | `object_path`, `bucket?` |

### Project Management

| Operation | Tool | Parameters |
|-----------|------|------------|
| Get project | `firebase_get_project` | (none) |
| List projects | `firebase_list_projects` | `page_size?`, `page_token?` |
| List apps | `firebase_list_apps` | `platform?` (ios/android/web/all) |
| Get SDK config | `firebase_get_sdk_config` | `platform?` OR `app_id?` |
| Create project | `firebase_create_project` | `project_id`, `display_name?` |
| Create app | `firebase_create_app` | `platform`, `display_name?`, `ios_config?`, `android_config?` |
| Add Android SHA | `firebase_create_android_sha` | `app_id`, `sha_hash` |
| Get environment | `firebase_get_environment` | (none) |
| Update environment | `firebase_update_environment` | `project_dir?`, `active_project?`, `active_user_account?` |
| Initialize | `firebase_init` | `features` (object with service configs) |
| Read resources | `firebase_read_resources` | `uris[]?` |
| Login | `firebase_login` | `authCode?` |
| Logout | `firebase_logout` | `email?` |

---

## Observability MCP Tools

### Cloud Logging (`mcp__observability__*`)

| Operation | Tool | Parameters |
|-----------|------|------------|
| List log entries | `list_log_entries` | `resourceNames[]`, `filter?`, `orderBy?`, `pageSize?` |
| List log names | `list_log_names` | `parent`, `pageSize?` |
| List buckets | `list_buckets` | `parent`, `pageSize?` |
| List views | `list_views` | `parent`, `pageSize?` |
| List sinks | `list_sinks` | `parent`, `pageSize?` |
| List log scopes | `list_log_scopes` | `parent`, `pageSize?` |

**Log Query Example:**
```json
{
  "resourceNames": ["projects/abundance-mvp"],
  "filter": "severity=\"ERROR\" AND timestamp > \"2026-01-17T00:00:00Z\"",
  "orderBy": "timestamp desc",
  "pageSize": 50
}
```

### Cloud Monitoring

| Operation | Tool | Parameters |
|-----------|------|------------|
| List metric descriptors | `list_metric_descriptors` | `name`, `filter?`, `pageSize?` |
| Get time series | `list_time_series` | `name`, `filter`, `interval`, `aggregation?` |
| List alert policies | `list_alert_policies` | `name`, `filter?`, `orderBy?` |
| List alerts | `list_alerts` | `parent`, `filter?`, `orderBy?` |

**Time Series Example:**
```json
{
  "name": "projects/abundance-mvp",
  "filter": "metric.type = \"cloudfunctions.googleapis.com/function/execution_count\"",
  "interval": {
    "startTime": "2026-01-17T00:00:00Z",
    "endTime": "2026-01-17T23:59:59Z"
  }
}
```

### Cloud Trace

| Operation | Tool | Parameters |
|-----------|------|------------|
| List traces | `list_traces` | `projectId`, `filter?`, `startTime?`, `endTime?`, `orderBy?` |
| Get trace | `get_trace` | `projectId`, `traceId` |

### Error Reporting

| Operation | Tool | Parameters |
|-----------|------|------------|
| List error groups | `list_group_stats` | `projectName`, `timeRangePeriod?`, `order?` |

**Error Groups Example:**
```json
{
  "projectName": "projects/abundance-mvp",
  "timeRangePeriod": "PERIOD_1_DAY",
  "order": "COUNT_DESC"
}
```

---

## Storage MCP Tools (GCS)

### Bucket Operations (`mcp__storage__*`)

| Operation | Tool | Parameters |
|-----------|------|------------|
| List buckets | `list_buckets` | `project_id?` |
| Get bucket location | `get_bucket_location` | `bucket_name` |
| Get bucket metadata | `get_bucket_metadata` | `bucket_name` |
| View IAM policy | `view_iam_policy` | `bucket_name` |
| Check IAM permissions | `check_iam_permissions` | `bucket_name`, `permissions[]` |
| Create bucket | `create_bucket` | `project_id`, `bucket_name`, `location?`, `storage_class?` |

### Object Operations

| Operation | Tool | Parameters |
|-----------|------|------------|
| List objects | `list_objects` | `bucket_name`, `prefix?`, `delimiter?`, `max_results?` |
| Read object content | `read_object_content` | `bucket_name`, `object_name` |
| Read object metadata | `read_object_metadata` | `bucket_name`, `object_name` |
| Download object | `download_object` | `bucket_name`, `object_name`, `file_path` |
| Delete object | `delete_object` | `bucket_name`, `object_name` |
| Write object | `write_object_safe` | `bucket_name`, `object_name`, `content` (base64) |
| Upload object | `upload_object_safe` | `bucket_name`, `file_path`, `object_name?` |
| Copy object | `copy_object_safe` | `source_bucket_name`, `source_object_name`, `destination_bucket_name`, `destination_object_name` |

### Storage Insights

| Operation | Tool | Parameters |
|-----------|------|------------|
| Get metadata schema | `get_metadata_table_schema` | `datasetConfigName`, `datasetConfigLocation`, `projectId?` |
| Execute insights query | `execute_insights_query` | `config`, `query` |
| List insights configs | `list_insights_configs` | `projectId?` |

---

## GCloud MCP Tool

| Operation | Tool | Parameters |
|-----------|------|------------|
| Run command | `run_gcloud_command` | `args[]` |

**Command Examples:**
```json
// List compute instances
{"args": ["compute", "instances", "list"]}

// Describe project
{"args": ["projects", "describe", "abundance-mvp"]}

// List Cloud Run services
{"args": ["run", "services", "list"]}

// Get IAM policy
{"args": ["projects", "get-iam-policy", "abundance-mvp"]}
```

**Restrictions:** No command chaining, pipes, redirects, or SSH.

---

## Common Workflows

### Deploy Cloud Function with Verification

```
1. Run local tests: npm test (in functions/)
2. Deploy: firebase deploy --only functions:<name>
3. Verify deployed: functions_list_functions
4. Check logs: functions_get_logs with min_severity="WARNING"
5. Check errors: list_group_stats for new stack traces
6. (Optional) Notify: messaging_send_message to topic
```

### Debug Production Issue

```
1. Check function logs: functions_get_logs
2. Check Cloud Logging: list_log_entries with severity filter
3. Check traces: list_traces for latency issues
4. Check error groups: list_group_stats for stack traces
5. Check metrics: list_time_series for resource spikes
6. Check alerts: list_alerts for triggered policies
```

### Manage Feature Flags

```
1. Get current: remoteconfig_get_template
2. Modify template object
3. Update: remoteconfig_update_template
4. Verify: remoteconfig_get_template to confirm
```

### Validate Security Rules Before Deploy

```
1. Get current: firebase_get_security_rules type="firestore"
2. Validate new: firebase_validate_security_rules type="firestore" source="..."
3. If valid, deploy: firebase deploy --only firestore:rules
```

### Query Firestore for Debug

```
1. List collections: firestore_list_collections
2. Query with filters: firestore_query_collection
3. Get specific docs: firestore_get_documents with paths
```

---

## Error Handling

### Not logged in
```
ERROR: Not authenticated with Firebase

Fix: Use firebase_login or run `firebase login` in terminal
```

### Wrong project
```
ERROR: Operation on wrong project

Fix: Use firebase_update_environment to set active_project
Or: firebase_get_environment to check current project
```

### Permission denied
```
ERROR: Permission denied for operation

Fix:
1. Check IAM: view_iam_policy on bucket or run_gcloud_command for project IAM
2. Verify: check_iam_permissions for specific permissions
3. Request access from project admin
```

### Rules validation failed
```
ERROR: Security rules syntax error

Fix: Review error message, check rules syntax
Use firebase_validate_security_rules before deploying
```

---

## Verification (`superpowers:verification-before-completion`)

**REQUIRED:** After any operation that modifies code or deploys changes, run the gate function before claiming success.

### Gate Function

```
1. IDENTIFY: What command proves the operation succeeded?
2. RUN: Execute the FULL command (fresh, not cached):
   - TypeScript compile: `cd functions && npx tsc --noEmit`
   - Tests: `cd functions && npm test`
   - Deploy verify: `functions_list_functions` + `functions_get_logs`
3. READ: Full output — exit code, error count, deployment status
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence. Do NOT claim success.
   - If YES: State claim WITH evidence (exit code, test results, deploy log)
5. ONLY THEN: Claim completion

Skip any step = unverified claim. Do not proceed.
```

### Dispatched Agent Verification

When dispatching Task agents (including via `troubleshoot` multi-domain), include this instruction in every agent prompt:

```
VERIFICATION REQUIRED: Before claiming work is complete, you MUST run build/test
commands, read full output, and report results WITH evidence (exit codes, test
counts). No 'should work' or 'looks good' claims. Evidence before claims, always.
```

### Common Verification Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Deploy succeeded | `functions_list_functions` showing new version | `firebase deploy` exiting 0 (could be partial) |
| No errors | `functions_get_logs` with min_severity WARNING showing 0 entries | Absence of crash |
| Tests pass | `npm test` output: 0 failures, N passed | "Should pass now" |
| Rules valid | `firebase_validate_security_rules` returning valid | Reading the rules file |

---

## Post-Operation: Documentation Check

After backend operations that modify code:

1. Run: `uv run scripts/check_doc_freshness.py --quiet`
2. If exit code 1:
   - Print: "Documentation may need updating. Run `/doc-superpowers review-pr backend`"

---

## When NOT to Use This Skill

- iOS/Swift development → use `ios-superpowers`
- Physical device testing → use `device-tester`

**Note:** AI pipeline/Gemini work is now routed through this skill - it auto-detects Gemini patterns and invokes `gemini-integration` skill when needed.

---

## Project-Specific Configuration

**Project ID:** `abundance-mvp`
**Default Region:** `us-central1`

**Cloud Functions:**
- `ai-pipeline-orchestrator` - Main AI pipeline
- `gemini-service` - Gemini API integration

**Firestore Collections:**
- `users` - User profiles
- `items` - Cataloged items
- `captures` - Photo captures

**GCS Buckets:**
- `abundance-mvp.appspot.com` - Default Firebase Storage
- `abundance-mvp-captures` - Raw capture images
