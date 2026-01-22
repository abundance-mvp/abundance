# Deployment Runbook: Gemini 3 Pro Pipeline

**Created**: 2026-01-14
**Stage**: 7.1 - Integration Testing & Deployment
**Status**: Active

---

## Overview

This runbook documents the deployment process for the Gemini 3 Pro AI pipeline (`onItemCreatedGemini3` trigger). The trigger processes new items in Firestore using Gemini 3 Pro with native tool calling.

---

## Prerequisites

### 1. Firebase CLI

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Verify login
firebase projects:list
```

### 2. API Keys

| Key | Source | Notes |
|-----|--------|-------|
| GOOGLE_API_KEY | [Google AI Studio](https://aistudio.google.com/apikey) | For Gemini 3 Pro API |
| SERPAPI_KEY | [SerpAPI](https://serpapi.com/manage-api-key) | Developer plan ($75/mo) recommended |

### 3. GCP Project Setup

Ensure the following are enabled in your GCP project:
- Cloud Functions API
- Secret Manager API
- Firebase Storage
- Firestore

### 4. Service Account Permissions

For signed URL generation, ensure the service account has:
```
roles/storage.objectViewer
roles/storage.objectCreator
roles/iam.serviceAccountTokenCreator
```

---

## Step 1: Configure Secrets

### 1.1 Select Firebase Project

```bash
# List available projects
firebase projects:list

# Select staging project
firebase use abundance-staging

# Or if not configured:
firebase use --add
```

### 1.2 Create Secrets

```bash
# Create GOOGLE_API_KEY secret
firebase functions:secrets:set GOOGLE_API_KEY
# Paste your Google AI Studio API key when prompted

# Create SERPAPI_KEY secret
firebase functions:secrets:set SERPAPI_KEY
# Paste your SerpAPI key when prompted
```

### 1.3 Verify Secrets

```bash
# Verify secrets are accessible
firebase functions:secrets:access GOOGLE_API_KEY
firebase functions:secrets:access SERPAPI_KEY
```

Expected: Secrets are accessible (values masked)

### 1.4 Local Development Secrets (Optional)

For local development with the Firebase Emulator:

```bash
# Create .secret.local in functions/
cd functions
cat > .secret.local << EOF
GOOGLE_API_KEY=your-dev-api-key
SERPAPI_KEY=your-dev-serpapi-key
EOF
```

Note: `.secret.local` is in `.gitignore` and won't be committed.

---

## Step 2: Pre-Deployment Checks

### 2.1 Build and Lint

```bash
cd functions
npm run build
npm run lint
```

Expected: Build succeeds, no lint errors

### 2.2 Run Unit Tests

```bash
npm test
```

Expected: All tests pass (128+ tests)

### 2.3 Run Integration Tests (Optional)

If you have credentials configured:

```bash
# Copy template and fill in values
cp .env.integration.example .env.integration
# Edit .env.integration with your credentials

# Run integration tests
npm run test:integration
```

Expected: Integration tests pass

---

## Step 3: Deploy to Staging

### 3.1 Deploy the Trigger

```bash
firebase use abundance-staging
firebase deploy --only functions:onItemCreatedGemini3
```

Expected output:
```
✔  functions[onItemCreatedGemini3(us-central1)] Successful create operation.
```

### 3.2 Verify Deployment

```bash
# List deployed functions
firebase functions:list --project abundance-staging

# Check function status
gcloud functions describe onItemCreatedGemini3 --region us-central1
```

Expected: `onItemCreatedGemini3` shows `ACTIVE` status

### 3.3 Monitor Logs

```bash
firebase functions:log --only onItemCreatedGemini3 --project abundance-staging
```

Expected: No errors in logs

---

## Step 4: Staging Smoke Test

### 4.1 Create Test Item

Using Firebase Console or a script:

```typescript
import * as admin from 'firebase-admin';

admin.initializeApp();

const testItem = {
  userId: 'test-user-123',
  imageUrl: 'https://storage.googleapis.com/abundance-test-public/test-product.jpg',
  status: 'pending',
  createdAt: admin.firestore.FieldValue.serverTimestamp(),
  layer1Result: {
    objects: [{
      label: 'bottle',
      confidence: 0.95,
      boundingBox: { x: 0, y: 0, width: 100, height: 200 }
    }],
    detectedBarcode: null,
  },
};

