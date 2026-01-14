# COST-MODEL-001: AI Cataloging Cost Per Item

**Created**: 2025-11-08
**Updated**: 2026-01-14
**Stage**: 2.0 - Computer Vision & AI Research (updated for Gemini 3 Pro)
**Status**: Validated
**References**:
- docs/plans/2026-01-13-gemini-3-pipeline-design.md (supersedes old architecture)
- docs/validation/RESEARCH-VALIDATION-stage-2.0.md

---

## Executive Summary

This document defines the complete cost model for AI-powered cataloging in the Abundance app. The **simplified 2-layer pipeline** (Gemini 3 Pro with tools) enables:
- **Free tier**: $0 per item (on-device Vision Framework only)
- **Premium tier**: ~$0.033-0.043 per item (Gemini 3 Pro + tools)
- **Margins**: 80-90% depending on scale and item mix

**Key Change (2026-01-14)**: Architecture simplified from 4 models to 1 (Gemini 3 Pro with native tool calling). Layer 3 eliminated. Claude models removed.

---

## Cost Breakdown by Layer

### Layer 1: On-Device Detection (iOS)

| Component | Technology | Cost | Latency |
|-----------|------------|------|---------|
| YOLOv11n Object Detection | Vision Framework + CoreML | **$0** | ~50ms |
| Quality Assessment | Vision Framework | **$0** | ~10ms |
| Subject Masking/Cropping | Vision Framework | **$0** | ~20ms |
| **Total Layer 1** | | **$0** | **< 100ms** |

**Note**: Barcode detection disabled for MVP (Gemini 3 Pro handles barcode recognition in image).

---

### Layer 2: Gemini 3 Pro (Cloud)

Single model handles all semantic work: visual analysis, barcode recognition, tool calling, synthesis.

| Component | Technology | Pricing | Cost per Item |
|-----------|------------|---------|---------------|
| Gemini 3 Pro | Google AI | $2-4/M input, $12-18/M output | **~$0.004** |

**Calculation** (typical item):
- Input: ~1000 tokens (image + prompt + tool results)
- Output: ~200 tokens (CatalogItem JSON)
- Input cost: 1000 × $3 / 1,000,000 = $0.003
- Output cost: 200 × $15 / 1,000,000 = $0.003
- **Total Gemini**: ~$0.004 per item (can vary $0.002-0.006)

---

### Tools (Called by Gemini 3 Pro)

| Tool | Service | Pricing | Cost per Call |
|------|---------|---------|---------------|
| `google_lens_search` | SerpAPI | $75/5K (Dev plan) | **$0.015** |
| `barcode_lookup` | UPCitemdb | $99/20K (Dev plan) | **~$0.005** |
| `web_search` | Google Search Grounding | $14/1K queries | **$0.014** |

---

## Total Cost Per Item

### Free Tier (Layer 1 Only)

| Layer | Cost |
|-------|------|
| Layer 1 (on-device) | $0 |
| **Total** | **$0** |

**User Experience**: Basic detection, privacy-first (no uploads).

---

### Premium Tier: Visual Path (No Barcode)

| Component | Cost |
|-----------|------|
| Gemini 3 Pro | $0.004 |
| Google Lens (SerpAPI) | $0.015 |
| Web Search (pricing) | $0.014 |
| **Total** | **$0.033** |

---

### Premium Tier: Barcode Path

| Component | Cost |
|-----------|------|
| Gemini 3 Pro | $0.004 |
| Barcode Lookup (UPCitemdb) | $0.005 |
| Google Lens (verification) | $0.015 |
| Web Search (pricing) | $0.014 |
| **Total** | **$0.038** |

**Note**: Barcode path is slightly more expensive because we always call Google Lens for visual verification even when barcode succeeds.

---

### Blended Cost (50% Barcode Rate)

| Path | Probability | Cost | Weighted |
|------|-------------|------|----------|
| Visual only | 50% | $0.033 | $0.0165 |
| Barcode + Visual | 50% | $0.038 | $0.019 |
| **Blended Total** | | | **$0.036** |

---

## Monthly Cost Scenarios

### Scenario 1: Month 6 (MVP)

**User Base**:
- Total users: 5,000
- Free tier: 4,250 (85%)
- Premium tier: 750 (15%)

**Items**:
- Items per premium user/month: 50
- Total premium items: 37,500

**Costs**:
| Tier | Items | Cost per Item | Total Cost |
|------|-------|---------------|------------|
| **Free** | 212,500 | $0 | **$0** |
| **Premium** | 37,500 | $0.036 | **$1,350** |

**Revenue**: 750 × $8/month = **$6,000/month**

**Margin**: ($6,000 - $1,350) / $6,000 = **78%**

---

### Scenario 2: Month 12 (Growth)

**User Base**:
- Total users: 10,000
- Premium tier: 2,000 (20%)

**Items**: 150,000 premium items

**Costs**: 150,000 × $0.036 = **$5,400/month**

**Revenue**: 2,000 × $8 = **$16,000/month**

**Margin**: ($16,000 - $5,400) / $16,000 = **66%**

---

### Scenario 3: Month 24 (Scale)

**User Base**:
- Total users: 50,000
- Premium tier: 12,500 (25%)

**Items**: 1,250,000 premium items

**Cost Optimization at Scale**:
- SerpAPI Production plan: $250/month for 25K searches ($0.010/search vs $0.015)
- Reduced per-item cost: ~$0.030

**Costs**: 1,250,000 × $0.030 = **$37,500/month**

**Revenue**: 12,500 × $8 = **$100,000/month**

**Margin**: ($100,000 - $37,500) / $100,000 = **63%**

---

## Comparison: Old vs New Architecture

| Metric | Old (4 models) | New (Gemini 3 Pro) |
|--------|----------------|-------------------|
| **Visual path cost** | $0.017 | $0.033 |
| **Barcode path cost** | $0.010 | $0.038 |
| **Models** | 4 (Gemini, Haiku, Sonnet, SerpAPI) | 1 (Gemini 3 Pro + tools) |
| **Complexity** | High | Low |
| **Latency** | 8-12s (sequential) | 5-8s (single inference + tools) |
| **Maintenance** | 4 API integrations | 1 API + tool adapters |

**Trade-off**: New architecture costs ~2x more per item but dramatically simplifies operations, reduces latency, and improves reasoning quality with Gemini 3 Pro's superior benchmarks.

---

## Cost Optimization Strategies

### 1. Skip Web Search for Low-Value Items

**Trigger**: estimatedValue < $20 or confidence = "low"
**Savings**: $0.014 per item
**Impact**: ~30% items → ~$0.004 savings overall

### 2. Cache Google Lens Results

**Opportunity**: Same products cataloged by multiple users
**Implementation**: Hash image embeddings, cache SerpAPI responses
**Impact**: 10-20% reduction in SerpAPI costs

### 3. SerpAPI Production Plan (At Scale)

**Trigger**: > 5,000 items/month
**Cost**: $250/month for 25K searches ($0.010 vs $0.015)
**Savings**: 33% on Google Lens costs

---

## Acceptance Criteria

- [x] Free tier cost = $0 per item
- [x] Premium tier cost < $0.05 per item
- [x] Margins > 60% at scale
- [x] Single model architecture documented
- [x] Tool costs verified against official pricing

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-08 | 1.0 | Initial cost model, 4-layer pipeline | Computer Vision & ML Engineer |
| 2026-01-14 | 2.0 | Updated for Gemini 3 Pro single-model architecture | AI Pipeline Refactor |

---

**This cost model supports sustainable freemium economics with simplified operations.**
