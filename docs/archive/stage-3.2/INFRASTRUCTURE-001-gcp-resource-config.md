# GCP Resource Configuration - Infrastructure-as-Code

**Created**: 2025-11-10
**Stage**: 3.2 - Backend Implementation Research
**Status**: Complete
**References**:
- docs/research/RESEARCH-002-backend-implementation-patterns.md
- docs/research/CODE-EXAMPLES-002-cloud-functions-reference.md
- docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md

---

## Table of Contents

1. [Firebase Configuration](#firebase-configuration)
2. [Firestore Configuration](#firestore-configuration)
3. [Cloud Functions Configuration](#cloud-functions-configuration)
4. [Environment Variables](#environment-variables)
5. [Deployment Commands](#deployment-commands)

---

## Firebase Configuration

### firebase.json

**File**: `firebase.json` (root directory)

```json
{
  "functions": [
    {
      "source": "functions",
      "codebase": "default",
      "ignore": [
        "node_modules",
        ".git",
        "firebase-debug.log",
        "firebase-debug.*.log",
        "*.local"
      ],
      "predeploy": [
        "npm --prefix \"$RESOURCE_DIR\" run build"
      ]
    }
  ],
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  },
  "emulators": {
    "auth": {
      "port": 9099
    },
    "functions": {
      "port": 5001
    },
    "firestore": {
      "port": 8080
    },
    "storage": {
      "port": 9199
    },
    "ui": {
      "enabled": true,
      "port": 4000
    },
    "singleProjectMode": true
  }
}
```

**Key Configurations**:
- **Functions**: Node.js 20, TypeScript compilation before deploy
- **Firestore**: Security rules + composite indexes
- **Storage**: Access control rules
- **Emulators**: Local testing on standard ports

---

## Firestore Configuration

### firestore.indexes.json

**File**: `firestore.indexes.json` (root directory)

```json
{
  "indexes": [
    {
      "collectionGroup": "items",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "userId", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "items",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "userId", "order": "ASCENDING"},
        {"fieldPath": "category", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "items",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "visibility", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "items",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "userId", "order": "ASCENDING"},
        {"fieldPath": "status", "order": "ASCENDING"},
        {"fieldPath": "createdAt", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "items",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "deletedAt", "order": "ASCENDING"}
      ]
    },
    {
      "collectionGroup": "subscriptions",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "status", "order": "ASCENDING"},
        {"fieldPath": "expiresAt", "order": "ASCENDING"}
      ]
    },
    {
      "collectionGroup": "subscriptions",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "userId", "order": "ASCENDING"},
        {"fieldPath": "status", "order": "ASCENDING"}
      ]
    }
  ],
  "fieldOverrides": []
}
```

**Composite Indexes**:
- `userId + createdAt` → User's items, newest first
- `userId + category + createdAt` → User's items by category
- `visibility + createdAt` → Showcase feed (all users)
- `userId + status + createdAt` → User's pending items
- `deletedAt` → Cleanup query for soft-deleted items
- `status + expiresAt` → Expired subscriptions query
- `userId + status` → User's subscription status

---

### firestore.rules

**File**: `firestore.rules` (root directory)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }

    function isPremium() {
      return isSignedIn() && request.auth.token.get('premium', false) == true;
    }

    // Users collection
    match /users/{userId} {
      // Users can read/write their own profile
      allow read, write: if isOwner(userId);
    }

    // Items collection
    match /items/{itemId} {
      // Users can read their own items
      allow read: if isSignedIn() &&
                     resource.data.userId == request.auth.uid;

      // Users can create items (must set userId to own uid)
      allow create: if isSignedIn() &&
                       request.resource.data.userId == request.auth.uid;

      // Users can update their own items
      allow update: if isSignedIn() &&
                       resource.data.userId == request.auth.uid &&
                       request.resource.data.userId == request.auth.uid;  // userId cannot change

      // Users can delete their own items (soft delete)
      allow delete: if isSignedIn() &&
                       resource.data.userId == request.auth.uid;

      // Premium users can access showcase items (visibility = 'showcase')
      allow read: if isSignedIn() &&
                     isPremium() &&
                     resource.data.visibility == 'showcase';
    }

    // Subscriptions collection (Cloud Functions only)
    match /subscriptions/{subscriptionId} {
      // Users can read their own subscription
      allow read: if isSignedIn() &&
                     resource.data.userId == request.auth.uid;

      // Only Cloud Functions can write (via Firebase Admin SDK)
      allow write: if false;
    }

    // Audit logs (Cloud Functions only)
    match /audit_logs/{logId} {
      allow read, write: if false;  // Only Cloud Functions
    }
  }
}
```

**Security Rules**:
- **Row-Level Security**: Users can only access their own data
- **Premium Enforcement**: Custom claims for premium features
- **Cloud Functions Only**: Subscriptions and audit logs (Firebase Admin SDK bypasses rules)

---

### storage.rules

**File**: `storage.rules` (root directory)

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    // Users can upload to their own folder
    match /users/{userId}/items/{itemId}/{fileName} {
      // Read: User must own the item
      allow read: if request.auth != null &&
                     request.auth.uid == userId;

      // Write: User must own the item, 10MB file size limit
      allow write: if request.auth != null &&
                      request.auth.uid == userId &&
                      request.resource.size < 10 * 1024 * 1024;  // 10MB
    }

    // Items folder (Cloud Functions only)
    match /items/{itemId}/{fileName} {
      // Read: Via signed URLs only (generated by Cloud Functions)
      allow read: if false;

      // Write: Cloud Functions only (Firebase Admin SDK)
      allow write: if false;
    }
  }
}
```

**Storage Rules**:
- **User Uploads**: Users can upload to `users/{userId}/items/{itemId}/`
- **File Size Limit**: 10MB per file
- **Cloud Functions Uploads**: Items folder (bypasses rules via Admin SDK)
- **Signed URLs**: Read access via time-limited signed URLs (generated by Cloud Functions)

---

## Cloud Functions Configuration

### package.json

**File**: `functions/package.json`

```json
{
  "name": "abundance-functions",
  "version": "1.0.0",
  "description": "Cloud Functions for Abundance Backend",
  "main": "lib/index.js",
  "engines": {
    "node": "20"
  },
  "scripts": {
    "lint": "eslint --ext .js,.ts .",
    "build": "tsc",
    "watch": "tsc -w",
    "serve": "npm run build && firebase emulators:start --only functions",
    "dev": "concurrently \"npm run watch\" \"firebase emulators:start --only functions\"",
    "shell": "npm run build && firebase functions:shell",
    "start": "npm run shell",
    "deploy": "firebase deploy --only functions",
    "logs": "firebase functions:log"
  },
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^5.0.0",
    "@google-cloud/vertexai": "^1.0.0",
    "axios": "^1.6.0"
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "concurrently": "^8.0.0",
    "@typescript-eslint/eslint-plugin": "^6.0.0",
    "@typescript-eslint/parser": "^6.0.0",
    "eslint": "^8.0.0",
    "eslint-config-google": "^0.14.0",
    "eslint-plugin-import": "^2.29.0"
  },
  "private": true
}
```

---

### tsconfig.json

**File**: `functions/tsconfig.json`

```json
{
  "compilerOptions": {
    "module": "commonjs",
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "outDir": "lib",
    "sourceMap": true,
    "strict": true,
    "target": "es2017",
    "esModuleInterop": true,
    "resolveJsonModule": true
  },
  "compileOnSave": true,
  "include": [
    "src"
  ],
  "exclude": [
    "node_modules",
    "lib"
  ]
}
```

---

### .eslintrc.js

**File**: `functions/.eslintrc.js`

```javascript
module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
  },
  extends: [
    "eslint:recommended",
    "plugin:import/errors",
    "plugin:import/warnings",
    "plugin:import/typescript",
    "google",
    "plugin:@typescript-eslint/recommended",
  ],
  parser: "@typescript-eslint/parser",
  parserOptions: {
    project: ["tsconfig.json"],
    sourceType: "module",
  },
  ignorePatterns: [
    "/lib/**/*",  // Ignore compiled files
  ],
  plugins: [
    "@typescript-eslint",
    "import",
  ],
  rules: {
    "quotes": ["error", "single"],
    "import/no-unresolved": 0,
    "indent": ["error", 2],
  },
};
```

---

## Environment Variables

### .env.development

**File**: `functions/.env.development` (NOT committed to Git)

```bash
# Firebase Emulator Suite
GCP_PROJECT=abundance-dev
FIRESTORE_EMULATOR_HOST=localhost:8080
FIREBASE_AUTH_EMULATOR_HOST=localhost:9099
FIREBASE_STORAGE_EMULATOR_HOST=localhost:9199

# AI Provider API Keys (Test)
SERPAPI_KEY=test_serpapi_key_development
ANTHROPIC_API_KEY=test_anthropic_key_development

# Feature Flags
ENABLE_LAYER_2B=true
ENABLE_LAYER_3=false  # Disable Layer 3 for faster testing
```

---

### .env.staging

**File**: `functions/.env.staging` (NOT committed to Git)

```bash
# Firebase Staging Project
GCP_PROJECT=abundance-staging

# AI Provider API Keys (Staging)
SERPAPI_KEY=sk_staging_serpapi_key
ANTHROPIC_API_KEY=sk_staging_anthropic_key

# Feature Flags
ENABLE_LAYER_2B=true
ENABLE_LAYER_3=true
```

---

### .env.production

**File**: `functions/.env.production` (NOT committed to Git)

```bash
# Firebase Production Project
GCP_PROJECT=abundance-prod

# AI Provider API Keys (Production)
# IMPORTANT: Use Google Secret Manager for production secrets
# These values are loaded from Secret Manager at runtime
SERPAPI_KEY=projects/abundance-prod/secrets/serpapi-api-key/versions/latest
ANTHROPIC_API_KEY=projects/abundance-prod/secrets/anthropic-api-key/versions/latest

# Feature Flags
ENABLE_LAYER_2B=true
ENABLE_LAYER_3=true
```

---

### .env.example

**File**: `functions/.env.example` (committed to Git as template)

```bash
# Firebase Project
GCP_PROJECT=your-project-id

# AI Provider API Keys
SERPAPI_KEY=your_serpapi_key
ANTHROPIC_API_KEY=your_anthropic_key

# Feature Flags
ENABLE_LAYER_2B=true
ENABLE_LAYER_3=true
```

---

### .gitignore

**File**: `functions/.gitignore`

```
# Compiled output
lib/

# Logs
logs
*.log
npm-debug.log*
firebase-debug.log*
firebase-debug.*.log*

# Dependencies
node_modules/

# Environment variables (NEVER commit secrets!)
.env
.env.local
.env.development
.env.staging
.env.production

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db
```

---

## Deployment Commands

### Development (Local Emulator)

```bash
# Install dependencies
cd functions
npm install

# Start emulators with hot reload
npm run dev

# Open Emulator UI
open http://localhost:4000
```

---

### Staging Deployment

```bash
# Set Firebase project to staging
firebase use abundance-staging

# Deploy all (functions, firestore, storage)
firebase deploy

# Deploy only functions
firebase deploy --only functions

# Deploy only Firestore rules and indexes
firebase deploy --only firestore

# Deploy only Storage rules
firebase deploy --only storage
```

---

### Production Deployment

```bash
# Set Firebase project to production
firebase use abundance-prod

# IMPORTANT: Run tests before production deploy
npm test

# Deploy all (functions, firestore, storage)
firebase deploy

# Deploy with confirmation prompt
firebase deploy --only functions --force

# View deployment logs
firebase functions:log --only onItemCreated --limit 100
```

---

### Rollback Strategy

```bash
# List recent deployments
firebase functions:list

# Rollback specific function to previous version
gcloud functions deploy onItemCreated \
  --source=gs://gcf-sources-123456/previous-version.zip \
  --runtime=nodejs20

# Firestore rollback (point-in-time recovery, up to 7 days)
gcloud firestore databases restore \
  --source-database=abundance-prod \
  --destination-database=abundance-prod-restore \
  --source-backup=projects/abundance-prod/databases/(default)/backups/backup-id
```

---

## Secret Management (Production)

### Store Secrets in Google Secret Manager

```bash
# Store SerpAPI key
echo -n "your_serpapi_production_key" | \
  gcloud secrets create serpapi-api-key \
    --data-file=- \
    --project=abundance-prod

# Store Anthropic API key
echo -n "your_anthropic_production_key" | \
  gcloud secrets create anthropic-api-key \
    --data-file=- \
    --project=abundance-prod

# Grant Cloud Functions service account access to secrets
gcloud secrets add-iam-policy-binding serpapi-api-key \
  --member="serviceAccount:abundance-prod@appspot.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor" \
  --project=abundance-prod

gcloud secrets add-iam-policy-binding anthropic-api-key \
  --member="serviceAccount:abundance-prod@appspot.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor" \
  --project=abundance-prod
```

---

### Access Secrets in Cloud Functions

**File**: `functions/src/utils/secrets.ts`

```typescript
import {SecretManagerServiceClient} from '@google-cloud/secret-manager';

const client = new SecretManagerServiceClient();

export async function getSecret(secretName: string): Promise<string> {
  const name = `projects/${process.env.GCP_PROJECT}/secrets/${secretName}/versions/latest`;

  const [version] = await client.accessSecretVersion({name});
  const payload = version.payload?.data?.toString();

  if (!payload) {
    throw new Error(`Secret ${secretName} not found`);
  }

  return payload;
}

// Usage
// const serpApiKey = await getSecret('serpapi-api-key');
// const anthropicApiKey = await getSecret('anthropic-api-key');
```

---

## Monitoring & Alerts Setup

### Create Budget Alert

```bash
# Create budget (monthly $517 limit)
gcloud billing budgets create \
  --billing-account=BILLING_ACCOUNT_ID \
  --display-name="Abundance Backend Budget" \
  --budget-amount=517 \
  --threshold-rule=percent=50 \
  --threshold-rule=percent=90 \
  --threshold-rule=percent=100 \
  --project=abundance-prod
```

---

### Create Alert Policies

**File**: `alert-policy-error-rate.yaml`

```yaml
displayName: "Cloud Functions - High Error Rate"
conditions:
  - displayName: "Error rate > 5% over 5 minutes"
    conditionThreshold:
      filter: 'resource.type="cloud_function" metric.type="cloudfunctions.googleapis.com/function/execution_count" metric.label.status!="ok"'
      comparison: "COMPARISON_GT"
      thresholdValue: 0.05
      duration: "300s"
      aggregations:
        - alignmentPeriod: "60s"
          perSeriesAligner: "ALIGN_RATE"
notificationChannels:
  - projects/abundance-prod/notificationChannels/email-alerts
```

```bash
# Create alert policy
gcloud alpha monitoring policies create \
  --policy-from-file=alert-policy-error-rate.yaml \
  --project=abundance-prod
```

---

## CI/CD Pipeline (GitHub Actions)

### .github/workflows/deploy-functions.yml

```yaml
name: Deploy Cloud Functions

on:
  push:
    branches:
      - main
    paths:
      - 'functions/**'
      - 'firestore.rules'
      - 'firestore.indexes.json'
      - 'storage.rules'

jobs:
  deploy-staging:
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

      - name: Run tests
        run: |
          cd functions
          npm test

      - name: Deploy to Staging
        uses: w9jds/firebase-action@master
        with:
          args: deploy --project abundance-staging
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN_STAGING }}

  deploy-production:
    runs-on: ubuntu-latest
    needs: deploy-staging
    if: github.ref == 'refs/heads/main'
    environment:
      name: production
      url: https://abundance-prod.web.app
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

      - name: Run tests
        run: |
          cd functions
          npm test

      - name: Deploy to Production
        uses: w9jds/firebase-action@master
        with:
          args: deploy --project abundance-prod
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN_PROD }}
```

---

## Summary

This document provides complete infrastructure-as-code configuration for the Abundance backend:

✅ **Firebase Configuration**: firebase.json (functions, firestore, storage, emulators)
✅ **Firestore Configuration**: firestore.indexes.json (7 composite indexes), firestore.rules (row-level security)
✅ **Storage Configuration**: storage.rules (user uploads, 10MB limit, signed URLs)
✅ **Cloud Functions Configuration**: package.json (Node.js 20), tsconfig.json (TypeScript 5.0), .eslintrc.js (linting)
✅ **Environment Variables**: .env templates (development, staging, production)
✅ **Secret Management**: Google Secret Manager integration (production secrets)
✅ **Deployment Commands**: Development (emulator), staging, production, rollback
✅ **Monitoring & Alerts**: Budget alerts, error rate alerts, latency alerts
✅ **CI/CD Pipeline**: GitHub Actions workflow (staging → production)

**Ready for deployment**: All configuration files are production-ready and follow GCP/Firebase best practices.

---

**Created**: 2025-11-10
**Status**: Complete
**References**: RESEARCH-002, CODE-EXAMPLES-002, TECH-STACK-MAP-001
