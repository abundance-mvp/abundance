# AI-INTEGRATION-LAYER-002: Gemini 3 Pro Orchestration

**Created**: 2026-01-14
**Stage**: Layer 2 Implementation
**Status**: Draft
**Supersedes**: AI-INTEGRATION-LAYER-001 (archived)
**References**:
- docs/plans/2026-01-13-gemini-3-pipeline-design.md (authoritative design)
- docs/tech-stack/COST-MODEL-001-ai-cataloging-cost-per-item.md

---

## Overview

This document defines the Cloud Function orchestration for the Gemini 3 Pro AI pipeline. The architecture uses a single model with native tool calling, replacing the previous 4-model approach.

**Key Changes from v1**:
- Single Gemini 3 Pro model (no Claude Haiku, Claude Sonnet, or Gemini Flash-Lite)
- Native tool calling (google_lens, barcode_lookup, web_search)
- Simplified orchestration (one Cloud Function, not three)

---

## Architecture

```
iOS App                    Cloud Function              Gemini 3 Pro
   │                            │                           │
   │ Upload cropped image       │                           │
   │ ─────────────────────────> │                           │
   │                            │                           │
   │                            │ Send image + prompt       │
   │                            │ ────────────────────────> │
   │                            │                           │
   │                            │      (Pro analyzes)       │
   │                            │                           │
   │                            │ <── Tool: barcode_lookup  │
   │                            │ ── Tool result ─────────> │
   │                            │                           │
   │                            │ <── Tool: google_lens     │
   │                            │ ── Tool result ─────────> │
   │                            │                           │
   │                            │ <── Tool: web_search      │
   │                            │ ── Tool result ─────────> │
   │                            │                           │
   │                            │ <── Final CatalogItem(s)  │
   │                            │                           │
   │ Firestore update           │                           │
   │ <───────────────────────── │                           │
```

---

## Directory Structure

```
functions/src/ai-pipeline/
├── index.ts                      # Exports
├── orchestrator.ts               # Main entry point (Cloud Function)
├── orchestrator.test.ts
│
├── gemini/
│   ├── gemini-service.ts         # Gemini 3 Pro client wrapper
│   ├── gemini-service.test.ts
│   ├── prompts.ts                # System prompt + tool definitions
│   └── schemas/
│       └── catalog-item.ts       # TypeScript types + JSON schema
│
└── tools/
    ├── tool-executor.ts          # Routes tool calls to implementations
    ├── tool-executor.test.ts
    ├── google-lens.ts            # SerpAPI Google Lens integration
    ├── google-lens.test.ts
    ├── barcode-lookup.ts         # UPCitemdb integration
    ├── barcode-lookup.test.ts
    ├── web-search.ts             # E-commerce price search
    └── web-search.test.ts
```

---

## Cloud Function Entry Point

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { processItemWithGemini } from './gemini/gemini-service';

admin.initializeApp();

/**
 * Firestore trigger: When item document created, process with Gemini 3 Pro
 * Triggered by: iOS app creating item with status="processing"
 */
