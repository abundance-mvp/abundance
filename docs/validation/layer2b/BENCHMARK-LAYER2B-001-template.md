# BENCHMARK-LAYER2B-001: Layer 2b Performance Benchmarks

**Created**: [YYYY-MM-DD]
**Stage**: 6.3 - Layer 2b Validation
**Status**: [Pending/Complete]

---

## Methodology

**Dataset**: Golden dataset v1.0 (100 household items)
- 50 items with barcodes
- 50 items without barcodes
- Categories: camping (20), kitchen (20), tools (20), electronics (20), home-decor (10), clothing (10)

**Metrics Measured**:
1. Barcode lookup success rate
2. Visual search accuracy
3. LLM parsing accuracy
4. Latency (p50, p90, p95)
5. Cost per item
6. Cost savings (barcode-first vs visual-only)

**Baseline Targets** (from VALIDATION-MASTER-001):
- Barcode lookup success rate > 50%
- Visual search accuracy > 80%
- LLM parsing accuracy > 85%
- End-to-end latency < 8s
- Cost savings > 20%

---

## Results

### Barcode Lookup Performance

| Metric | Target | Actual | Pass/Fail |
|--------|--------|--------|-----------|
| Barcode match rate | > 50% | [X%] | [✅/❌] |
| UPCitemdb API latency (p50) | < 500ms | [Xms] | [✅/❌] |
| UPCitemdb API latency (p95) | < 1s | [Xms] | [✅/❌] |
| UPCitemdb API error rate | < 5% | [X%] | [✅/❌] |

### Visual Search Performance

| Metric | Target | Actual | Pass/Fail |
|--------|--------|--------|-----------|
| Visual search accuracy | > 80% | [X%] | [✅/❌] |
| SerpAPI latency (p50) | 2-4s | [Xs] | [✅/❌] |
| SerpAPI latency (p95) | < 6s | [Xs] | [✅/❌] |
| Visual matches returned (avg) | > 3 | [X] | [✅/❌] |

### LLM Parsing Performance

| Metric | Target | Actual | Pass/Fail |
|--------|--------|--------|-----------|
| Brand extraction accuracy | > 85% | [X%] | [✅/❌] |
| Model extraction accuracy | > 85% | [X%] | [✅/❌] |
| Overall parsing accuracy | > 85% | [X%] | [✅/❌] |
| Claude latency (p50) | < 1s | [Xms] | [✅/❌] |
| Claude latency (p95) | < 2s | [Xms] | [✅/❌] |

### End-to-End Performance

| Metric | Target | Actual | Pass/Fail |
|--------|--------|--------|-----------|
| Barcode-first path latency | < 1s | [Xms] | [✅/❌] |
| Visual-only path latency | < 8s | [Xs] | [✅/❌] |
| Blended average latency | < 5s | [Xs] | [✅/❌] |

### Cost Analysis

| Metric | Target | Actual | Pass/Fail |
|--------|--------|--------|-----------|
| Cost per barcode item | < $0.005 | $[X] | [✅/❌] |
| Cost per visual item | < $0.020 | $[X] | [✅/❌] |
| Blended cost per item | < $0.013 | $[X] | [✅/❌] |
| Cost savings vs visual-only | > 20% | [X%] | [✅/❌] |
| Total validation cost | < $50 | $[X] | [✅/❌] |

---

## Failure Analysis

### Barcode Lookup Failures

**Category**: [e.g., "International products"]
**Count**: [N items]
**Root Cause**: [e.g., "EAN-13 codes not in UPCitemdb"]
**Mitigation**: [e.g., "Falls back to visual search successfully"]

### Visual Search Failures

**Category**: [e.g., "Generic kitchen items"]
**Count**: [N items]
**Root Cause**: [e.g., "No distinctive visual features"]
**Mitigation**: [e.g., "LLM provides generic category, user reviews"]

### LLM Parsing Failures

**Category**: [e.g., "Ambiguous visual matches"]
**Count**: [N items]
**Root Cause**: [e.g., "Multiple similar products in results"]
**Mitigation**: [e.g., "Low confidence score triggers user review"]

---

## Visualizations

[Embed or reference saved visualizations from Jupyter notebook]

- Path distribution chart
- Accuracy by category
- Latency distribution histogram
- Cost breakdown pie chart

---

## Recommendations

1. [Recommendation based on results]
2. [Recommendation based on results]
3. [Recommendation based on results]

---

## Revision History

| Date | Version | Changes |
|------|---------|---------|
| [YYYY-MM-DD] | 1.0 | Initial benchmark results |
