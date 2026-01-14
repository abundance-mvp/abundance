# AI Pipeline v2: Gemini 3 Pro Simplification

**Created**: 2026-01-13
**Status**: Draft
**Supersedes**: DESIGN-004 (partial), ADR-014, ADR-015

---

## Overview

This document specifies the refactored AI pipeline for cataloging household items. The architecture consolidates from 4 models to 1, using Gemini 3 Pro with native tool calling.

**Key Changes:**
- Layer 1: Quality-only detection (no barcode, no categorization)
- Layer 2: Single Gemini 3 Pro with tools (replaces Flash-Lite + Claude Haiku + Claude Sonnet)
- Layer 3: Eliminated

**Benefits:**
- Simpler architecture (1 model vs 4)
- Better reasoning (Gemini 3 Pro benchmarks)
- Similar cost (~$0.03-0.04 per item)
- Unified tool calling (barcode, Google Lens, web search)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          iOS CLIENT                              │
│                                                                  │
│  Layer 1: Quality-Focused Detection (MVP)                       │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ - Real-time 2 FPS object detection (YOLOv11n)              │ │
│  │ - Quality assessment (blur, lighting, aesthetics)          │ │
│  │ - Subject masking + cropping                               │ │
│  │ - NO barcode detection (MVP - Gemini 3 Pro handles)        │ │
│  │ - NO category detection (Gemini 3 Pro handles)             │ │
│  │                                                             │ │
│  │ Trigger: Quality > 0.65 AND Confidence > 0.70              │ │
│  │ Output: Cropped object image (JPG)                         │ │
│  └────────────────────────────────────────────────────────────┘ │
└───────────────────────────────┬─────────────────────────────────┘
                                ↓
┌───────────────────────────────────────────────────────────────────┐
│                      GOOGLE CLOUD PLATFORM                         │
│                                                                    │
│  Layer 2: Gemini 3 Pro (Single Model with Tools)                  │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ - Receives cropped image                                      │ │
│  │ - Analyzes visually (category, color, condition, dimensions) │ │
│  │ - Detects barcodes in image if present                       │ │
│  │ - Calls tools: google_lens, barcode_lookup, web_search       │ │
│  │ - Verifies tool results against image                        │ │
│  │ - Searches e-commerce for pricing                            │ │
│  │ - Outputs final catalog entry (or multiple if multi-object)  │ │
│  │                                                               │ │
│  │ Model: Gemini 3 Pro                                          │ │
│  │ Cost: ~$0.03-0.04 per item                                   │ │
│  └──────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────┘
```

---

## Output Schema

```typescript
interface CatalogItem {
  // Core identification
  name: string;                    // "Nike Air Max 90"
  category: string;                // "footwear" (free-form)
  subCategory: string;             // "sneakers" (free-form)

  // Product details
  brand: string | null;            // "Nike"
  model: string | null;            // "Air Max 90"
  color: string;                   // "white/red"
  condition: Condition;            // "good"
  dimensions: string | null;       // "size 10 mens", or "barcode: 012345" if lookup failed
  quantity: number;                // 1 (or more if multiple identical items)

  // Valuation
  estimatedValue: number | null;   // 85.00 (per-unit, condition-adjusted)
  confidence: Confidence;          // "high"
}

