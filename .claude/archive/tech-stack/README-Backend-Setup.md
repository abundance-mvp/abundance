# Abundance Backend Setup Guide

**Created**: 2025-11-11
**Stage**: 4.2 - Backend Project Scaffolding
**Audience**: Backend developers setting up local development environment

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Firebase Project Configuration](#firebase-project-configuration)
4. [Local Development](#local-development)
5. [Deployment](#deployment)
6. [Testing](#testing)
7. [Troubleshooting](#troubleshooting)
8. [Architecture Overview](#architecture-overview)

---

## Prerequisites

### Required Software

| Tool | Version | Installation Command |
|------|---------|---------------------|
| **Node.js** | 20 LTS | Download from [nodejs.org](https://nodejs.org/) |
| **npm** | 9.0+ | Included with Node.js |
| **Firebase CLI** | 13.0.0+ | `npm install -g firebase-tools` |
| **Git** | 2.30+ | Download from [git-scm.com](https://git-scm.com/) |
| **Java** | 11+ | Required for Firebase Emulator Suite |

### Verify Installation

```bash
# Check Node.js version (should be 20.x)
node --version

# Check npm version
npm --version

# Check Firebase CLI version (should be 13.x+)
firebase --version

# Check Git version
git --version

# Check Java version (should be 11+)
java --version
```

---

## Initial Setup

### 1. Clone Repository

```bash
git clone <repository-url>
cd abundance-backend
```

### 2. Install Dependencies

```bash
# Install Cloud Functions dependencies
cd functions
npm install
cd ..
```

### 3. Authenticate with Firebase

```bash
# Login to Firebase (opens browser)
firebase login

# Verify authentication
firebase projects:list
```

You should see three projects:
- `abundance-dev` (Development)
- `abundance-staging` (Staging)
- `abundance-prod` (Production)

### 4. Set Default Project

```bash
# Set development as default
firebase use abundance-dev

# Verify current project
firebase use
```

---

## Firebase Project Configuration

### 1. Configure Environment Variables

Copy the environment template:

```bash
cp docs/tech-stack/.env.template .env.development
```

Edit `.env.development` with your API keys:

```bash
# Required API keys
ANTHROPIC_API_KEY=sk-ant-api03-...  # Get from https://console.anthropic.com/
SERPAPI_KEY=...                      # Get from https://serpapi.com/manage-api-key
UPCITEMDB_API_KEY=...                # Get from https://www.upcitemdb.com/api/explorer
```

### 2. Set Up Secret Manager (Required for Cloud Functions)

Secrets must be stored in Google Secret Manager for Cloud Functions to access them:

```bash
# Create Anthropic API secret
echo -n "sk-ant-api03-..." | gcloud secrets create ANTHROPIC_API_KEY \
  --data-file=- \
  --project=abundance-dev

# Create SerpAPI secret
echo -n "your-serpapi-key" | gcloud secrets create SERPAPI_KEY \
  --data-file=- \
  --project=abundance-dev

# Grant Cloud Functions access to secrets
gcloud secrets add-iam-policy-binding ANTHROPIC_API_KEY \
  --member=serviceAccount:abundance-dev@appspot.gserviceaccount.com \
  --role=roles/secretmanager.secretAccessor \
  --project=abundance-dev

gcloud secrets add-iam-policy-binding SERPAPI_KEY \
  --member=serviceAccount:abundance-dev@appspot.gserviceaccount.com \
  --role=roles/secretmanager.secretAccessor \
  --project=abundance-dev

# Verify secrets exist
gcloud secrets list --project abundance-dev
```

### 3. Copy Project Configuration Files

Copy the scaffolded configuration files to project root:

```bash
# Copy from docs/tech-stack/ to project root
cp docs/tech-stack/firestore.rules firestore.rules
cp docs/tech-stack/storage.rules storage.rules
cp docs/tech-stack/firestore.indexes.json firestore.indexes.json
cp docs/tech-stack/firebase.json firebase.json

# Copy Cloud Functions files
mkdir -p functions/src
cp docs/tech-stack/functions-package.json functions/package.json
cp docs/tech-stack/functions-index-scaffold.ts functions/src/index.ts

# Create tsconfig.json for TypeScript
cat > functions/tsconfig.json <<EOF
{
  "compilerOptions": {
    "module": "commonjs",
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "outDir": "lib",
    "sourceMap": true,
    "strict": true,
    "target": "es2017",
    "esModuleInterop": true
  },
  "compileOnSave": true,
  "include": [
    "src"
  ]
}
EOF

# Install dependencies
cd functions
npm install
cd ..
```

---

## Local Development

### 1. Start Firebase Emulator Suite

The Firebase Emulator Suite allows you to test Cloud Functions, Firestore, Auth, and Storage locally without hitting production.

```bash
# Start emulators (runs on http://localhost:4000)
firebase emulators:start
```

**Emulator Ports**:
- **Emulator UI**: http://localhost:4000 (web interface)
- **Functions**: http://localhost:5001
- **Firestore**: http://localhost:8080
- **Auth**: http://localhost:9099
- **Storage**: http://localhost:9199

### 2. Test Health Check Endpoint

In a new terminal, test the health check endpoint:

```bash
# Health check (should return {"status":"ok","timestamp":"..."})
curl http://localhost:5001/abundance-dev/us-central1/health
```

### 3. Watch Mode for Development

For faster iteration, run TypeScript in watch mode:

```bash
cd functions
npm run build:watch
```

This will automatically recompile TypeScript when you save changes.

### 4. Test with Firestore Data

Use the Emulator UI to add test data:

1. Open http://localhost:4000
2. Go to Firestore tab
3. Add test documents to `users` and `items` collections
4. Test security rules by trying to read/write with different user IDs

---

## Deployment

### Deploy to Development

```bash
# Deploy all components (functions, Firestore rules/indexes, storage rules)
firebase deploy --project abundance-dev
```

### Deploy Specific Components

```bash
# Deploy only functions
firebase deploy --only functions --project abundance-dev

# Deploy only Firestore rules
firebase deploy --only firestore:rules --project abundance-dev

# Deploy only Firestore indexes
firebase deploy --only firestore:indexes --project abundance-dev

# Deploy only Storage rules
firebase deploy --only storage --project abundance-dev
```

### Deploy to Staging

```bash
# Run tests first
cd functions
npm test
cd ..

# Deploy to staging
firebase use abundance-staging
firebase deploy --project abundance-staging
```

### Deploy to Production

**⚠️ WARNING**: Production deployments require confirmation and full testing.

```bash
# Run all checks
cd functions
npm test
npm run lint
cd ..

# Deploy to production
firebase use abundance-prod
firebase deploy --project abundance-prod
```

### Use Deployment Scripts

For convenience, use the deployment scripts:

```bash
# Deploy to dev (fast, no tests)
./deploy-dev.sh

# Deploy to staging (runs tests)
./deploy-staging.sh

# Deploy to production (confirmation prompt + tests + lint)
./deploy-prod.sh
```

---

## Testing

### Unit Tests

```bash
cd functions
npm test
```

### Integration Tests with Emulator

```bash
# Start emulators in test mode
firebase emulators:exec --only functions,firestore,auth,storage "npm test"
```

### Test Security Rules

```bash
# Test Firestore rules
firebase emulators:exec --only firestore "npm run test:rules"

# Test Storage rules
firebase emulators:exec --only storage "npm run test:storage-rules"
```

### Manual API Testing

Use `curl` to test HTTP endpoints:

```bash
# Health check
curl http://localhost:5001/abundance-dev/us-central1/health

# Analyze item (requires auth token)
curl -X POST http://localhost:5001/abundance-dev/us-central1/analyzeItem \
  -H "Authorization: Bearer <firebase-id-token>" \
  -H "Content-Type: application/json" \
  -d '{"imageBase64":"...","barcode":null,"category":"camping"}'
```

---

## Troubleshooting

### Issue 1: Firebase CLI authentication fails

**Symptoms**: `firebase login` doesn't open browser or authentication fails

**Solutions**:
```bash
# Try CI login token
firebase login:ci

# Use --no-localhost flag
firebase login --no-localhost

# Verify authentication
firebase projects:list
```

### Issue 2: Emulators fail to start

**Symptoms**: `firebase emulators:start` fails with port conflicts or Java errors

**Solutions**:
```bash
# Check if ports are in use
lsof -i :5001  # Functions port
lsof -i :8080  # Firestore port

# Kill processes using ports
kill -9 <PID>

# Verify Java is installed (required for Firestore emulator)
java --version  # Should be 11+
```

### Issue 3: TypeScript compilation errors

**Symptoms**: `npm run build` fails with TypeScript errors

**Solutions**:
```bash
cd functions

# Clean build directory
rm -rf lib/

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install

# Run build
npm run build
```

### Issue 4: Firestore index errors

**Symptoms**: Queries fail with "index required" error

**Solutions**:
```bash
# Deploy indexes
firebase deploy --only firestore:indexes --project abundance-dev

# Check index status in Firebase Console
# Indexes can take 5-10 minutes to build
```

### Issue 5: Cloud Functions deployment fails

**Symptoms**: `firebase deploy --only functions` fails

**Solutions**:
```bash
# Check Node.js version (must be 20)
node --version

# Verify package.json engines.node is "20"
cat functions/package.json | grep -A 2 "engines"

# Check Firebase CLI version (must be 13.0.0+)
firebase --version

# Update Firebase CLI
npm install -g firebase-tools@latest
```

### Issue 6: Missing secrets error

**Symptoms**: Cloud Functions fail with "Secret not found" error

**Solutions**:
```bash
# List secrets
gcloud secrets list --project abundance-dev

# Create missing secret
echo -n "your-api-key" | gcloud secrets create ANTHROPIC_API_KEY \
  --data-file=- \
  --project=abundance-dev

# Grant access to Cloud Functions service account
gcloud secrets add-iam-policy-binding ANTHROPIC_API_KEY \
  --member=serviceAccount:abundance-dev@appspot.gserviceaccount.com \
  --role=roles/secretmanager.secretAccessor \
  --project=abundance-dev
```

---

## Architecture Overview

### Backend Components

```
abundance-backend/
├── firestore.rules          # Firestore security rules
├── storage.rules            # Firebase Storage security rules
├── firestore.indexes.json   # Composite indexes
├── firebase.json            # Firebase project configuration
└── functions/
    ├── package.json         # Dependencies (Node.js 20)
    ├── tsconfig.json        # TypeScript configuration
    └── src/
        └── index.ts         # Cloud Functions entry point
```

### Cloud Functions Structure

**HTTP Endpoints** (8 functions):
- `health` - Health check (no auth)
- `analyzeItem` - Create catalog item with Layer 1 results
- `getItem` - Get catalog item by ID
- `listItems` - List user's catalog items (paginated)
- `updateItem` - Update catalog item
- `deleteItem` - Soft delete catalog item
- `getUserProfile` - Get user profile
- `handleStripeWebhook` - Stripe webhook (Phase 2)

**Firestore Triggers** (3 functions):
- `onItemCreated` - Launch Layer 2a (Gemini attribute extraction)
- `onLayer2aComplete` - Launch Layer 2b (SerpAPI product ID)
- `onLayer2bComplete` - Launch Layer 3 (Claude synthesis)

**Scheduled Jobs** (2 functions):
- `cleanupDeletedItems` - Daily at 2:00 AM UTC (delete soft-deleted items > 90 days)
- `checkSubscriptionExpiry` - Daily at 6:00 AM UTC (downgrade expired premium users)

### Firestore Collections

- `users/{userId}` - User profiles and subscription status
- `items/{itemId}` - Catalog items with AI analysis results
- `subscriptions/{subscriptionId}` - Stripe subscription records (Phase 2)

### Security Model

**Row-Level Security**: Users can only read/write their own data (enforced via `request.auth.uid` checks in Firestore rules)

**Storage Access Control**: Users can only upload to their own folder (`users/{userId}/items/{itemId}/*.jpg`)

**API Authentication**: All HTTP endpoints (except health check) require Firebase ID token in `Authorization: Bearer <token>` header

---

## Next Steps

1. **Test locally** with Firebase Emulator Suite
2. **Deploy to dev** environment (`./deploy-dev.sh`)
3. **Verify deployment** with health check endpoint
4. **Add actual implementation** to TODO functions in `functions/src/index.ts` (see CODE-EXAMPLE-005)
5. **Integrate AI providers** (Stage 4.3 - AI Pipeline Integration Scaffolding)

---

## Useful Commands Cheatsheet

```bash
# Firebase CLI
firebase login                           # Authenticate
firebase use <project>                   # Switch project
firebase projects:list                   # List projects
firebase deploy                          # Deploy all
firebase emulators:start                 # Start emulators
firebase functions:log --project <proj>  # View logs

# Cloud Functions
cd functions && npm run build            # Compile TypeScript
cd functions && npm test                 # Run tests
cd functions && npm run lint             # Run linter

# Deployment
./deploy-dev.sh                          # Deploy to dev
./deploy-staging.sh                      # Deploy to staging
./deploy-prod.sh                         # Deploy to production

# Secrets
gcloud secrets list --project <proj>     # List secrets
gcloud secrets describe <name>           # View secret details

# Firestore
firebase firestore:delete <path>         # Delete document
```

---

## Cross-References

### Architecture Documents
- **TECH-STACK-MAP-001**: Complete technology stack
- **DATA-MODEL-001**: Firestore schema
- **SECURITY-RULES-001**: Firestore security rules specification
- **STORAGE-RULES-001**: Firebase Storage security rules specification
- **CODE-EXAMPLE-005**: Cloud Functions implementation patterns
- **INFRASTRUCTURE-001**: GCP deployment automation

### Stage Outputs
- **PLAN-SUMMARY-stage-4.2**: Stage 4.2 plan summary
- **RESEARCH-VALIDATION-stage-4.2**: Technical verification report

---

## Support

**Issues**: If you encounter issues not covered in this guide, check:
- Firebase CLI documentation: https://firebase.google.com/docs/cli
- Cloud Functions documentation: https://firebase.google.com/docs/functions
- Firestore documentation: https://firebase.google.com/docs/firestore

---

**Status**: Ready for backend development
**Version**: 1.0
**Last Updated**: 2025-11-11
