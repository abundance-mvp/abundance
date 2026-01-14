---
name: gcp-deploy
description: Deploy Cloud Functions with verification
---

# GCP Deploy Command

Deploy Cloud Functions to staging or production with verification.

## Usage

```
/gcp-deploy [function-name]
/gcp-deploy [function-name] --staging
/gcp-deploy [function-name] --production --verify
```

## Examples

```
/gcp-deploy ai-pipeline-orchestrator --staging
/gcp-deploy ai-pipeline-orchestrator --production --verify
/gcp-deploy gemini-service --staging
```

## What This Does

1. **Pre-Deploy Checks**
   - Run local tests (`npm test`)
   - Verify TypeScript compiles
   - Check environment variables
   - Validate secrets exist

2. **Deploy to Staging** (default)
   ```bash
   firebase deploy --only functions:[name] --project abundance-mvp-staging
   ```

3. **Test Staging**
   - Send test request
   - Verify response structure
   - Check logs for errors

4. **Deploy to Production** (with --production)
   ```bash
   firebase deploy --only functions:[name] --project abundance-mvp
   ```

5. **Verify Production** (with --verify)
   - Check function status
   - Send smoke test request
   - Monitor logs
   - Verify observability alerts

## Flags

| Flag | Description |
|------|-------------|
| `--staging` | Deploy to staging only (default) |
| `--production` | Deploy to production |
| `--verify` | Run verification after deploy |
| `--dry-run` | Show commands without executing |

## MCP Servers Used

- **firebase** - Deploy commands, function management (primary)
- **gcloud** - Non-Firebase GCP resources if needed
- **observability** - Log monitoring, alert verification

## Prerequisites

- Firebase CLI authenticated (`firebase login`)
- Project configured in firebase.json
- Secrets in Secret Manager
- Tests passing locally

## Output

- Function deployed
- Verification results
- Log monitoring link
- Rollback command if needed
