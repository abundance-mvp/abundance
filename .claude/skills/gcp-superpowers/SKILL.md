---
name: gcp-superpowers
description: Non-Firebase GCP operations using gcloud MCP server. Use for Cloud Storage, Monitoring, Logging, and other GCP services not covered by Firebase.
---

# GCP Superpowers

Skill for GCP operations that are NOT covered by Firebase MCP server.

## When This Skill Activates

- Cloud Storage bucket operations (outside Firebase Storage)
- Cloud Monitoring and alerting
- Cloud Logging queries
- Other GCP services (Vertex AI, BigQuery, etc.)

## MCP Servers

**Primary:** `gcloud` - General GCP CLI operations
**Secondary:** `observability` - Monitoring and logging
**Secondary:** `storage` - GCS bucket operations

## Available Operations

### Cloud Storage (via storage MCP)

| Operation | MCP Tool |
|-----------|----------|
| List buckets | `mcp__storage__list_buckets` |
| List objects | `mcp__storage__list_objects` |
| Read object | `mcp__storage__read_object_content` |
| Upload object | `mcp__storage__upload_object_safe` |
| Download object | `mcp__storage__download_object` |
| Delete object | `mcp__storage__delete_object` |

### Monitoring (via observability MCP)

| Operation | MCP Tool |
|-----------|----------|
| List metrics | `mcp__observability__list_metric_descriptors` |
| Get time series | `mcp__observability__list_time_series` |
| List alerts | `mcp__observability__list_alerts` |
| List alert policies | `mcp__observability__list_alert_policies` |

### Logging (via observability MCP)

| Operation | MCP Tool |
|-----------|----------|
| List logs | `mcp__observability__list_log_entries` |
| List log names | `mcp__observability__list_log_names` |
| List buckets | `mcp__observability__list_buckets` |
| List sinks | `mcp__observability__list_sinks` |

### Tracing (via observability MCP)

| Operation | MCP Tool |
|-----------|----------|
| List traces | `mcp__observability__list_traces` |
| Get trace | `mcp__observability__get_trace` |

### General GCP (via gcloud MCP)

| Operation | MCP Tool |
|-----------|----------|
| Run command | `mcp__gcloud__run_gcloud_command` |

## Usage Patterns

### Querying Logs

```
1. Use list_log_names to discover available logs
2. Build filter: severity="ERROR" AND timestamp > "2026-01-14T00:00:00Z"
3. Use list_log_entries with filter
4. Analyze results
```

### Checking Metrics

```
1. Use list_metric_descriptors to find relevant metrics
2. Define time interval (startTime, endTime)
3. Use list_time_series with filter and aggregation
4. Analyze time series data
```

### Managing Storage

```
1. Use list_buckets to see available buckets
2. Use list_objects with prefix filter
3. Use read_object_content for text files
4. Use download_object for binary files
```

## When NOT to Use This Skill

- Firestore operations → use `firebase-superpowers`
- Cloud Functions → use `firebase-superpowers`
- Firebase Auth → use `firebase-superpowers`
- iOS development → use `ios-superpowers`

## Common Commands via gcloud MCP

```bash
# List compute instances
mcp__gcloud__run_gcloud_command(args: ["compute", "instances", "list"])

# Get project info
mcp__gcloud__run_gcloud_command(args: ["projects", "describe", "PROJECT_ID"])

# List Cloud Run services
mcp__gcloud__run_gcloud_command(args: ["run", "services", "list"])
```
