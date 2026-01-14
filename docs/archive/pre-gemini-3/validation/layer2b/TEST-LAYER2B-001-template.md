# TEST-LAYER2B-001: Layer 2b Product Search Validation

**Created**: [YYYY-MM-DD]
**Stage**: 6.3 - Layer 2b Validation
**Status**: [Pending/In Progress/Complete]

---

## Test Cases

### TC-001: Barcode Lookup (UPCitemdb) - Known UPC

**Input**: Item with barcode "049000050103" (Coca-Cola)
**Expected Output**:
- API returns 200 OK
- Product found: brand="Coca-Cola", category="Food & Beverage"
- Latency < 500ms
**Actual Output**: [To be filled after test execution]
**Pass/Fail**: [✅/❌]

### TC-002: Barcode Lookup - Unknown UPC

**Input**: Item with invalid barcode "000000000000"
**Expected Output**:
- API returns 200 OK with empty items array
- Fallback to visual search triggered
**Actual Output**: [To be filled]
**Pass/Fail**: [✅/❌]

### TC-003: Visual Search (SerpAPI) - Branded Product

**Input**: Public image URL of Coleman camping stove
**Expected Output**:
- visual_matches array length > 0
- Top match contains "Coleman" in title
- Latency 2-4 seconds
**Actual Output**: [To be filled]
**Pass/Fail**: [✅/❌]

### TC-004: Visual Search - Generic Item

**Input**: Public image URL of generic cast iron skillet
**Expected Output**:
- visual_matches array length > 0
- Generic product matches returned
- Latency 2-4 seconds
**Actual Output**: [To be filled]
**Pass/Fail**: [✅/❌]

### TC-005: LLM Parsing (Claude Haiku) - Clear Brand/Model

**Input**: SerpAPI visual_matches with "Coleman Triton 2-Burner Camping Stove"
**Expected Output**:
- brand: "Coleman"
- model: "Triton"
- variant: "2-Burner"
- confidence > 0.8
**Actual Output**: [To be filled]
**Pass/Fail**: [✅/❌]

### TC-006: LLM Parsing - Ambiguous Results

**Input**: SerpAPI visual_matches with mixed product titles
**Expected Output**:
- Best-effort parsing
- confidence < 0.7
- reasoning field explains ambiguity
**Actual Output**: [To be filled]
**Pass/Fail**: [✅/❌]

### TC-007: End-to-End Barcode-First Path

**Input**: Item with valid barcode
**Expected Output**:
- Barcode lookup succeeds
- Visual search skipped (cost optimization)
- Total latency < 1 second
**Actual Output**: [To be filled]
**Pass/Fail**: [✅/❌]

### TC-008: End-to-End Visual-Only Path

**Input**: Item without barcode
**Expected Output**:
- Visual search executes
- Claude parsing extracts product info
- Total latency < 8 seconds
**Actual Output**: [To be filled]
**Pass/Fail**: [✅/❌]

---

## Test Execution

**Date**: [YYYY-MM-DD]
**Environment**: [Jupyter notebook, Python 3.11, API credentials loaded]
**Dataset**: Golden dataset v1.0 (100 items)
**Sample Size**: [20 / 100]

---

## Results Summary

**Total Test Cases**: 8
**Passed**: [N]
**Failed**: [N]
**Skipped**: [N]

**Overall Status**: [✅ PASS / ❌ FAIL / ⚠️ PARTIAL]

---

## Notes

[Any observations, edge cases discovered, or issues encountered during testing]