type Condition = "new" | "like-new" | "good" | "fair" | "poor";
type Confidence = "high" | "medium" | "low";
```

**Schema Examples:**

| Item | category | subCategory | dimensions | quantity |
|------|----------|-------------|------------|----------|
| Nike Air Max | footwear | sneakers | size 10 mens | 1 |
| Toilet paper 6-pack | household | paper goods | 6 rolls | 6 |
| Coleman stove | outdoor | camping stove | 2-burner | 1 |
| Unknown item w/ barcode | kitchen | appliance | barcode: 012345678905 | 1 |

---

## Tool Definitions

```typescript
const tools = [
  {
    name: "google_lens_search",
    description: "Search for product information using visual matching. Use to identify products by appearance, find brand/model info, or get pricing.",
    parameters: {
      type: "object",
      properties: {
        image_url: {
          type: "string",
          description: "Public URL of the product image"
        }
      },
      required: ["image_url"]
    }
  },
  {
    name: "barcode_lookup",
    description: "Look up product information by barcode number. Use when you detect a barcode (UPC, EAN, QR code) visible in the image.",
    parameters: {
      type: "object",
      properties: {
        code: {
          type: "string",
          description: "The barcode number"
        },
        symbology: {
          type: "string",
          enum: ["upc_a", "upc_e", "ean_13", "ean_8", "qr", "code_128"],
          description: "The barcode format"
        }
      },
      required: ["code"]
    }
  },
  {
    name: "web_search",
    description: "Search e-commerce sites for current pricing. Use AFTER identifying the product to find estimated value.",
    parameters: {
      type: "object",
      properties: {
        query: {
          type: "string",
          description: "Search query, e.g., 'Nike Air Max 90 size 10 price'"
        }
      },
      required: ["query"]
    }
  }
]
```

---

## System Prompt

```
You are an expert product cataloger. Analyze the provided image and create detailed catalog entries.

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
   - Target sites: Amazon, eBay, Etsy, Facebook Marketplace, Poshmark

5. Return complete catalog entry(ies) with confidence level.

MULTI-OBJECT RULES:
1. If image contains DIFFERENT objects:
   - Return an array of CatalogItem entries, one per distinct object

2. If image contains MULTIPLE of the SAME object:
   - Return single CatalogItem with quantity > 1
   - Example: 6 rolls of toilet paper → quantity: 6
   - estimatedValue should be per-unit price

3. If objects partially overlap or are unclear:
   - Catalog the primary/foreground object
   - Note others in dimensions: "additional items visible"

CONFIDENCE SCORING:
- "high": Google Lens returned exact_matches:true OR barcode lookup succeeded
  AND visual verification confirms the match
- "medium": Google Lens returned similar products but not exact,
  OR barcode lookup failed but Google Lens found likely match
- "low": Only related suggestions available, relying primarily on visual analysis

BARCODE FAILURE:
If barcode_lookup fails, include the barcode value in dimensions field as
"barcode: {value}" for future reference. Continue with google_lens_search.

PRICING:
- Use SOLD prices when available (eBay sold listings)
- Apply condition multipliers to new retail price:
  - new: 1.0
  - like-new: 0.85
  - good: 0.65
  - fair: 0.45
  - poor: 0.25
- If range found, use midpoint
- If no pricing found, set estimatedValue: null

OUTPUT FORMAT:
Return valid JSON matching the CatalogItem schema (or array for multi-object).
```

---

## Gemini 3 Pro Configuration

```typescript
const generationConfig = {
  temperature: 0.1,              // Low for consistent structured output
  topP: 0.95,
  maxOutputTokens: 1024,
  responseMimeType: "application/json",
  responseSchema: catalogItemSchema
};

// Model initialization
const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY);
const model = genAI.getGenerativeModel({
  model: "gemini-3-pro",
  tools: CATALOG_TOOLS,
  generationConfig: GENERATION_CONFIG,
  systemInstruction: SYSTEM_PROMPT
});
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

## Data Flow

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
   │                            │      "I see a shoe..."    │
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
   │                            │      (Pro synthesizes)    │
   │                            │                           │
   │                            │ <── Final CatalogItem(s)  │
   │                            │                           │
   │ Firestore update           │                           │
   │ <───────────────────────── │                           │
   │                            │                           │
   │ (Real-time listener)       │                           │
   │ Display in UI              │                           │
```

---

## Gemini 3 Pro Reasoning Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ Gemini 3 Pro Reasoning Flow                                     │
│                                                                 │
│  1. Analyze image visually                                      │
│     ↓                                                           │
│  2. Detect barcode? → YES → barcode_lookup                     │
│     ↓                       ↓                                   │
│  3. google_lens_search ←────┘                                   │
│     ↓                                                           │
│  4. Synthesize: Do I have HIGH/MEDIUM confidence?              │
│     ↓ YES                                                       │
│  5. web_search("{brand} {model} {condition} price")            │
│     ↓                                                           │
│  6. Calculate estimatedValue with condition adjustment          │
│     ↓                                                           │
│  7. Return final CatalogItem(s)                                │
└─────────────────────────────────────────────────────────────────┘
```

---

## Cost Analysis

