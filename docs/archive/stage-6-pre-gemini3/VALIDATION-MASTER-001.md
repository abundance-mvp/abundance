# VALIDATION-MASTER-001: AI Pipeline Validation Strategy

**Created**: 2025-11-12
**Stage**: 6.0 - Master Validation Document
**Status**: Active
**Owner**: Software Architecture Expert
**References**:
- docs/design/DESIGN-004-computer-vision-pipeline.md
- docs/tech-stack/TECH-STACK-MAP-001-abundance-tech-stack.md
- docs/roadmap/SPRINT-PLAN-002.md (Layer 1)
- docs/roadmap/SPRINT-PLAN-003.md (Layer 1 validation)
- docs/roadmap/SPRINT-PLAN-004.md (Layer 2a)

---

## Executive Summary

This document establishes the **master validation strategy** for the Abundance AI cataloging pipeline (4 layers). The strategy follows a **validate-before-implement** philosophy: each AI layer must be proven functional with real APIs and representative data before Sprint implementation begins.

### Validation Philosophy

**Principle**: Never write production code against unvalidated AI capabilities.

**Approach**:
1. **Pre-Sprint Validation**: Validate AI layer capabilities BEFORE sprint implementation
2. **Real APIs**: Use actual provider APIs (Vertex AI, Anthropic, SerpAPI) with test credentials
3. **Representative Data**: Test with diverse household item images (golden dataset)
4. **Quantitative Metrics**: Establish accuracy thresholds, cost models, latency targets
5. **Document Failures**: Catalog edge cases, failure modes, mitigation strategies

### Validation Timeline

```
Stage 6.0 (Now)     → Master validation framework established
Stage 6.1 (Sprint 1) → Layer 1 validation (iOS Vision + YOLO + barcode)
Stage 6.2 (Sprint 2) → Layer 2a validation (Gemini attribute extraction)
Stage 6.3 (Sprint 2) → Layer 2b validation (SerpAPI + UPCitemdb + Claude parsing)
Stage 6.4 (Sprint 3) → Layer 3 validation (Claude Sonnet synthesis)
```

**Critical Path**: Stages 6.1-6.4 are **sprint blockers**. No implementation sprint begins until validation passes.

---

## Validation Layers Overview

### Layer 1: On-Device Real-Time Object Detection (iOS 26 Vision Framework)
**Stage**: 6.1
**Validates Before**: Sprint 2 (Camera Capture & Backend Infrastructure)
**Technology**: Vision Framework + Core ML (YOLOv11n) + Real-time streaming (2 FPS)
**Test Infrastructure**: iOS XCTest suite + golden dataset (100 images) + CVPixelBuffer frame simulation

**Key Validations**:
- Household item detection accuracy > 60%
- Real-time streaming performance (2 FPS continuous detection)
- Per-object processing latency < 120ms (YOLO 23ms + mask 50-80ms + quality ~35ms)
- Parallel multi-object processing (5 objects simultaneously in ~120ms total)
- Organic border mask generation (VNGenerateForegroundInstanceMaskRequest)
- Visual fingerprinting deduplication (VNImageFingerprint, 0.90 similarity threshold)
- Quality assessment accuracy (VNCalculateImageAestheticsScoresRequest, threshold 0.65)
- Three-tier confidence system (automatic/manual/ignore based on confidence + quality)
- Supported device compatibility (iPhone 15 Pro A17 chip)

**Note**: Barcode detection moved to Layer 2b (Stage 6.3) per Sprint 3 architecture refactor

---

### Layer 2a: Attribute Extraction (Gemini 2.5 Flash-Lite)
**Stage**: 6.2
**Validates Before**: Sprint 4 (AI Pipeline Layer 2a)
**Technology**: Vertex AI Gemini 2.5 Flash-Lite
**Test Infrastructure**: Jupyter notebook + Vertex AI SDK

**Key Validations**:
- Category accuracy > 87%
- Color accuracy > 83%
- Material accuracy > 80%
- Condition accuracy > 77%
- Cost per image: $0.000046 (within budget)
- Latency: 30-50ms

---

### Layer 2b: Product Search (SerpAPI + UPCitemdb + Claude Haiku)
**Stage**: 6.3
**Validates Before**: Sprint 4 (AI Pipeline Layer 2a/2b integration)
**Technology**: SerpAPI Google Lens, UPCitemdb, Claude 4.5 Haiku
**Test Infrastructure**: Jupyter notebook + API SDKs

**Key Validations**:
- Barcode lookup success rate > 50% (UPCitemdb hit rate)
- Visual search fallback accuracy > 80%
- LLM parsing accuracy > 85%
- Cost savings: 22.6% via barcode-first strategy
- End-to-end latency: < 8 seconds

