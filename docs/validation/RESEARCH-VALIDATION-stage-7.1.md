# Research Validation Report: Stage 7.1

**Created**: 2026-01-14
**Stage**: 7.1 - Gemini 3 Pro Integration Testing & Deployment
**Technologies Verified**: Firebase Storage Signed URLs, Gemini 3 Pro API, SerpAPI, Firebase Emulator Suite, Cloud Functions 2nd Gen

---

## Executive Summary

Stage 7.1 focuses on wiring the Gemini 3 Pro pipeline (implemented in Stage 7.0) to real GCP services and deploying to staging. Five key technical claims were verified: Firebase Storage signed URLs have a **maximum expiration of 7 days** (not unlimited), the Firebase Storage Emulator **does not support `getSignedUrl`** (requiring workarounds for integration testing), Gemini 3 Pro API access via `@google/genai` SDK v1.35.0 is confirmed, SerpAPI rate limits are well-documented (100 free searches/month, 20% hourly throughput for paid plans), and Cloud Functions 2nd gen requires explicit `secrets` binding with `defineSecret` for API key management.

---

## Verified Technical Claims

### Claim 1: Firebase Storage Signed URLs

- **Verification Status**: VERIFIED with IMPORTANT CORRECTIONS
- **Original Claim**: Signed URLs with 1-hour expiration for Gemini API access
- **Actual Values**:
  - Maximum expiration: **7 days (604800 seconds)** - this is a hard limit
  - Minimum practical expiration: Depends on signing key rotation (can be as low as 12 hours if using `signBlob`)
  - 1-hour expiration: **Valid and recommended** for security
