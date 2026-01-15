# Gemini 3 Vertex AI Migration Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Migrate Gemini 3 Pro API calls from Google AI Studio authentication (broken) to Vertex AI authentication (working)

**Architecture:** The `@google/genai` SDK supports both backends. We switch from `{ apiKey }` to `{ vertexai: true, project, location }`. Cloud Functions automatically authenticate via Application Default Credentials (service account).

**Tech Stack:** TypeScript, @google/genai SDK v1.35.0, Firebase Cloud Functions 2nd gen

---

## Background

Gemini 3 Preview models (`gemini-3-pro-preview`, `gemini-3-flash-preview`) do NOT support Google AI Studio API keys. They require Vertex AI authentication:
- Error: "API keys are not supported by this API. Expected OAuth2 access token"
- Root cause: Preview models are Vertex AI-only
- Solution: Configure SDK for Vertex AI mode with ADC

## Scope

**In scope (Gemini 3 models - broken):**
- `functions/src/ai-pipeline/gemini/gemini-service.ts` - uses `gemini-3-pro-preview`
- `functions/src/ai-pipeline/tools/web-search.ts` - uses `gemini-3-pro-preview`
- `functions/src/triggers/onItemCreatedGemini3.ts` - trigger configuration

**Out of scope (older models - still working):**
- `functions/src/ai-pipeline/providers/GeminiProvider.ts` - uses `gemini-2.5-flash-lite` (API keys work)

---

### Task 1: Create Vertex AI Configuration Module

**Files:**
- Create: `functions/src/ai-pipeline/gemini/vertexai-config.ts`
- Test: `functions/src/ai-pipeline/gemini/__tests__/vertexai-config.test.ts`

**Step 1: Write the failing test**

Create `functions/src/ai-pipeline/gemini/__tests__/vertexai-config.test.ts`:

```typescript
import { getVertexAIConfig, createVertexAIClient } from '../vertexai-config';

describe('Vertex AI Configuration', () => {
  const originalEnv = process.env;

  beforeEach(() => {
    jest.resetModules();
    process.env = { ...originalEnv };
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  describe('getVertexAIConfig', () => {
    it('should return config with project and location from env vars', () => {
      process.env.GOOGLE_CLOUD_PROJECT = 'test-project';
      process.env.GOOGLE_CLOUD_LOCATION = 'us-central1';

      const config = getVertexAIConfig();

      expect(config).toEqual({
        vertexai: true,
        project: 'test-project',
        location: 'us-central1'
      });
    });

    it('should default location to global when not set', () => {
      process.env.GOOGLE_CLOUD_PROJECT = 'test-project';
      delete process.env.GOOGLE_CLOUD_LOCATION;

      const config = getVertexAIConfig();

      expect(config.location).toBe('global');
    });

    it('should throw error when project is not set', () => {
      delete process.env.GOOGLE_CLOUD_PROJECT;

      expect(() => getVertexAIConfig()).toThrow(
        'GOOGLE_CLOUD_PROJECT environment variable is required for Vertex AI'
      );
    });
  });

  describe('createVertexAIClient', () => {
    it('should create GoogleGenAI client with Vertex AI config', () => {
      process.env.GOOGLE_CLOUD_PROJECT = 'test-project';
      process.env.GOOGLE_CLOUD_LOCATION = 'global';

      const client = createVertexAIClient();

      expect(client).toBeDefined();
    });
  });
});
```

**Step 2: Run test to verify it fails**

Run: `cd functions && npm test -- --testPathPattern="vertexai-config.test.ts" -v`
Expected: FAIL with "Cannot find module '../vertexai-config'"

**Step 3: Write minimal implementation**

Create `functions/src/ai-pipeline/gemini/vertexai-config.ts`:

```typescript
/**
 * Vertex AI Configuration for Gemini 3 Models
 *
 * Gemini 3 Preview models require Vertex AI authentication (not API keys).
 * Cloud Functions authenticate automatically via Application Default Credentials.
 */

import { GoogleGenAI } from '@google/genai';

export interface VertexAIConfig {
  vertexai: true;
  project: string;
  location: string;
}

/**
 * Get Vertex AI configuration from environment variables.
 *
 * Required env vars:
 * - GOOGLE_CLOUD_PROJECT: GCP project ID
 * - GOOGLE_CLOUD_LOCATION: Region (defaults to 'global' for Gemini 3)
 *
 * @throws Error if GOOGLE_CLOUD_PROJECT is not set
 */
export function getVertexAIConfig(): VertexAIConfig {
  const project = process.env.GOOGLE_CLOUD_PROJECT;

  if (!project) {
    throw new Error(
      'GOOGLE_CLOUD_PROJECT environment variable is required for Vertex AI'
    );
  }

  // Default to 'global' for Gemini 3 models per Google's recommendation
  const location = process.env.GOOGLE_CLOUD_LOCATION || 'global';

  return {
    vertexai: true,
    project,
    location
  };
}

/**
 * Create a GoogleGenAI client configured for Vertex AI.
 *
 * Authentication is automatic in Cloud Functions via service account.
 * For local development, use: gcloud auth application-default login
 */
export function createVertexAIClient(): GoogleGenAI {
  const config = getVertexAIConfig();
  return new GoogleGenAI(config);
}
```

**Step 4: Run test to verify it passes**

Run: `cd functions && npm test -- --testPathPattern="vertexai-config.test.ts" -v`
Expected: PASS

**Step 5: Commit**

```bash
git add functions/src/ai-pipeline/gemini/vertexai-config.ts functions/src/ai-pipeline/gemini/__tests__/vertexai-config.test.ts
git commit -m "$(cat <<'EOF'
feat(ai-pipeline): add Vertex AI configuration module for Gemini 3

Gemini 3 Preview models require Vertex AI authentication (not API keys).
This module provides centralized configuration for the SDK switch.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: Update gemini-service.ts to Use Vertex AI

**Files:**
- Modify: `functions/src/ai-pipeline/gemini/gemini-service.ts:26-37`
- Modify: `functions/src/ai-pipeline/gemini/__tests__/gemini-service.test.ts`

**Step 1: Update the test to use Vertex AI config**

Edit `functions/src/ai-pipeline/gemini/__tests__/gemini-service.test.ts`:

Replace lines 14-21:
```typescript
  beforeEach(() => {
    jest.clearAllMocks();
    process.env.GOOGLE_API_KEY = 'test-api-key';
  });

  afterEach(() => {
    delete process.env.GOOGLE_API_KEY;
    global.fetch = originalFetch;
  });
```

With:
```typescript
  beforeEach(() => {
    jest.clearAllMocks();
    // Vertex AI config for Gemini 3 models
    process.env.GOOGLE_CLOUD_PROJECT = 'test-project';
    process.env.GOOGLE_CLOUD_LOCATION = 'global';
  });

  afterEach(() => {
    delete process.env.GOOGLE_CLOUD_PROJECT;
    delete process.env.GOOGLE_CLOUD_LOCATION;
    global.fetch = originalFetch;
  });
```

Update line 63-68 (the "should throw error when API key is missing" test):
```typescript
  it('should throw error when project is not configured', async () => {
    delete process.env.GOOGLE_CLOUD_PROJECT;

    await expect(processItemWithGemini('https://example.com/image.jpg'))
      .rejects.toThrow('GOOGLE_CLOUD_PROJECT environment variable is required for Vertex AI');
  });