---

### Layer 3: AI Synthesis (Claude Sonnet 4.5 Batch API)
**Stage**: 6.4
**Validates Before**: Sprint 4 (complete AI pipeline)
**Technology**: Anthropic Claude Sonnet 4.5 Batch API
**Test Infrastructure**: Jupyter notebook + Anthropic SDK

**Key Validations**:
- Conflict resolution accuracy > 90%
- Confidence scoring precision > 85%
- End-to-end pipeline accuracy > 75%
- Cost per synthesis: $0.0027 (within budget)
- Batch latency: 1-2s (acceptable for async)

---

## Validation Methodology

### 1. Functional Testing
**Goal**: Prove the AI capability works as designed

**Approach**:
- **Unit Tests**: Test individual API calls with known inputs
- **Integration Tests**: Test layer interactions (Layer 2a → Layer 2b → Layer 3)
- **Capability Discovery**: Document what the AI can/cannot do

**Artifacts**:
- `TEST-LAYER{X}-001.md` - Test plan and cases
- Test code (iOS XCTest or Jupyter .ipynb)
- Validation reports with pass/fail metrics

---

### 2. Performance Benchmarking
**Goal**: Quantify accuracy, latency, cost under realistic conditions

**Approach**:
- **Golden Dataset**: 100 diverse household items (camping, kitchen, tools, electronics, furniture, clothing)
- **Accuracy Metrics**: Precision, recall, F1 score (where applicable)
- **Latency Metrics**: p50, p90, p99 processing times
- **Cost Metrics**: $ per item, $ per API call

**Artifacts**:
- `BENCHMARK-LAYER{X}-001.md` - Methodology and results
- CSV/JSON data exports (raw results)
- Visualizations (accuracy histograms, latency distributions)

---

### 3. Edge Case Documentation
**Goal**: Catalog failure modes and establish mitigation strategies

**Approach**:
- **Failure Classification**: Categorize failure types (API error, low confidence, timeout, etc.)
- **Mitigation Strategies**: Define fallback logic for each failure type
- **Edge Case Catalog**: Document problematic inputs (dark images, reflective surfaces, etc.)

**Artifacts**:
- `VALIDATION-LAYER{X}-001.md` - Comprehensive validation report
- Edge case library (images + descriptions)
- Mitigation decision tree

---

## Test Infrastructure Requirements

### Layer 1: iOS XCTest Suite
**Purpose**: Validate on-device Vision Framework real-time performance

**Setup**:
```
ios/AbundanceTests/Layer1ValidationTests/
├── HouseholdItemDetectorTests.swift     # VNCoreMLRequest (YOLOv11n) validation
├── SubjectMaskGeneratorTests.swift      # VNGenerateForegroundInstanceMaskRequest validation
├── ImageQualityAssessorTests.swift      # VNCalculateImageAestheticsScoresRequest validation
├── ObjectDeduplicatorTests.swift        # VNImageFingerprint deduplication validation
├── RealTimeStreamingTests.swift         # 2 FPS CVPixelBuffer frame processing validation
├── ParallelProcessingTests.swift        # Multi-object parallel processing validation
├── GoldenDataset/
│   ├── camping/                         # 20 images
│   ├── kitchen/                         # 20 images
│   ├── tools/                           # 20 images
│   ├── electronics/                     # 20 images
│   ├── furniture/                       # 10 images
│   └── clothing/                        # 10 images
└── ValidationReport.swift               # Accuracy calculation, CSV export
```

**Golden Dataset Requirements**:
- 100 diverse household items (photos)
- Ground truth labels (category, quality indicators)
- Variety: lighting conditions, angles, backgrounds
- Storage: `ios/AbundanceTests/Layer1ValidationTests/GoldenDataset/`
- Note: Barcode validation moved to Layer 2b (Stage 6.3)

**Test Execution**:
```bash
xcodebuild test -scheme AbundanceApp -destination 'platform=iOS,name=iPhone 15 Pro'
```

---

### Layers 2a/2b/3: Jupyter Notebooks
**Purpose**: Validate cloud AI APIs with live credentials

**Setup**:
```
notebooks/validation/
├── layer2a/
│   ├── layer2a_validation.ipynb         # Gemini attribute extraction
│   ├── golden_dataset_urls.csv          # GCS URLs for test images
│   └── results/
│       ├── layer2a_accuracy.csv         # Per-image results
│       └── layer2a_report.md            # Summary report
├── layer2b/
│   ├── layer2b_validation.ipynb         # SerpAPI + UPCitemdb + Claude parsing
│   ├── barcode_samples.csv              # Known UPC codes
│   └── results/
│       ├── layer2b_accuracy.csv
│       └── layer2b_report.md
└── layer3/
    ├── layer3_validation.ipynb          # Claude Sonnet synthesis
    ├── conflicting_inputs.json          # Test cases with 2a/2b disagreements
    └── results/
        ├── layer3_accuracy.csv
        └── layer3_report.md
```

