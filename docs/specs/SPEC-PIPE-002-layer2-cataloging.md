# SPEC-PIPE-002: Layer 2 Premium Cataloging

**Created:** 2026-01-18
**Status:** Active
**Author:** Claude Code Audit

---

## Table of Contents

1. [Overview](#1-overview)
2. [Model Configuration](#2-model-configuration)
3. [System Prompt](#3-system-prompt)
4. [Tool Definitions](#4-tool-definitions)
5. [Thought Signature Handling](#5-thought-signature-handling)
6. [Tool Execution Flow](#6-tool-execution-flow)
7. [Catalog Output Schema](#7-catalog-output-schema)
8. [Error Handling and Retries](#8-error-handling-and-retries)
9. [Cost Estimates](#9-cost-estimates)

---

## 1. Overview

Layer 2 Premium Cataloging is the AI-powered item cataloging service in the Abundance pipeline. It uses Google's Gemini 3 Pro model with function calling (tool use) to:

1. **Analyze product images** - Visual examination of items including brand logos, condition, dimensions
2. **Identify products** - Using barcode lookup and Google Lens visual search
3. **Determine pricing** - Web search for current market values
4. **Generate structured catalog entries** - JSON output matching the CatalogItem schema

### Architecture Position

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Firestore Trigger                            │
│                   onItemCreatedGemini3                              │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         Orchestrator                                │
│                   handleItemCreated()                               │
│                                                                     │
│  1. Validate item status (pending)                                  │
│  2. Get signed URL for image                                        │
│  3. Call processItemWithGemini()                                    │
│  4. Validate and save results                                       │
└─────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Gemini Service                                 │
│                  processItemWithGemini()                            │
│                                                                     │
│  1. Fetch image as base64                                           │
│  2. Send to Gemini 3 Pro with tools                                 │
│  3. Handle tool calling loop (max 10 iterations)                    │
│  4. Return CatalogItem JSON                                         │
└─────────────────────────────────────────────────────────────────────┘
                                │
                    ┌───────────┼───────────┐
                    ▼           ▼           ▼
            ┌───────────┐ ┌───────────┐ ┌───────────┐
            │  Google   │ │  Barcode  │ │   Web     │
            │   Lens    │ │  Lookup   │ │  Search   │
            └───────────┘ └───────────┘ └───────────┘
```

### Key Files

| File | Purpose |
|------|---------|
| `functions/src/triggers/onItemCreatedGemini3.ts` | Firestore trigger entry point |
| `functions/src/ai-pipeline/gemini/orchestrator.ts` | Pipeline orchestration |
| `functions/src/ai-pipeline/gemini/gemini-service.ts` | Gemini API interaction |
| `functions/src/ai-pipeline/gemini/prompts.ts` | System prompt and tool definitions |
| `functions/src/ai-pipeline/gemini/schemas/catalog-item.ts` | Output schema |
| `functions/src/ai-pipeline/tools/tool-executor.ts` | Tool dispatch |
| `functions/src/ai-pipeline/tools/google-lens.ts` | Visual search via SerpAPI |
| `functions/src/ai-pipeline/tools/barcode-lookup.ts` | UPC/EAN lookup via UPCitemdb |
| `functions/src/ai-pipeline/tools/web-search.ts` | Price search via Gemini + Google Search |
| `functions/src/ai-pipeline/gemini/catalog-history-service.ts` | Catalog history CRUD |
| `functions/src/ai-pipeline/gemini/context-cache-service.ts` | Gemini context caching |
| `functions/src/ai-pipeline/gemini/schemas/catalog-history.ts` | History data models |

---

## 2. Model Configuration

### Model ID

```typescript
export const GEMINI_MODEL_ID = 'gemini-3-pro-preview';
```

The pipeline uses **Gemini 3 Pro Preview**, accessed through Vertex AI (not API keys). This model supports:

- Native function calling with thought signatures
- Structured JSON output via `responseSchema`
- Multi-modal image understanding
- Extended context for complex tool orchestration

### Generation Configuration

```typescript
export const GENERATION_CONFIG = {
  temperature: 0.1,
  topP: 0.95,
  maxOutputTokens: 8192,
  responseMimeType: 'application/json',
  responseSchema: CATALOG_ITEM_SCHEMA
};
```

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| `temperature` | 0.1 | Low temperature for consistent, deterministic cataloging |
| `topP` | 0.95 | Nucleus sampling for focused yet slightly varied responses |
| `maxOutputTokens` | 8192 | Large budget for tool calling + JSON response (increased from 1024) |
| `responseMimeType` | `'application/json'` | Enforces JSON output format |
| `responseSchema` | `CATALOG_ITEM_SCHEMA` | Structured output validation |

### Vertex AI Authentication

```typescript
// From vertexai-config.ts
export function createVertexAIClient(): GoogleGenAI {
  const config = getVertexAIConfig();
  return new GoogleGenAI(config);
}

export function getVertexAIConfig(): VertexAIConfig {
  const project = getProjectId();
  const location = process.env.GOOGLE_CLOUD_LOCATION || 'global';

  return {
    vertexai: true,
    project,
    location
  };
}
```

Authentication uses **Application Default Credentials (ADC)**:
- In Cloud Functions: Automatic via service account
- Local development: `gcloud auth application-default login`

---

## 3. System Prompt

The system prompt defines the cataloging workflow, confidence scoring, and pricing methodology:

```typescript
export const SYSTEM_PROMPT = `You are an expert product cataloger. Analyze the provided image and create detailed catalog entries.

WORKFLOW:
1. Examine the image carefully for:
   - Product type, category, and sub-category
   - Visible barcodes (if any)
   - Brand logos or text
   - Physical condition indicators
   - Size/dimension clues
   - Quantity (if multiple identical items)

2. If you see a barcode, use barcode_lookup to get product details.
   Always also use google_lens_search for verification and additional data.

3. Verify tool results against what you see:
   - Does the returned product match the image?
   - If mismatch, trust your visual analysis over tool results.

4. Once you have HIGH or MEDIUM confidence on product identity:
   - Use web_search to find current market prices
   - Search query format: "{brand} {model} {condition} price"

5. Return complete catalog entry(ies) with confidence level.

CONFIDENCE SCORING:
- "high": Google Lens returned exact_matches:true OR barcode lookup succeeded AND visual verification confirms
- "medium": Google Lens returned similar products but not exact, OR barcode lookup failed but Google Lens found likely match
- "low": Only related suggestions available, relying primarily on visual analysis

PRICING:
- Use SOLD prices when available (eBay sold listings)
- Apply condition multipliers to new retail price:
  - new: 1.0
  - like-new: 0.85
  - good: 0.65
  - fair: 0.45
  - poor: 0.25
- If no pricing found, set estimatedValue: null

OUTPUT FORMAT:
Return valid JSON matching the CatalogItem schema.`;
```

### Workflow Steps

1. **Visual Analysis** - Examine image for product attributes
2. **Barcode Lookup** - If barcode visible, use `barcode_lookup`
3. **Visual Search** - Always use `google_lens_search` for verification
4. **Result Verification** - Cross-check tool results against visual evidence
5. **Price Search** - Use `web_search` for market pricing
6. **Output** - Return structured CatalogItem JSON

### Confidence Scoring Rules

| Level | Criteria |
|-------|----------|
| `high` | Google Lens exact match OR barcode lookup success + visual confirmation |
| `medium` | Google Lens similar matches OR barcode failure + Lens likely match |
| `low` | Only related suggestions, relying on visual analysis alone |

### Condition-Based Pricing Multipliers

| Condition | Multiplier |
|-----------|------------|
| `new` | 1.00 |
| `like-new` | 0.85 |
| `good` | 0.65 |
| `fair` | 0.45 |
| `poor` | 0.25 |

---

## 4. Tool Definitions

Three tools are available for Gemini function calling:

### 4.1 google_lens_search

Visual product matching using Google Lens via SerpAPI.

#### Function Declaration

```typescript
{
  name: 'google_lens_search',
  description: 'Search for product information using visual matching.',
  parameters: {
    type: 'object',
    properties: {
      image_url: {
        type: 'string',
        description: 'Public URL of the product image'
      }
    },
    required: ['image_url']
  }
}
```

#### Implementation (`google-lens.ts`)

```typescript
export interface GoogleLensResult {
  exact_matches: boolean;
  products: Array<{
    title: string;
    brand?: string;
    price?: number;
    source: string;
    link: string;
  }>;
}

export async function searchGoogleLens(imageUrl: string): Promise<GoogleLensResult> {
  const apiKey = process.env.SERPAPI_KEY;

  if (!apiKey) {
    throw new Error('SERPAPI_KEY environment variable is required');
  }

  const url = new URL('https://serpapi.com/search');
  url.searchParams.set('engine', 'google_lens');
  url.searchParams.set('url', imageUrl);
  url.searchParams.set('api_key', apiKey);

  const response = await fetch(url.toString(), {
    method: 'GET',
    headers: { 'Accept': 'application/json' }
  });

  if (!response.ok) {
    throw new Error(`SerpAPI request failed: ${response.status} ${response.statusText}`);
  }

  const data = await response.json() as SerpApiResponse;
  const visualMatches = data.visual_matches || [];

  const hasExactMatch = visualMatches.some((m) => m.exact_match === true);

  const products = visualMatches.slice(0, 5).map((match) => ({
    title: match.title || 'Unknown Product',
    brand: extractBrand(match),
    price: match.price?.extracted_value,
    source: match.source || 'Unknown',
    link: match.link || ''
  }));

  return { exact_matches: hasExactMatch, products };
}
```

**Features:**
- Returns up to 5 product matches
- Includes `exact_matches` boolean for confidence scoring
- Extracts brand from explicit field or known brand list in title
- Requires `SERPAPI_KEY` secret

### 4.2 barcode_lookup

UPC/EAN barcode lookup using UPCitemdb API.

#### Function Declaration

```typescript
{
  name: 'barcode_lookup',
  description: 'Look up product information by barcode number.',
  parameters: {
    type: 'object',
    properties: {
      code: {
        type: 'string',
        description: 'The barcode number'
      },
      symbology: {
        type: 'string',
        enum: ['upc_a', 'upc_e', 'ean_13', 'ean_8', 'qr', 'code_128'],
        description: 'The barcode format (optional)'
      }
    },
    required: ['code']
  }
}
```

#### Implementation (`barcode-lookup.ts`)

```typescript
export interface BarcodeResult {
  found: boolean;
  product?: {
    title: string;
    brand?: string;
    model?: string;
    description?: string;
  };
  barcode?: string;
}

export async function lookupBarcode(
  code: string,
  symbology?: string
): Promise<BarcodeResult> {
  try {
    const url = `https://api.upcitemdb.com/prod/trial/lookup?upc=${encodeURIComponent(code)}`;

    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'Abundance-App/1.0'
      }
    });

    if (!response.ok) {
      console.warn(`Barcode lookup failed for ${code}: HTTP ${response.status}`);
      return { found: false, barcode: code };
    }

    const data = await response.json() as UPCitemdbResponse;

    if (data.items && data.items.length > 0) {
      const item = data.items[0];
      return {
        found: true,
        product: {
          title: item.title || 'Unknown Product',
          brand: item.brand || undefined,
          model: item.model || undefined,
          description: item.description || undefined
        }
      };
    }

    return { found: false, barcode: code };

  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    console.warn(`Barcode lookup error for ${code}:`, message);
    return { found: false, barcode: code };
  }
}
```

**Features:**
- Uses UPCitemdb trial API
- Graceful failure with `found: false`
- Supports UPC-A, UPC-E, EAN-13, EAN-8, QR, Code 128

### 4.3 web_search

E-commerce price search using Gemini with Google Search grounding.

#### Function Declaration

```typescript
{
  name: 'web_search',
  description: 'Search e-commerce sites for current pricing.',
  parameters: {
    type: 'object',
    properties: {
      query: {
        type: 'string',
        description: 'Search query'
      }
    },
    required: ['query']
  }
}
```

#### Implementation (`web-search.ts`)

```typescript
export interface WebSearchResult {
  prices: Array<{
    source: string;
    price: number;
    condition?: string;
  }>;
  raw?: string;
}

export async function searchWeb(query: string): Promise<WebSearchResult> {
  const ai = createVertexAIClient();

  try {
    const response = await ai.models.generateContent({
      model: 'gemini-3-pro-preview',
      contents: `Find current market prices for: ${query}

Search e-commerce sites (Amazon, eBay, Walmart, Target) and return pricing data.

Return JSON in this exact format:
{
  "prices": [
    { "source": "Amazon", "price": 99.99, "condition": "new" },
    { "source": "eBay", "price": 75.00, "condition": "used" }
  ]
}

Only include prices you found. If no prices found, return {"prices": []}`,
      config: {
        tools: [{ googleSearch: {} }],
        temperature: 0.1,
        maxOutputTokens: 512
      }
    });

    const text = response.text || '';

    try {
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        const parsed = JSON.parse(jsonMatch[0]);
        return { prices: parsed.prices || [] };
      }
      return { prices: [], raw: text };
    } catch {
      return { prices: [], raw: text };
    }

  } catch (error: any) {
    console.error('Web search error:', error.message);
    return { prices: [] };
  }
}
```

**Features:**
- Uses Gemini with `googleSearch` grounding (not legacy `googleSearchRetrieval`)
- Targets Amazon, eBay, Walmart, Target
- Returns structured price data with source and condition
- Graceful failure with empty prices array

---

## 5. Thought Signature Handling

### Why Thought Signatures Are Required

**CRITICAL:** Gemini 3 models use "thought signatures" for function calling. When the model makes function calls, it includes internal reasoning state that must be preserved and passed back with function responses. **Failure to preserve thought signatures results in HTTP 400 errors.**

From Google's documentation:
> Gemini 3 requires thought_signature to be passed back with function calls, otherwise it returns a 400 error.

Reference: https://cloud.google.com/vertex-ai/generative-ai/docs/thought-signatures

### Implementation

The `getModelPartsWithThoughtSignature` function extracts and preserves the model's parts including thought-related content:

```typescript
/**
 * Extract model parts from response, preserving thought_signature for Gemini 3.
 *
 * Gemini 3 requires thought_signature to be passed back with function calls,
 * otherwise it returns a 400 error. The signature is attached to the first
 * functionCall part in parallel calls, and to each functionCall in sequential calls.
 *
 * @param response - The GenerateContentResponse from Gemini
 * @returns Array of Part objects with preserved thought_signature
 */
function getModelPartsWithThoughtSignature(response: GenerateContentResponse): Part[] {
  // Get parts directly from the response to preserve thought_signature
  const candidate = response.candidates?.[0];
  if (!candidate?.content?.parts) {
    return [];
  }

  // Return the original parts which include thought_signature
  // Filter to only include parts that have function calls or thought-related content
  return candidate.content.parts.filter(part =>
    part.functionCall || part.thought || part.thoughtSignature
  );
}
```

### Conversation Flow with Thought Signatures

```
Turn 1: User sends image
  ↓
Turn 2: Model responds with functionCall + thoughtSignature
  ↓
Turn 3: User sends functionResponse (MUST include model's Turn 2 parts)
  ↓
Turn 4: Model continues with more function calls or final response
```

The key insight is in building the conversation history:

```typescript
// CRITICAL: Preserve the original model parts including thought_signature
const modelParts = getModelPartsWithThoughtSignature(response);
const userParts: Part[] = toolResults.map(r => ({ functionResponse: r.functionResponse }));

contents = [
  ...contents,
  { role: 'model', parts: modelParts },  // Includes thoughtSignature
  { role: 'user', parts: userParts }
];
```

### Part Types Preserved

| Part Type | Description |
|-----------|-------------|
| `functionCall` | The model's tool invocation request |
| `thought` | Internal reasoning content |
| `thoughtSignature` | Cryptographic signature of the thought |

---

## 6. Tool Execution Flow

### Main Processing Loop

```typescript
export async function processItemWithGemini(
  imageUrl: string
): Promise<CatalogItem | CatalogItem[]> {
  const imageBase64 = await fetchImageBase64(imageUrl);
  const ai = createVertexAIClient();

  const toolDeclarations = CATALOG_TOOLS.flatMap(t => t.functionDeclarations || []);

  let contents: Content[] = [{
    role: 'user',
    parts: [
      { text: 'Analyze this image and create catalog entry(ies).' },
      {
        inlineData: {
          mimeType: 'image/jpeg',
          data: imageBase64
        }
      }
    ]
  }];

  let response = await ai.models.generateContent({
    model: GEMINI_MODEL_ID,
    contents,
    config: {
      systemInstruction: SYSTEM_PROMPT,
      tools: [{ functionDeclarations: toolDeclarations as any }],
      ...GENERATION_CONFIG
    }
  });

  let iterations = 0;
  const maxIterations = 10;

  while (iterations < maxIterations) {
    const functionCalls = response.functionCalls || [];

    if (functionCalls.length === 0) {
      break;  // No more tool calls, model is ready to respond
    }

    console.log(`Iteration ${iterations + 1}: Processing ${functionCalls.length} function call(s): ${functionCalls.map(c => c.name).join(', ')}`);

    // Execute tool calls in parallel
    const toolResults = await Promise.all(
      functionCalls.map(async (call: FunctionCall) => {
        const name = call.name || '';
        const result = await executeToolCall(name, call.args || {}, imageUrl);
        return {
          functionResponse: {
            name,
            response: result as Record<string, unknown>
          }
        };
      })
    );

    // Preserve thought signature and continue conversation
    const modelParts = getModelPartsWithThoughtSignature(response);
    const userParts: Part[] = toolResults.map(r => ({ functionResponse: r.functionResponse }));

    contents = [
      ...contents,
      { role: 'model', parts: modelParts },
      { role: 'user', parts: userParts }
    ];

    response = await ai.models.generateContent({
      model: GEMINI_MODEL_ID,
      contents,
      config: {
        systemInstruction: SYSTEM_PROMPT,
        tools: [{ functionDeclarations: toolDeclarations as any }],
        ...GENERATION_CONFIG
      }
    });

    iterations++;
  }

  // Parse final JSON response
  const text = response.text;
  if (!text) {
    throw new Error(`No text response from Gemini after ${iterations} iterations`);
  }

  return JSON.parse(text) as CatalogItem | CatalogItem[];
}
```

### Session Persistence Mode

For items requiring context continuity across multiple catalog attempts, use `processItemWithGeminiPersistent()`:

**Reference:** [SPEC-PIPE-003: Session Persistence](./SPEC-PIPE-003-session-persistence.md)

```typescript
export async function processItemWithGeminiPersistent(
  imageUrl: string,
  itemId?: string,
  useContextCache: boolean = true
): Promise<CatalogItem | CatalogItem[]>
```

**Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `imageUrl` | string | Public URL of the image to process |
| `itemId` | string? | Optional item ID for history lookup/save |
| `useContextCache` | boolean | Whether to use cached system prompt (default: true) |

**Features:**

1. **History Context Injection** - When `itemId` is provided, fetches recent catalog history and injects it into the prompt
2. **Context Caching** - Caches system prompt + tool definitions for ~90% token cost reduction
3. **Tool Call Recording** - Records all tool calls (including failures) for history
4. **Token Tracking** - Accumulates `totalTokenCount` across all iterations
5. **Auto-Save** - Saves catalog result to history subcollection after processing

**History Storage:**

```
items/{itemId}/catalogHistory/{entryId}
```

Each entry contains:
- `catalogedAt` - Timestamp
- `model` - Gemini model ID
- `imageUrls` - Images processed
- `toolCalls` - Array of tool call records
- `result` - CatalogResultSnapshot
- `metadata` - Token count, duration, cache usage

**Cost Savings:**

| Scenario | Without Persistence | With Persistence |
|----------|---------------------|------------------|
| First catalog | ~$0.04 | ~$0.044 |
| Subsequent catalogs | ~$0.04 | ~$0.016 |
| 3 catalogs total | ~$0.12 | ~$0.076 (37% savings) |

### Tool Call Detection

Tool calls are detected by checking `response.functionCalls`:

```typescript
const functionCalls = response.functionCalls || [];

if (functionCalls.length === 0) {
  break;  // Model is done with tools, ready to output
}
```

### Parallel Tool Execution

Multiple tool calls in a single response are executed in parallel using `Promise.all`:

```typescript
const toolResults = await Promise.all(
  functionCalls.map(async (call: FunctionCall) => {
    const name = call.name || '';
    const result = await executeToolCall(name, call.args || {}, imageUrl);
    return {
      functionResponse: {
        name,
        response: result as Record<string, unknown>
      }
    };
  })
);
```

### Tool Executor Dispatch

```typescript
export async function executeToolCall(
  name: string,
  args: Record<string, unknown>,
  imageUrl: string
): Promise<unknown> {
  switch (name) {
    case 'google_lens_search': {
      const searchImageUrl = (args.image_url as string) || imageUrl;
      return searchGoogleLens(searchImageUrl);
    }

    case 'barcode_lookup': {
      return lookupBarcode(
        args.code as string,
        args.symbology as string | undefined
      );
    }

    case 'web_search': {
      return searchWeb(args.query as string);
    }

    default:
      throw new Error(`Unknown tool: ${name}`);
  }
}
```

### Function Response Format

Tool results are wrapped in the Gemini function response format:

```typescript
{
  functionResponse: {
    name: 'google_lens_search',
    response: {
      exact_matches: true,
      products: [
        { title: 'Product Name', brand: 'Brand', price: 99.99, source: 'Amazon', link: '...' }
      ]
    }
  }
}
```

---

## 7. Catalog Output Schema

### CatalogItem Interface

```typescript
export type Condition = 'new' | 'like-new' | 'good' | 'fair' | 'poor';
export type Confidence = 'high' | 'medium' | 'low';

export interface CatalogItem {
  name: string;
  category: string;
  subCategory: string;
  brand: string | null;
  model: string | null;
  color: string;
  condition: Condition;
  dimensions: string | null;
  quantity: number;
  estimatedValue: number | null;
  confidence: Confidence;
  processingNotes: string | null;
}
```

### JSON Schema for Gemini

```typescript
export const CATALOG_ITEM_SCHEMA = {
  type: 'object',
  properties: {
    name: { type: 'string', description: 'Product name' },
    category: { type: 'string', description: 'Primary category' },
    subCategory: { type: 'string', description: 'Sub-category' },
    brand: { type: ['string', 'null'], description: 'Brand name if identifiable' },
    model: { type: ['string', 'null'], description: 'Model name/number' },
    color: { type: 'string', description: 'Primary color(s)' },
    condition: {
      type: 'string',
      enum: ['new', 'like-new', 'good', 'fair', 'poor'],
      description: 'Physical condition'
    },
    dimensions: { type: ['string', 'null'], description: 'Size/dimensions info' },
    quantity: { type: 'integer', minimum: 1, description: 'Number of items' },
    estimatedValue: { type: ['number', 'null'], description: 'Estimated market value in USD' },
    confidence: {
      type: 'string',
      enum: ['high', 'medium', 'low'],
      description: 'Confidence level'
    },
    processingNotes: {
      type: ['string', 'null'],
      description: 'Notes about AI processing quality or issues'
    }
  },
  required: ['name', 'category', 'subCategory', 'color', 'condition', 'quantity', 'confidence']
};
```

### Field Descriptions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | Yes | Product name/title |
| `category` | string | Yes | Primary category (e.g., "Electronics", "Clothing") |
| `subCategory` | string | Yes | Sub-category (e.g., "Headphones", "T-Shirts") |
| `brand` | string/null | No | Brand name if identifiable |
| `model` | string/null | No | Model name or number |
| `color` | string | Yes | Primary color(s) |
| `condition` | enum | Yes | One of: new, like-new, good, fair, poor |
| `dimensions` | string/null | No | Size/dimension information |
| `quantity` | integer | Yes | Number of items (minimum: 1) |
| `estimatedValue` | number/null | No | Estimated market value in USD |
| `confidence` | enum | Yes | One of: high, medium, low |
| `processingNotes` | string/null | No | Notes about AI processing quality |

### Validation

```typescript
export function validateCatalogItem(item: CatalogItem): ValidationResult {
  const errors: string[] = [];

  if (!item.name || typeof item.name !== 'string') {
    errors.push('Name is required and must be a string');
  }
  if (!item.category || typeof item.category !== 'string') {
    errors.push('Category is required and must be a string');
  }
  if (!item.subCategory || typeof item.subCategory !== 'string') {
    errors.push('SubCategory is required and must be a string');
  }
  if (!item.color || typeof item.color !== 'string') {
    errors.push('Color is required and must be a string');
  }
  if (!VALID_CONDITIONS.includes(item.condition)) {
    errors.push(`Invalid condition: ${item.condition}`);
  }
  if (!VALID_CONFIDENCES.includes(item.confidence)) {
    errors.push(`Invalid confidence: ${item.confidence}`);
  }
  if (typeof item.quantity !== 'number' || item.quantity < 1) {
    errors.push('Quantity must be positive');
  }
  if (item.estimatedValue !== null && typeof item.estimatedValue !== 'number') {
    errors.push('EstimatedValue must be a number or null');
  }

  return { valid: errors.length === 0, errors };
}
```

---

## 8. Error Handling and Retries

### Maximum Iterations

The tool calling loop is limited to prevent infinite loops:

```typescript
let iterations = 0;
const maxIterations = 10;

while (iterations < maxIterations) {
  // ... tool calling loop
  iterations++;
}

if (iterations >= maxIterations) {
  console.warn(`Hit max iterations (${maxIterations}) - model may be stuck in tool-calling loop`);
}
```

### Error Code Classification

| Error Type | Handling |
|------------|----------|
| Image fetch failure | Throw error, document marked as failed |
| No Vertex AI config | Throw error with config instructions |
| Tool execution failure | Logged, tool returns error response to model |
| No text in response | Throw error with debug info |
| JSON parse failure | Throw error |
| Validation failure | Log warning, continue with partial data |

### Document Status Updates

```typescript
// On success
await snapshot.ref.update({
  status: 'complete',
  // ... catalog fields
  completedAt: admin.firestore.FieldValue.serverTimestamp(),
  updatedAt: admin.firestore.FieldValue.serverTimestamp()
});

// On failure
await snapshot.ref.update({
  status: 'failed',
  error: errorMessage,
  updatedAt: admin.firestore.FieldValue.serverTimestamp()
});
```

### Debug Logging

When no text response is received:

```typescript
const candidate = response.candidates?.[0];
console.error('No text in response. Finish reason:', candidate?.finishReason);
console.error('Response parts:', JSON.stringify(candidate?.content?.parts?.map(p => ({
  hasText: !!p.text,
  hasFunctionCall: !!p.functionCall,
  hasThought: !!p.thought
})), null, 2));
```

---

## 9. Cost Estimates

### Per-Item Cost Breakdown

Based on COST-MODEL-001:

| Component | Cost per Item |
|-----------|---------------|
| Gemini 3 Pro | ~$0.004 |
| Google Lens (SerpAPI) | ~$0.015 |
| Barcode Lookup (amortized) | ~$0.005 |
| Web Search (Gemini + grounding) | ~$0.014 |
| **Total (typical)** | **~$0.04** |

**With Session Persistence:**

When using `processItemWithGeminiPersistent()`, subsequent catalogs of the same item achieve significant cost savings through context caching and tool call deduplication. See [SPEC-PIPE-003](./SPEC-PIPE-003-session-persistence.md#cost-savings-analysis) for detailed analysis.

### Cost Logging

```typescript
export async function logCosts(
  itemId: string,
  toolsUsed: string[]
): Promise<void> {
  const toolCosts: Record<string, number> = {
    google_lens_search: 0.015,
    barcode_lookup: 0.005,
    web_search: 0.014
  };

  const geminiCost = 0.004;
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

### Cloud Function Resources

```typescript
// From onItemCreatedGemini3.ts
{
  document: 'items/{itemId}',
  secrets: [serpApiKey],
  region: 'us-central1',
  memory: '512MiB',
  timeoutSeconds: 120
}
```

| Resource | Value |
|----------|-------|
| Memory | 512 MiB |
| Timeout | 120 seconds |
| Region | us-central1 |

---

## Appendix A: Complete Tool Declarations

```typescript
export const CATALOG_TOOLS: Tool[] = [
  {
    functionDeclarations: [
      {
        name: 'google_lens_search',
        description: 'Search for product information using visual matching.',
        parameters: {
          type: 'object',
          properties: {
            image_url: {
              type: 'string',
              description: 'Public URL of the product image'
            }
          },
          required: ['image_url']
        }
      }
    ]
  },
  {
    functionDeclarations: [
      {
        name: 'barcode_lookup',
        description: 'Look up product information by barcode number.',
        parameters: {
          type: 'object',
          properties: {
            code: {
              type: 'string',
              description: 'The barcode number'
            },
            symbology: {
              type: 'string',
              enum: ['upc_a', 'upc_e', 'ean_13', 'ean_8', 'qr', 'code_128'],
              description: 'The barcode format (optional)'
            }
          },
          required: ['code']
        }
      }
    ]
  },
  {
    functionDeclarations: [
      {
        name: 'web_search',
        description: 'Search e-commerce sites for current pricing.',
        parameters: {
          type: 'object',
          properties: {
            query: {
              type: 'string',
              description: 'Search query'
            }
          },
          required: ['query']
        }
      }
    ]
  }
];
```

---

## Appendix B: Sequence Diagram

```
┌──────┐          ┌─────────┐          ┌──────────┐          ┌───────────┐
│Client│          │Firestore│          │ Cloud Fn │          │ Gemini 3  │
└──┬───┘          └────┬────┘          └────┬─────┘          └─────┬─────┘
   │                   │                    │                      │
   │ Create item doc   │                    │                      │
   │──────────────────>│                    │                      │
   │                   │                    │                      │
   │                   │ onCreate trigger   │                      │
   │                   │───────────────────>│                      │
   │                   │                    │                      │
   │                   │                    │ generateContent      │
   │                   │                    │ (image + tools)      │
   │                   │                    │─────────────────────>│
   │                   │                    │                      │
   │                   │                    │  functionCall:       │
   │                   │                    │  google_lens_search  │
   │                   │                    │<─────────────────────│
   │                   │                    │                      │
   │                   │                    │──┐                   │
   │                   │                    │  │ Execute tool      │
   │                   │                    │<─┘                   │
   │                   │                    │                      │
   │                   │                    │ functionResponse +   │
   │                   │                    │ thoughtSignature     │
   │                   │                    │─────────────────────>│
   │                   │                    │                      │
   │                   │                    │  functionCall:       │
   │                   │                    │  web_search          │
   │                   │                    │<─────────────────────│
   │                   │                    │                      │
   │                   │                    │──┐                   │
   │                   │                    │  │ Execute tool      │
   │                   │                    │<─┘                   │
   │                   │                    │                      │
   │                   │                    │ functionResponse +   │
   │                   │                    │ thoughtSignature     │
   │                   │                    │─────────────────────>│
   │                   │                    │                      │
   │                   │                    │  CatalogItem JSON    │
   │                   │                    │<─────────────────────│
   │                   │                    │                      │
   │                   │  Update document   │                      │
   │                   │  status: complete  │                      │
   │                   │<───────────────────│                      │
   │                   │                    │                      │
```

---

## Related Specifications

- [SPEC-ARCH-001: System Overview](./SPEC-ARCH-001-system-overview.md)
- [SPEC-ARCH-002: Layer 1 and Layer 2 Pipeline](./SPEC-ARCH-002-layer1-layer2-pipeline.md)
- [SPEC-DATA-001: Firestore Schema](./SPEC-DATA-001-firestore-schema.md)
- [SPEC-API-001: Cloud Functions](./SPEC-API-001-cloud-functions.md)
- [SPEC-PIPE-003: Session Persistence](./SPEC-PIPE-003-session-persistence.md)
