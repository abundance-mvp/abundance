---
name: firebase-superpowers
description: "DEPRECATED: Use backend-superpowers instead. Unified skill covers all Firebase and GCP operations."
deprecated: true
deprecated_by: backend-superpowers
---

# DEPRECATED: Use backend-superpowers

This skill has been deprecated and merged into `backend-superpowers`.

## Migration

Replace:
```
Skill(skill="firebase-superpowers")
```

With:
```
Skill(skill="backend-superpowers")
```

## Why Deprecated?

1. **Incomplete coverage** - This skill only documented 15 of 29 Firebase MCP tools
2. **Missing features** - FCM, Remote Config, RTDB, project creation were not covered
3. **Unified experience** - `backend-superpowers` covers ALL Firebase and GCP operations in one place

## What backend-superpowers Provides

- **Complete Firebase MCP inventory** (29 tools):
  - Firestore (CRUD, query)
  - Cloud Functions (list, logs)
  - Authentication (get, update, SMS policy)
  - FCM Cloud Messaging (send notifications)
  - Remote Config (get, update templates)
  - Realtime Database (get, set)
  - Security Rules (validate, get)
  - Project Management (create, configure, init)

- **Complete GCP MCP inventory** (30+ tools):
  - Cloud Logging
  - Cloud Monitoring
  - Cloud Trace
  - Error Reporting
  - Cloud Storage (GCS)
  - General gcloud CLI

## Removal Timeline

This file will be removed after 2026-02-17 (30 days from deprecation).

---

## Legacy Content (for reference only)

The following was the original skill content. Use `backend-superpowers` instead.

### Original MCP Operations

| Operation | MCP Tool |
|-----------|----------|
| Get documents | `firestore_get_documents` |
| Query collection | `firestore_query_collection` |
| List collections | `firestore_list_collections` |
| Delete document | `firestore_delete_document` |
| List functions | `functions_list_functions` |
| Get logs | `functions_get_logs` |
| Get users | `auth_get_users` |
| Update user | `auth_update_user` |
| Get download URL | `storage_get_object_download_url` |
| Validate rules | `firebase_validate_security_rules` |
| Get rules | `firebase_get_security_rules` |
| Get project | `firebase_get_project` |
| List apps | `firebase_list_apps` |
| Get environment | `firebase_get_environment` |
| Initialize | `firebase_init` |

**Missing from original (now in backend-superpowers):**
- `messaging_send_message` (FCM)
- `remoteconfig_get_template`, `remoteconfig_update_template`
- `realtimedatabase_get_data`, `realtimedatabase_set_data`
- `firebase_create_project`, `firebase_create_app`
- `firebase_update_environment`
- `firebase_read_resources`
- `auth_set_sms_region_policy`
- And more...