**Credential Management**:
- Use `.env.validation` file (gitignored)
- Variables: `GOOGLE_API_KEY`, `ANTHROPIC_API_KEY`, `SERPAPI_KEY`, `UPCITEMDB_KEY`
- Test API keys (not production)

**Cost Control**:
- Budget cap: $50 per validation stage
- Use smallest test dataset that achieves statistical significance
- Run notebooks once, review results, iterate prompts if needed

---

## Acceptance Criteria (Master)

### Stage 6.1: Layer 1 Validation (Real-Time Object Detection)
- [ ] ✅ Household item detection accuracy > 60% (golden dataset)
- [ ] ✅ Real-time streaming validation (2 FPS continuous detection)
- [ ] ✅ Per-object processing latency < 120ms (p90) — YOLO 23ms + mask 50-80ms + quality ~35ms
- [ ] ✅ Parallel multi-object processing (5 objects in ~120ms total)
- [ ] ✅ Organic border mask generation success rate > 95%
- [ ] ✅ Visual fingerprinting deduplication (false positive rate < 5%, 0.90 similarity)
- [ ] ✅ Quality assessment threshold validation (composite score > 0.65)
- [ ] ✅ Three-tier confidence system accuracy (automatic/manual/ignore classification)
- [ ] ✅ Edge cases documented (DESIGN-040 updated)
- [ ] ✅ Validation report published (VALIDATION-LAYER1-001.md)

**Note**: Barcode detection validation moved to Stage 6.3 (Layer 2b) per Sprint 3 refactor

### Stage 6.2: Layer 2a Validation
- [ ] ✅ Category accuracy > 87%
- [ ] ✅ Color accuracy > 83%
- [ ] ✅ Material accuracy > 80%
- [ ] ✅ Condition accuracy > 77%
- [ ] ✅ Cost per image: $0.000046 ± 10%
- [ ] ✅ Latency: 30-50ms (p90)
- [ ] ✅ Validation report published (VALIDATION-LAYER2A-001.md)

### Stage 6.3: Layer 2b Validation
- [ ] ✅ Barcode lookup success rate > 50%
- [ ] ✅ Visual search accuracy > 80%
- [ ] ✅ LLM parsing accuracy > 85%
- [ ] ✅ Cost savings > 20% (barcode-first vs visual-only)
- [ ] ✅ End-to-end latency < 8s (p90)
- [ ] ✅ Validation report published (VALIDATION-LAYER2B-001.md)

### Stage 6.4: Layer 3 Validation
- [ ] ✅ Conflict resolution accuracy > 90%
- [ ] ✅ Confidence scoring precision > 85%
- [ ] ✅ End-to-end pipeline accuracy > 75% (name + category correct)
- [ ] ✅ Cost per synthesis: $0.0027 ± 10%
- [ ] ✅ Batch latency: 1-2s (acceptable)
- [ ] ✅ Validation report published (VALIDATION-LAYER3-001.md)

---

## Validation Artifacts Template

Each validation stage (6.1-6.4) produces 3 artifacts:

### 1. Test Plan (`TEST-LAYER{X}-001.md`)
```markdown
# TEST-LAYER{X}-001

## Test Cases
- TC-001: [Description]
  - Input: [Sample data]
  - Expected Output: [Criteria]
  - Actual Output: [To be filled]
  - Pass/Fail: [✅/❌]

## Test Execution
- Date: [ISO 8601]
- Environment: [Dev/Staging]
- Dataset: [Golden dataset v1.0]

## Results Summary
- Total Cases: [N]
- Passed: [N]
- Failed: [N]
- Accuracy: [%]
```

### 2. Benchmark Report (`BENCHMARK-LAYER{X}-001.md`)
```markdown
# BENCHMARK-LAYER{X}-001

## Methodology
- Dataset: [100 items, categories: camping (20), kitchen (20), ...]
- Metrics: [Accuracy, latency, cost]
- Baseline: [From RESEARCH-VALIDATION-stage-3.X]

## Results
| Metric | Target | Actual | Pass/Fail |
|--------|--------|--------|-----------|
| Accuracy | > X% | Y% | ✅/❌ |
| Latency (p90) | < Xms | Yms | ✅/❌ |
| Cost per item | $X | $Y | ✅/❌ |

## Failure Analysis
- [Category with lowest accuracy]
- [Edge cases identified]
```

