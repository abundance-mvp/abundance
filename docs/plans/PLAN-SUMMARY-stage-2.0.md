# PLAN SUMMARY: Stage 2.0 - Computer Vision & AI Research

**Created**: 2025-11-08
**Stage**: 2.0 - Computer Vision & AI Research
**Status**: Planning Complete → Ready for Execution
**Expert Agent**: Computer Vision & ML Engineer

---

## What This Stage Accomplishes

Stage 2.0 performs **foundational AI/CV research** to verify ALL technical capabilities for the AI cataloging pipeline BEFORE making technology decisions in Stage 2.1. This research validates:

1. **iOS 26 Vision Framework** (VNCoreMLRequest + VNDetectBarcodesRequest verified)
2. **Core ML object detection** (YOLOv3-Tiny: 34 MB, 80 COCO classes, 33.1% mAP)
3. **Barcode product lookup** (OpenFoodFacts selected: free, 100/min, 2.8M products)
4. **Cloud AI for attributes** (Gemini 2.5 Flash-Lite: $0.000249/image, JSON mode)
5. **Visual product search** (SerpAPI Google Lens: $0.015/search, 5-7s latency)
6. **AI synthesis layer** (Claude Sonnet 4.5 Batch: 50% discount, conflict resolution)
7. **Complete cost model** (Free tier: $0, Premium tier: $0.017276/item)

**Result**: Zero unverified technical claims. All APIs exist, pricing verified, cost model sustainable (64-91% margin).

---

## Key Decisions Made

### Decision 1: 4-Layer AI Pipeline Architecture

**Rationale**: Layered approach balances privacy, cost, and accuracy:
- **Layer 1** (on-device Vision): Privacy + $0 cost
- **Layer 2a** (Gemini): Fast attribute extraction ($0.000249)
- **Layer 2b** (SerpAPI + barcode): Product identification ($0.015 or $0)
- **Layer 3** (Claude Sonnet): Conflict resolution and synthesis ($0.002)

**Impact**: Enables sustainable freemium model (free tier $0 cost, premium tier 64-91% margin)

**Documented in**: docs/design/DESIGN-004-computer-vision-pipeline.md (to be created)

### Decision 2: VNCoreMLRequest + YOLOv3-Tiny for On-Device Detection

**Rationale**:
- Privacy-first (full photos never leave device)
- $0 cost (vs $0.020 cloud AI)
- iOS 26 native API (production-ready)
- Apple Neural Engine optimized (< 500ms latency)

**Impact**: Free tier sustainability + premium brand positioning (iOS 26-only aligns with ADR-004)

**Documented in**: docs/adr/ADR-013-vision-framework-strategy.md (to be created)

### Decision 3: OpenFoodFacts for Barcode Lookup (MVP)

**Rationale**:
- Free tier (unlimited, 100/min rate limit)
- 2.8M+ products (food-focused but adequate for MVP)
- Upgrade path to UPCitemdb ($0/100 per day) if coverage insufficient

**Impact**: 50% barcode rate → 50% of items skip SerpAPI → 43% cost reduction

**Documented in**: docs/adr/ADR-018-barcode-product-lookup-strategy.md (to be created)

### Decision 4: Gemini 2.5 Flash-Lite for Attribute Extraction

**Rationale**:
- 30× cheaper than GPT-4V ($0.000249 vs $0.00765)
- JSON schema mode (structured output)
- Fast (30-50ms latency)

**Impact**: Low Layer 2a cost enables high-margin premium tier

**Documented in**: docs/adr/ADR-014-cloud-ai-provider-selection.md (to be created)

### Decision 5: Claude Sonnet 4.5 Batch for AI Synthesis

**Rationale**:
- Best-in-class reasoning for conflict resolution
- 50% cost discount (Batch API vs real-time)
- Multimodal (vision + JSON parsing)

**Impact**: High-quality metadata synthesis, confidence scoring, brand/model extraction

**Documented in**: docs/adr/ADR-015-ai-reasoning-layer-architecture.md (to be created)

### Decision 6: GCS + Cloud CDN for Image Hosting

**Rationale**:
- SerpAPI requires public HTTPS URLs
- GCP-native (tech stack alignment)
- Cloud CDN (low-latency global access)

**Impact**: SerpAPI integration works, no cross-cloud complexity

**Documented in**: docs/adr/ADR-016-image-hosting-strategy.md (to be created)

---

## Outputs Created

### Research & Validation

✅ **docs/validation/RESEARCH-VALIDATION-stage-2.0.md**
- 7 technical claims verified
- 0 contradictions resolved
- 6 official sources documented
- Token budget: 11,000 (under 25,000 target)

### Artifacts to Be Created (Execution Phase)

⏳ **docs/design/DESIGN-004-computer-vision-pipeline.md**
- 4-layer architecture diagram
- Sequence diagrams (happy path, error flows)
- Data flow: iOS → GCS → Cloud Functions → Firestore
- Privacy firewall design

⏳ **docs/adr/ADR-013-vision-framework-strategy.md**
- VNCoreMLRequest + YOLOv3-Tiny justification
- Alternatives considered (YOLOv8n, cloud-only AI)

⏳ **docs/adr/ADR-014-cloud-ai-provider-selection.md**
- Gemini 2.5 Flash-Lite selection rationale
- Comparison with GPT-4V, Claude Sonnet Vision

