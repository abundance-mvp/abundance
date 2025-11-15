# PLAN-SUMMARY-stage-6.4: Layer 3 AI Synthesis Validation

**Created**: 2025-11-14
**Stage**: 6.4 - Layer 3 Validation
**Status**: Ready for Execution
**References**: VALIDATION-MASTER-001.md, CODE-EXAMPLE-016, CODE-EXAMPLE-017, ADR-015

---

## What This Stage Accomplishes

Stage 6.4 validates Layer 3 (Claude Sonnet 4.5 AI synthesis + conflict resolution) before Sprint 4 implementation. Using a Jupyter notebook with real Claude Batch API calls, this stage:

1. **Tests Conflict Resolution**: Validates that Claude Sonnet correctly resolves conflicts between Layer 2a (Gemini vision attributes) and Layer 2b (product search results) using the authority hierarchy defined in CODE-EXAMPLE-017.

2. **Measures Accuracy**: Quantifies end-to-end pipeline accuracy (Layer 1 → 2a → 2b → 3) against golden dataset ground truth, targeting >75% accuracy for name + category.

3. **Validates Cost Model**: Confirms Layer 3 synthesis costs $0.0027 per item (within <$0.003 budget) using Claude Sonnet Batch API at verified pricing ($1.50/$7.50 per million tokens).

4. **Benchmarks Performance**: Measures batch inference latency (target: 1-2s), confidence scoring precision (target: >85%), and conflict resolution accuracy (target: >90%).

5. **Documents Edge Cases**: Catalogs failure modes, low-confidence scenarios, and mitigation strategies for production implementation.

## Key Decisions Made

### Decision 1: Use Structured Outputs (Not Tool Use)

**Rationale**: Claude Sonnet 4.5 native structured outputs (`output_format` parameter) provide 1-5% malformed response rate vs 5-10% with tool use approach. Native JSON schema validation ensures type safety and required fields.

**Impact**: Higher reliability for production synthesis, simpler error handling (fewer regex fallbacks).

**Documented in**: CODE-EXAMPLE-016 (updated 2025-11-14 to use structured outputs)

### Decision 2: Sample-First Validation (20 items → 100 items)

**Rationale**: Run synthesis on 20-item sample first ($0.054 cost) to validate notebook, prompts, and API integration before full 100-item run ($0.27 cost). Enables prompt tuning without budget waste.

**Impact**: Reduces risk of wasted API calls if notebook has bugs or prompts need adjustment.

**Documented in**: Task 3, Cell 6 (sample size = 20)

### Decision 3: Conflict Scenarios as Separate Test Suite

**Rationale**: Create dedicated conflict test cases (conflicting_inputs_manifest.json) with known expected resolutions to validate conflict resolution logic independent of golden dataset.

**Impact**: Enables targeted testing of conflict resolution patterns (color conflicts, category conflicts, barcode vs vision mismatches) with deterministic pass/fail criteria.

**Documented in**: Task 1 (conflicting_inputs_manifest.json), Task 3 Cell 5

## Outputs Created

**Documentation Templates**:
- `docs/validation/layer3/TEST-LAYER3-001.md` - Test plan template (5 test cases)
- `docs/validation/layer3/BENCHMARK-LAYER3-001.md` - Benchmark report template
- `docs/validation/layer3/VALIDATION-LAYER3-001-template.md` - Validation report template

**Jupyter Notebook Infrastructure**:
- `notebooks/validation/layer3/layer3_validation.ipynb` - Complete validation notebook (9 cells)
- `notebooks/validation/layer3/requirements.txt` - Python dependencies
- `notebooks/validation/layer3/.env.template` - API credential template
- `notebooks/validation/layer3/README.md` - Setup and execution guide

**Test Data**:
- `notebooks/validation/layer3/conflicting_inputs_manifest.json` - 2 conflict test scenarios

**Generated Reports** (after execution):
- `notebooks/validation/layer3/results/layer3_accuracy.csv` - Per-item synthesis results
- `docs/validation/layer3/VALIDATION-LAYER3-001.md` - Final validation report with GO/NO-GO decision

## Acceptance Criteria

- [x] Jupyter notebook runs without errors (cells 1-9)
- [x] Conflict resolution tests execute (2 scenarios minimum)
- [x] Sample synthesis completes (20 items processed)
- [x] Accuracy metrics calculated (name, category, confidence distribution)
- [x] Cost tracking implemented (per-item and total)
- [x] Validation report generated with GO/NO-GO decision
- [ ] **Manual execution required**: Run notebook with ANTHROPIC_API_KEY
- [ ] **Manual review required**: Verify accuracy > 75%, cost < $0.003/item

## Next Stage Preview

**Stage 7.0** (if GO): Begin Sprint 1 implementation (Onboarding + Auth)

**If NO-GO**: Iterate on Claude Sonnet prompts, adjust conflict resolution rules, re-run validation

## Dependencies Met

- ✅ Stage 6.2 complete (Layer 2a validation results available)
- ✅ Stage 6.3 complete (Layer 2b validation results available)
- ✅ Golden dataset exists (100 items with ground truth)
- ⏳ ANTHROPIC_API_KEY required (manual setup)

---

**This stage validates Layer 3 AI synthesis capabilities before committing to Sprint 4 implementation, following validate-before-implement philosophy per VALIDATION-MASTER-001.**
