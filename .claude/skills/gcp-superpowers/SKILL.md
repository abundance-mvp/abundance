---
name: gcp-superpowers
description: "DEPRECATED: Use backend-superpowers instead. Unified skill covers all Firebase and GCP operations."
deprecated: true
deprecated_by: backend-superpowers
---

# DEPRECATED: Use backend-superpowers

This skill has been deprecated and merged into `backend-superpowers`.

## Migration

Replace:
```
Skill(skill="gcp-superpowers")
```

With:
```
Skill(skill="backend-superpowers")
```

## Why Deprecated?

1. **Incomplete coverage** - This skill only documented 7 of 17 Storage MCP tools, 10 of 13 Observability tools
2. **Missing features** - Error Reporting, Storage Insights, bucket management were not covered
3. **Unified experience** - `backend-superpowers` covers ALL Firebase and GCP operations in one place
4. **Better discoverability** - One skill instead of two

## What backend-superpowers Provides

- **Complete Observability MCP inventory** (13 tools):
  - Cloud Logging (entries, names, buckets, views, sinks, scopes)
  - Cloud Monitoring (metrics, time series)
  - Alerting (policies, alerts)
  - Cloud Trace (list, get)
  - Error Reporting (group stats)

- **Complete Storage MCP inventory** (17 tools):
  - Bucket operations (list, create, metadata, IAM)
  - Object operations (list, read, write, copy, delete)
  - Storage Insights (schema, queries, configs)

- **GCloud CLI** (run_gcloud_command)

- **Complete Firebase MCP inventory** (29 tools)

## Removal Timeline

This file will be removed after 2026-02-17 (30 days from deprecation).

---

## Legacy Content (for reference only)

The following was the original skill content. Use `backend-superpowers` instead.

### Original Operations

**Cloud Storage (via storage MCP):**
| Operation | MCP Tool |
|-----------|----------|
| List buckets | `list_buckets` |
| List objects | `list_objects` |
| Read object | `read_object_content` |
| Upload object | `upload_object_safe` |
| Download object | `download_object` |
| Delete object | `delete_object` |

**Missing from original (now in backend-superpowers):**
- `get_bucket_location`, `get_bucket_metadata`
- `view_iam_policy`, `check_iam_permissions`
- `create_bucket`
- `read_object_metadata`
- `write_object_safe`, `copy_object_safe`
- Storage Insights tools

**Monitoring (via observability MCP):**
| Operation | MCP Tool |
|-----------|----------|
| List metrics | `list_metric_descriptors` |
| Get time series | `list_time_series` |
| List alerts | `list_alerts` |
| List alert policies | `list_alert_policies` |

**Logging:**
| Operation | MCP Tool |
|-----------|----------|
| List logs | `list_log_entries` |
| List log names | `list_log_names` |
| List buckets | `list_buckets` |
| List sinks | `list_sinks` |

**Missing from original:**
- `list_views`, `list_log_scopes`
- `list_group_stats` (Error Reporting)

**Tracing:**
| Operation | MCP Tool |
|-----------|----------|
| List traces | `list_traces` |
| Get trace | `get_trace` |

**General GCP:**
| Operation | MCP Tool |
|-----------|----------|
| Run command | `run_gcloud_command` |