### 3. Validation Report (`VALIDATION-LAYER{X}-001.md`)
```markdown
# VALIDATION-LAYER{X}-001

## Executive Summary
- **Status**: ✅ Passed / ❌ Failed / ⚠️ Conditional Pass
- **Date**: [ISO 8601]
- **Sprint Blocker**: [Yes/No - can Sprint X proceed?]

## Key Findings
1. [Finding 1]
2. [Finding 2]

## Recommendations
- [Action 1]
- [Action 2]

## Edge Cases Documented
- [Edge case 1: description, mitigation]
- [Edge case 2: description, mitigation]

## Go/No-Go Decision
- **Decision**: [GO / NO-GO]
- **Rationale**: [Explanation]
- **Conditions**: [If conditional, list conditions for GO]
```

---

## Risk Mitigation Strategies

### Risk 1: Validation Fails (Accuracy Below Threshold)
**Impact**: Sprint implementation blocked

**Mitigation**:
1. **Tune Prompts**: Iterate on Gemini/Claude prompts with golden dataset
2. **Adjust Thresholds**: Re-evaluate if baseline targets are realistic
3. **Partial Pass**: Allow conditional pass with documented limitations
4. **Fallback Strategy**: Implement manual review queue for low-confidence items

**Go/No-Go Criteria**: If accuracy within 5% of target AND mitigation plan exists → Conditional GO

---

### Risk 2: API Cost Exceeds Budget
**Impact**: Validation incomplete, financial overrun

**Mitigation**:
1. **Sampling Strategy**: Use statistically significant sample size (50 items vs 100)
2. **Mock Responses**: Cache API responses, replay for iteration
3. **Budget Alerts**: Set GCP budget alert at 80% of validation budget
4. **Test Credentials**: Use developer tier APIs (lower cost)

**Budget Cap**: $50 per validation stage (6.1-6.4), $200 total

---

### Risk 3: Validation Infrastructure Not Ready
**Impact**: Validation stage delayed

**Mitigation**:
1. **Pre-Stage Setup**: Create test infrastructure BEFORE Stage 6.1 execution
2. **Template Notebooks**: Provide pre-built Jupyter notebook templates
3. **Credential Checklist**: Verify all API keys before validation begins
4. **Dry Run**: Test notebook setup with 5 sample items

**Readiness Checklist** (Stage 6.1):
- [ ] iOS XCTest suite scaffolded
- [ ] Golden dataset (100 images) collected
- [ ] Jupyter environment configured
- [ ] API credentials verified (test API call successful)

---

## Validation Status Dashboard

Track validation progress across all stages:

| Stage | Layer | Status | Accuracy | Cost | Latency | Sprint Blocker | Report |
|-------|-------|--------|----------|------|---------|----------------|--------|
| 6.1 | Layer 1 (Real-Time YOLOv11n) | 🟡 Pending | - | $0 | < 120ms/obj | Sprint 2 | - |
| 6.2 | Layer 2a (Gemini) | 🟡 Pending | - | - | - | Sprint 4 | - |
| 6.3 | Layer 2b (SerpAPI + Barcode) | 🟡 Pending | - | - | - | Sprint 4 | - |
| 6.4 | Layer 3 (Claude) | 🟡 Pending | - | - | - | Sprint 4 | - |

**Legend**:
- 🟡 Pending (not started)
- 🔵 In Progress
- 🟢 Passed (GO)
- 🟠 Conditional Pass (GO with conditions)
- 🔴 Failed (NO-GO)

**Update Frequency**: After each validation stage completes

---

## Validation Execution Workflow

### Pre-Validation (Setup)
1. Read this master doc (VALIDATION-MASTER-001.md)
2. Review layer-specific design docs (DESIGN-004, CODE-EXAMPLE-00X)
3. Set up test infrastructure (iOS XCTest or Jupyter)
4. Verify API credentials (test API call)
5. Prepare golden dataset (if Layer 1)

### Validation Execution
1. Run test cases (unit, integration)
2. Execute benchmarks (golden dataset)
3. Collect metrics (accuracy, latency, cost)
4. Document edge cases and failures
5. Generate validation report

### Post-Validation (Decision)
1. Compare results to acceptance criteria
2. Make GO/NO-GO decision
3. If NO-GO: Define mitigation plan, re-run validation
4. If GO: Update validation dashboard, proceed to sprint
5. Archive validation artifacts (reports, data, notebooks)

---

## Appendix A: Golden Dataset Specification

