# INFRASTRUCTURE-001: GCP Deployment Automation

**Created**: 2025-11-10
**Stage**: 3.2 - Backend Implementation Research
**References**: CLOUD-FUNCTIONS-001, RESEARCH-VALIDATION-stage-3.2, CODE-EXAMPLE-005
**Status**: Complete

## Overview

Production-ready deployment automation for Abundance backend on Google Cloud Platform (GCP):

- **Firebase CLI**: Deploy functions, indexes, security rules
- **Environment Management**: Development, staging, production
- **Secret Manager**: Secure API key storage
- **CI/CD Pipeline**: GitHub Actions automation
- **Rollback Strategy**: Version pinning and safe deployment

All commands verified against Firebase CLI v13.0.0+ documentation.

## 1. Firebase Project Setup

### Initialize Firebase Project

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize project (run once in repo root)
firebase init

# Select features:
# - Functions (Cloud Functions for Firebase)
# - Firestore (Database)
# - Storage (Cloud Storage)

# Output: Creates firebase.json, firestore.rules, storage.rules, functions/
```

### firebase.json

```json
{
  "functions": {
    "source": "functions",
    "runtime": "nodejs20",
    "ignore": [
      "node_modules",
      ".git",
      "firebase-debug.log",
      "firebase-debug.*.log",
      "*.test.js"
    ],
    "predeploy": [
      "npm --prefix \"$RESOURCE_DIR\" run lint",
      "npm --prefix \"$RESOURCE_DIR\" test"
    ]
  },
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  }
}
```

## 2. Environment Configuration

### .firebaserc (Project Aliases)

```json
{
  "projects": {
    "default": "abundance-dev",
    "staging": "abundance-staging",
    "production": "abundance-prod"
  }
}
```

### Environment Variables

```bash
# .env.development (local development)
GCP_PROJECT_ID=abundance-dev
GEMINI_MODEL=gemini-2.0-flash-exp
ANTHROPIC_API_KEY=sk-ant-dev-...
SERPAPI_KEY=serpapi-dev-...
NODE_ENV=development

# .env.staging (staging environment)
GCP_PROJECT_ID=abundance-staging
GEMINI_MODEL=gemini-2.0-flash-exp
ANTHROPIC_API_KEY=sk-ant-staging-...
SERPAPI_KEY=serpapi-staging-...
NODE_ENV=staging

# .env.production (production environment)
GCP_PROJECT_ID=abundance-prod
GEMINI_MODEL=gemini-2.0-flash-exp
ANTHROPIC_API_KEY=sk-ant-prod-...
SERPAPI_KEY=serpapi-prod-...
NODE_ENV=production
```

### Set Environment Variables (Firebase CLI)

```bash
# Set config for development
firebase functions:config:set \
  anthropic.api_key="sk-ant-dev-..." \
  serpapi.api_key="serpapi-dev-..." \
  --project abundance-dev

# Set config for production
firebase functions:config:set \
  anthropic.api_key="sk-ant-prod-..." \
  serpapi.api_key="serpapi-prod-..." \
  --project abundance-prod

# View current config
firebase functions:config:get --project abundance-prod
```

### Access Config in Functions

```javascript
const functions = require('firebase-functions');

// Access environment variables
const anthropicKey = functions.config().anthropic.api_key;
const serpapiKey = functions.config().serpapi.api_key;

// Or use Secret Manager (recommended)
const { defineSecret } = require('firebase-functions/v2/params');

const anthropicSecret = defineSecret('ANTHROPIC_API_KEY');
const serpapiSecret = defineSecret('SERPAPI_KEY');

exports.analyzeItem = functions
  .runWith({ secrets: [anthropicSecret, serpapiSecret] })
  .https.onRequest(async (req, res) => {
    const apiKey = anthropicSecret.value();
    // ...
  });
```

## 3. Secret Manager Integration

### Create Secrets (via gcloud CLI)

```bash
# Create secret in Secret Manager
echo -n "sk-ant-prod-..." | gcloud secrets create ANTHROPIC_API_KEY \
  --data-file=- \
  --project=abundance-prod

echo -n "serpapi-prod-..." | gcloud secrets create SERPAPI_KEY \
  --data-file=- \
  --project=abundance-prod

# Grant Cloud Functions access to secrets
gcloud secrets add-iam-policy-binding ANTHROPIC_API_KEY \
  --member=serviceAccount:abundance-prod@appspot.gserviceaccount.com \
  --role=roles/secretmanager.secretAccessor \
  --project=abundance-prod

gcloud secrets add-iam-policy-binding SERPAPI_KEY \
  --member=serviceAccount:abundance-prod@appspot.gserviceaccount.com \
  --role=roles/secretmanager.secretAccessor \
  --project=abundance-prod
