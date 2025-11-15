# AI Pipeline Setup Guide

**Created**: 2025-11-11
**Stage**: 4.3 - AI Pipeline Integration Scaffolding
**References**:
- docs/validation/RESEARCH-VALIDATION-stage-4.3.md
- docs/tech-stack/ai-pipeline-project-structure.md
- docs/tech-stack/ai-provider-adapters.md
**Status**: Draft

## Overview

This guide walks through setting up the AI pipeline Cloud Functions for local development and deployment. The pipeline uses Google Generative AI (Gemini), Anthropic (Claude), SerpAPI (Google Lens), and barcode lookup services.

**IMPORTANT**: This project uses the current `@google/genai` SDK (v1.29.0+), not the deprecated `@google-cloud/vertexai` package.

## Prerequisites

### Required Software

- **Node.js 20**: Download from [nodejs.org](https://nodejs.org/)
- **Firebase CLI**: Install with `npm install -g firebase-tools`
- **Git**: For version control

### Required Accounts & API Keys

1. **Google Cloud Platform**
   - Create project at [console.cloud.google.com](https://console.cloud.google.com/)
   - Enable Generative Language API
   - Get API key: [aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)

2. **Anthropic**
   - Sign up at [console.anthropic.com](https://console.anthropic.com/)
   - Get API key from Settings → API Keys

3. **SerpAPI** (optional, for Google Lens visual search)
   - Sign up at [serpapi.com](https://serpapi.com/)
   - Get API key from [serpapi.com/manage-api-key](https://serpapi.com/manage-api-key)
   - Pricing: $50/5000 searches = $0.01 per search

4. **UPCitemdb** (optional, for paid barcode lookup)
   - Sign up at [upcitemdb.com](https://www.upcitemdb.com/)
   - Get API key from API section
   - Pricing: 100 free calls/day, then $0.002 per call

## Installation

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/abundance.git
cd abundance/functions
```

### 2. Install Dependencies

```bash
npm install
```

This installs:
- `@google/genai` (v1.29.0+) - Google Generative AI SDK
- `@anthropic-ai/sdk` (v0.68.0+) - Anthropic Claude SDK
- `firebase-admin` - Firebase Admin SDK
- `firebase-functions` - Cloud Functions SDK
- TypeScript, Jest, ESLint

### 3. Configure Environment Variables

Copy the template and fill in your API keys:

```bash
cp .env.template .env
```

Edit `.env`:

```bash
# Required
GOOGLE_API_KEY=your_google_api_key_here
ANTHROPIC_API_KEY=your_anthropic_api_key_here

# Optional (for visual search)
SERPAPI_API_KEY=your_serpapi_api_key_here

# Optional (for paid barcode lookup)
UPCITEMDB_API_KEY=your_upcitemdb_api_key_here

# GCP Project
GCP_PROJECT_ID=abundance-prod
GCP_REGION=us-central1

# Feature flags
BATCH_API_ENABLED=false
VISUAL_SEARCH_ENABLED=true
BARCODE_DETECTION_ENABLED=true
```

**IMPORTANT**: Never commit `.env` to version control! It should already be in `.gitignore`.

### 4. Set Up Firebase

Login to Firebase:

```bash
firebase login
```

Select your Firebase project:

```bash
firebase use --add
# Select "abundance-prod" or your project ID
```

### 5. Install Firebase Emulator Suite

```bash
firebase init emulators
```

Select:
- Firestore Emulator
- Storage Emulator
- Functions Emulator

Default ports:
- Firestore: 8080
- Storage: 9199
- Functions: 5001

## Development Workflow

### 1. Start Firebase Emulators

In one terminal:

```bash
npm run serve
```

This runs:
- `npm run build` - Compile TypeScript
- `firebase emulators:start --only functions,firestore,storage`

Output should show:
```
✔ functions[us-central1-layer2aOrchestrator]: http function initialized
✔ functions[us-central1-layer2bOrchestrator]: http function initialized
✔ functions[us-central1-layer3Orchestrator]: http function initialized
```

Emulator UI: [http://localhost:4000](http://localhost:4000)

### 2. Run Tests

In another terminal:

```bash
# Run all tests
npm test

# Run with coverage
npm run test:coverage

# Run in watch mode (TDD)
npm run test:watch

# Run specific test file
npm test -- gemini-provider.test.ts
```

### 3. Test with Emulator UI

1. Open [http://localhost:4000](http://localhost:4000)
2. Go to Firestore tab
3. Create test document in `/items` collection:

```json
{
  "user_id": "test-user",
  "photo_url": "https://storage.googleapis.com/abundance-test/sample.jpg",
  "status": "pending",
  "created_at": "2025-11-11T00:00:00.000Z"
}
```

4. Watch Functions tab for triggered execution
5. Check Firestore for updated document (should have `layer2a_complete: true`)

### 4. Check Logs

```bash
# Local logs (in emulator terminal)
# Watch for console.log() output

# Production logs (after deployment)
firebase functions:log
```

## Deployment

### 1. Build Production Code

```bash
npm run build
```

This compiles TypeScript to `lib/` directory.

### 2. Deploy to Cloud Functions

```bash
# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:layer2aOrchestrator
```

Deployment output:
```
✔ functions[us-central1-layer2aOrchestrator]: Successful create operation.
Function URL (layer2aOrchestrator): https://us-central1-abundance-prod.cloudfunctions.net/layer2aOrchestrator
```

### 3. Set Environment Variables in Production

**IMPORTANT**: Don't use `.env` in production! Use Firebase config:

```bash
firebase functions:config:set \
  google.api_key="your_google_api_key" \
  anthropic.api_key="your_anthropic_api_key" \
  serpapi.api_key="your_serpapi_api_key"

# Deploy to apply config changes
firebase deploy --only functions
```

Access in code:

```typescript
const googleApiKey = functions.config().google.api_key;
const anthropicApiKey = functions.config().anthropic.api_key;
```

### 4. Monitor Production

```bash
# View logs
firebase functions:log

# View logs for specific function
firebase functions:log --only layer2aOrchestrator

# Follow logs in real-time
firebase functions:log --follow
```

## Architecture Overview

```
User uploads photo
     ↓
Layer 1: iOS (AVFoundation) crops photo
     ↓
Firestore: /items/{itemId} created with photo_url
     ↓
Layer 2a: Gemini 2.5 Flash-Lite extracts attributes
     ↓
Firestore: /items/{itemId} updated with attributes
     ↓
Layer 2b: SerpAPI + Barcode lookup for enrichment
     ↓
Firestore: /items/{itemId} updated with enriched data
     ↓
Layer 3: Claude Sonnet 4.5 synthesizes final metadata
     ↓
Firestore: /items/{itemId} finalized
     ↓
iOS app displays final metadata
```

## Cost Estimation

Based on verified pricing (as of 2025-11-11):

### Per-Item Cost Breakdown

| Provider | Layer | Input | Output | Cost per Item |
|----------|-------|--------|--------|---------------|
| Gemini 2.5 Flash-Lite | 2a | 258 tokens | 100 tokens | $0.00007 |
| Claude Haiku 4.5 | 2b | 200 tokens | 100 tokens | $0.00056 |
| Claude Sonnet 4.5 | 3 | 500 tokens | 300 tokens | $0.00600 |
| SerpAPI (optional) | 2b | - | - | $0.01000 |
| UPCitemdb (optional) | 2b | - | - | $0.00200 |

**Total per item**:
- Without optional APIs: $0.00663 (~$0.007)
- With visual search: $0.01663 (~$0.017)
- With all APIs: $0.01863 (~$0.019)

**Monthly costs** (assuming 1000 items/month):
- Base: $6.63
- With visual search: $16.63
- With all APIs: $18.63

**Cost savings**: Use Claude Sonnet Batch API for 50% discount on Layer 3 (reduces to $0.003 per item).

## Troubleshooting

### Error: "API key not found"

**Symptom**: Functions fail with "Missing API key" error

**Solution**:
1. Check `.env` file exists and has correct keys
2. For production, set config: `firebase functions:config:set google.api_key="..."`
3. Redeploy: `firebase deploy --only functions`

### Error: "Module not found: @google/genai"

**Symptom**: TypeScript compilation fails or runtime import error

**Solution**:
1. Delete `node_modules` and `package-lock.json`
2. Run `npm install` again
3. Verify `package.json` has `"@google/genai": "^1.29.0"`
4. Do NOT use deprecated `@google-cloud/vertexai`

### Error: "ECONNREFUSED localhost:8080"

**Symptom**: Tests fail with connection refused

**Solution**:
1. Start Firebase Emulator: `npm run serve`
2. Verify emulators are running in browser: [http://localhost:4000](http://localhost:4000)
3. Check `.env` has `FIRESTORE_EMULATOR_HOST=localhost:8080`

### Error: "Rate limit exceeded" (429)

**Symptom**: API calls fail with 429 status code

**Solution**:
1. Implemented exponential backoff (automatic retry)
2. Check quota in GCP Console / Anthropic Console
3. Request quota increase if needed
4. Consider caching responses in Firestore

### Error: "Image too large" (413)

**Symptom**: Gemini API rejects image

**Solution**:
1. Verify Layer 1 (iOS) crops image to 1024x1024 max
2. Check image file size < 4MB
3. Compress JPEG with quality=0.8

## Next Steps

1. Implement provider classes (Task 3 from plan)
2. Implement orchestrator functions (Task 4)
3. Set up cost tracking (Task 6)
4. Add error handling with retry logic (Task 10)
5. Deploy to production and monitor costs

## Additional Resources

- **Google Generative AI SDK**: [ai.google.dev/gemini-api/docs/quickstart?lang=node](https://ai.google.dev/gemini-api/docs/quickstart?lang=node)
- **Anthropic SDK**: [docs.anthropic.com/en/api/client-sdks](https://docs.anthropic.com/en/api/client-sdks)
- **SerpAPI Docs**: [serpapi.com/google-lens-api](https://serpapi.com/google-lens-api)
- **Firebase Functions**: [firebase.google.com/docs/functions](https://firebase.google.com/docs/functions)
- **Open Food Facts API**: [wiki.openfoodfacts.org/API](https://wiki.openfoodfacts.org/API)

---

**Last Updated**: 2025-11-11