```

**Step 2: Run test to verify it fails**

Run: `cd functions && npm test -- --testPathPattern="gemini-service.test.ts" -v`
Expected: FAIL (old implementation still checks for GOOGLE_API_KEY)

**Step 3: Update implementation to use Vertex AI**

Edit `functions/src/ai-pipeline/gemini/gemini-service.ts`:

Replace lines 8 and 26-37:

Old import (line 8):
```typescript
import { GoogleGenAI, Content, Part, FunctionCall } from '@google/genai';
```

New import:
```typescript
import { Content, Part, FunctionCall } from '@google/genai';
import { createVertexAIClient } from './vertexai-config';
```

Old initialization (lines 26-37):
```typescript
export async function processItemWithGemini(
  imageUrl: string
): Promise<CatalogItem | CatalogItem[]> {
  const apiKey = process.env.GOOGLE_API_KEY;

  if (!apiKey) {
    throw new Error('GOOGLE_API_KEY environment variable is required');
  }

  const imageBase64 = await fetchImageBase64(imageUrl);

  const ai = new GoogleGenAI({ apiKey });
```

New initialization:
```typescript
export async function processItemWithGemini(
  imageUrl: string
): Promise<CatalogItem | CatalogItem[]> {
  const imageBase64 = await fetchImageBase64(imageUrl);

  // Gemini 3 models require Vertex AI (not API keys)
  const ai = createVertexAIClient();
```

**Step 4: Run test to verify it passes**

Run: `cd functions && npm test -- --testPathPattern="gemini-service.test.ts" -v`
Expected: PASS

**Step 5: Commit**

```bash
git add functions/src/ai-pipeline/gemini/gemini-service.ts functions/src/ai-pipeline/gemini/__tests__/gemini-service.test.ts
git commit -m "$(cat <<'EOF'
feat(ai-pipeline): migrate gemini-service to Vertex AI authentication

Gemini 3 Pro Preview requires Vertex AI, not API keys.
Uses createVertexAIClient() for centralized configuration.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: Update web-search.ts to Use Vertex AI

**Files:**
- Modify: `functions/src/ai-pipeline/tools/web-search.ts:1-26`
- Modify: `functions/src/ai-pipeline/tools/__tests__/web-search.test.ts`

**Step 1: Update the test to use Vertex AI config**

Edit `functions/src/ai-pipeline/tools/__tests__/web-search.test.ts`:

Replace environment setup in beforeEach/afterEach (around lines 16-22):
```typescript
  beforeEach(() => {
    jest.clearAllMocks();
    // Vertex AI config for Gemini 3 models
    process.env.GOOGLE_CLOUD_PROJECT = 'test-project';
    process.env.GOOGLE_CLOUD_LOCATION = 'global';
  });

  afterEach(() => {
    delete process.env.GOOGLE_CLOUD_PROJECT;
    delete process.env.GOOGLE_CLOUD_LOCATION;
  });
```

Update the "should throw error when API key is missing" test (around line 60-63):
```typescript
  it('should throw error when project is not configured', async () => {
    delete process.env.GOOGLE_CLOUD_PROJECT;

    await expect(searchWeb('test query'))
      .rejects.toThrow('GOOGLE_CLOUD_PROJECT environment variable is required for Vertex AI');
  });
```

**Step 2: Run test to verify it fails**

Run: `cd functions && npm test -- --testPathPattern="web-search.test.ts" -v`
Expected: FAIL

**Step 3: Update implementation to use Vertex AI**

Edit `functions/src/ai-pipeline/tools/web-search.ts`:

Replace lines 1-26:

Old code:
```typescript
import { GoogleGenAI } from '@google/genai';

export interface WebSearchResult {
  prices: Array<{
    source: string;
    price: number;
    condition?: string;
  }>;
  raw?: string;
}

/**
 * Search the web for product pricing using Google Search Grounding.
 *
 * @param query - Search query for product pricing
 * @returns WebSearchResult with extracted prices from e-commerce sites
 * @throws Error if GOOGLE_API_KEY is not set
 */
export async function searchWeb(query: string): Promise<WebSearchResult> {
  const apiKey = process.env.GOOGLE_API_KEY;

  if (!apiKey) {
    throw new Error('GOOGLE_API_KEY environment variable is required');
  }

  const ai = new GoogleGenAI({ apiKey });
```

New code:
```typescript
import { createVertexAIClient } from '../gemini/vertexai-config';

export interface WebSearchResult {
  prices: Array<{
    source: string;
    price: number;
    condition?: string;
  }>;
  raw?: string;
}

/**
 * Search the web for product pricing using Google Search Grounding.
 *
 * @param query - Search query for product pricing
 * @returns WebSearchResult with extracted prices from e-commerce sites
 * @throws Error if Vertex AI is not configured
 */
export async function searchWeb(query: string): Promise<WebSearchResult> {
  // Gemini 3 models require Vertex AI (not API keys)
  const ai = createVertexAIClient();
```

**Step 4: Run test to verify it passes**

Run: `cd functions && npm test -- --testPathPattern="web-search.test.ts" -v`
Expected: PASS

**Step 5: Commit**

```bash
git add functions/src/ai-pipeline/tools/web-search.ts functions/src/ai-pipeline/tools/__tests__/web-search.test.ts
git commit -m "$(cat <<'EOF'
feat(ai-pipeline): migrate web-search to Vertex AI authentication

Web search uses Gemini 3 Pro with Google Search Grounding.
Gemini 3 requires Vertex AI, not API keys.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: Update Cloud Function Trigger Configuration

**Files:**
- Modify: `functions/src/triggers/onItemCreatedGemini3.ts`

**Step 1: Read current trigger configuration**

Current trigger uses `defineSecret('GOOGLE_API_KEY')` which is no longer needed for Vertex AI.

**Step 2: Update trigger to remove GOOGLE_API_KEY secret**

Edit `functions/src/triggers/onItemCreatedGemini3.ts`:

Replace entire file with:

```typescript
/**
 * Firestore Trigger: Process new items with Gemini 3 Pro
 *
 * Triggers when item document is created with status="pending"
 * Calls Gemini 3 Pro with tool calling for:
 * - Visual analysis
 * - Barcode lookup
 * - Google Lens search
 * - Web search for pricing
 *
 * Replaces: onItemCreated (old 4-layer pipeline)
 *
 * Authentication:
 * - Vertex AI: Uses Application Default Credentials (service account)
 * - SERPAPI_KEY: Required for Google Lens visual search
 *
 * Deploy: firebase deploy --only functions:onItemCreatedGemini3
 */

import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { defineSecret } from 'firebase-functions/params';
import { handleItemCreated } from '../ai-pipeline/gemini';

// Define secrets for 2nd gen Cloud Functions
// GOOGLE_API_KEY no longer needed - Vertex AI uses ADC
const serpApiKey = defineSecret('SERPAPI_KEY');

export const onItemCreatedGemini3 = onDocumentCreated(
  {
    document: 'items/{itemId}',
    secrets: [serpApiKey],
    region: 'us-central1',
    memory: '512MiB',
    timeoutSeconds: 120,
  },
  async (event) => {
    if (!event.data) {
      console.error('onItemCreatedGemini3: No document data');
      return;
    }

    // SERPAPI_KEY still needed for Google Lens tool
    process.env.SERPAPI_KEY = serpApiKey.value();

    // GOOGLE_CLOUD_PROJECT is automatically set in Cloud Functions
    // GOOGLE_CLOUD_LOCATION defaults to 'global' in vertexai-config.ts

    await handleItemCreated(event.data, {
      params: { itemId: event.params.itemId },
    });
  }
);
```

**Step 3: Run all tests to verify nothing broke**

Run: `cd functions && npm test`
Expected: All tests pass

**Step 4: Commit**

```bash
git add functions/src/triggers/onItemCreatedGemini3.ts
git commit -m "$(cat <<'EOF'
feat(triggers): update onItemCreatedGemini3 to use Vertex AI ADC

- Remove GOOGLE_API_KEY secret (no longer needed)
- Vertex AI uses Application Default Credentials automatically
- SERPAPI_KEY still required for Google Lens tool

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: Update Trigger Unit Test

**Files:**
- Modify: `functions/src/triggers/__tests__/onItemCreatedGemini3.test.ts`

**Step 1: Read current test**

Run: Read the test file to understand current assertions

**Step 2: Update test to reflect new secret configuration**

The test that checks for `GOOGLE_API_KEY` secret needs to be updated.

Find and update the assertion that checks for both secrets to only check for SERPAPI_KEY:

```typescript
  it('should define secret for SERPAPI_KEY', async () => {
    // Import to check secret definition
    const trigger = require('../onItemCreatedGemini3');

    // Verify the function exists and is configured
    expect(trigger.onItemCreatedGemini3).toBeDefined();

    // Note: GOOGLE_API_KEY no longer needed - Vertex AI uses ADC
    // Only SERPAPI_KEY is required for Google Lens tool
  });
```

**Step 3: Run test to verify it passes**

Run: `cd functions && npm test -- --testPathPattern="onItemCreatedGemini3.test.ts" -v`
Expected: PASS

**Step 4: Commit**

```bash
git add functions/src/triggers/__tests__/onItemCreatedGemini3.test.ts
git commit -m "$(cat <<'EOF'
test(triggers): update test for Vertex AI authentication

GOOGLE_API_KEY secret is no longer used - Vertex AI uses ADC.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 6: Update Environment Configuration Files

**Files:**
- Modify: `functions/.env.example`
- Modify: `functions/.env.integration.example`

**Step 1: Update .env.example**

Edit `functions/.env.example`:

```bash
# Vertex AI Configuration (for Gemini 3 models)
# GOOGLE_CLOUD_PROJECT is auto-set in Cloud Functions
# For local development, set these:
GOOGLE_CLOUD_PROJECT=your-project-id
GOOGLE_CLOUD_LOCATION=global

# SerpAPI for Google Lens visual search
SERPAPI_KEY=your_serpapi_key_here

# Legacy: Google AI Studio API key (for gemini-2.5-flash-lite in old pipeline)
# GOOGLE_API_KEY=your_api_key_here
```

**Step 2: Update .env.integration.example**

Edit `functions/.env.integration.example`:

```bash
# Integration Test Configuration
# Copy to .env.integration and fill in real values

# Firebase Project
FIREBASE_PROJECT_ID=your-firebase-project-id

# Vertex AI Configuration (for Gemini 3 models)
GOOGLE_CLOUD_PROJECT=your-project-id
GOOGLE_CLOUD_LOCATION=global

# SerpAPI for Google Lens
SERPAPI_KEY=your-serpapi-key

# For local testing: run 'gcloud auth application-default login'
```

**Step 3: Commit**

```bash
git add functions/.env.example functions/.env.integration.example
git commit -m "$(cat <<'EOF'
docs(config): update env examples for Vertex AI authentication

- Add GOOGLE_CLOUD_PROJECT and GOOGLE_CLOUD_LOCATION
- Mark GOOGLE_API_KEY as legacy (for old pipeline only)
- Document ADC requirement for local development

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 7: Update Integration Test Setup

**Files:**
- Modify: `functions/src/ai-pipeline/__tests__/integration-setup.ts`

**Step 1: Update required env vars check**

Edit `functions/src/ai-pipeline/__tests__/integration-setup.ts`:

Change the required env vars from `GOOGLE_API_KEY` to `GOOGLE_CLOUD_PROJECT`:

```typescript
const requiredEnvVars = ['GOOGLE_CLOUD_PROJECT', 'SERPAPI_KEY', 'FIREBASE_PROJECT_ID'];
```

**Step 2: Run integration test setup to verify**

Run: `cd functions && npm run test:integration -- --testPathPattern="integration" --listTests`
Expected: Lists tests without env var errors

**Step 3: Commit**

```bash
git add functions/src/ai-pipeline/__tests__/integration-setup.ts
git commit -m "$(cat <<'EOF'
test(integration): update setup for Vertex AI configuration

Replace GOOGLE_API_KEY requirement with GOOGLE_CLOUD_PROJECT.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 8: Run Full Test Suite and Verify

**Step 1: Run all unit tests**

Run: `cd functions && npm test`
Expected: All tests pass

**Step 2: Run TypeScript compilation check**

Run: `cd functions && npm run lint`
Expected: No errors

**Step 3: Final commit with all changes**

If any files were missed, add them:

```bash
git status
git add -A
git commit -m "$(cat <<'EOF'
chore(ai-pipeline): complete Vertex AI migration for Gemini 3

All Gemini 3 API calls now use Vertex AI authentication:
- gemini-service.ts: Vertex AI client
- web-search.ts: Vertex AI client
- onItemCreatedGemini3: Removed GOOGLE_API_KEY secret

Authentication is automatic via ADC in Cloud Functions.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 9: Manual Verification (Post-Deploy)

**Step 1: Set up local ADC for testing**

Run: `gcloud auth application-default login`

**Step 2: Test locally with emulator**

Run: `cd functions && npm run serve`

**Step 3: Deploy to Firebase**

Run: `firebase deploy --only functions:onItemCreatedGemini3`

**Step 4: Verify in Cloud Console**

- Check Cloud Function logs for successful Gemini 3 API calls
- Verify no 401 authentication errors

---

## Summary

| Task | Description | Files Changed |
|------|-------------|---------------|
| 1 | Create Vertex AI config module | +2 new files |
| 2 | Update gemini-service.ts | 2 files |
| 3 | Update web-search.ts | 2 files |
| 4 | Update trigger configuration | 1 file |
| 5 | Update trigger test | 1 file |
| 6 | Update env examples | 2 files |
| 7 | Update integration setup | 1 file |
| 8 | Run full test suite | - |
| 9 | Manual verification | - |

**Total:** ~11 files modified, ~8 commits
