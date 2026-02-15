# ADR-015: AI Reasoning Layer Architecture

**Status**: Superseded
**Date**: 2025-11-08
**Superseded By**: docs/plans/2026-01-13-gemini-3-pipeline-design.md
**Superseded Date**: 2026-01-13
**Decision Makers**: Engineering Leadership, Computer Vision & ML Engineer
**Related Documents**:
- docs/validation/RESEARCH-VALIDATION-stage-2.0.md
- docs/design/DESIGN-004-computer-vision-pipeline.md

> **⚠️ SUPERSEDED**: Layer 3 has been eliminated. The new Gemini 3 Pro pipeline
> consolidates all reasoning, synthesis, and conflict resolution into a single model.
> See `docs/plans/2026-01-13-gemini-3-pipeline-design.md`.

---

## Context

Layer 3 of the AI cataloging pipeline requires synthesis of Layer 2a (attributes) and Layer 2b (product search) results. Requirements:
- Resolve conflicts (vision vs product search mismatches)
- Extract brand/model from product search results
- Generate confidence scores (high/medium/low)
- High-quality reasoning for metadata synthesis

## Decision

**Use Claude Sonnet 4.5 Batch API for Layer 3 AI synthesis and conflict resolution.**

### Specifications

- **Model**: Claude Sonnet 4.5 (model ID: `claude-sonnet-4-5-20250929`)
- **API**: Batch API (50% discount vs real-time)
- **Pricing**: $1.50 per million input tokens, $7.50 per million output tokens (batch discount; standard: $3.00/$15.00)
- **Cost per Inference**: ~$0.0027 (800 input + 200 output tokens)
- **Latency**: 1-2 seconds inference time (batch processing window up to 24 hours)

## Rationale

### 1. Best-in-Class Reasoning for Conflict Resolution

**Use Case**: Layer 2a says "blue camping stove", Layer 2b says "Coleman Triton green stove". Which is correct?

**Solution**: Claude Sonnet excels at reasoning through contradictions:

```
Layer 2a (Gemini): { category: "outdoor equipment", color: "blue" }
Layer 2b (SerpAPI): { name: "Coleman Triton Camping Stove", color: "green", brand: "Coleman" }

Claude Sonnet Synthesis:
{
  "name": "Coleman Triton Camping Stove",
  "brand": "Coleman",
  "color": "green",
  "confidence": "high",
  "reasoning": "Product listing data (Layer 2b) more reliable for color than vision analysis (Layer 2a) due to lighting variations. Coleman Triton is known green model."
}
```

**Outcome**: 90%+ conflict resolution accuracy (measured in research validation).

### 2. Multimodal Capabilities (Vision + Text)

**Requirement**: Layer 3 may need to re-analyze cropped images when Layer 2a/2b outputs are insufficient.

**Solution**: Claude Sonnet supports multimodal input (image + text).

**Example**: If SerpAPI returns ambiguous results, Claude can directly analyze the image for brand logos, model numbers.

### 3. Cost Efficiency with Batch API (50% Discount)

**Cost Comparison**:

| API Type | Input Cost | Output Cost | Total per Inference |
|----------|------------|-------------|---------------------|
| **Batch API** | **$1.50/M** | **$7.50/M** | **$0.0027** |
| Real-time API | $3.00/M | $15.00/M | $0.0054 |

**Impact**: Batch API saves 50% ($0.0027 vs $0.0054) with acceptable 24-hour latency for async cataloging.

**Margin Calculation** (125K premium items/month):
- Batch API: 125,000 × $0.0027 = $337.50/month
- Real-time API: 125,000 × $0.0054 = $675.00/month
- **Savings**: $337.50/month (50%)

### 4. Latency Acceptable for Async Cataloging

**Constraint**: Batch API has 24-hour processing delay.

**Mitigation**: Cataloging is async (users don't wait for final metadata). Progressive disclosure:
1. Layer 1: Instant (on-device, 300-500ms)
2. Layer 2a: Fast (30-50ms)
3. Layer 2b: Medium (5-7s)
4. Layer 3: Slow (1-2s batch queued, completes within 24 hours)

**Outcome**: Users see partial results immediately (Layer 1/2a/2b), Layer 3 synthesis updates asynchronously.

## Alternatives Considered

### Alternative 1: Claude Haiku (Cheaper)

**Pros**:
- 87% cheaper ($0.25/$1.25 per million tokens)
- Fast (real-time, < 1s)

**Cons**:
- Lower reasoning quality (70-80% conflict resolution vs 90%+ Sonnet)
- Less effective at brand/model extraction from messy HTML

**Why Rejected**: Layer 3 is critical for final metadata quality. $0.002 per item acceptable for Sonnet-level reasoning.

### Alternative 2: Gemini Pro (Google)

**Pros**:
- Similar cost to Claude Sonnet Batch
- GCP-native (same platform as Layer 2a)

**Cons**:
- Weaker reasoning for conflict resolution (80-85% vs 90%+)
- Less effective multimodal analysis

**Why Rejected**: Claude Sonnet's reasoning superiority worth platform diversity.

### Alternative 3: No Layer 3 (Direct Use of Layer 2a/2b)

**Pros**:
- Zero cost for Layer 3
- Faster (no synthesis delay)

**Cons**:
- Conflicts unresolved (users see mismatched metadata)
- Lower confidence in metadata quality
- Brand/model extraction from SerpAPI HTML requires manual parsing (brittle)

**Why Rejected**: Layer 3 adds $0.0027 per item but significantly improves metadata quality (75% → 90% accuracy).

## Implications & Consequences

### Positive

1. **High-Quality Synthesis**: 90%+ conflict resolution accuracy
2. **50% Cost Savings**: Batch API vs real-time
3. **Multimodal Fallback**: Can re-analyze images when needed
4. **Brand/Model Extraction**: Claude excels at parsing messy HTML/JSON

### Negative

1. **24-Hour Latency**: Batch processing delay (mitigated by progressive disclosure UX)
2. **Platform Diversity**: Claude (Anthropic) + Gemini (Google) increases vendor dependencies

### Mitigation

- Progressive UI updates (Layer 1/2a/2b → Layer 3 fills in asynchronously)
- Hot-swappable AI integration layer enables future provider changes

## Acceptance Criteria

- [x] ✅ Claude Sonnet resolves conflicts between Layer 2a and 2b with > 85% accuracy
- [x] ✅ Brand/model extraction from SerpAPI responses achieves > 80% accuracy
- [x] ✅ Confidence scoring correlates with actual metadata accuracy
- [x] ✅ Batch API cost per inference < $0.003 ($0.0027 actual)

## Related Decisions

- **ADR-014**: Cloud AI provider selection → Layer 2a Gemini + Layer 3 Claude Sonnet complement each other
- **ADR-017**: LLM parsing architecture → Claude Haiku for simple parsing, Sonnet for complex synthesis
- **DESIGN-004**: 4-layer pipeline → Layer 3 synthesis is final quality gate

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-08 | 1.0 | Initial decision, Claude Sonnet 4.5 Batch API for Layer 3 | Computer Vision & ML Engineer |
