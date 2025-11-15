# ADR-014: Cloud AI Provider Selection for Object Analysis

**Status**: Accepted
**Date**: 2025-10-23
**Updated**: 2025-11-01 (Stage 2.1 verification)
**Deciders**: Engineering, ML/AI, Product, Finance
**Related**: DESIGN-004, gemini-2.5-flash-lite-verification.md, RECONCILIATION-design-004-vs-stage-2.1.md

---

## Context

Abundance's computer vision pipeline requires a cloud AI service to analyze cropped object images and extract structured metadata (name, category, brand, estimated value). The AI provider choice directly impacts:

1. **Cost**: Primary expense of vision pipeline (~75% of per-item cost)
2. **Accuracy**: Must correctly identify household items > 75% of the time
3. **Latency**: Target < 3 seconds for cloud processing
4. **Integration**: Must work seamlessly with GCP/Firebase backend
5. **Flexibility**: Ability to return structured JSON output

**Current Options**:
- **Vertex AI Vision API** (Google Cloud's traditional vision service)
- **Gemini Vision via Vertex AI** (Google's latest multimodal LLM)
- **OpenAI GPT-4 Vision** (Third-party, highest accuracy)

---

## Decision

We will use **Gemini 2.5 Flash-Lite via Vertex AI** as the primary cloud AI provider for Abundance MVP Layer 2a (attribute extraction).

**Implementation** - ✅ VERIFIED (Stage 2.1):
- **Model**: `gemini-2.5-flash-lite` (GA since July 2025)
- **Cost**: **$0.000249 per image** (60x cheaper than initially estimated!)
- **Latency**: **30-50ms** (60x faster than Gemini 1.5 Pro!)
- **Output**: JSON mode with schema validation
- **Use Case**: Extract condition, color, material, category, size, features

**Rationale**: Gemini 2.5 Flash-Lite offers dramatically better cost and speed while maintaining sufficient accuracy for attribute extraction.

---

## Alternatives Considered

### Option 1: Vertex AI Vision API (Traditional)

**Capabilities**:
- Object detection and classification
- Label detection
- Product Search API (maintenance mode)

**Pros**:
- ✅ Native GCP integration
- ✅ Lower cost (~$0.015/image)
- ✅ Fast inference (500ms-1s)
- ✅ Established, stable API

**Cons**:
- ❌ Limited metadata extraction (predefined labels only)
- ❌ No flexible JSON output (returns fixed label structure)
- ❌ Harder to customize for household items
- ⚠️ Product Search in maintenance mode (being replaced)

**Cost**: ~$0.015 per image
**Accuracy**: Good for generic objects (70-80%)

**Decision**: ⚠️ **Use as fallback** for simple objects (e.g., "chair", "cup")

---

### Option 2: Gemini 2.5 Flash-Lite via Vertex AI (CHOSEN)

**Capabilities** - ✅ VERIFIED:
- Multimodal AI (image + text understanding)
- JSON mode with schema validation (not just prompting!)
- Fast inference (887 tokens/second - fastest proprietary model)
- MMMU score: 72.9% (multimodal understanding)

**Pros**:
- ✅ **Ultra-low cost**: $0.10/1M input, $0.40/1M output = **$0.000249/image**
- ✅ **Ultra-fast**: 30-50ms typical latency (vs. 1-3s for Gemini Pro)
- ✅ **Native JSON mode**: Schema validation built-in (reliable structured output)
- ✅ **GCP native**: Seamless Vertex AI integration
- ✅ **Batch API**: 50% cost reduction available ($0.000125/image)
- ✅ **Context caching**: 10x cheaper for repeated prompts
- ✅ **Production-proven**: GA since July 2025

**Cons**:
- ⚠️ Lower accuracy than Gemini Pro (72.9% vs 75% MMMU)
- ⚠️ Complex schemas can cause errors (need to keep simple)

**Cost**: **$0.000249 per image** (verified)
**Accuracy**: Good (72.9% MMMU) - sufficient for attribute extraction
**Latency**: **30-50ms** (verified)

**Decision**: ✅ **SELECTED** - 60x cheaper and 60x faster than originally proposed Gemini 1.5 Pro

---

### Option 3: OpenAI GPT-4 Vision

**Capabilities**:
- State-of-the-art multimodal LLM
- Excellent natural language understanding
- High accuracy on diverse objects

**Pros**:
- ✅ **Highest accuracy**: 85-95% on complex objects
- ✅ **Excellent reasoning**: Best at estimating value, condition
- ✅ **Flexible prompting**: Similar to Gemini

**Cons**:
- ❌ **High cost**: ~$0.03-0.05 per image (2x Gemini)
- ❌ **Third-party API**: Not GCP-native, adds integration complexity
- ⚠️ Latency comparable to Gemini
- ❌ **Vendor lock-in**: Harder to migrate from OpenAI later

**Cost**: ~$0.03-0.05 per image
**Accuracy**: Excellent (85-95%)

**Decision**: ❌ **Rejected for MVP** - Too expensive, but keep as future option for ultra-complex items

---

## Decision Matrix

| **Criteria** | **Weight** | **Vertex AI Vision** | **Gemini 2.5 Flash-Lite** | **OpenAI Vision** |
|-------------|-----------|---------------------|---------------------------|-------------------|
| **Cost** | 35% | 🟢 $0.015 (8/10) | 🟢 **$0.000249 (10/10)** ⭐ | 🔴 $0.040 (3/10) |
| **Accuracy** | 30% | 🟡 70-80% (6/10) | 🟢 72.9% MMMU (7/10) | 🟢 85-95% (9/10) |
| **GCP Integration** | 15% | 🟢 Native (10/10) | 🟢 Native (10/10) | 🔴 Third-party (3/10) |
| **Flexibility** | 10% | 🔴 Limited (4/10) | 🟢 JSON mode (10/10) ⭐ | 🟢 Excellent (9/10) |
| **Latency** | 10% | 🟢 Fast (9/10) | 🟢 **30-50ms (10/10)** ⭐ | 🟡 Medium (7/10) |
| **TOTAL** | 100% | **7.0/10** | **9.2/10** ⭐ **WINNER** | **5.9/10** |

**Winner**: Gemini 2.5 Flash-Lite (9.2/10) - Dramatically better than initial assessment!

---

## Hybrid Strategy (Cost Optimization)

To reduce costs while maintaining accuracy, we'll implement an **intelligent routing strategy**:

```javascript
async function analyzeObject(croppedImage, barcode, detectedLabel) {
    // Strategy 1: If barcode exists, use barcode API (post-MVP)
    if (barcode) {
        const barcodeData = await lookupBarcode(barcode);
        if (barcodeData && barcodeData.confidence > 0.9) {
            return barcodeData; // Cost: $0.005
        }
    }

    // Strategy 2: If detected label is simple/common object, use Vision API
    const simpleObjects = ['chair', 'table', 'cup', 'bottle', 'book', 'laptop'];
    if (detectedLabel && simpleObjects.includes(detectedLabel.toLowerCase())) {
        const visionResult = await callVertexAIVision(croppedImage);
        return enrichWithDefaults(visionResult); // Cost: $0.015
    }

    // Strategy 3: Default to Gemini Vision for everything else
    const geminiResult = await callGeminiVision(croppedImage);
    return geminiResult; // Cost: $0.020
}
```

**Expected Cost Distribution**:
- 10% via Barcode API (post-MVP): $0.005 × 10% = $0.0005
- 20% via Vertex AI Vision: $0.015 × 20% = $0.003
- 70% via Gemini Vision: $0.020 × 70% = $0.014
- **Average cost per item**: ~$0.018 (vs. $0.020 Gemini-only)

**Estimated savings**: ~10%

---

## Implementation Specification

### Gemini 2.5 Flash-Lite Prompt & Schema

**Note**: Flash-Lite supports JSON mode with schema validation (more reliable than prompting!)

```javascript
const ATTRIBUTE_SCHEMA = {
  "type": "object",
  "properties": {
    "condition": {"type": "string", "enum": ["new", "used", "damaged"]},
    "color": {"type": "string"},
    "material": {"type": "string"},
    "category": {"type": "string"},
    "size": {"type": "string"},
    "features": {"type": "array", "items": {"type": "string"}, "maxItems": 5},
    "confidence": {"type": "number", "minimum": 0, "maximum": 1}
  },
  "required": ["condition", "color", "category"]
};

const GEMINI_PROMPT = `Analyze this product image and extract:
- condition: "new", "used", or "damaged"
- color: primary color name
- material: material type
- category: product category
- size: estimated size category ("small", "medium", "large")
- features: list of notable features (max 5)
- confidence: your confidence in these assessments (0.0 to 1.0)

Return ONLY valid JSON with these exact keys. Be concise.`;
```

### Cloud Function Integration

```javascript
const {VertexAI} = require('@google-cloud/vertexai');

async function callGeminiFlashLite(imageBuffer) {
    const vertexAI = new VertexAI({
        project: process.env.GCP_PROJECT_ID,
        location: 'us-central1'
    });

    const model = vertexAI.getGenerativeModel({
        model: 'gemini-2.5-flash-lite',  // Updated model!
        generationConfig: {
            responseMimeType: 'application/json',  // JSON mode!
            responseSchema: ATTRIBUTE_SCHEMA  // Schema validation!
        }
    });

    const result = await model.generateContent([
        {text: GEMINI_PROMPT},
        {
            inlineData: {
                mimeType: 'image/jpeg',
                data: imageBuffer.toString('base64')
            }
        }
    ]);

    // JSON mode ensures valid JSON response (no markdown wrappers!)
    return JSON.parse(result.response.text());
}
```

**Performance**: ~30-50ms latency, $0.000249 per image

---

## Consequences

### Positive

1. ✅ **Cost-effective**: 30-50% cheaper than OpenAI
2. ✅ **Flexible output**: Custom JSON structure via prompting
3. ✅ **Native GCP**: Seamless Vertex AI integration (no third-party dependencies)
4. ✅ **Future-proof**: Using Google's latest AI technology
5. ✅ **Easy iteration**: Can refine prompt without code changes

### Negative

1. ⚠️ **Latency**: 1-3s response time (vs. 0.5-1s for Vision API)
2. ⚠️ **Token costs**: Need to monitor output verbosity to control costs
3. ⚠️ **Newness**: Less proven than traditional Vision API
4. ⚠️ **Parsing complexity**: Must handle JSON parsing (Gemini may return markdown-wrapped JSON)

### Neutral

1. 🔄 **Fallback flexibility**: Can easily add OpenAI as ultra-premium option later
2. 🔄 **Hybrid strategy**: Can optimize costs with intelligent routing

---

## Validation Criteria

**Success Metrics**:
- ✅ Accuracy > 75% (name + category correct)
- ✅ Average cost < $0.025 per item (with hybrid strategy)
- ✅ Latency < 3 seconds (95th percentile)
- ✅ JSON parsing success rate > 98%

**Failure Conditions**:
- ❌ Accuracy < 70%
- ❌ Cost > $0.030 per item
- ❌ Latency > 5 seconds (95th percentile)
- ❌ Frequent JSON parsing errors (> 5%)

**Monitoring**:
- Track accuracy by category (Electronics vs. Furniture vs. Kitchenware)
- Monitor cost per image (detect unexpected usage spikes)
- Log parsing failures for prompt refinement

---

## Fallback Strategy

### When Gemini Fails

1. **JSON parsing error** → Retry once with clarified prompt
2. **Still fails** → Fall back to Vertex AI Vision API (return label-based metadata)
3. **Vision API fails** → Return empty metadata, prompt user for manual entry

### Rate Limiting

- **Gemini API rate limit hit** → Queue request, retry with exponential backoff
- **Persistent rate limiting** → Fall back to Vertex AI Vision API temporarily

---

## Future Considerations

### Post-MVP Optimizations

1. **Add barcode API** (UPC Database) for packaged goods → $0.005/item
2. **Fine-tune custom model** for household items (reduce cloud AI dependency)
3. **Implement caching** for common items (e.g., "Coca-Cola can")
4. **A/B test** Gemini vs. OpenAI on complex items (measure accuracy delta vs. cost)

### Scaling (100K+ users)

1. **Negotiate enterprise pricing** with Google Vertex AI
2. **Train custom model** for common household items (on-device inference)
3. **Hybrid on-device + cloud** (use cloud only for rare items)

---

## Revision History

| Date | Status | Notes |
|------|--------|-------|
| 2025-10-23 | Proposed | Initial ADR proposing Gemini 1.5 Pro Vision |
| 2025-11-01 | Accepted | Updated with Stage 2.1 verification: Gemini 2.5 Flash-Lite (60x cheaper, 60x faster!), JSON mode with schema validation |

---

## References

1. **Vertex AI Pricing**: https://cloud.google.com/vertex-ai/pricing
2. **Gemini 2.5 Flash-Lite Documentation**: https://cloud.google.com/vertex-ai/generative-ai/docs/models/gemini/2-5-flash-lite
3. **Gemini API Structured Output**: https://ai.google.dev/gemini-api/docs/structured-output
4. **Stage 2.1 Verification**: docs/research/gemini-2.5-flash-lite-verification.md
5. **Stage 2.1 Synthesis**: docs/research/SYNTHESIS-stage-2.1-comprehensive-verification.md

---

**Next Steps**:
1. ✅ Verification complete (Stage 2.1)
2. ⏳ iOS/Cloud implementation (Stage 2.2) - See docs/plans/2025-11-01-stage-2.2-ios-architecture-implementation.md
3. ⏳ POC validation: Test accuracy on 50 household items
4. ⏳ Optimize with batch API for 50% cost savings