**Cost per Item**

| Path | Components | Cost |
|------|------------|------|
| **Visual + Pricing** | Gemini 3 Pro + Google Lens + Web Search | $0.004 + $0.015 + $0.014 = **$0.033** |
| **Barcode + Visual + Pricing** | Gemini 3 Pro + Barcode + Google Lens + Web Search | $0.004 + $0.01 + $0.015 + $0.014 = **$0.043** |

**Component Costs**

| Component | Cost | Notes |
|-----------|------|-------|
| Gemini 3 Pro | ~$0.004 | $2-4/M input, $12-18/M output |
| Google Lens (SerpAPI) | $0.015 | Per search |
| Barcode (UPCitemdb) | $0.01 | Per lookup |
| Web Search | ~$0.014 | Google Search grounding ($14/1K queries) |

**Comparison to Old Architecture**

| Path | Old Architecture | New Architecture |
|------|------------------|------------------|
| Visual only | $0.019 | $0.021 |
| Barcode + Visual | $0.004 | $0.031 |

Note: New architecture costs more for barcode items but provides better verification and richer data.

---

## Error Handling

**Barcode Lookup Failure**

```typescript
async function handleBarcodeFailure(
  barcode: string,
  imageUrl: string
): Promise<ToolResult> {
  console.warn(`Barcode lookup failed for: ${barcode}`);

  // Preserve barcode in dimensions for manual lookup later
  const dimensionsNote = `barcode: ${barcode}`;

  // Continue with Google Lens
  const lensResult = await googleLensSearch(imageUrl);

  return {
    name: "google_lens_search",
    result: {
      ...lensResult,
      failedBarcode: barcode,
      dimensionsNote
    },
    success: true
  };
}
```

**Retry Logic**

```typescript
async function withRetry<T>(
  fn: () => Promise<T>,
  opts: { maxAttempts: number; backoffMs: number }
): Promise<T> {
  let lastError: Error;

  for (let i = 0; i < opts.maxAttempts; i++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error as Error;
      if (i < opts.maxAttempts - 1) {
        await sleep(opts.backoffMs * Math.pow(2, i));
      }
    }
  }

  throw lastError!;
}
```

---

## Implementation Steps

| Step | Action | Risk |
|------|--------|------|
| 1 | Update spec documents using `verified-stage-development` | None |
| 2 | Create new directory structure | None |
| 3 | Implement `catalog-item.ts` schema | None |
| 4 | Implement `gemini-service.ts` with Gemini 3 Pro | Low |
| 5 | Implement `google-lens.ts` | Low |
| 6 | Implement `barcode-lookup.ts` (UPCitemdb) | Low |
| 7 | Implement `web-search.ts` | Low |
| 8 | Implement `tool-executor.ts` | Low |
| 9 | Implement `orchestrator.ts` | Medium |
| 10 | Write all tests | None |
| 11 | Deploy to staging, test with real images | Medium |

---

## Spec Documents to Update

| Document | Action |
|----------|--------|
| `DESIGN-004-computer-vision-pipeline.md` | Major update — reference this new design |
| `ADR-014-cloud-ai-provider-selection.md` | Update — Gemini 3 Pro replaces Flash-Lite |
| `ADR-015-ai-reasoning-layer-architecture.md` | Deprecate — Layer 3 eliminated |
| `DESIGN-041-layer-2a-json-schema.md` | Replace with new catalog-item schema |

---

## Decisions Log

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Layer 1 categorization | Skip | Gemini 3 Pro handles all semantic work |
| Layer 1 barcode detection | Disabled (MVP) | Simplifies trigger logic |
| Layer 2 model | Gemini 3 Pro | Best reasoning, native tool calling |
| Layer 3 (Claude Sonnet) | Eliminated | Gemini 3 Pro handles synthesis |
| Claude Haiku parsing | Eliminated | Gemini 3 Pro parses tool results |
| Barcode API | UPCitemdb only | Simpler, broader coverage |
| Categories | Free-form (category + subCategory) | Flexible, normalize in UI |
| Pricing | Web search after identification | E-commerce sites for market value |

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2026-01-13 | 1.0 | Initial design — Gemini 3 Pro simplification | AI Pipeline Refactor |