export const onItemCreated = functions.firestore
  .document('items/{itemId}')
  .onCreate(async (snapshot, context) => {
    const itemId = context.params.itemId;
    const itemData = snapshot.data();

    console.log({
      severity: 'INFO',
      message: 'AI pipeline started',
      itemId,
      userId: itemData.userId
    });

    try {
      // Get signed URL for image
      const imageUrl = await getSignedImageUrl(itemData.imagePath);

      // Process with Gemini 3 Pro (handles all tool calls internally)
      const result = await processItemWithGemini(imageUrl);

      // Update Firestore with results
      await snapshot.ref.update({
        status: 'complete',
        catalog: result,
        completedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      console.log({
        severity: 'INFO',
        message: 'AI pipeline completed',
        itemId,
        itemCount: Array.isArray(result) ? result.length : 1
      });

    } catch (error) {
      console.error({
        severity: 'ERROR',
        message: 'AI pipeline failed',
        itemId,
        error: (error as Error).message
      });

      await snapshot.ref.update({
        status: 'failed',
        error: (error as Error).message,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }
  });

async function getSignedImageUrl(imagePath: string): Promise<string> {
  const bucket = admin.storage().bucket();
  const file = bucket.file(imagePath);
  const [url] = await file.getSignedUrl({
    action: 'read',
    expires: Date.now() + 15 * 60 * 1000 // 15 minutes
  });
  return url;
}
```

---

## Gemini Service

```typescript
import { GoogleGenerativeAI } from '@google/genai';
import { SYSTEM_PROMPT, CATALOG_TOOLS, GENERATION_CONFIG } from './prompts';
import { executeToolCall } from '../tools/tool-executor';
import { CatalogItem } from './schemas/catalog-item';

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY!);

export async function processItemWithGemini(imageUrl: string): Promise<CatalogItem | CatalogItem[]> {
  const model = genAI.getGenerativeModel({
    model: 'gemini-3-pro',
    tools: CATALOG_TOOLS,
    generationConfig: GENERATION_CONFIG,
    systemInstruction: SYSTEM_PROMPT
  });

  // Initial request with image
  let response = await model.generateContent({
    contents: [{
      role: 'user',
      parts: [
        { text: 'Analyze this image and create catalog entry(ies).' },
        { inlineData: { mimeType: 'image/jpeg', data: await fetchImageBase64(imageUrl) } }
      ]
    }]
  });

  // Handle tool calls in a loop
  while (response.response.candidates?.[0]?.content?.parts?.some(p => p.functionCall)) {
    const toolCalls = response.response.candidates[0].content.parts
      .filter(p => p.functionCall)
      .map(p => p.functionCall!);

    // Execute all tool calls
    const toolResults = await Promise.all(
      toolCalls.map(async (call) => ({
        functionResponse: {
          name: call.name,
          response: await executeToolCall(call.name, call.args, imageUrl)
        }
      }))
    );

    // Send tool results back to Gemini
    response = await model.generateContent({
      contents: [
        ...response.response.candidates[0].content.parts,
        ...toolResults.map(r => ({ functionResponse: r.functionResponse }))
      ]
    });
  }

  // Extract final JSON response
  const text = response.response.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text) {
    throw new Error('No response from Gemini');
  }

  return JSON.parse(text) as CatalogItem | CatalogItem[];
}

async function fetchImageBase64(url: string): Promise<string> {
  const response = await fetch(url);
  const buffer = await response.arrayBuffer();
  return Buffer.from(buffer).toString('base64');
}
```

---

## Tool Executor

```typescript
import { searchGoogleLens } from './google-lens';
import { lookupBarcode } from './barcode-lookup';
import { searchWeb } from './web-search';

export async function executeToolCall(
  name: string,
  args: Record<string, unknown>,
  imageUrl: string
): Promise<unknown> {
  switch (name) {
    case 'google_lens_search':
      return searchGoogleLens(args.image_url as string || imageUrl);

    case 'barcode_lookup':
      return lookupBarcode(args.code as string, args.symbology as string);

    case 'web_search':
      return searchWeb(args.query as string);

    default:
      throw new Error(`Unknown tool: ${name}`);
  }
}
```

---

## Tool Implementations

### Google Lens (SerpAPI)

```typescript
import axios from 'axios';

export async function searchGoogleLens(imageUrl: string): Promise<GoogleLensResult> {
  const response = await axios.get('https://serpapi.com/search', {
    params: {
      engine: 'google_lens',
      url: imageUrl,
      api_key: process.env.SERPAPI_KEY
    },
    timeout: 30000
  });

  const visualMatches = response.data.visual_matches || [];

  return {
    exact_matches: visualMatches.some((m: any) => m.exact_match === true),
    products: visualMatches.slice(0, 5).map((match: any) => ({
      title: match.title,
      brand: match.brand,
      price: match.price?.extracted_value,
      source: match.source,
      link: match.link
    }))
  };
}

interface GoogleLensResult {
  exact_matches: boolean;
  products: Array<{
    title: string;
    brand?: string;
    price?: number;
    source: string;
    link: string;
  }>;
}
```

### Barcode Lookup (UPCitemdb)

```typescript
import axios from 'axios';

export async function lookupBarcode(code: string, symbology?: string): Promise<BarcodeResult> {
  try {
    const response = await axios.get('https://api.upcitemdb.com/prod/trial/lookup', {
      params: { upc: code },
      timeout: 10000
    });

    if (response.data.items?.length > 0) {
      const item = response.data.items[0];
      return {
        found: true,
        product: {
          title: item.title,
          brand: item.brand,
          model: item.model,
          category: item.category
        }
      };
    }

    return { found: false, barcode: code };

  } catch (error) {
    console.warn(`Barcode lookup failed for ${code}:`, error);
    return { found: false, barcode: code };
  }
}

interface BarcodeResult {
  found: boolean;
  product?: {
    title: string;
    brand?: string;
    model?: string;
    category?: string;
  };
  barcode?: string;
}
```

### Web Search (Google Search Grounding)

```typescript
import { GoogleGenerativeAI } from '@google/genai';

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY!);

export async function searchWeb(query: string): Promise<WebSearchResult> {
  const model = genAI.getGenerativeModel({
    model: 'gemini-3-pro',
    tools: [{ googleSearchRetrieval: {} }]
  });

  const response = await model.generateContent({
    contents: [{
      role: 'user',
      parts: [{ text: `Find current market prices for: ${query}. Return JSON with prices array.` }]
    }]
  });

  const text = response.response.candidates?.[0]?.content?.parts?.[0]?.text;

  try {
    return JSON.parse(text || '{"prices":[]}');
  } catch {
    return { prices: [], raw: text };
  }
}

interface WebSearchResult {
  prices: Array<{
    source: string;
    price: number;
    condition?: string;
  }>;
  raw?: string;
}
```

---

## Cost Tracking

```typescript
import * as admin from 'firebase-admin';

export async function logCosts(
  itemId: string,
  geminiTokens: { input: number; output: number },
  toolsUsed: string[]
): Promise<void> {
  const geminiCost = (geminiTokens.input * 3 + geminiTokens.output * 15) / 1_000_000;

  const toolCosts: Record<string, number> = {
    google_lens_search: 0.015,
    barcode_lookup: 0.005,
    web_search: 0.014
  };

  const totalToolCost = toolsUsed.reduce((sum, tool) => sum + (toolCosts[tool] || 0), 0);

  await admin.firestore().collection('aiCosts').add({
    itemId,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    gemini: geminiCost,
    tools: Object.fromEntries(toolsUsed.map(t => [t, toolCosts[t] || 0])),
    total: geminiCost + totalToolCost
  });
}
```

---

## Error Handling

```typescript
export async function withRetry<T>(
  fn: () => Promise<T>,
  opts: { maxAttempts?: number; backoffMs?: number } = {}
): Promise<T> {
  const { maxAttempts = 3, backoffMs = 1000 } = opts;
  let lastError: Error;

  for (let i = 0; i < maxAttempts; i++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error as Error;

      // Don't retry on auth errors
      if (lastError.message.includes('401') || lastError.message.includes('403')) {
        throw lastError;
      }

      if (i < maxAttempts - 1) {
        await new Promise(r => setTimeout(r, backoffMs * Math.pow(2, i)));
      }
    }
  }

  throw lastError!;
}
```

---

## Testing

All components tested with:
- **Unit tests**: Mock API responses, verify tool routing
- **Integration tests**: Firebase Emulator Suite
- **Golden dataset**: 100 items with ground truth labels

See: docs/test/TEST-EXAMPLE-003-cloud-functions-testing-patterns.md

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2026-01-14 | 1.0 | Initial Gemini 3 Pro orchestration design | AI Pipeline Refactor |
