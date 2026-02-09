# ADR-014: Cloud AI Provider Selection

**Status**: Superseded
**Date**: 2025-11-08
**Superseded By**: docs/plans/2026-01-13-gemini-3-pipeline-design.md
**Superseded Date**: 2026-01-13
**Decision Makers**: Engineering Leadership, Computer Vision & ML Engineer
**Related Documents**:
- docs/validation/RESEARCH-VALIDATION-stage-2.0.md
- docs/design/DESIGN-004-computer-vision-pipeline.md

> **⚠️ SUPERSEDED**: This ADR has been replaced by the Gemini 3 Pro pipeline design.
> The new architecture consolidates Layer 2a, 2b, and 3 into a single Gemini 3 Pro model
> with native tool calling. See `docs/plans/2026-01-13-gemini-3-pipeline-design.md`.

---

## Context

Layer 2a of the AI cataloging pipeline requires cloud AI to extract visual attributes (color, material, condition, category) from cropped object images. Requirements:
- Low cost (< $0.001 per image to maintain margins)
- Fast (< 100ms latency)
- JSON schema mode (structured output)
- High accuracy (> 80% attribute extraction)

## Decision

**Use Gemini 2.5 Flash-Lite (Google Generative AI SDK) for Layer 2a attribute extraction.**

### Specifications

- **Model**: Gemini 2.5 Flash-Lite
- **Provider**: Google Generative AI SDK (@google/genai)
- **Pricing**: $0.10 per million input tokens, $0.40 per million output tokens
- **Cost per Image**: ~$0.000249 (assuming 200 input tokens + 50 output tokens)
- **Latency**: 30-50ms
- **Capabilities**: Vision analysis, JSON schema mode, 1M token context window

## Rationale

### 1. Cost Efficiency (30× Cheaper Than GPT-4V)

**Cost Comparison**:

| Provider | Model | Cost per Image | Quality |
|----------|-------|----------------|---------|
| **Google** | **Gemini 2.5 Flash-Lite** | **$0.000249** | **High** |
| OpenAI | GPT-4V | $0.00765 | Excellent |
| Anthropic | Claude Sonnet Vision | $0.015 | Excellent |
| Google | Gemini 2.0 Flash | $0.000075 | Medium |

**Impact**: Gemini Flash-Lite is 30× cheaper than GPT-4V while maintaining high quality for attribute extraction.

**Margin Calculation** (5,000 users, 15% premium, 125K items):
- Gemini Flash-Lite: 125,000 × $0.000249 = $31.13/month
- GPT-4V: 125,000 × $0.00765 = $956.25/month
- **Savings**: $925.12/month (96.7% cost reduction)

### 2. JSON Schema Mode (Structured Output)

**Requirement**: Attribute extraction needs structured output (category, color, material, condition) to avoid parsing errors.

**Solution**: Gemini Flash-Lite supports JSON schema mode (responseSchema parameter).

**Example**:
```json
{
  "category": "camping",
  "color": "green",
  "material": "metal",
  "condition": "good"
}
```

**Outcome**: Zero parsing errors, direct JSON → Firestore storage.

### 3. Speed (30-50ms Latency)

**Requirement**: Layer 2a must be fast to keep end-to-end processing < 10 seconds.

**Solution**: Gemini Flash-Lite optimized for speed (30-50ms vs GPT-4V 200-500ms).

**Impact**: Faster user experience, enables real-time UI updates.

## Alternatives Considered

### Alternative 1: GPT-4V (OpenAI)

**Pros**:
- Highest accuracy (90%+ attribute extraction)
- Best reasoning capabilities
- Multimodal (vision + text)

**Cons**:
- 30× more expensive ($0.00765 vs $0.000249)
- Slower (200-500ms vs 30-50ms)
- Overkill for simple attribute extraction

**Why Rejected**: Cost too high for premium tier margins. Gemini quality sufficient for Layer 2a (Layer 3 Claude Sonnet handles complex reasoning).

### Alternative 2: Claude Sonnet Vision (Anthropic)

**Pros**:
- Excellent reasoning
- High accuracy (85-90%)

**Cons**:
- 60× more expensive ($0.015 vs $0.000249)
- Slower (100-300ms)

**Why Rejected**: Reserved for Layer 3 synthesis where reasoning matters. Layer 2a only needs attribute extraction.

### Alternative 3: Gemini 2.0 Flash (Cheaper)

**Pros**:
- 3× cheaper ($0.000075 vs $0.000249)
- Fast (30-40ms)

**Cons**:
- Lower quality (70-80% accuracy vs 85-90%)
- Less reliable JSON schema support

**Why Rejected**: Quality-cost balance favors Flash-Lite. Extra $0.000174 per item worth higher accuracy.

## Implications & Consequences

### Positive

1. **Low Cost**: $0.000249 per image enables 80%+ margins
2. **Fast**: 30-50ms keeps end-to-end processing < 10s
3. **Structured Output**: JSON schema mode eliminates parsing errors
4. **High Quality**: 85-90% attribute extraction accuracy

### Negative

1. **Vendor Lock-In**: GCP-specific (Vertex AI), migration to other providers requires code changes
2. **Quality Gap vs GPT-4V**: 5-10% lower accuracy (acceptable trade-off for 30× cost savings)

### Mitigation

- Layer 3 Claude Sonnet compensates for Layer 2a quality gaps
- Hot-swappable AI integration layer (ADR-015) enables future provider changes

## Acceptance Criteria

- [x] ✅ Gemini Flash-Lite extracts attributes (color, material, condition, category) with > 80% accuracy
- [x] ✅ JSON schema mode returns structured output (no parsing errors)
- [x] ✅ Latency < 100ms per image
- [x] ✅ Cost per image < $0.001

## Related Decisions

- **ADR-013**: Vision Framework strategy → Layer 1 provides coarse detection, Layer 2a refines
- **ADR-015**: AI reasoning layer → Layer 3 Claude Sonnet compensates for Layer 2a gaps
- **COST-MODEL-001**: AI cataloging cost → Layer 2a contributes $0.000249 to $0.017276 total

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-08 | 1.0 | Initial decision, Gemini 2.5 Flash-Lite for Layer 2a | Computer Vision & ML Engineer |