⏳ **docs/adr/ADR-015-ai-reasoning-layer-architecture.md**
- Claude Sonnet 4.5 Batch API justification
- Conflict resolution use cases

⏳ **docs/adr/ADR-016-image-hosting-strategy.md**
- GCS + Cloud CDN selection rationale
- Alternatives: Firebase Storage, AWS S3

⏳ **docs/adr/ADR-017-llm-parsing-architecture.md**
- Claude Haiku 4.5 for brand/model extraction
- SerpAPI response parsing strategy

⏳ **docs/adr/ADR-018-barcode-product-lookup-strategy.md**
- Dual-mode strategy (barcode-first, visual fallback)
- OpenFoodFacts selection, UPCitemdb upgrade path
- 50% barcode rate → 43% cost reduction

⏳ **docs/tech-stack/COST-MODEL-001-ai-cataloging-cost-per-item.md**
- Free tier: $0 per item
- Premium tier: $0.017276 per item (Dev plan)
- Premium tier: $0.012276 per item (Prod plan)
- Barcode-optimized: $0.009776 per item (43% savings)
- Margin analysis: 64-91% depending on scale and barcode rate

---

## Cost Model Summary

### Per-Item Costs

| Tier | Layer 1 | Layer 2a | Layer 2b | Layer 3 | Total |
|------|---------|----------|----------|---------|-------|
| **Free** | $0 | - | - | - | **$0** |
| **Premium (Dev)** | $0 | $0.000249 | $0.015000 | $0.002027 | **$0.017276** |
| **Premium (Prod)** | $0 | $0.000249 | $0.010000 | $0.002027 | **$0.012276** |
| **Barcode-Opt** | $0 | $0.000249 | $0.007500 | $0.002027 | **$0.009776** |

### Month 6 Scenario (5,000 Users, Phase 1)

- **Users**: 5,000 total (4,250 free, 750 premium @ 15% conversion)
- **Items**: 250,000 total (50 items/user median)
- **Premium items**: 125,000 cataloged with cloud AI

**Costs**:
- Free tier: $0
- Premium tier (Prod plan, barcode-opt): 125,000 × $0.009776 = **$1,222/month**

**Revenue**:
- Premium subscriptions: 750 × $8 = **$6,000/month**

**Margin**: ($6,000 - $1,222) / $6,000 = **80% margin** ✅

### Month 12 Scenario (10,000 Users, Phase 2)

- **Users**: 10,000 total (8,000 free, 2,000 premium @ 20% conversion)
- **Items**: 750,000 total (75 items/user)
- **Premium items**: 150,000

**Costs**: 150,000 × $0.009776 = **$1,466/month**

**Revenue**:
- Premium: 2,000 × $8 = $16,000
- Marketplace fees: 500 transactions × $10 × 3% = $150
- **Total**: **$16,150/month**

**Margin**: ($16,150 - $1,466) / $16,150 = **91% margin** ✅

---

## Risks Identified

### ⚠️ Risk 1: SerpAPI Cost Escalation
- **Impact**: High (could exceed budget)
- **Mitigation**: Barcode-first strategy (50% reduction), cache results, upgrade to Prod plan if justified

### ⚠️ Risk 2: OpenFoodFacts Coverage Insufficient
- **Impact**: Medium (non-food items fallback to SerpAPI, higher cost)
- **Mitigation**: Monitor hit rate (target > 60%), upgrade to UPCitemdb if < 50%

### ⚠️ Risk 3: YOLOv3-Tiny Accuracy Too Low
- **Impact**: Medium (user dissatisfaction with missed objects)
- **Mitigation**: Beta test 100 diverse items, Layer 2/3 cloud AI compensates, upgrade to YOLOv8n if needed

---

## Next Stage Preview

**Stage 2.1: High-Level Tech Stack Mapping**

- **Expert Agent**: Software Architecture Expert
- **Will accomplish**: Lock in ALL technology decisions (GCP, Firebase, REST API, Firestore, Cloud Functions, etc.)
- **Will produce**: TECH-STACK-MAP-001 (foundation document), API-CONTRACTS-001, TEST-STRATEGY-001, ADR-005 through ADR-012
- **Prerequisites**: ✅ Stage 2.0 complete (research validated, cost model established)

**Why Stage 2.0 must complete first**: Stage 2.1 tech stack decisions (GCP services, API design, data model) depend on verified AI capabilities and cost constraints from Stage 2.0. Without research validation, tech stack choices would be based on assumptions rather than verified facts.

---

## References

- **Master Design**: docs/abundance-analysis-pipeline-design.md (Stage 2.0 section)
- **Research Validation**: docs/validation/RESEARCH-VALIDATION-stage-2.0.md
- **Detailed Plan**: docs/plans/2025-11-08-stage-2.0-computer-vision-ai-research.md
- **Phase 1 ADRs**: ADR-003 (MVP scope), ADR-004 (iOS 26-only)
- **Feature Requirements**: docs/specs/feature-prioritization-matrix.md, mvp-vision-features.md

---

**Status**: ✅ Research Complete → ⏳ Awaiting Gate 1 Approval → Execute Plan (Create 8 Artifacts)

**Execution Timeline**: ~2 weeks to create all design docs and ADRs

**Next Action**: Human approval at Gate 1 (review research + plan) → Proceed to Phase 4 (Execution)
