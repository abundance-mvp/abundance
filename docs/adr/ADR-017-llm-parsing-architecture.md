# ADR-017: LLM Parsing Architecture

**Status**: Approved
**Date**: 2025-11-08
**Decision Makers**: Engineering Leadership, Computer Vision & ML Engineer
**Related Documents**:
- docs/validation/RESEARCH-VALIDATION-stage-2.0.md
- docs/design/DESIGN-004-computer-vision-pipeline.md

---

## Context

Layer 2b (SerpAPI Google Lens) returns unstructured HTML/JSON with product information. Requirements:
- Extract brand, model, variant from SerpAPI `visual_matches` array
- Handle varying HTML structures (not all products have consistent fields)
- Fast parsing (< 1 second)
- Low cost (< $0.001 per parse)

## Decision

**Use Claude Haiku 4.5 for brand/model extraction from SerpAPI responses.**

### Specifications

- **Model**: Claude Haiku 4.5
- **Pricing**: $0.25 per million input tokens, $1.25 per million output tokens
- **Cost per Parse**: ~$0.00035 (assuming 500 input + 100 output tokens)
- **Latency**: < 1 second

## Rationale

### 1. Robust Parsing of Messy HTML/JSON

**Challenge**: SerpAPI returns inconsistent formats:

```json
{
  "visual_matches": [
    {
      "title": "Coleman Triton 2-Burner Camping Stove - Green",
      "price": "$44.99",
      "link": "https://example.com/coleman-triton"
    },
    {
      "title": "Coleman Camping Stove",
      "price": "$45",
      "source": "Amazon"
    }
  ]
}
```

**Solution**: Claude Haiku handles structural variations:

```javascript
const prompt = `Extract brand, model, variant from these product results:

${JSON.stringify(visualMatches, null, 2)}

Return JSON: { brand, model, variant, estimatedValue }`;

// Claude Haiku response:
{
  "brand": "Coleman",
  "model": "Triton",
  "variant": "2-Burner",
  "estimatedValue": 44.99
}
```

**Outcome**: 85%+ extraction accuracy (vs < 50% with regex parsing).

### 2. Cost-Effective (Cheap LLM for Simple Task)

**Cost Comparison**:

| LLM | Cost per Parse | Accuracy |
|-----|----------------|----------|
| **Claude Haiku** | **$0.00035** | **85%** |
| Claude Sonnet | $0.002027 | 90% |
| GPT-4 | $0.005 | 90% |
| Regex (free) | $0 | 40-50% |

**Rationale**: Haiku provides 85% accuracy at $0.00035 (cheap enough to use inline). Sonnet/GPT-4 overkill for simple parsing.

### 3. Fast (< 1 Second)

**Requirement**: Layer 2b SerpAPI call takes 5-7 seconds. Parsing must not add significant latency.

**Solution**: Claude Haiku real-time API returns in < 1 second.

**Outcome**: Total Layer 2b latency ~6-8 seconds (acceptable for async cataloging).

## Alternatives Considered

### Alternative 1: Regex Parsing (Free)

**Pros**:
- Zero cost
- Fast (instant)

**Cons**:
- Brittle (breaks when HTML structure changes)
- Low accuracy (40-50% extraction success)
- High maintenance (constant regex updates)

**Why Rejected**: $0.00035 cost worth 85% vs 50% accuracy. Haiku parsing is robust.

### Alternative 2: GPT-4 (High Quality)

**Pros**:
- 90%+ accuracy
- Excellent reasoning

**Cons**:
- 14× more expensive ($0.005 vs $0.00035)
- Slower (200-500ms vs < 1s)

**Why Rejected**: 5% accuracy gain not worth 14× cost increase. Haiku sufficient for parsing.

### Alternative 3: No LLM (Manual Parsing)

**Approach**: Write custom parsers for each e-commerce site format (Amazon, eBay, Walmart, etc.)

**Pros**:
- Zero cost
- Potentially higher accuracy (site-specific logic)

**Cons**:
- High maintenance (100+ site formats)
- Breaks when sites update HTML
- Engineering time expensive

**Why Rejected**: Claude Haiku generalizes across all formats. $0.00035 cheaper than engineering hours.

## Implications & Consequences

### Positive

1. **Robust Parsing**: Handles HTML variations, 85% extraction accuracy
2. **Low Cost**: $0.00035 per parse (negligible in overall cost model)
3. **Fast**: < 1 second latency
4. **Low Maintenance**: No regex updates when HTML changes

### Negative

1. **API Dependency**: Requires Anthropic Claude API (another vendor)
2. **Cost vs Free**: $0.00035 vs $0 for regex (acceptable trade-off)

## Acceptance Criteria

- [x] ✅ Claude Haiku extracts brand/model with > 80% accuracy
- [x] ✅ Parsing latency < 1 second
- [x] ✅ Handles SerpAPI format variations gracefully
- [x] ✅ Cost per parse < $0.001

## Related Decisions

- **ADR-015**: AI reasoning layer → Claude Sonnet for complex synthesis, Haiku for simple parsing
- **DESIGN-004**: 4-layer pipeline → Layer 2b uses Claude Haiku for SerpAPI parsing

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-08 | 1.0 | Initial decision, Claude Haiku for SerpAPI parsing | Computer Vision & ML Engineer |