const docRef = await admin.firestore().collection('items').add(testItem);
console.log(`Created test item: ${docRef.id}`);
```

### 4.2 Monitor Trigger Execution

```bash
firebase functions:log --only onItemCreatedGemini3 --project abundance-staging --follow
```

Expected logs:
- Trigger fired
- Gemini API called
- Tool calls executed (google_lens, etc.)
- Item updated with catalog data

### 4.3 Verify Item Updated

Check Firestore document for the test item:
- `status` should be `complete`
- `catalog` should contain AI-generated metadata
- `aiAnalysis.gemini3` should contain processing details

---

## Step 5: Deploy to Production

### 5.1 Pre-Production Checklist

- [ ] Staging smoke test passed
- [ ] All unit tests pass
- [ ] Integration tests pass (if run)
- [ ] Cost monitoring configured
- [ ] Error alerting configured

### 5.2 Deploy

```bash
firebase use abundance-prod
firebase deploy --only functions:onItemCreatedGemini3
```

### 5.3 Verify Production

```bash
firebase functions:list --project abundance-prod
firebase functions:log --only onItemCreatedGemini3 --project abundance-prod
```

---

## Rollback Procedure

If issues detected after deployment:

### Quick Rollback (Re-deploy Previous Version)

```bash
# List recent deployments
gcloud functions list-versions onItemCreatedGemini3 --region us-central1

# Rollback to previous code version
git checkout HEAD~1 -- functions/
cd functions && npm run build
firebase deploy --only functions:onItemCreatedGemini3
```

### Disable Function (Emergency)

```bash
# Disable the function immediately
gcloud functions update onItemCreatedGemini3 --region us-central1 --no-trigger
```

### Delete and Redeploy

```bash
firebase functions:delete onItemCreatedGemini3
firebase deploy --only functions:onItemCreatedGemini3
```

---

## Monitoring

### Cloud Logging

```bash
# Filter logs for this function
gcloud logging read 'resource.labels.function_name="onItemCreatedGemini3"' \
  --limit 50 \
  --format 'table(timestamp,severity,textPayload)'
```

### Cloud Monitoring

Set up alerts for:
- Function execution errors
- High latency (> 30s)
- Memory limit exceeded

### Cost Monitoring

Monitor costs in:
- [Google AI Studio Console](https://aistudio.google.com/) - Gemini API usage
- [SerpAPI Dashboard](https://serpapi.com/dashboard) - Search usage
- [Firebase Console](https://console.firebase.google.com/) - Function invocations

---

## Troubleshooting

### Secret Access Errors

```
Error: Secret version not found or access denied
```

**Solution**: Verify secrets exist and function has access:
```bash
firebase functions:secrets:access GOOGLE_API_KEY
```

### Timeout Errors

```
Error: Function execution took X ms, finished with status: 'timeout'
```

**Solution**:
- Increase timeout in trigger config (max 540s for 2nd gen)
- Optimize tool calls (reduce parallel API calls)

### Signed URL Errors

```
Error: Cannot sign data without 'client_email'
```

**Solution**: Ensure service account has `serviceAccountTokenCreator` role:
```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member serviceAccount:SERVICE_ACCOUNT_EMAIL \
  --role roles/iam.serviceAccountTokenCreator
```

### Memory Errors

```
Error: Memory limit of 512 MiB exceeded
```

**Solution**: Increase memory in trigger config:
```typescript
memory: '1GiB', // or '2GiB'
```

---

## Cost Estimates

| Component | Cost per Item | Notes |
|-----------|---------------|-------|
| Gemini 3 Pro API | ~$0.02-0.03 | Input + output tokens |
| SerpAPI (Google Lens) | ~$0.01 | If visual search needed |
| Firebase Storage | ~$0.001 | Signed URL generation |
| Cloud Functions | ~$0.0004 | 120s execution |
| **Total** | **~$0.03-0.04** | |

### Monthly Estimates

| Volume | Estimated Cost |
|--------|---------------|
| 100 items | $3-4 |
| 1,000 items | $30-40 |
| 10,000 items | $300-400 |

---

## Related Documentation

- Research Validation: `docs/validation/RESEARCH-VALIDATION-stage-7.1.md`
- Stage 7.0 Plan: `docs/plans/PLAN-SUMMARY-stage-7.0.md`
- Cloud Functions Config: `docs/design/CLOUD-FUNCTIONS-001-function-structure.md`
- Cost Model: `docs/tech-stack/COST-MODEL-001-ai-cataloging-cost-per-item.md`

---

**Generated by**: verified-stage-development orchestrator
**Last Updated**: 2026-01-14