```

### Access Secrets in Functions (V2)

```javascript
const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/v2/params');

// Define secrets
const anthropicKey = defineSecret('ANTHROPIC_API_KEY');
const serpapiKey = defineSecret('SERPAPI_KEY');

// Use secrets in function
exports.analyzeItem = onRequest(
  { secrets: [anthropicKey, serpapiKey] },
  async (req, res) => {
    const apiKey = anthropicKey.value();
    const serpapi = serpapiKey.value();

    // Use API keys...
    res.json({ success: true });
  }
);
```

## 4. Firestore Configuration

### firestore.indexes.json

```json
{
  "indexes": [
    {
      "collectionGroup": "items",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "items",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "items",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "category", "order": "ASCENDING" },
        { "fieldPath": "estimatedValue", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

### firestore.rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper: Check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }

    // Helper: Check if user owns the document
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // Helper: Check if user is premium
    function isPremium() {
      return isAuthenticated() &&
             request.auth.token.premium == true;
    }

    // Users collection
    match /users/{userId} {
      // Users can read/write their own document
      allow read, write: if isOwner(userId);
    }

    // Items collection
    match /items/{itemId} {
      // Users can read their own items
      allow read: if isOwner(resource.data.userId);

      // Users can create items (must set userId to their own UID)
      allow create: if isAuthenticated() &&
                       request.resource.data.userId == request.auth.uid;

      // Users can update their own items
      allow update: if isOwner(resource.data.userId);

      // Users can delete their own items
      allow delete: if isOwner(resource.data.userId);
    }

    // Failed items (dead letter queue) - Cloud Functions only
    match /failedItems/{itemId} {
      allow read, write: if false; // No client access
    }

    // AI costs (analytics) - Cloud Functions only
    match /aiCosts/{costId} {
      allow read, write: if false; // No client access
    }
  }
}
```

## 5. Storage Configuration

### storage.rules

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    // Helper: Check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }

    // Helper: Check if file path matches user ID
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // Items folder: users can only access their own subfolder
    match /items/{userId}/{itemId} {
      // Read: User owns the item
      allow read: if isOwner(userId);

      // Write: User owns the item, max size 10MB
      allow write: if isOwner(userId) &&
                      request.resource.size < 10 * 1024 * 1024 &&
                      request.resource.contentType.matches('image/.*');
    }
  }
}
```

### Lifecycle Policy (Auto-Delete After 90 Days)

```json
{
  "lifecycle": {
    "rule": [
      {
        "action": { "type": "Delete" },
        "condition": {
          "age": 90,
          "matchesPrefix": ["items/"]
        }
      }
    ]
  }
}
```

```bash
# Apply lifecycle policy
gsutil lifecycle set lifecycle.json gs://abundance-prod.appspot.com
```

## 6. Deployment Commands

### Deploy All Components

```bash
# Development
firebase deploy --project abundance-dev

# Staging
firebase deploy --project abundance-staging

# Production
firebase deploy --project abundance-prod
```

### Deploy Specific Components

```bash
# Deploy only functions
firebase deploy --only functions --project abundance-prod

# Deploy specific function
firebase deploy --only functions:analyzeItem --project abundance-prod

# Deploy Firestore indexes
firebase deploy --only firestore:indexes --project abundance-prod

# Deploy Firestore rules
firebase deploy --only firestore:rules --project abundance-prod

# Deploy Storage rules
firebase deploy --only storage --project abundance-prod
```

### Deploy with Flags

```bash
# Force deploy (skip predeploy hooks)
firebase deploy --only functions --force --project abundance-prod

# Deploy with debug logging
firebase deploy --only functions --debug --project abundance-prod

# Deploy non-interactively (CI/CD)
firebase deploy --only functions --non-interactive --project abundance-prod
```

## 7. CI/CD Pipeline (GitHub Actions)

### .github/workflows/deploy-production.yml

```yaml
name: Deploy to Production

on:
  push:
    branches:
      - main

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'

      - name: Install dependencies
        run: |
          cd functions
          npm ci

      - name: Run linter
        run: |
          cd functions
          npm run lint

      - name: Run tests
        run: |
          cd functions
          npm test -- --coverage

  deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'

      - name: Install Firebase CLI
        run: npm install -g firebase-tools

      - name: Deploy to Production
        run: |
          firebase deploy \
            --only functions,firestore:indexes,firestore:rules,storage \
            --project abundance-prod \
            --non-interactive \
            --token ${{ secrets.FIREBASE_TOKEN }}
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}

      - name: Slack Notification
        if: success()
        run: |
          curl -X POST ${{ secrets.SLACK_WEBHOOK_URL }} \
            -H 'Content-Type: application/json' \
            -d '{"text":"✅ Abundance backend deployed to production"}'
```

### .github/workflows/deploy-staging.yml

```yaml
name: Deploy to Staging

on:
  push:
    branches:
      - develop

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'

      - name: Install Firebase CLI
        run: npm install -g firebase-tools

      - name: Deploy to Staging
        run: |
          firebase deploy \
            --only functions \
            --project abundance-staging \
            --non-interactive \
            --token ${{ secrets.FIREBASE_TOKEN }}
```

### Setup GitHub Secrets

```bash
# Generate Firebase token for CI/CD
firebase login:ci

# Copy token and add to GitHub Secrets:
# Settings → Secrets → Actions → New repository secret
# Name: FIREBASE_TOKEN
# Value: 1//... (token from login:ci)
```

## 8. Rollback Strategy

### List Function Versions

```bash
# List deployed functions
firebase functions:list --project abundance-prod

# View function details
gcloud functions describe analyzeItem \
  --project abundance-prod \
  --region us-central1
```

### Rollback to Previous Version

```bash
# Deploy specific version from Git
git checkout <previous-commit-hash>
firebase deploy --only functions --project abundance-prod
git checkout main
```

### Version Pinning (package.json)

```json
{
  "dependencies": {
    "firebase-admin": "12.0.0",
    "firebase-functions": "4.5.0",
    "@google-cloud/vertexai": "1.0.0",
    "@anthropic-ai/sdk": "0.20.0"
  }
}
```

## 9. Monitoring Deployment

### View Deployment Logs

```bash
# Watch deployment progress
firebase deploy --only functions --project abundance-prod --debug

# View function logs after deployment
firebase functions:log --project abundance-prod --limit 50

# View specific function logs
firebase functions:log --only analyzeItem --project abundance-prod
```

### Health Check After Deployment

```bash
# Test HTTP endpoint
curl -X POST https://us-central1-abundance-prod.cloudfunctions.net/api/health \
  -H "Content-Type: application/json"

# Expected: {"status":"ok","timestamp":"2025-11-10T12:00:00.000Z"}
```

## 10. Deployment Checklist

```markdown
## Pre-Deployment Checklist

- [ ] All tests passing (`npm test`)
- [ ] Linter passing (`npm run lint`)
- [ ] Environment variables configured
- [ ] Secrets updated in Secret Manager
- [ ] Firestore indexes deployed
- [ ] Security rules reviewed
- [ ] Code reviewed and approved
- [ ] Staging deployment successful
- [ ] Breaking changes documented

## Post-Deployment Checklist

- [ ] Health check endpoint responds
- [ ] Cloud Functions logs show no errors
- [ ] Firestore queries working (no index errors)
- [ ] Storage uploads working
- [ ] AI pipeline processing items
- [ ] Error rates within SLO (<1%)
- [ ] Latency within SLO (<10s p95)
- [ ] Team notified (Slack)
```

## 11. Cost Optimization

### Function Resource Limits

```javascript
// functions/index.js
const functions = require('firebase-functions');

// Optimize memory and timeout for each function
exports.analyzeItem = functions
  .runWith({
    memory: '1GB', // Default: 256MB (increase for AI workloads)
    timeoutSeconds: 60, // Default: 60s (max: 540s)
    maxInstances: 100 // Prevent runaway costs
  })
  .https.onRequest(async (req, res) => {
    // ...
  });

exports.retryFailedItems = functions
  .runWith({
    memory: '512MB',
    timeoutSeconds: 300 // 5 minutes for batch job
  })
  .pubsub.schedule('0 2 * * *')
  .onRun(async (context) => {
    // ...
  });
```

### Budget Alerts

```bash
# Set up budget alert (via GCP Console)
# Billing → Budgets & Alerts
# - Budget: $100/month
# - Alert thresholds: 50%, 90%, 100%
# - Notification: email + Slack webhook
```

## Cross-References

- **CODE-EXAMPLE-005**: See Cloud Functions being deployed
- **CODE-EXAMPLE-006**: See Firestore indexes being deployed
- **TEST-EXAMPLE-003**: See tests run in predeploy hooks
- **MONITORING-001**: See deployment monitoring dashboards
- **RESEARCH-VALIDATION-stage-3.2**: Verified Cloud Functions pricing

## Notes

- Firebase CLI v13.0.0+ required (supports Node.js 20)
- Use `firebase.json` predeploy hooks to run tests before deployment
- Store API keys in Secret Manager (NOT environment config)
- Deploy indexes BEFORE deploying functions (avoid index errors)
- Use `--force` flag only in emergencies (skips safety checks)
- Set `maxInstances` to prevent runaway costs
- Always deploy to staging before production
- Use GitHub Actions for automated deployments
- Monitor Cloud Logging for deployment errors
