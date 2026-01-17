---
name: gcp-deploy
description: Deploy Cloud Functions with full MCP verification, logging, and optional notifications
---

# GCP Deploy Command

Deploy Cloud Functions to staging or production with comprehensive MCP-powered verification.

## Usage

```
/gcp-deploy [function-name]
/gcp-deploy [function-name] --staging
/gcp-deploy [function-name] --production --verify
/gcp-deploy [function-name] --notify
```

## Examples

```
/gcp-deploy ai-pipeline-orchestrator --staging
/gcp-deploy ai-pipeline-orchestrator --production --verify --notify
/gcp-deploy gemini-service --staging
```

## MCP Tools Used

This command leverages all available backend MCP tools:

| Phase | MCP Tool | Purpose |
|-------|----------|---------|
| Pre-deploy | `functions_list_functions` | Check current deployment state |
| Pre-deploy | `firebase_get_environment` | Verify correct project |
| Deploy | Firebase CLI | `firebase deploy --only functions` |
| Verify | `functions_list_functions` | Confirm deployment success |
| Verify | `functions_get_logs` | Check for startup errors |
| Monitor | `list_log_entries` | Deep log analysis |
| Monitor | `list_group_stats` | Check error reporting |
| Monitor | `list_time_series` | Check metrics |
| Notify | `messaging_send_message` | FCM notification (optional) |

---

## Deployment Workflow

### 1. Pre-Deploy Checks

```
# Verify environment
mcp__plugin_firebase_firebase__firebase_get_environment

# List current functions
mcp__plugin_firebase_firebase__functions_list_functions

# Run local tests
cd functions && npm test
```

### 2. Deploy to Staging (default)

```bash
firebase deploy --only functions:[name] --project abundance-mvp-staging
```

### 3. Verify Staging

```
# Check function deployed
mcp__plugin_firebase_firebase__functions_list_functions

# Check for errors (last 10 minutes)
mcp__plugin_firebase_firebase__functions_get_logs
  function_names: ["[name]"]
  min_severity: "WARNING"
  order: "desc"
  page_size: 20

# Check error reporting
mcp__observability__list_group_stats
  projectName: "projects/abundance-mvp-staging"
  timeRangePeriod: "PERIOD_1_HOUR"
```

### 4. Deploy to Production (with --production)

```bash
firebase deploy --only functions:[name] --project abundance-mvp
```

### 5. Verify Production (with --verify)

```
# Check function status
mcp__plugin_firebase_firebase__functions_list_functions

# Check logs for errors
mcp__plugin_firebase_firebase__functions_get_logs
  function_names: ["[name]"]
  min_severity: "ERROR"
  order: "desc"
  page_size: 50

# Check error reporting for new errors
mcp__observability__list_group_stats
  projectName: "projects/abundance-mvp"
  timeRangePeriod: "PERIOD_1_HOUR"
  order: "LAST_SEEN_DESC"

# Check execution metrics
mcp__observability__list_time_series
  name: "projects/abundance-mvp"
  filter: "metric.type = \"cloudfunctions.googleapis.com/function/execution_count\" AND resource.labels.function_name = \"[name]\""
  interval:
    startTime: "[1 hour ago]"
    endTime: "[now]"

# Check latency metrics
mcp__observability__list_time_series
  name: "projects/abundance-mvp"
  filter: "metric.type = \"cloudfunctions.googleapis.com/function/execution_times\" AND resource.labels.function_name = \"[name]\""
  interval:
    startTime: "[1 hour ago]"
    endTime: "[now]"
```

### 6. Send Notification (with --notify)

```
# Send FCM notification to dev team
mcp__plugin_firebase_firebase__messaging_send_message
  title: "Deployment Complete"
  body: "[name] deployed to production successfully"
  topic: "dev-notifications"
```

---

## Flags

| Flag | Description |
|------|-------------|
| `--staging` | Deploy to staging only (default) |
| `--production` | Deploy to production |
| `--verify` | Run full verification after deploy |
| `--notify` | Send FCM notification on success |
| `--dry-run` | Show commands without executing |
| `--skip-tests` | Skip local tests (not recommended) |

---

## Advanced: Feature Flag Toggle

If deploying a feature behind a flag, update Remote Config:

```
# Get current template
mcp__plugin_firebase_firebase__remoteconfig_get_template

# Update with new flag
mcp__plugin_firebase_firebase__remoteconfig_update_template
  template: {
    "parameters": {
      "feature_[name]_enabled": {
        "defaultValue": { "value": "false" },
        "conditionalValues": {
          "beta_users": { "value": "true" }
        }
      }
    }
  }
```

---

## Troubleshooting

### Deployment Failed

```
# Check recent logs
mcp__plugin_firebase_firebase__functions_get_logs
  min_severity: "ERROR"
  page_size: 50

# Check if function exists
mcp__plugin_firebase_firebase__functions_list_functions
```

### Function Not Responding

```
# Check Cloud Logging for more detail
mcp__observability__list_log_entries
  resourceNames: ["projects/abundance-mvp"]
  filter: "resource.type=\"cloud_function\" AND resource.labels.function_name=\"[name]\" AND severity>=ERROR"
  orderBy: "timestamp desc"
  pageSize: 50
```

### High Latency

```
# Check execution times
mcp__observability__list_time_series
  name: "projects/abundance-mvp"
  filter: "metric.type = \"cloudfunctions.googleapis.com/function/execution_times\""

# Check for cold starts
mcp__observability__list_log_entries
  filter: "textPayload:\"Cold start\""
```

### Permission Errors

```
# Check project environment
mcp__plugin_firebase_firebase__firebase_get_environment

# Verify you're logged in
# If not: firebase login
```

---

## Rollback

If deployment causes issues:

```bash
# List previous versions
firebase functions:log --only [name]

# Rollback (redeploy previous version from git)
git checkout HEAD~1 -- functions/src/[name]/
firebase deploy --only functions:[name]
```

---

## Prerequisites

- Firebase CLI authenticated (`firebase login`)
- Project configured in `firebase.json`
- Secrets in Secret Manager (if applicable)
- Tests passing locally (`npm test`)
- FCM topic `dev-notifications` exists (for --notify)

---

## Output

On successful deployment:

```
Deployment Complete

Function: [name]
Environment: production
Status: ACTIVE
Region: us-central1

Verification:
- Function deployed
- No errors in logs
- Metrics normal
- Error rate: 0%

Rollback command (if needed):
  git checkout HEAD~1 -- functions/src/[name]/
  firebase deploy --only functions:[name]
```
