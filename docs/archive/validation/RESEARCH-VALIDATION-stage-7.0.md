# Research Validation Report: Stage 7.0

**Created**: 2026-01-14
**Stage**: 7.0 - Layer 2 Gemini 3 Pro Implementation
**Technologies Verified**: Gemini 3 Pro, SerpAPI Google Lens, UPCitemdb, @google/genai SDK, Google Search Grounding

---

## Executive Summary

The design document `2026-01-13-gemini-3-pipeline-design.md` contains several technical claims that require correction. The Gemini 3 Pro model ID should be `gemini-3-pro-preview` (not `gemini-3-pro`), the SDK import statement uses `GoogleGenAI` class (not `GoogleGenerativeAI`), UPCitemdb pricing is significantly higher than stated ($99/month Dev plan, not $0.005/lookup), and the UPCitemdb response does not include a `category` field. Google Search Grounding pricing at $0.014/query is accurate for Gemini 3 models.

---

## Verified Technical Claims

### Claim 1: Gemini 3 Pro Model ID

- **Verification Status**: **CORRECTED**
- **Original Claim**: `gemini-3-pro`
- **Actual Value**: `gemini-3-pro-preview`
- **Source**: [Gemini 3 Developer Guide](https://ai.google.dev/gemini-api/docs/gemini-3)
- **Notes**: The model is currently in preview. When it reaches GA (General Availability), the model ID may change. The design document should use `gemini-3-pro-preview` until Google announces the stable release name.

---

### Claim 2: Gemini 3 Pro Pricing - Input Tokens

- **Verification Status**: **VERIFIED**
- **Original Claim**: $2-4/M input tokens
- **Actual Value**:
  - $2.00/M tokens for prompts <= 200K tokens
  - $4.00/M tokens for prompts > 200K tokens
- **Source**: [Gemini API Pricing](https://ai.google.dev/gemini-api/docs/pricing)
- **Notes**: The range stated in the design is accurate. Context caching is available at $0.20-0.40/M tokens (input) with storage at $4.50/M tokens/hour.

---

### Claim 3: Gemini 3 Pro Pricing - Output Tokens

- **Verification Status**: **VERIFIED**
- **Original Claim**: $12-18/M output tokens
- **Actual Value**:
  - $12.00/M tokens for prompts <= 200K tokens
  - $18.00/M tokens for prompts > 200K tokens
- **Source**: [Gemini API Pricing](https://ai.google.dev/gemini-api/docs/pricing)
- **Notes**: Output pricing includes thinking tokens. Batch processing offers 50% discount ($6.00/$9.00 per M tokens).

---

### Claim 4: Gemini 3 Pro Native Tool Calling Support

- **Verification Status**: **VERIFIED**
- **Original Claim**: Native tool calling support
- **Actual Value**: Yes - supports Google Search, File Search, Code Execution, URL Context, and custom Function Calling
- **Source**: [Gemini 3 Developer Guide](https://ai.google.dev/gemini-api/docs/gemini-3), [Function Calling Documentation](https://ai.google.dev/gemini-api/docs/function-calling)
- **Notes**: Limitation: Combining built-in tools with custom function calling is not yet supported in the same request. The design's tool definitions (google_lens_search, barcode_lookup, web_search) would all be custom function declarations, so this limitation does not affect the architecture.

---

### Claim 5: Gemini 3 Pro Vision/Image Analysis Support

- **Verification Status**: **VERIFIED**
- **Original Claim**: Vision/image analysis support
- **Actual Value**: Yes - multimodal with configurable image resolution levels (low through ultra_high)
- **Source**: [Gemini 3 Developer Guide](https://ai.google.dev/gemini-api/docs/gemini-3)
- **Notes**: The model supports "complex multimodal tasks" including image analysis. Media resolution can be configured via `media_resolution_low`, `media_resolution_medium`, `media_resolution_high`, `media_resolution_ultra_high` parameters.

---

### Claim 6: Gemini 3 Pro JSON Schema Mode (Structured Output)

- **Verification Status**: **VERIFIED**
- **Original Claim**: JSON schema mode (structured output)
- **Actual Value**: Yes - via `response_mime_type: "application/json"` and `response_json_schema` parameters
- **Source**: [Gemini 3 Developer Guide](https://ai.google.dev/gemini-api/docs/gemini-3)
- **Notes**: The design document correctly shows `responseMimeType: "application/json"` and `responseSchema` in the generation config. The parameter name in the new SDK is `response_json_schema` (snake_case).

---

### Claim 7: SerpAPI Google Lens Pricing

- **Verification Status**: **VERIFIED**
- **Original Claim**: $0.015 per search ($75/5K developer plan)
- **Actual Value**: Developer plan is $75/month for 5,000 searches = $0.015 per search
- **Source**: [SerpAPI Pricing](https://serpapi.com/pricing)
- **Notes**: Pricing is accurate. Cached searches (within 1 hour) are free and don't count toward monthly limits. Only successful searches count.

---

### Claim 8: SerpAPI Google Lens API Endpoint

- **Verification Status**: **VERIFIED**
- **Original Claim**: `https://serpapi.com/search?engine=google_lens`
- **Actual Value**: Confirmed endpoint: `https://serpapi.com/search?engine=google_lens`
- **Source**: [SerpAPI Google Lens API](https://serpapi.com/google-lens-api)
- **Notes**: Additional parameters include `url` (image URL), `type` (search type: all, products, visual_matches, exact_matches, about_this_image), and `hl` (language code).

---

### Claim 9: SerpAPI Google Lens Response Structure

- **Verification Status**: **VERIFIED**
- **Original Claim**: Response includes visual_matches array with title, brand, price
- **Actual Value**: visual_matches array contains:
  - `position` (integer)
  - `title` (string)
  - `link` (string)
  - `source` (string)
  - `source_icon` (string)
  - `thumbnail` / `image` URLs with dimensions
  - `price` object (value, extracted_value, currency)
  - `in_stock` (boolean)
  - `condition` (string)
  - `exact_matches` (boolean)
  - `serpapi_exact_matches_link` (string)
- **Source**: [SerpAPI Google Lens API](https://serpapi.com/google-lens-api)
- **Notes**: The `brand` field is not explicitly listed in the response schema; brand information is typically extracted from the `title` or `source` fields. The design may need to account for this.

---

### Claim 10: UPCitemdb Pricing

- **Verification Status**: **CORRECTED**
- **Original Claim**: $0.005 per lookup (implying ~$0.01 in the cost table)
- **Actual Value**:
  - **Free (Explorer)**: 100 requests/day, no signup required
  - **Dev Plan**: $99/month for 20,000 lookups/day ($0.00495/lookup if using max daily)
  - **Pro Plan**: $699/month for 150,000 lookups/day
  - **Overage**: $0.04 per 100 lookups ($0.0004/lookup) for Dev/Pro plans
- **Source**: [UPCitemdb API](https://www.upcitemdb.com/api/)
- **Notes**: The design document claims $0.01 per lookup. Actual pricing depends on the plan:
  - If using Free tier: $0.00/lookup (limited to 100/day)
  - If using Dev plan at capacity: ~$0.00495/lookup
  - Monthly cost for Dev plan is $99, not usage-based

  **Recommendation**: Update cost analysis to reflect monthly subscription model rather than per-lookup pricing. For typical usage (1000 items/month), the Dev plan cost would be $99/month regardless of lookups.

---

### Claim 11: UPCitemdb API Endpoint

- **Verification Status**: **CORRECTED**
- **Original Claim**: `https://api.upcitemdb.com/prod/trial/lookup`
- **Actual Value**:
  - **Free tier**: `https://api.upcitemdb.com/prod/trial/lookup`
  - **Paid plans**: `https://api.upcitemdb.com/prod/v1/lookup`
- **Source**: [UPCitemdb Getting Started](https://www.upcitemdb.com/wp/docs/main/development/getting-started/)
- **Notes**: The claim is correct for the free trial endpoint. Paid plans use `/prod/v1/lookup` with API key authentication in headers.

---

### Claim 12: UPCitemdb Response Structure

- **Verification Status**: **PARTIALLY VERIFIED / CORRECTED**
- **Original Claim**: Response includes items array with title, brand, model, category
- **Actual Value**: Items array includes:
  - `ean` - EAN/UPC code
  - `title` - Product title
  - `description` - Product description
  - `brand` - Brand name
  - `model` - Model number
  - `color` - Product color
  - `size` - Product size
  - `dimension` - Product dimensions
  - `weight` - Product weight
  - `lowest_recorded_price` / `highest_recorded_price`
  - `images` - Array of image URLs
  - `offers` - Array of merchant offers (merchant, currency, price, link)
- **Source**: [UPCitemdb API Documentation](https://devs.upcitemdb.com/), [Public APIs Directory](https://publicapis.io/upc-database-api)
- **Notes**:
  - **title**: VERIFIED
  - **brand**: VERIFIED
  - **model**: VERIFIED
  - **category**: **NOT FOUND** - The `category` field does not appear in the response structure. Category can be used as a search filter parameter but is not returned in lookup responses.

  **Recommendation**: Update the design to not rely on `category` from UPCitemdb. The model (Gemini 3 Pro) should determine category from the visual analysis and title/description returned.

---

### Claim 13: Google Search Grounding Pricing

- **Verification Status**: **VERIFIED**
- **Original Claim**: $0.014 per query ($14/1K queries)
- **Actual Value**: $14 per 1,000 search queries for Gemini 3 models (after free tier of 5,000 prompts/month)
- **Source**: [Gemini API Pricing](https://ai.google.dev/gemini-api/docs/pricing)
- **Notes**:
  - Free tier: 5,000 prompts/month
  - Billing is per search query, not per prompt - if the model executes multiple searches in one API call, each counts separately
  - Gemini 2.5 models have different pricing: $35/1,000 grounded prompts (not queries)

---

### Claim 14: Google Search Grounding Integration

- **Verification Status**: **VERIFIED**
- **Original Claim**: Integration via `googleSearchRetrieval` tool
- **Actual Value**: Integrated as a built-in tool via the Gemini API
- **Source**: [Grounding with Google Search](https://ai.google.dev/gemini-api/docs/google-search)
- **Notes**: The design uses custom function calling for web_search rather than the built-in Google Search grounding. This is a valid approach and avoids the limitation of not being able to combine built-in tools with custom function calling.

---

### Claim 15: @google/genai SDK Version

- **Verification Status**: **UPDATED**
- **Original Claim**: ^1.29.0 or later
- **Actual Value**: Latest version is **1.35.0** (as of 2026-01-09)
- **Source**: [@google/genai npm](https://www.npmjs.com/package/@google/genai)
- **Notes**: The minimum version claim is valid (1.29.0+ works), but should be updated to the current version for new projects. The SDK reached GA in May 2025 and is actively maintained.

---

### Claim 16: @google/genai SDK Import Statement

- **Verification Status**: **CORRECTED**
- **Original Claim**: `import { GoogleGenerativeAI } from '@google/genai'`
- **Actual Value**: `import { GoogleGenAI } from '@google/genai'`
- **Source**: [Migrate to Google GenAI SDK](https://ai.google.dev/gemini-api/docs/migrate), [Function Calling Documentation](https://ai.google.dev/gemini-api/docs/function-calling)
- **Notes**:
  - The class name changed from `GoogleGenerativeAI` (old @google/generative-ai package) to `GoogleGenAI` (new @google/genai package)
  - The old package @google/generative-ai is deprecated (support ended August 31, 2025)
  - The design document code samples use the old API pattern and must be updated

---

### Claim 17: @google/genai Tool Calling API Pattern

- **Verification Status**: **CORRECTED**
- **Original Claim**:
```typescript
const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY);
const model = genAI.getGenerativeModel({
  model: "gemini-3-pro",
  tools: CATALOG_TOOLS,
  ...
});
```

- **Actual Value**:
```typescript
import { GoogleGenAI, Type } from '@google/genai';

const ai = new GoogleGenAI({ apiKey: process.env.GOOGLE_API_KEY });

const response = await ai.models.generateContent({
  model: 'gemini-3-pro-preview',
  contents: 'user message',
  config: {
    tools: [{
      functionDeclarations: [toolDeclaration]
    }],
    // other config options
  }
});

// Access function calls
if (response.functionCalls && response.functionCalls.length > 0) {
  const functionCall = response.functionCalls[0];
}
```
- **Source**: [Function Calling with Gemini API](https://ai.google.dev/gemini-api/docs/function-calling), [Migrate to Google GenAI SDK](https://ai.google.dev/gemini-api/docs/migrate)
- **Notes**: The new SDK uses:
  - `GoogleGenAI` class instead of `GoogleGenerativeAI`
  - `ai.models.generateContent()` instead of `model.generateContent()`
  - `config` object for tools, generation config, etc.
  - Tool declarations use `functionDeclarations` array
  - Parameter schema uses `parametersJsonSchema` or `Type` enum

---

## Contradictions Resolved

### 1. Model ID Discrepancy
- **Original**: `gemini-3-pro`
- **Corrected**: `gemini-3-pro-preview`
- **Reason**: Model is currently in preview status

### 2. SDK Class Name Discrepancy
- **Original**: `GoogleGenerativeAI`
- **Corrected**: `GoogleGenAI`
- **Reason**: The design references the deprecated @google/generative-ai package API

### 3. UPCitemdb Pricing Model
- **Original**: Per-lookup pricing ($0.005-0.01)
- **Corrected**: Monthly subscription ($99/month Dev plan)
- **Reason**: UPCitemdb uses subscription-based pricing, not per-lookup

### 4. UPCitemdb Response Category Field
- **Original**: Response includes `category` field
- **Corrected**: No `category` field in response
- **Reason**: Category is a search filter, not a response field

---

## Curated Sources

### Official Documentation
- **Gemini API Pricing**: [https://ai.google.dev/gemini-api/docs/pricing](https://ai.google.dev/gemini-api/docs/pricing)
- **Gemini 3 Developer Guide**: [https://ai.google.dev/gemini-api/docs/gemini-3](https://ai.google.dev/gemini-api/docs/gemini-3)
- **Function Calling with Gemini**: [https://ai.google.dev/gemini-api/docs/function-calling](https://ai.google.dev/gemini-api/docs/function-calling)
- **SDK Migration Guide**: [https://ai.google.dev/gemini-api/docs/migrate](https://ai.google.dev/gemini-api/docs/migrate)
- **Google Search Grounding**: [https://ai.google.dev/gemini-api/docs/google-search](https://ai.google.dev/gemini-api/docs/google-search)

### Third-Party APIs
- **SerpAPI Pricing**: [https://serpapi.com/pricing](https://serpapi.com/pricing)
- **SerpAPI Google Lens API**: [https://serpapi.com/google-lens-api](https://serpapi.com/google-lens-api)
- **UPCitemdb API**: [https://www.upcitemdb.com/api/](https://www.upcitemdb.com/api/)
- **UPCitemdb Documentation**: [https://devs.upcitemdb.com/](https://devs.upcitemdb.com/)
- **UPCitemdb Getting Started**: [https://www.upcitemdb.com/wp/docs/main/development/getting-started/](https://www.upcitemdb.com/wp/docs/main/development/getting-started/)

### SDK Package
- **@google/genai npm**: [https://www.npmjs.com/package/@google/genai](https://www.npmjs.com/package/@google/genai)

---

## Warnings

### 1. Gemini 3 Pro Preview Status
The Gemini 3 Pro model is currently in preview. Pricing, model ID, and capabilities may change when the model reaches GA. Monitor Google's announcements for updates.

### 2. UPCitemdb Free Tier Limitations
The free tier (100 requests/day) may be insufficient for testing. Consider the Dev plan ($99/month) for development and production.

### 3. SerpAPI Google Lens Brand Extraction
The Google Lens API does not return a dedicated `brand` field. Brand information must be extracted from `title` or `source` fields, which requires additional parsing logic.

### 4. Multiple Search Queries Billing
When using Google Search Grounding with Gemini 3, each individual search query executed by the model is billed separately. A single prompt may result in multiple billable queries.

### 5. Built-in vs Custom Tool Limitation
Gemini 3 does not yet support combining built-in tools (Google Search, Code Execution) with custom function calling in the same request. The design's approach of using only custom function declarations avoids this issue.

---

## Verification Summary

| Category | Count |
|----------|-------|
| **Total claims identified** | 17 |
| **Verified as accurate** | 10 |
| **Updated/corrected** | 6 |
| **Partially verified** | 1 |

### Detailed Breakdown

| Claim | Status |
|-------|--------|
| Gemini 3 Pro Model ID | CORRECTED |
| Gemini 3 Pro Input Pricing | VERIFIED |
| Gemini 3 Pro Output Pricing | VERIFIED |
| Gemini 3 Pro Tool Calling | VERIFIED |
| Gemini 3 Pro Vision Support | VERIFIED |
| Gemini 3 Pro JSON Schema Mode | VERIFIED |
| SerpAPI Google Lens Pricing | VERIFIED |
| SerpAPI Google Lens Endpoint | VERIFIED |
| SerpAPI Response Structure | VERIFIED |
| UPCitemdb Pricing | CORRECTED |
| UPCitemdb Endpoint | CORRECTED |
| UPCitemdb Response Structure | PARTIALLY VERIFIED |
| Google Search Grounding Pricing | VERIFIED |
| Google Search Grounding Integration | VERIFIED |
| @google/genai SDK Version | UPDATED |
| @google/genai Import Statement | CORRECTED |
| @google/genai Tool Calling Pattern | CORRECTED |

---

## Required Design Document Updates

The following corrections should be applied to `docs/plans/2026-01-13-gemini-3-pipeline-design.md`:

1. **Line 243**: Change `model: "gemini-3-pro"` to `model: "gemini-3-pro-preview"`

2. **Line 240**: Update import and initialization:
   ```typescript
   // Old (incorrect):
   const genAI = new GoogleGenerativeAI(process.env.GOOGLE_API_KEY);
   const model = genAI.getGenerativeModel({...});

   // New (correct):
   import { GoogleGenAI, Type } from '@google/genai';
   const ai = new GoogleGenAI({ apiKey: process.env.GOOGLE_API_KEY });
   const response = await ai.models.generateContent({...});
   ```

3. **Cost Table (Line 354)**: Update UPCitemdb cost from "$0.01 per lookup" to "Monthly subscription: $99/month (Dev plan) for 20K lookups/day"

4. **Remove `category` from UPCitemdb expectations**: The response does not include category; Gemini 3 Pro should determine category from visual analysis

---

*Report generated by Research Verification Agent*
*Verification completed: 2026-01-14*
