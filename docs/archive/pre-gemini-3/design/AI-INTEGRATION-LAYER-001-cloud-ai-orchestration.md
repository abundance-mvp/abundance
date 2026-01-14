# AI-INTEGRATION-LAYER-001: Cloud AI Orchestration

**Created**: 2025-11-08
**Stage**: 2.3 - Backend Cloud Architecture
**Status**: Approved
**References**:
- docs/design/DESIGN-004-computer-vision-pipeline.md (4-layer AI architecture)
- docs/adr/ADR-014-cloud-ai-provider-selection.md
- docs/adr/ADR-015-ai-reasoning-layer-architecture.md
- docs/validation/RESEARCH-VALIDATION-stage-2.3.md

---

## AI Pipeline Flow

```
iOS (Layer 1: On-device Vision)
  ↓ POST /api/v1/items
Cloud Functions (Layer 2-3):
  1. onItemCreated → Gemini Vision (Layer 2a: attributes)
  2. onLayer2aComplete → SerpAPI (Layer 2b: product ID)
  3. onLayer2bComplete → Claude Batch API (Layer 3: synthesis)
  4. Item status updated to "complete"
```

---

## Layer 2a: Gemini Vision (Attribute Extraction)

**Provider**: Google Generative AI SDK (Gemini 2.5 Flash-Lite)
**Cost**: $0.000249/image (verified 2025-11-08)
**Purpose**: Extract color, material, condition, category

**Implementation** (in `onItemCreated` Cloud Function):
```javascript
const { GoogleGenerativeAI } = require('@google/genai');

async function extractAttributes(imageURL) {
  const genAI = new GoogleGenerativeAI({
    apiKey: process.env.GOOGLE_API_KEY, // API key authentication
    // OR use Application Default Credentials for GCP
  });

  const model = genAI.getGenerativeModel({
    model: 'gemini-2.5-flash-lite',
    generationConfig: {
      maxOutputTokens: 256,
      temperature: 0.2,
      responseMimeType: 'application/json',
      responseSchema: {
        type: 'object',
        properties: {
          productName: { type: 'string' },
          color: { type: 'string' },
          material: { type: 'string' },
          condition: {
            type: 'string',
            enum: ['new', 'excellent', 'good', 'fair', 'poor']
          },
          category: { type: 'string' }
        }
      }
    }
  });

  const request = {
    contents: [{
      role: 'user',
      parts: [
        { fileData: { mimeType: 'image/jpeg', fileUri: imageURL } },
        { text: 'Extract: product name, color, material, condition (new/excellent/good/fair/poor), and category.' }
      ]
    }]
  };

  const response = await model.generateContent(request);
  return JSON.parse(response.response.text());
}
```

**Example Output**:
```json
{
  "productName": "Coleman Evanston Tent",
  "color": "green",
  "material": "polyester",
  "condition": "good",
  "category": "camping"
}
```

---

## Layer 2b: SerpAPI (Product Identification)

**Provider**: SerpAPI Google Lens
**Cost**: $0.015/search, Developer Plan $75/month (verified 2025-11-08)
**Purpose**: Identify product name, brand, model via visual search

**Implementation** (in `onLayer2aComplete` Cloud Function):
```javascript
const axios = require('axios');

async function identifyProduct(imageURL, barcode) {
  // Barcode lookup (Phase 2 - not implemented in MVP)
  if (barcode) {
    return {
      productName: null,
      brand: null,
      model: null,
      source: 'barcode',
      confidence: 0
    };
  }

  // Google Lens visual search
  const response = await axios.get('https://serpapi.com/search', {
    params: {
      engine: 'google_lens',
      url: imageURL,
      api_key: process.env.SERPAPI_KEY
    }
  });

  const visualMatches = response.data.visual_matches || [];

  if (visualMatches.length === 0) {
    return {
      productName: null,
      source: 'visual',
      confidence: 0
    };
  }

  return {
    productName: visualMatches[0].title,
    brand: visualMatches[0].brand || null,
    model: visualMatches[0].model || null,
    source: 'visual',
    confidence: visualMatches[0].position === 1 ? 0.92 : 0.75
  };
}
```

**Example Output**:
```json
{
  "productName": "Coleman Evanston 8-Person Tent",
  "brand": "Coleman",
  "model": "Evanston 8-Person",
  "source": "visual",
  "confidence": 0.92
}
```

---

## Layer 3: Claude Batch API (Synthesis)

**Provider**: Anthropic Claude Sonnet 4.5 Batch API
**Cost**: $0.002027/inference (50% discount, verified 2025-11-08)
**Purpose**: Synthesize estimated value and reasoning

**Implementation** (in `onLayer2bComplete` Cloud Function):
```javascript
const Anthropic = require('@anthropic-ai/sdk');

async function synthesizeMetadata(aiAnalysis) {
  const anthropic = new Anthropic({
    apiKey: process.env.ANTHROPIC_API_KEY
  });

  const prompt = `
You are an AI assistant that synthesizes product metadata for home inventory cataloging.

Layer 2a (Attributes): ${JSON.stringify(aiAnalysis.layer2a)}
Layer 2b (Product ID): ${JSON.stringify(aiAnalysis.layer2b)}

Based on this information, provide:
1. Estimated market value (USD) - current resale value
2. Confidence level (high/medium/low)
3. Brief reasoning (1-2 sentences)

Return JSON format:
{
  "estimatedValue": number,
  "confidence": "high" | "medium" | "low",
  "reasoning": "string"
}
`;

  const message = await anthropic.messages.create({
    model: 'claude-sonnet-4-20250514',
    max_tokens: 512,
    messages: [{ role: 'user', content: prompt }]
  });

  return JSON.parse(message.content[0].text);
}
```

**Example Output**:
```json
{
  "estimatedValue": 249.99,
  "confidence": "high",
  "reasoning": "Brand: Coleman (premium camping brand). Model: Evanston 8-Person (large family tent). Condition: good. Market value: $249.99 (based on similar listings)."
}
```

---

## Error Handling

Each layer wrapped in try/catch. On failure, item status set to "failed" with error message.

**Example**:
```javascript
try {
  const layer2aResult = await extractAttributes(item.imageURL);
  await snap.ref.update({
    'aiAnalysis.layer2a': layer2aResult,
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });
} catch (error) {
  console.error('Layer 2a failed:', error);
  await snap.ref.update({
    status: 'failed',
    errorMessage: error.message,
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });
}
```

---

## Cost Projection (Month 6, 5K users)

**Assumptions**:
- 750 premium users
- 5 new items/month per premium user
- Total: 3,750 items/month

**AI Costs**:
- Layer 2a (Gemini): 3,750 × $0.000249 = $0.93
- Layer 2b (SerpAPI): 3,750 × $0.015 = $56.25
- Layer 3 (Claude Batch): 3,750 × $0.002027 = $7.60
- **Total AI**: $64.78/month

**Revenue**: 750 premium × $8/month = $6,000/month
**AI Margin**: 98.9%

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-08 | 1.0 | Initial AI orchestration design | Cloud Backend Architect |
