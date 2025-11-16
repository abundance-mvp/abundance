# Firebase CI/CD Setup Guide

**Last Updated:** 2025-11-16
**Author:** Claude Code
**Related:** Sprint 5 Tasks 11-12

---

## Overview

This guide walks through setting up automated testing and deployment for Firebase Functions using GitHub Actions.

**Workflows Created:**
1. `firebase-functions-test.yml` - Integration testing with Firebase Emulator
2. `firebase-functions-deploy.yml` - Automated deployment to Firebase

---

## Prerequisites

- Firebase project created (https://console.firebase.google.com)
- GitHub repository with admin access
- Firebase CLI installed: `npm install -g firebase-tools`
- Node.js 20+ installed

---

## Setup Steps

### Step 1: Authenticate Firebase CLI

```bash
# Login to Firebase
firebase login

# Verify you're logged in
firebase projects:list
```

Expected output: List of your Firebase projects

---

### Step 2: Generate Firebase CI Token

The Firebase CI token allows GitHub Actions to deploy without interactive login.

```bash
# Generate CI token
firebase login:ci
```

**Expected output:**
```
✔  Success! Use this token to login on a CI server:

1//0xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

Example: firebase deploy --token "$FIREBASE_TOKEN"
```

**⚠️ Important:**
- Copy this token immediately - it won't be shown again
- Store it securely - it has full access to your Firebase project
- This is a **long-lived token** that doesn't expire

---

### Step 3: Create Firebase Service Account (Optional but Recommended)

Service accounts provide more granular permissions than CI tokens.

**3a. Via Firebase Console:**

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project → Project Settings (⚙️)
3. Navigate to **Service Accounts** tab
4. Click **Generate New Private Key**
5. Download the JSON file (e.g., `abundance-mvp-firebase-adminsdk.json`)

**3b. Via gcloud CLI:**

```bash
# Set your project ID
PROJECT_ID="abundance-mvp"

# Create service account
gcloud iam service-accounts create github-actions-deployer \
  --display-name="GitHub Actions Deployer" \
  --project=$PROJECT_ID

# Grant necessary roles
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions-deployer@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/firebase.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:github-actions-deployer@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/cloudfunctions.admin"

# Generate key
gcloud iam service-accounts keys create ~/firebase-sa-key.json \
  --iam-account=github-actions-deployer@${PROJECT_ID}.iam.gserviceaccount.com
```

**⚠️ Security Warning:**
- Never commit service account JSON to git
- Store securely and delete local copy after uploading to GitHub
- Rotate keys every 90 days

---

### Step 4: Configure GitHub Secrets

**4a. Navigate to GitHub Repository Settings:**

```
https://github.com/woodrowpearson/abundance-mvp/settings/secrets/actions
```

Or manually:
1. Go to your repository on GitHub
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**

**4b. Add Required Secrets:**

#### Secret 1: `FIREBASE_TOKEN`

- **Name:** `FIREBASE_TOKEN`
- **Value:** Paste the CI token from Step 2
- Click **Add secret**

#### Secret 2: `FIREBASE_SERVICE_ACCOUNT`

- **Name:** `FIREBASE_SERVICE_ACCOUNT`
- **Value:** Paste the **entire contents** of the service account JSON file
- Click **Add secret**

**Example JSON structure:**
```json
{
  "type": "service_account",
  "project_id": "abundance-mvp",
  "private_key_id": "abc123...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...",
  "client_email": "github-actions-deployer@abundance-mvp.iam.gserviceaccount.com",
  "client_id": "123456789",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  ...
}
```

**4c. Verify Secrets Added:**

You should see:
- ✅ `FIREBASE_TOKEN`
- ✅ `FIREBASE_SERVICE_ACCOUNT`

---

### Step 5: Configure Firebase Project ID

**5a. Check `.firebaserc` exists:**

```bash
cat .firebaserc
```

**Expected:**
```json
{
  "projects": {
    "default": "abundance-mvp"
  }
}
```

**5b. If `.firebaserc` doesn't exist:**

```bash
# Initialize Firebase (select existing project)
firebase use --add

# Select your project from the list
# Enter alias: default
```

---

### Step 6: Test Integration Test Workflow Locally

Before pushing to GitHub, test the integration workflow locally with Firebase Emulator.

**6a. Start Firebase Emulator:**

```bash
# Terminal 1: Start emulators
firebase emulators:start --only functions,firestore,auth,storage
```

**Expected output:**
```
✔  functions: Emulator started at http://127.0.0.1:5001
✔  firestore: Emulator started at http://127.0.0.1:8080
✔  auth: Emulator started at http://127.0.0.1:9099
✔  storage: Emulator started at http://127.0.0.1:9199
✔  Emulator UI running at http://127.0.0.1:4000
```

**6b. Run Integration Tests:**

```bash
# Terminal 2: Run integration tests
cd functions
npm run test:integration
```

**Expected output:**
```
PASS src/__tests__/pipeline-integration.test.ts
  Full AI Pipeline Integration
    ✓ completes full pipeline: Layer 1 → 2a → 2b → 3 (5000ms)

Test Suites: 1 passed, 1 total
Tests:       1 passed, 1 total
```

---

### Step 7: Test Deployment Workflow Locally

**7a. Build Functions:**

```bash
cd functions
npm run build
```

**Expected:** No TypeScript errors

**7b. Deploy to Firebase (Dry Run):**

```bash
firebase deploy --only functions --dry-run
```

**Expected:**
```
=== Deploying to 'abundance-mvp'...

i  functions: preparing codebase for deployment...
✔  functions: functions folder uploaded successfully
```

**7c. Deploy for Real:**

```bash
firebase deploy --only functions
```

**Expected:**
```
✔  Deploy complete!

Project Console: https://console.firebase.google.com/project/abundance-mvp/overview
Function URL (createItemHTTP): https://us-central1-abundance-mvp.cloudfunctions.net/createItemHTTP
```

---

### Step 8: Trigger GitHub Actions Workflows

**8a. Test Integration Workflow (Automatic):**

Create a PR that modifies `functions/` code:

```bash
git checkout -b test/ci-cd-integration
echo "// test change" >> functions/src/index.ts
git add functions/src/index.ts
git commit -m "test: trigger CI/CD integration workflow"
git push origin test/ci-cd-integration
```

Then create a PR on GitHub. The **Firebase Functions Integration Tests** workflow should trigger automatically.

**8b. Test Deployment Workflow (Manual):**

1. Go to **Actions** tab in GitHub
2. Select **Deploy Firebase Functions** workflow
3. Click **Run workflow**
4. Select branch: `main`
5. Select environment: `production` or `staging`
6. Click **Run workflow**

**8c. Monitor Workflow Execution:**

Watch the workflow run in real-time:
```
https://github.com/woodrowpearson/abundance-mvp/actions
```

---

## Workflow Details

### Integration Test Workflow

**Trigger:**
- Pull requests modifying `functions/**`, `firestore.rules`, `storage.rules`
- Push to `main` branch

**Steps:**
1. Checkout code
2. Set up Node.js 20
3. Install Firebase CLI
4. Install function dependencies
5. Build TypeScript
6. Run unit tests
7. Start Firebase Emulators
8. Run integration tests
9. Stop emulators
10. Upload test artifacts

**Duration:** ~2-3 minutes

---

### Deployment Workflow

**Trigger:**
- Automatic: Push to `main` with changes to `functions/**`
- Manual: Workflow dispatch (supports staging/production)

**Steps:**
1. Checkout code
2. Set up Node.js 20
3. Install Firebase CLI
4. Install dependencies
5. Build TypeScript
6. Run tests
7. Authenticate to Firebase
8. Deploy Functions
9. Deploy Firestore rules
10. Deploy Storage rules
11. Post-deployment validation
12. Create deployment summary

**Duration:** ~3-5 minutes

---

## Troubleshooting

### Issue 1: "FIREBASE_TOKEN is not set"

**Error:**
```
Error: HTTP Error: 401, Request had invalid authentication credentials.
```

**Solution:**
1. Verify secret exists: GitHub → Settings → Secrets → Actions
2. Regenerate token: `firebase login:ci`
3. Update GitHub secret with new token

---

### Issue 2: "Permission denied" during deployment

**Error:**
```
Error: HTTP Error: 403, The caller does not have permission
```

**Solution:**
1. Check service account has correct roles:
   - `roles/firebase.admin`
   - `roles/cloudfunctions.admin`
2. Verify service account JSON is valid (no truncation)
3. Check `.firebaserc` has correct project ID

---

### Issue 3: Emulator fails to start in CI

**Error:**
```
Error: Could not start emulator. Port 8080 already in use.
```

**Solution:**
The workflow handles this automatically with:
```yaml
timeout-minutes: 2
```

If issue persists, check for zombie processes:
```bash
lsof -ti:8080 | xargs kill -9
```

---

### Issue 4: Functions build fails

**Error:**
```
Error: TypeScript compilation failed
```

**Solution:**
1. Run locally first: `npm run build`
2. Fix TypeScript errors
3. Ensure `tsconfig.json` is committed
4. Verify `node_modules` not committed (in `.gitignore`)

---

### Issue 5: Integration tests timeout

**Error:**
```
Error: Timeout - Async callback was not invoked within the 60000 ms timeout
```

**Solution:**
1. Check Firebase emulator is running
2. Verify `FIRESTORE_EMULATOR_HOST=localhost:8080`
3. Increase timeout: `jest.setTimeout(120000)`
4. Check function triggers are registered

---

### Issue 6: "Module not found" during tests

**Error:**
```
Cannot find module '@anthropic-ai/sdk'
```

**Solution:**
1. Ensure `npm ci` runs before tests
2. Check `package-lock.json` is committed
3. Verify Node.js version matches (20)
4. Clear cache and reinstall:
   ```bash
   rm -rf node_modules package-lock.json
   npm install
   ```

---

## Security Best Practices

### 1. Rotate Secrets Regularly

**Every 90 days:**
- Regenerate Firebase CI token
- Rotate service account keys
- Update GitHub secrets

```bash
# Revoke old tokens
firebase logout

# Generate new token
firebase login:ci

# Update GitHub secret
```

---

### 2. Limit Service Account Permissions

**Principle of Least Privilege:**
- Only grant necessary roles
- Use separate service accounts for staging/production
- Never grant `roles/owner` or `roles/editor`

**Required roles:**
```
roles/firebase.admin
roles/cloudfunctions.admin
roles/firestore.rulesAdmin
roles/storage.admin
```

---

### 3. Environment-Specific Secrets

For staging vs. production:

**Option 1: GitHub Environments**
1. Create environments: Settings → Environments → New environment
2. Add environment-specific secrets
3. Update workflow:
   ```yaml
   environment: ${{ github.event.inputs.environment || 'production' }}
   ```

**Option 2: Separate Repositories**
- `abundance-mvp-staging` (staging project)
- `abundance-mvp` (production project)

---

### 4. Secret Scanning

Enable GitHub secret scanning:
1. Settings → Code security and analysis
2. Enable **Secret scanning**
3. Enable **Push protection**

This prevents accidental commits of:
- Firebase tokens
- Service account keys
- API keys

---

### 5. Audit Logs

Monitor deployments:
1. **Firebase Console:** Console → Usage and billing → Usage
2. **GitHub Actions:** Actions tab → Workflow runs
3. **GCP Audit Logs:** Cloud Console → Logging → Logs Explorer

---

## Monitoring and Alerts

### Set Up Deployment Alerts

**GitHub Actions Notifications:**
1. GitHub → Settings → Notifications
2. Enable **Actions** notifications
3. Choose email or mobile

**Firebase Alerts:**
1. Firebase Console → Alerts
2. Create alert: "Function deployment failed"
3. Set notification channels (email, Slack, PagerDuty)

---

## Next Steps

After setup is complete:

1. ✅ Merge PR #15 (Sprint 5 implementation)
2. ✅ Monitor first automated deployment
3. ✅ Set up staging environment
4. ✅ Configure deployment approvals for production
5. ✅ Add health check endpoints
6. ✅ Implement rollback strategy

---

## Additional Resources

**Firebase Documentation:**
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)
- [Functions Deployment](https://firebase.google.com/docs/functions/deployment-and-runtime-options)
- [Service Accounts](https://firebase.google.com/docs/admin/setup#initialize-sdk)

**GitHub Actions:**
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)

**Google Cloud:**
- [IAM Roles](https://cloud.google.com/iam/docs/understanding-roles)
- [Service Account Best Practices](https://cloud.google.com/iam/docs/best-practices-service-accounts)

---

**Questions or Issues?**
- Create GitHub issue: https://github.com/woodrowpearson/abundance-mvp/issues
- Check workflow logs: https://github.com/woodrowpearson/abundance-mvp/actions

---

*Generated with [Claude Code](https://claude.com/claude-code)*
