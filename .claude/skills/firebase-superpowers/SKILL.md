---
name: firebase-superpowers
description: Firebase operations skill using official Firebase MCP server. Use for Firestore, Cloud Functions, Authentication, Storage, and Security Rules.
---

# Firebase Superpowers

Primary backend skill for all Firebase operations using the official Firebase MCP server.

## When This Skill Activates

- Firestore database operations (read, write, query)
- Cloud Functions deployment and management
- Firebase Authentication operations
- Firebase Storage operations
- Security Rules validation and deployment

## MCP Server

**Primary:** `firebase` (official Firebase MCP)

```json
{
  "firebase": {
    "command": "npx",
    "args": ["-y", "firebase-tools@latest", "mcp"]
  }
}
```

## Available Operations

### Firestore

| Operation | MCP Tool |
|-----------|----------|
| Get documents | `mcp__plugin_firebase_firebase__firestore_get_documents` |
| Query collection | `mcp__plugin_firebase_firebase__firestore_query_collection` |
| List collections | `mcp__plugin_firebase_firebase__firestore_list_collections` |
| Delete document | `mcp__plugin_firebase_firebase__firestore_delete_document` |

### Cloud Functions

| Operation | MCP Tool |
|-----------|----------|
| List functions | `mcp__plugin_firebase_firebase__functions_list_functions` |
| Get logs | `mcp__plugin_firebase_firebase__functions_get_logs` |

### Authentication

| Operation | MCP Tool |
|-----------|----------|
| Get users | `mcp__plugin_firebase_firebase__auth_get_users` |
| Update user | `mcp__plugin_firebase_firebase__auth_update_user` |
| Set SMS policy | `mcp__plugin_firebase_firebase__auth_set_sms_region_policy` |

### Storage

| Operation | MCP Tool |
|-----------|----------|
| Get download URL | `mcp__plugin_firebase_firebase__storage_get_object_download_url` |

### Security Rules

| Operation | MCP Tool |
|-----------|----------|
| Validate rules | `mcp__plugin_firebase_firebase__firebase_validate_security_rules` |
| Get rules | `mcp__plugin_firebase_firebase__firebase_get_security_rules` |

### Project Management

| Operation | MCP Tool |
|-----------|----------|
| Get project | `mcp__plugin_firebase_firebase__firebase_get_project` |
| List apps | `mcp__plugin_firebase_firebase__firebase_list_apps` |
| Get environment | `mcp__plugin_firebase_firebase__firebase_get_environment` |
| Initialize | `mcp__plugin_firebase_firebase__firebase_init` |

## Usage Patterns

### Querying Firestore

```
1. Use firestore_list_collections to discover available collections
2. Use firestore_query_collection with filters to find documents
3. Use firestore_get_documents for specific document retrieval
```

### Deploying Functions

```
1. Run local tests: npm test
2. Use functions_list_functions to verify current state
3. Deploy via firebase CLI: firebase deploy --only functions
4. Use functions_get_logs to verify deployment
```

### Managing Security Rules

```
1. Use firebase_get_security_rules to review current rules
2. Modify rules locally
3. Use firebase_validate_security_rules before deploy
4. Deploy: firebase deploy --only firestore:rules
```

## When NOT to Use This Skill

- Non-Firebase GCP resources → use `gcp-superpowers`
- iOS/Swift development → use `ios-superpowers`
- AI pipeline logic → use `gemini-integration`

## Error Handling

### Not logged in
→ Run: `firebase login`

### Wrong project
→ Run: `firebase use <project-id>`

### Rules validation failed
→ Review error message, fix rules syntax
