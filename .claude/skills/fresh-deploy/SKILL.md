---
name: fresh-deploy
description: >
  Atomic reset for device development: wipe a user's Firebase catalog data (items + sessions),
  deploy all Cloud Functions, and build + install the app on physical device w-16e.
user-invocable: true
---

# Fresh Deploy Workflow

Atomic pipeline for resetting to a clean state during physical device development.

## When to Use

- Starting a new test cycle on device and need clean data
- After schema changes that require re-ingestion
- After backend code changes that need fresh function deploy + clean data
- Debugging data-dependent issues where stale data interferes

## When NOT to Use

- **Just building to device** (no data wipe needed) → Use `device-tester build`
- **Just deploying functions** (no data wipe or device build) → Use `/gcp-deploy`
- **Simulator testing** → Use `sim-test` skill
- **Production data** → This skill is for development only

## Constants

| Key | Value |
|-----|-------|
| Physical Device | `w-16e` |
| Bundle ID | `com.abundance.mvp` |
| Scheme | `Abundance` |
| Firebase Project | `abundance-mvp-staging` |
| Firestore Collections | `items`, `sessions` |
| GCS Image Path | `/users/{userId}/items/` |

## Pipeline Overview

```
Phase 1: Resolve User ID
Phase 2: Wipe Firebase Data
Phase 3: Deploy Cloud Functions
Phase 4: Build & Deploy to Device
Phase 5: Report
```

---

## Phase 1: Resolve User ID

Determine the Firebase UID to wipe. Priority order:

1. **Explicit `--uid` argument** — use as-is
2. **Query from Firebase Auth MCP** — get the dev user

```
# Load the Firebase auth tool, then look up the dev user
ToolSearch: "+firebase auth"
mcp__plugin_firebase_firebase__auth_get_users
```

If no UID can be resolved, **STOP** and ask the user:
> "Which Firebase user ID should I wipe? Run `firebase auth:export` or check the Firebase Console."

Store the resolved UID for all subsequent phases.

---

## Phase 2: Wipe Firebase Data

### 2.1 Load Firebase MCP Tools

```
ToolSearch: "+firebase firestore"
```

### 2.2 Query and Delete Items

```
# Query all items for this user
mcp__plugin_firebase_firebase__firestore_query_collection
  collection_path: "items"
  filters:
    - field: "userId"
      operator: "=="
      value: "{userId}"

# For each item document returned:
mcp__plugin_firebase_firebase__firestore_delete_document
  path: "items/{itemId}"
```

**Important:** Deleting each item individually fires the `onItemDeleted` Cloud Function trigger, which automatically cleans up GCS images (primary image, crops, motion clips). This cascade is intentional — do NOT batch-delete or use Admin SDK directly, as that would orphan storage files.

### 2.3 Query and Delete Sessions

```
# Query all sessions for this user
mcp__plugin_firebase_firebase__firestore_query_collection
  collection_path: "sessions"
  filters:
    - field: "userId"
      operator: "=="
      value: "{userId}"

# For each session document returned:
mcp__plugin_firebase_firebase__firestore_delete_document
  path: "sessions/{sessionId}"
```

### 2.4 Record Counts

Track: `itemsDeleted`, `sessionsDeleted` for the final report.

If both counts are 0, note: "No data found for user — catalog was already clean."

---

## Phase 3: Deploy Cloud Functions

### 3.1 Run Backend Tests

```bash
cd functions && npm test 2>&1 | tail -20
```

If tests fail, **STOP** and report. Do not deploy broken functions.

### 3.2 Deploy All Functions

```bash
cd functions && firebase deploy --only functions --project abundance-mvp-staging 2>&1
```

### 3.3 Verify Deployment

```
ToolSearch: "+firebase functions"

mcp__plugin_firebase_firebase__functions_list_functions

mcp__plugin_firebase_firebase__functions_get_logs
  min_severity: "ERROR"
  order: "desc"
  page_size: 10
```

If errors found in logs within last 2 minutes, **WARN** but continue (errors may be from pre-deploy state).

Record: `functionsDeployed` count for report.

---

## Phase 4: Build & Deploy to Device

### 4.1 Load XcodeBuildMCP Tools

```
ToolSearch: "+XcodeBuildMCP build_device"
```

### 4.2 Set Session Defaults

```
mcp__XcodeBuildMCP__session-set-defaults
  scheme: "Abundance"
  device: "w-16e"
```

### 4.3 Build for Device

```
mcp__XcodeBuildMCP__build_device
```

If build fails, route to `build-fixer` agent and **STOP**.

### 4.4 Install on Device

```
mcp__XcodeBuildMCP__install_app_device
```

### 4.5 Launch App

```
mcp__XcodeBuildMCP__launch_app_device
```

---

## Phase 5: Report

Present a summary table:

```
## Fresh Deploy Complete

| Step                           | Result                                 |
|--------------------------------|----------------------------------------|
| User ID                        | {userId} (first 8 chars)              |
| Wipe Firebase catalog data     | {itemsDeleted} items + {sessionsDeleted} sessions deleted |
| Deploy backend Cloud Functions | {functionsDeployed} functions deployed |
| Build & deploy app to w-16e    | Built, installed, launched             |
```

---

## Partial Execution

Arguments control which phases run:

| Argument | Phase 1 | Phase 2 | Phase 3 | Phase 4 |
|----------|---------|---------|---------|---------|
| *(none)* | Y | Y | Y | Y |
| `wipe` | Y | Y | - | - |
| `deploy` | - | - | Y | - |
| `build` | - | - | - | Y |
| `--skip-deploy` | Y | Y | - | Y |

---

## Issue Routing

| Problem | Route To |
|---------|----------|
| Build failed | `build-fixer` agent |
| Function deploy failed | Check `functions_get_logs`, then fix code |
| Device not found | Reconnect USB, run `xcrun devicectl list devices` |
| MCP tool not available | Run `ToolSearch` to load it, check MCP server status |
| No items found to delete | Not an error — user catalog was already empty |
| `onItemDeleted` trigger errors | Check `functions_get_logs` for the trigger function |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Using Admin SDK batch delete instead of MCP single-doc delete | Batch delete skips `onItemDeleted` trigger — GCS images become orphaned. Always delete one-by-one. |
| Deploying functions before running tests | Always `npm test` first. Broken deploys affect the whole team. |
| Forgetting `--project` flag on deploy | Always specify `--project abundance-mvp-staging` to avoid deploying to wrong project. |
| Wiping without confirming user ID | Always resolve and display the UID before deleting. Never assume. |