### Purpose
Representative sample of household items for accuracy benchmarking

### Composition (100 items)
- **Camping** (20): Tents, stoves, backpacks, sleeping bags, coolers
- **Kitchen** (20): Pots, pans, utensils, appliances, dishes
- **Tools** (20): Hand tools, power tools, toolboxes, fasteners
- **Electronics** (20): Cameras, laptops, tablets, headphones, chargers
- **Furniture** (10): Chairs, tables, shelves, lamps
- **Clothing** (10): Jackets, shoes, hats, bags

### Diversity Requirements
- **Lighting**: Indoor, outdoor, mixed
- **Angles**: Front, side, top-down, angled
- **Backgrounds**: Clean, cluttered, textured
- **Conditions**: New, used, damaged
- **Barcodes**: 50% with visible barcodes, 50% without

### Ground Truth Labels
Each item requires:
- `category`: String (camping, kitchen, tools, etc.)
- `name`: String (specific item name)
- `brand`: String (if applicable)
- `color`: String (primary color)
- `material`: String (dominant material)
- `condition`: Enum (new, like-new, good, fair, poor)
- `barcode`: String (UPC/EAN if present, else null)
- `estimatedValue`: Number (market value in USD)

### Storage Format
```json
{
  "golden_dataset_v1": {
    "version": "1.0",
    "created": "2025-11-12",
    "total_items": 100,
    "items": [
      {
        "id": "camping-001",
        "image_path": "GoldenDataset/camping/coleman-triton-stove.jpg",
        "ground_truth": {
          "category": "camping",
          "name": "Coleman Triton 2-Burner Camping Stove",
          "brand": "Coleman",
          "color": "green",
          "material": "metal",
          "condition": "good",
          "barcode": null,
          "estimatedValue": 44.99
        }
      }
    ]
  }
}
```

---

## Appendix B: Validation Budget

### Budget Allocation (Stage 6.1-6.4)

| Stage | Layer | API Costs | Infrastructure | Total |
|-------|-------|-----------|----------------|-------|
| 6.1 | Layer 1 | $0 (on-device) | $0 (local Xcode) | **$0** |
| 6.2 | Layer 2a | $5 (Gemini 100 calls) | $0 (Jupyter local) | **$5** |
| 6.3 | Layer 2b | $25 (SerpAPI 50 + UPCitemdb 50) | $0 (Jupyter local) | **$25** |
| 6.4 | Layer 3 | $15 (Claude Batch 100 calls) | $0 (Jupyter local) | **$15** |
| **Total** | | $45 | $0 | **$45** |

**Contingency**: $5 (re-runs, edge case testing)
**Grand Total**: $50

**Funding Source**: Development budget (GCP project: `abundance-dev`)

---

## Appendix C: Jupyter Notebook Template

### Layer 2a Validation Notebook Outline

```python
# layer2a_validation.ipynb

# Cell 1: Setup
import os
from google.genai import GenerativeAI
import pandas as pd
import json

# Load credentials
GOOGLE_API_KEY = os.getenv('GOOGLE_API_KEY')

# Cell 2: Load golden dataset
golden_dataset = pd.read_csv('golden_dataset_urls.csv')
# Columns: id, image_url, ground_truth_category, ground_truth_color, etc.

# Cell 3: Run Gemini attribute extraction
results = []
for idx, row in golden_dataset.iterrows():
    result = extract_attributes_gemini(row['image_url'])
    results.append({
        'id': row['id'],
        'predicted_category': result['category'],
        'ground_truth_category': row['ground_truth_category'],
        'match': result['category'] == row['ground_truth_category']
    })

# Cell 4: Calculate accuracy
accuracy_df = pd.DataFrame(results)
category_accuracy = accuracy_df['match'].mean()
print(f"Category Accuracy: {category_accuracy:.2%}")

# Cell 5: Export results
accuracy_df.to_csv('results/layer2a_accuracy.csv', index=False)

# Cell 6: Generate validation report
# (Markdown export logic)
```

---

## Revision History

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-12 | 1.0 | Initial master validation strategy | Software Architecture Expert |
| 2025-11-15 | 2.0 | **MAJOR UPDATE**: Refactor Layer 1 validation for Sprint 3 real-time object detection architecture. Update YOLOv3-Tiny → YOLOv11n, latency 500ms → 120ms per object, add real-time streaming/quality/deduplication/organic mask validations. Move barcode detection from Layer 1 to Layer 2b (Stage 6.3). | Stage 6.x Documentation Refactor |

---

**This master validation document governs all AI pipeline validation (Stages 6.1-6.4) and establishes the validate-before-implement methodology for Abundance MVP development.**
