# DEPLOYMENT-001: Backend CI/CD Pipeline

**Created**: 2025-11-08
**Stage**: 2.3 - Backend Cloud Architecture
**Status**: Approved
**References**:
- docs/adr/ADR-002-platform-strategy.md (GCP platform)
- docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md

---

## Environments

| Environment | Firebase Project | GCP Project | Purpose |
|-------------|------------------|-------------|---------|
| **Development** | `abundance-dev` | `abundance-dev-123456` | Local emulators, dev builds |
| **Staging** | `abundance-staging` | `abundance-staging-123456` | Pre-production testing |
| **Production** | `abundance-prod` | `abundance-prod-123456` | Live users |

---

## CI/CD Pipeline (GitHub Actions)

**File**: `.github/workflows/deploy-functions.yml`

```yaml
name: Deploy Cloud Functions

on:
  push:
    branches: [main]
    paths:
      - 'functions/**'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '20'

      - name: Install dependencies
        run: cd functions && npm ci

      - name: Run tests
        run: cd functions && npm test

      - name: Run linter
        run: cd functions && npm run lint

  deploy-staging:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '20'

      - name: Deploy to staging
        run: |
          npm install -g firebase-tools
          firebase deploy --only functions --project abundance-staging
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}

  deploy-production:
    needs: deploy-staging
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '20'

      - name: Deploy to production
        run: |
          npm install -g firebase-tools
          firebase deploy --only functions --project abundance-prod
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}

      - name: Smoke tests
        run: |
          curl https://us-central1-abundance-prod.cloudfunctions.net/api/v1/health
```

---

## Environment Variables

**Set via Firebase CLI**:
```bash
# Production
firebase functions:config:set \
  gemini.api_key="..." \
  anthropic.api_key="..." \
  serpapi.api_key="..." \
  stripe.secret_key="..." \
  stripe.webhook_secret="..." \
  --project abundance-prod

# Staging
firebase functions:config:set \
  gemini.api_key="..." \
  anthropic.api_key="..." \
  serpapi.api_key="..." \
  stripe.secret_key="sk_test_..." \
  stripe.webhook_secret="whsec_test_..." \
  --project abundance-staging
```

---

## Monitoring

**Cloud Logging**: All function logs → BigQuery export
**Cloud Monitoring**: Function latency, error rate dashboards
**Alert Policies**:
- Error rate >5% → Email alert
- P95 latency >2s → Email alert
**Cost Monitoring**: Budget alerts at 50%, 90%, 100% of monthly target

---

## Rollback Strategy

```bash
# List function versions
gcloud functions list --project abundance-prod

# Rollback to previous version
firebase deploy --only functions:api_createItem --project abundance-prod
```

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-08 | 1.0 | Initial deployment architecture | Cloud Backend Architect |