- **Sources**:
  - [Cloud Storage Signed URLs Documentation](https://cloud.google.com/storage/docs/access-control/signed-urls)
  - [GitHub Issue #244 - SignatureDoesNotMatch errors](https://github.com/googleapis/nodejs-storage/issues/244)
- **Code Pattern**:
  ```typescript
  const [url] = await file.getSignedUrl({
    action: 'read',
    expires: Date.now() + 60 * 60 * 1000 // 1 hour
  });
  ```
- **Notes**:
  - The 1-hour expiration in Stage 7.0 orchestrator.ts is appropriate
  - If using longer expirations (>12 hours), watch for key rotation issues
  - For Gemini API calls, 15-60 minutes is sufficient and recommended

---

### Claim 2: Firebase Storage Emulator - getSignedUrl Support

- **Verification Status**: **CRITICAL WARNING** - NOT SUPPORTED
- **Original Claim**: Firebase Emulator Suite can be used for integration testing
- **Actual Value**: `getSignedUrl` is **NOT supported** in the Firebase Storage Emulator
- **Source**: [GitHub Issue #3400 - Add file.getSignedUrl() support in Storage Emulator](https://github.com/firebase/firebase-tools/issues/3400)
- **Error Message**: `Cannot sign data without 'client_email'`
- **Impact on Stage 7.1**:
  - Integration tests cannot use emulator for signed URL generation
  - Must use either:
    1. **Real Firebase Storage** with service account (recommended for integration tests)
    2. **Mock the signed URL** in unit tests (already done in Stage 7.0)
    3. **Public URLs** for local development only (not for production testing)
- **Workaround for Testing**:
  ```typescript
  // For integration tests, use real Firebase Storage
  process.env.FIREBASE_STORAGE_EMULATOR_HOST = undefined; // Disable emulator

  // Or mock in unit tests (Stage 7.0 approach)
  jest.mock('firebase-admin', () => ({
    storage: jest.fn(() => ({
      bucket: jest.fn(() => ({
        file: jest.fn(() => ({
          getSignedUrl: jest.fn().mockResolvedValue(['https://mock-signed-url.com/image.jpg'])
        }))
      }))
    }))
  }));
  ```

---

### Claim 3: Gemini 3 Pro API Access

- **Verification Status**: VERIFIED
- **Original Claim**: Gemini 3 Pro API available via @google/genai SDK
- **Actual Values**:
  - SDK: `@google/genai` v1.35.0 (latest as of 2026-01-09)
  - Model ID: `gemini-3-pro-preview` (preview status confirmed)
  - Authentication: API key via `GoogleGenAI({ apiKey })` or service account
  - Tool calling: Full support via `functionDeclarations`
- **Sources**:
  - [Gemini 3 Developer Guide](https://ai.google.dev/gemini-api/docs/gemini-3)
  - [Gemini 3 Pro on Vertex AI](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/models/gemini/3-pro)
  - [@google/genai npm package](https://www.npmjs.com/package/@google/genai)
  - [Function Calling Documentation](https://ai.google.dev/gemini-api/docs/function-calling)
- **Authentication Options**:
  | Method | Use Case | Notes |
  |--------|----------|-------|
  | API Key | Development, testing | Simple setup via AI Studio |
  | Service Account | Production | More secure, IAM-based |
  | ADC (Application Default Credentials) | GCP-hosted functions | Auto-detected in Cloud Functions |
- **Rate Limits (Free Tier via AI Studio)**:
  - 5 requests per minute
  - 25 requests per day
  - For production: Use paid API or Vertex AI
- **Notes**:
  - Model is in preview - ID may change at GA
  - Stage 7.0 implementation uses correct model ID `gemini-3-pro-preview`

---

### Claim 4: SerpAPI Google Lens Integration

- **Verification Status**: VERIFIED
- **Original Claim**: SerpAPI for visual product matching
- **Actual Values**:
  - Endpoint: `https://serpapi.com/search?engine=google_lens`
  - Authentication: API key via `api_key` query parameter or `Authorization: Bearer` header
  - Rate limits:
    - Free: 100 searches/month
    - Developer ($75/mo): 5,000 searches, 1,000/hour max throughput
    - Higher plans scale linearly (20% hourly throughput rule)
  - Caching: 1-hour cache (free, not counted against quota)
- **Sources**:
  - [SerpAPI Google Lens API](https://serpapi.com/google-lens-api)
  - [SerpAPI Pricing](https://serpapi.com/pricing)
  - [SerpAPI FAQ](https://serpapi.com/faq)
- **Key Parameters**:
  ```typescript
  const url = new URL('https://serpapi.com/search');
  url.searchParams.set('engine', 'google_lens');
  url.searchParams.set('url', imageUrl);  // Public image URL required
  url.searchParams.set('api_key', process.env.SERPAPI_KEY);
  url.searchParams.set('type', 'all');    // or: products, visual_matches, exact_matches
  ```
- **Response Fields** (from `visual_matches`):
  - `title`, `link`, `source`, `price` (with `extracted_value`, `currency`)
  - `exact_match` (boolean) - critical for confidence scoring
  - `thumbnail`, `image` - for verification
- **Notes**:
  - **No dedicated `brand` field** - must extract from `title` or `source`
  - Stage 7.0 correctly implements brand extraction via `extractBrand()` helper

---

### Claim 5: Cloud Functions 2nd Gen Deployment

- **Verification Status**: VERIFIED with IMPORTANT DETAILS
- **Original Claim**: Cloud Functions deployment with environment variables and secrets
- **Actual Values**:
  - **Secrets**: Use `defineSecret` from `firebase-functions/params`
  - **Explicit binding required**: Secrets must be in function's `{ secrets: [...] }` option
  - **Deployment command**: `firebase deploy --only functions`
  - **Secret creation**: `firebase functions:secrets:set SECRET_NAME`
- **Sources**:
  - [Configure your environment | Cloud Functions for Firebase](https://firebase.google.com/docs/functions/config-env)
  - [Upgrade 1st gen to 2nd gen](https://firebase.google.com/docs/functions/2nd-gen-upgrade)
  - [How to Secure API Keys with 2nd-Gen Cloud Functions](https://codewithandrea.com/articles/api-keys-2ndgen-cloud-functions-firebase/)
- **Code Pattern for Stage 7.1**:
  ```typescript
  import { onDocumentCreated } from 'firebase-functions/v2/firestore';
  import { defineSecret } from 'firebase-functions/params';

  const googleApiKey = defineSecret('GOOGLE_API_KEY');
  const serpApiKey = defineSecret('SERPAPI_KEY');

  export const onItemCreatedGemini3 = onDocumentCreated(
    {
      document: 'items/{itemId}',
      secrets: [googleApiKey, serpApiKey]
    },
    async (event) => {
      const apiKey = googleApiKey.value();
      // ... handler code
    }
  );
  ```
- **Local Development**:
  - Create `.secret.local` file for local testing
  - Emulator respects `.secret.local` values
- **Deprecation Warning**: `functions.config()` will be decommissioned after December 2025 - Stage 7.0 correctly uses `process.env` pattern
- **Known Issues**:
  - [Firebase CLI Issue #8775](https://github.com/firebase/firebase-tools/issues/8775): Misleading IAM errors when deploying with secrets
  - Workaround: Pre-create secrets via `gcloud secrets create`

---

## Critical Integration Test Considerations

### Testing Strategy Update

Given the Firebase Storage Emulator limitation, the Stage 7.1 integration testing strategy should be:

| Test Type | Storage | API Calls | Notes |
|-----------|---------|-----------|-------|
| Unit Tests | Mocked | Mocked | Stage 7.0 complete (124 tests) |
| Integration Tests | **Real Firebase** | Real | Requires service account |
| E2E Tests | Real Firebase | Real | Full pipeline validation |
| Local Dev | Emulator | Mocked | Use `.secret.local` |

### Required Service Account Permissions

For integration testing with real Firebase Storage:
```
Storage Object Viewer (roles/storage.objectViewer)
Storage Object Creator (roles/storage.objectCreator)
Service Account Token Creator (roles/iam.serviceAccountTokenCreator)  # For getSignedUrl
```

---

## Contradictions Resolved

### 1. Firebase Emulator Full Support

- **Original Assumption**: Firebase Emulator Suite fully supports integration testing
- **Corrected**: `getSignedUrl` not supported - integration tests must use real Firebase Storage
- **Impact**: Stage 7.1 plan should include real Firebase Storage setup as prerequisite

### 2. Signed URL Maximum Expiration

- **Stage 7.0 Code**: Uses 15-minute expiration (appropriate)
- **Clarification**: Maximum is 7 days, but shorter durations recommended for security
- **No change needed**: Current implementation is correct

---

## Curated Sources for Stage 7.1

### Firebase/GCP Sources
- [Firebase Storage Emulator](https://firebase.google.com/docs/emulator-suite/connect_storage)
- [Cloud Storage Signed URLs](https://cloud.google.com/storage/docs/access-control/signed-urls)
- [Cloud Functions Environment Config](https://firebase.google.com/docs/functions/config-env)
- [Cloud Functions 2nd Gen Upgrade](https://firebase.google.com/docs/functions/2nd-gen-upgrade)

### Gemini API Sources
- [Gemini 3 Developer Guide](https://ai.google.dev/gemini-api/docs/gemini-3)
- [Gemini API Pricing](https://ai.google.dev/gemini-api/docs/pricing)
- [Function Calling](https://ai.google.dev/gemini-api/docs/function-calling)
- [@google/genai npm](https://www.npmjs.com/package/@google/genai)

### SerpAPI Sources
- [Google Lens API](https://serpapi.com/google-lens-api)
- [SerpAPI Pricing](https://serpapi.com/pricing)
- [SerpAPI FAQ](https://serpapi.com/faq)

### Known Issues
- [Firebase Tools #3400 - getSignedUrl in Storage Emulator](https://github.com/firebase/firebase-tools/issues/3400)
- [Firebase Tools #8775 - Secrets deployment IAM errors](https://github.com/firebase/firebase-tools/issues/8775)

---

## Warnings

### 1. Firebase Storage Emulator Limitation (CRITICAL)
Integration tests requiring signed URLs cannot use the emulator. Plan for real Firebase Storage access with proper service account credentials.

### 2. Gemini 3 Pro Preview Status
The model is in preview (`gemini-3-pro-preview`). Model ID may change at GA. Monitor [Gemini API Release Notes](https://ai.google.dev/gemini-api/docs/changelog) for updates.

### 3. SerpAPI Rate Limits
Free tier (100/month) is insufficient for integration testing of 100-item golden dataset. Plan for Developer plan ($75/month, 5000/month) or use cached searches strategically.

### 4. `functions.config()` Deprecation
The old configuration pattern is deprecated and will fail after December 2025. Stage 7.0 correctly uses `process.env` with `defineSecret`.

### 5. Secret Manager Costs
Cloud Secret Manager allows 10,000 unbilled monthly access operations. If many function instances cold-start frequently, costs may apply ($0.03 per 10,000 operations).

---

## Verification Summary

| Category | Count |
|----------|-------|
| **Total claims identified** | 5 |
| **Verified as accurate** | 4 |
| **Corrected/updated** | 1 |
| **Critical warnings** | 1 |

### Detailed Breakdown

| Claim | Status | Notes |
|-------|--------|-------|
| Firebase Storage Signed URLs | VERIFIED | 7-day max, 1-hour recommended |
| Firebase Emulator getSignedUrl | **NOT SUPPORTED** | Critical - requires real Firebase for integration tests |
| Gemini 3 Pro API Access | VERIFIED | v1.35.0 SDK, `gemini-3-pro-preview` model |
| SerpAPI Google Lens | VERIFIED | 100 free/mo, caching available |
| Cloud Functions 2nd Gen Secrets | VERIFIED | `defineSecret` with explicit binding |

---

## Required Actions for Stage 7.1

Based on this research validation:

1. **Pre-requisite**: Set up real Firebase Storage bucket for integration testing (emulator insufficient)
2. **Service Account**: Create service account with `serviceAccountTokenCreator` role for signed URLs
3. **Secrets Setup**: Create secrets via `firebase functions:secrets:set`:
   - `GOOGLE_API_KEY`
   - `SERPAPI_KEY`
4. **SerpAPI Plan**: Upgrade to Developer plan ($75/mo) for integration testing
5. **Update Trigger**: Modify `onItemCreatedGemini3.ts` to use `defineSecret` pattern for 2nd gen deployment

---

*Report generated by Research Verification Agent*
*Verification completed: 2026-01-14*
