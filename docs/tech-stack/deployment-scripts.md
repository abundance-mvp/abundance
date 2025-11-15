# Deployment Scripts Specification

**Created**: 2025-11-11
**Stage**: 4.2 - Backend Project Scaffolding
**References**: INFRASTRUCTURE-001, PLAN-SUMMARY-stage-4.2

---

## Overview

Deployment scripts for Abundance backend across dev, staging, and production environments.

---

## Prerequisites

- Firebase CLI v13.0.0+ installed (`npm install -g firebase-tools`)
- Node.js 20 installed
- Authenticated with Firebase (`firebase login`)
- Environment variables configured (see .env.template)

---

## Script 1: deploy-dev.sh

**Purpose**: Deploy to development environment (abundance-dev)

**Usage**: `./deploy-dev.sh`

**Script**:

```bash
#!/bin/bash
set -e

echo "🚀 Deploying to DEVELOPMENT (abundance-dev)..."

# Set Firebase project
firebase use abundance-dev

# Deploy all components
firebase deploy \
  --only functions,firestore:rules,firestore:indexes,storage \
  --project abundance-dev

echo "✅ Development deployment complete"
```

**Make executable**:
```bash
chmod +x deploy-dev.sh
```

---

## Script 2: deploy-staging.sh

**Purpose**: Deploy to staging environment (abundance-staging)

**Usage**: `./deploy-staging.sh`

**Script**:

```bash
#!/bin/bash
set -e

echo "🚀 Deploying to STAGING (abundance-staging)..."

# Set Firebase project
firebase use abundance-staging

# Run tests first
cd functions
npm test
cd ..

# Deploy all components
firebase deploy \
  --only functions,firestore:rules,firestore:indexes,storage \
  --project abundance-staging

echo "✅ Staging deployment complete"
```

**Make executable**:
```bash
chmod +x deploy-staging.sh
```

---

## Script 3: deploy-prod.sh

**Purpose**: Deploy to production environment (abundance-prod)

**Usage**: `./deploy-prod.sh`

**Script**:

```bash
#!/bin/bash
set -e

echo "🚀 Deploying to PRODUCTION (abundance-prod)..."
echo "⚠️  WARNING: This will deploy to PRODUCTION. Are you sure? (yes/no)"
read -r confirmation

if [ "$confirmation" != "yes" ]; then
  echo "❌ Deployment cancelled"
  exit 1
fi

# Set Firebase project
firebase use abundance-prod

# Run tests
cd functions
npm test
npm run lint
cd ..

# Deploy all components
firebase deploy \
  --only functions,firestore:rules,firestore:indexes,storage \
  --project abundance-prod \
  --force

echo "✅ Production deployment complete"
echo "📊 View logs: firebase functions:log --project abundance-prod"
```

**Make executable**:
```bash
chmod +x deploy-prod.sh
```

---

## Script 4: test-local.sh

**Purpose**: Start Firebase Emulator Suite for local testing

**Usage**: `./test-local.sh`

**Script**:

```bash
#!/bin/bash
set -e

echo "🧪 Starting Firebase Emulators..."

# Install dependencies
cd functions
npm install
npm run build
cd ..

# Start emulators
firebase emulators:start \
  --only functions,firestore,auth,storage \
  --import=./emulator-data \
  --export-on-exit

echo "🛑 Emulators stopped"
```

**Make executable**:
```bash
chmod +x test-local.sh
```

---

## Script 5: deploy-functions-only.sh

**Purpose**: Deploy only Cloud Functions (faster iteration)

**Usage**: `./deploy-functions-only.sh [project]`

**Script**:

```bash
#!/bin/bash
set -e

PROJECT=${1:-abundance-dev}

echo "🚀 Deploying FUNCTIONS ONLY to $PROJECT..."

firebase use "$PROJECT"

cd functions
npm run build
cd ..

firebase deploy --only functions --project "$PROJECT"

echo "✅ Functions deployment complete"
```

**Make executable**:
```bash
chmod +x deploy-functions-only.sh
```

---

## Deployment Checklist

### Pre-Deployment

- [ ] All tests passing (`npm test`)
- [ ] Linter passing (`npm run lint`)
- [ ] Environment variables configured
- [ ] Secrets updated in Secret Manager (if changed)
- [ ] Code reviewed and approved (staging/production only)

### Post-Deployment

- [ ] Health check endpoint responds (`curl /api/health`)
- [ ] Cloud Functions logs show no errors
- [ ] Firestore queries working (no index errors)
- [ ] Storage uploads working
- [ ] Error rates within SLO (<1%)

---

## Rollback Procedure

If deployment causes issues:

```bash
# 1. Checkout previous Git commit
git checkout <previous-commit-hash>

# 2. Redeploy
./deploy-prod.sh

# 3. Return to main branch
git checkout main
```

---

## CI/CD Integration

See INFRASTRUCTURE-001 for GitHub Actions workflow examples.

**GitHub Actions Deployment**:

```yaml
# .github/workflows/deploy-production.yml
name: Deploy to Production

on:
  push:
    branches:
      - main

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

      - name: Deploy to Production
        run: |
          firebase deploy \
            --only functions,firestore:rules,firestore:indexes,storage \
            --project abundance-prod \
            --non-interactive
        env:
          GOOGLE_APPLICATION_CREDENTIALS: ${{ secrets.GCP_SA_KEY }}
```

---

## Troubleshooting

### Issue 1: Firebase CLI authentication fails

**Solution**: Run `firebase login` and follow the browser authentication flow.

### Issue 2: Firestore indexes not building

**Solution**: Check index status in Firebase Console. Indexes can take minutes to build. Wait for "Index created" status before deploying functions.

### Issue 3: Cloud Functions build errors

**Solution**: Run `npm run build` locally in functions/ directory to see TypeScript compilation errors.

### Issue 4: Missing secrets

**Solution**: Verify secrets exist in Secret Manager:
```bash
gcloud secrets list --project abundance-prod
```

---

## Cross-References

- **INFRASTRUCTURE-001**: GCP deployment automation
- **CODE-EXAMPLE-005**: Cloud Functions patterns
- **PLAN-SUMMARY-stage-4.2**: Stage 4.2 plan summary

---

**Status**: Ready for use after creating actual bash scripts in project root
