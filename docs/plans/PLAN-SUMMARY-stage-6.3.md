# Stage 6.3: Layer 2b Validation - Plan Summary

**Created**: 2025-11-14
**Stage**: 6.3 - Layer 2b Validation (Product Search)
**Status**: Ready for Execution
**References**:
- Detailed Plan: docs/plans/2025-11-14-stage-6.3-layer-2b-validation.md
- Master Validation Strategy: docs/validation/VALIDATION-MASTER-001.md
- Research Validation: docs/validation/RESEARCH-VALIDATION-stage-6.3.md

---

## What This Stage Accomplishes

Stage 6.3 validates the **barcode-first product search strategy** (Layer 2b) before Sprint 3 implementation. Using a golden dataset of 100 diverse household items, we prove that:

1. **Barcode lookup** via UPCitemdb API achieves >50% match rate for barcoded items
2. **Visual search fallback** via SerpAPI Google Lens achieves >80% accuracy when barcodes fail
3. **LLM parsing** via Claude Haiku 4.5 extracts brand/model/variant with >85% accuracy
4. **Cost optimization** via barcode-first strategy saves >20% vs visual-only approach
5. **End-to-end latency** stays under 8 seconds for complete Layer 2b pipeline

This validation uses **real APIs** (not mocks), **real costs** (within $50 budget), and **representative data** (golden dataset mirrors production usage). The Go/No-Go decision gates Sprint 3 implementation.

---

## Key Decisions Made

### Decision 1: Jupyter Notebook Validation Infrastructure

**Rationale**: Python notebooks provide interactive validation, easy visualization, and cost control (stop execution if budget exceeded). Faster to iterate than building test infrastructure in TypeScript.

**Impact**: Validation can be run by any team member with Python/Jupyter, not just backend engineers. Results are reproducible and shareable as notebooks.

**Documented in**: 2025-11-14-stage-6.3-layer-2b-validation.md (Task 3)

### Decision 2: 20-Item Sample Before Full 100-Item Run

**Rationale**: Testing 20 items first ($8 cost) validates infrastructure, API integration, and analysis logic before committing to full $40 budget.

**Impact**: Reduces risk of wasted budget on broken test setup. Allows prompt tuning and error handling fixes before full validation.

**Documented in**: 2025-11-14-stage-6.3-layer-2b-validation.md (Task 5)

### Decision 3: Real API Calls (Not Mocks)

**Rationale**: Mock APIs cannot validate real-world performance (latency variance, API errors, coverage gaps). Validate-before-implement philosophy requires real provider APIs.

**Impact**: Validation costs $40 (within budget) but proves actual behavior. Discoveries about API limitations (e.g., UPCitemdb coverage gaps) inform production architecture decisions.

**Documented in**: VALIDATION-MASTER-001.md, RESEARCH-VALIDATION-stage-6.3.md

---

## Outputs Created

### Infrastructure
- `notebooks/validation/layer2b/` (Jupyter validation environment)
- `notebooks/validation/layer2b/requirements.txt` (Python dependencies)
- `notebooks/validation/layer2b/.env.template` (API credential template)
- `notebooks/validation/layer2b/README.md` (Setup instructions)

### Golden Dataset
- `notebooks/validation/layer2b/golden_dataset_manifest_template.json` (100-item template)
- `notebooks/validation/layer2b/golden_dataset_README.md` (Collection guide)

### Validation Notebook
- `notebooks/validation/layer2b/layer2b_validation.ipynb` (Complete validation pipeline)
  - API wrappers (UPCitemdb, SerpAPI, Claude Haiku)
  - Orchestration logic (barcode-first workflow)
  - Batch validation (100 items)
  - Accuracy analysis
  - Cost tracking
  - Visualizations

### Report Templates
- `docs/validation/layer2b/TEST-LAYER2B-001-template.md` (Test plan)
- `docs/validation/layer2b/BENCHMARK-LAYER2B-001-template.md` (Benchmark report)
- `docs/validation/layer2b/VALIDATION-LAYER2B-001-template.md` (Go/No-Go report)

### Verification
- `docs/validation/RESEARCH-VALIDATION-stage-6.3.md` (API pricing/model ID verification)

---

## Next Stage Preview

**Stage 6.4**: Layer 3 Validation (AI Synthesis)

- **Expert Agent**: Computer Vision & ML Engineer
- **Will accomplish**: Validate Claude Sonnet 4.5 synthesis + conflict resolution before Sprint 3
- **Will produce**: Layer 3 validation notebook, synthesis accuracy benchmarks, Go/No-Go report
- **Prerequisites**: This checkpoint (Stage 6.3) approval + Layer 2a validation complete (Stage 6.2)

---

## Dependencies

**Inputs from Previous Stages**:
- VALIDATION-MASTER-001.md (Stage 6.0) - Master validation framework
- CODE-EXAMPLE-013.md (Stage 3.5) - SerpAPI integration patterns
- CODE-EXAMPLE-014.md (Stage 3.5) - Claude Haiku parsing patterns
- ADR-018.md (Stage 2.0) - Barcode-first strategy decision
- SPRINT-PLAN-003.md (Stage 5.1) - Sprint 3 context

**External Dependencies**:
- SerpAPI Developer plan ($75/month) - subscription active
- UPCitemdb DEV plan ($99/month) - subscription active
- Anthropic Claude API access (pay-as-you-go)
- Golden dataset (100 items) - manual collection required
- Public image hosting (for SerpAPI) - GCS or similar

---

## Execution Notes

**Critical Path**: Golden dataset collection is the blocker. Without 100 labeled items with public image URLs, validation cannot run.

**Budget Control**: Notebook has built-in budget limits (MAX_SERPAPI_CALLS=50, MAX_CLAUDE_CALLS=15000). Execution stops if exceeded.

**Iteration**: Run 20-item sample first, review results, tune prompts/thresholds, then run full 100 items.

**Timeline**: Assuming golden dataset ready, validation execution takes ~4 hours (API latency dominant factor).

---

**This summary document serves as the master reference for Stage 6.3 validation.**
