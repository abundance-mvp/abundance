# PLAN-SUMMARY: Stage 7.1 - Gemini 3 Pro Integration Testing & Deployment

**Created**: 2026-01-14
**Stage**: 7.1 - Gemini 3 Pro Integration Testing & Deployment
**Status**: Planning Complete
**Full Plan**: docs/plans/2026-01-14-stage-7.1-gemini-integration-deployment.md
**Research Validation**: docs/validation/RESEARCH-VALIDATION-stage-7.1.md

---

## What This Stage Accomplishes

Stage 7.1 wires the Stage 7.0 Gemini 3 Pro implementation to real GCP services and deploys to staging. Key activities:

- **Merge Stage 7.0**: Bring `feature/stage-7.0-gemini-3-pro` branch into main
- **Update for 2nd Gen Deployment**: Modify trigger to use `defineSecret` pattern (required for Cloud Functions 2nd gen)
- **Integration Testing**: Create tests that use real Firebase Storage (emulator doesn't support `getSignedUrl`)
- **Secrets Configuration**: Set up `GOOGLE_API_KEY` and `SERPAPI_KEY` via Firebase CLI
- **Staging Deployment**: Deploy `onItemCreatedGemini3` trigger to staging environment
- **Smoke Testing**: Verify end-to-end pipeline with real Firestore documents

---

## Key Decisions Made

### 1. Real Firebase Storage for Integration Tests
- **Decision**: Use real Firebase Storage instead of emulator for integration tests
- **Rationale**: Firebase Storage Emulator does NOT support `getSignedUrl` (GitHub issue #3400)
- **Impact**: Requires service account with `serviceAccountTokenCreator` role for local testing
- **Source**: RESEARCH-VALIDATION-stage-7.1.md, Claim 2

### 2. defineSecret Pattern for Secrets
- **Decision**: Use `defineSecret` from `firebase-functions/params` for API keys
- **Rationale**: `functions.config()` deprecated after December 2025; 2nd gen requires explicit secrets binding
- **Impact**: Trigger must declare secrets in options: `{ secrets: [googleApiKey, serpApiKey] }`
- **Source**: RESEARCH-VALIDATION-stage-7.1.md, Claim 5

### 3. Separate Integration Test Config
- **Decision**: Create `jest.integration.config.js` for integration tests
- **Rationale**: Integration tests require longer timeouts (60s) and real credentials
- **Impact**: Unit tests remain fast; integration tests run separately with `npm run test:integration`

---

## Outputs to Be Created

**New Files (6 total):**
- `functions/src/triggers/__tests__/onItemCreatedGemini3.test.ts` - Trigger unit tests
- `functions/src/ai-pipeline/__tests__/integration-setup.ts` - Integration test utilities
- `functions/src/ai-pipeline/gemini/__tests__/gemini-pipeline.integration.test.ts` - Full pipeline integration test
- `functions/jest.integration.config.js` - Jest config for integration tests
- `functions/.env.integration.example` - Template for integration test credentials
- `docs/tech-stack/DEPLOYMENT-RUNBOOK-gemini-3-pro.md` - Deployment documentation

**Modified Files:**
- `functions/src/triggers/onItemCreatedGemini3.ts` - Update to use defineSecret
- `functions/package.json` - Add test:integration script
- `functions/.gitignore` - Exclude integration credentials

---

## Critical Findings from Research

| Claim | Status | Impact |
|-------|--------|--------|
| Firebase Emulator getSignedUrl | **NOT SUPPORTED** | Must use real Firebase Storage for integration tests |
| Gemini 3 Pro API | VERIFIED | Model ID: `gemini-3-pro-preview`, SDK v1.35.0 |
| SerpAPI Rate Limits | VERIFIED | Free: 100/mo (insufficient); Developer $75/mo: 5000/mo |
| defineSecret Pattern | VERIFIED | Required for 2nd gen Cloud Functions |
| Signed URL Max Expiration | VERIFIED | 7 days max; 1-hour recommended |

---

## Dependencies

| Dependency | Status | Notes |
|------------|--------|-------|
| Stage 7.0 feature branch | Exists | `feature/stage-7.0-gemini-3-pro` - 830 lines added |
| Google AI Studio API key | Required | For Gemini 3 Pro API calls |
| SerpAPI key | Required | Developer plan ($75/mo) recommended |
| Firebase project | Required | `abundance-staging` for deployment |
| Service account | Required | With `serviceAccountTokenCreator` role |

---

## Next Stage Preview

**Stage 7.2**: iOS Client Integration (tentative)
- Update iOS app to work with new Gemini 3 trigger
- Handle new `catalog` field structure in Firestore
- UI updates for CatalogItem schema (subCategory, dimensions, confidence)
- SwiftUI views for displaying AI-generated metadata

---

## Cost Estimates

| Component | Cost per Item |
|-----------|---------------|
| Gemini 3 Pro API | ~$0.02-0.03 |
| SerpAPI (Google Lens) | ~$0.01 |
| Firebase Storage | ~$0.001 |
| **Total** | **~$0.03-0.04** |

Monthly estimate (1000 items): ~$30-40

---

**This plan provides complete integration and deployment steps for the Gemini 3 Pro pipeline implemented in Stage 7.0.**
