# TEST-004: AI Pipeline Integration Testing

**Extends**: TEST-STRATEGY-001
**Sprint**: 4-5 (AI Pipeline Layer 2a, Layers 2b & 3)
**Tool**: Jest (Backend), Golden Dataset
**Last Updated**: 2026-01-14

---

## Purpose

Validate AI pipeline accuracy across all layers (1-3) using golden dataset methodology. Ensures AI providers meet quality thresholds before production deployment.

**Referenced by**: ios-sprint-executor (Sprint 4-5 acceptance criteria)

---

## Security Requirements

**CRITICAL**: Test images may contain personal items. Privacy must be enforced at all levels.

### Private Test Bucket

| Setting | Value | Purpose |
|---------|-------|---------|
| Bucket Name | `gs://abundance-test-private` | Dedicated test image storage |
| Public Access Prevention | **Enforced** | Prevents accidental public exposure |
| Uniform Bucket-Level Access | **Enabled** | IAM-only access control |
| Location | `us-west1` | Colocated with Vertex AI |

### IAM Configuration

Only authorized service accounts have access:

| Service Account | Role | Purpose |
|-----------------|------|---------|
| `firebase-adminsdk-fbsvc@abundance-mvp.iam.gserviceaccount.com` | `storage.objectViewer` | Integration test execution |
| `github-actions-deployer@abundance-mvp.iam.gserviceaccount.com` | `storage.objectViewer` | CI/CD pipeline |
| `abundance-app-sa@abundance-mvp.iam.gserviceaccount.com` | `storage.objectViewer` | App service access |

### Signed URL Security

All test image access uses time-limited signed URLs:

```typescript
// From integration-setup.ts
const [signedUrl] = await file.getSignedUrl({
  action: 'read',
  expires: Date.now() + 15 * 60 * 1000, // 15 minute expiry
});
```

**Never use public URLs for test images.**

### Test Images

Pre-uploaded test images in `gs://abundance-test-private/integration-tests/`:

| File | Purpose |
|------|---------|
| `test-01-p1.jpg` | Product image for cataloging tests |
| `test-01-p4_obj-1.png` | Object detection test 1 |
| `test-01-p4_obj-2.png` | Object detection test 2 |

---

## AI Pipeline Architecture

```
Layer 1: Vision → Barcode Detection (iOS)
Layer 2a: Gemini → Attribute Extraction (Backend)
Layer 2b: Parallel Sources → Visual Search (SerpAPI), Text Parsing (Claude Haiku), Barcode Lookup
Layer 3: Claude Sonnet → Metadata Synthesis (Batch API)
```

---

## Golden Dataset

**Location**: `backend/functions/test/fixtures/golden-dataset/`

**Structure**:
```
golden-dataset/
├── layer-1/               # Vision Framework outputs
│   ├── barcode-001.json   # UPC detected: "012345678901"
│   ├── barcode-002.json   # EAN-13: "5012345678901"
│   └── ...                # 50 samples
├── layer-2a/              # Gemini attribute extraction
│   ├── attributes-001.json # Expected: { category: "Fruit", form: "Whole" }
│   └── ...                # 50 samples
├── layer-2b/              # Multi-source outputs
│   ├── visual-search-001.json
│   ├── text-parse-001.json
│   └── barcode-lookup-001.json
└── layer-3/               # Final synthesis
    ├── metadata-001.json  # Expected complete item metadata
    └── ...                # 50 samples
```

**Golden Dataset Creation** (Sprint 3 task):
1. Manually label 50 real food items
2. Run through pipeline
3. Human validate outputs
4. Freeze as ground truth

---

## Layer 1: Vision Framework Testing

**Tested in**: Sprint 2 (iOS XCTest)

**Test Code** (`ios/Tests/VisionProcessing/BarcodeDetectionTests.swift`):
```swift
func testBarcodeDetection() {
    let image = UIImage(named: "test-banana-barcode.jpg")!
    let expectation = expectation(description: "Barcode detected")

    visionService.detectBarcode(in: image) { result in
        switch result {
        case .success(let barcode):
            XCTAssertEqual(barcode, "012345678901", "UPC-A barcode mismatch")
            expectation.fulfill()
        case .failure(let error):
            XCTFail("Barcode detection failed: \(error)")
        }
    }

    wait(for: [expectation], timeout: 3.0)
}
```

**Accuracy Target**: ≥ 60% barcode detection rate (ADR-006)
**Validation**: 50-image golden dataset, measure detection success rate

---

## Layer 2a: Gemini Attribute Extraction

**Tested in**: Sprint 4 (Backend Mocha tests)

**Test Code** (`backend/functions/test/integration/gemini-extraction.test.ts`):
```typescript
import { expect } from 'chai';
import { GeminiProvider } from '../../src/providers/gemini';
import goldenDataset from '../fixtures/golden-dataset/layer-2a/attributes-001.json';

describe('Layer 2a: Gemini Attribute Extraction', () => {
  it('should extract attributes with ≥80% accuracy', async () => {
    const gemini = new GeminiProvider();
    const imageUrl = goldenDataset.input.imageUrl;

    const result = await gemini.extractAttributes(imageUrl, {
      prompt: 'Extract: category, form, ripeness, quantity',
    });

    // Compare against golden dataset expected output
    expect(result.category).to.equal(goldenDataset.expected.category); // "Fruit"
    expect(result.form).to.equal(goldenDataset.expected.form); // "Whole"
    expect(result.ripeness).to.equal(goldenDataset.expected.ripeness); // "Ripe"
    expect(result.quantity).to.equal(goldenDataset.expected.quantity); // "5"
  });

  it('should meet ≥80% accuracy across 50 samples', async () => {
    const results = await runGoldenDatasetTest('layer-2a', 50);
    const accuracy = calculateAccuracy(results);

    expect(accuracy).to.be.at.least(0.80); // 80% target from ADR-006
  });
});
```

**Accuracy Target**: ≥ 80% attribute extraction (ADR-006)
**Validation**: 50-sample golden dataset, field-level accuracy

---

## Layer 2b: Multi-Source Integration

**Tested in**: Sprint 5 (Backend Mocha tests)

### Visual Search (SerpAPI + Google Lens)

```typescript
describe('Layer 2b: Visual Search', () => {
  it('should return product matches with ≥70% confidence', async () => {
    const googleLens = new GoogleLensProvider();
    const imageUrl = goldenDataset.input.imageUrl;

    const results = await googleLens.visualSearch(imageUrl);

    expect(results.matches.length).to.be.at.least(3); // Top 3 matches
    expect(results.matches[0].confidence).to.be.at.least(0.70); // 70% min
    expect(results.matches[0].productName).to.include('Banana'); // Expected product
  });
});
```

### Text Parsing (Claude Haiku)

```typescript
describe('Layer 2b: Text Parsing', () => {
  it('should parse nutrition labels with ≥85% accuracy', async () => {
    const haiku = new ClaudeHaikuProvider();
    const ocrText = goldenDataset.input.ocrText; // Pre-extracted text

    const result = await haiku.parseText(ocrText, {
      schema: { calories: 'number', protein: 'number', carbs: 'number' },
    });

    expect(result.calories).to.equal(goldenDataset.expected.calories);
    expect(result.protein).to.equal(goldenDataset.expected.protein);
    expect(result.carbs).to.equal(goldenDataset.expected.carbs);
  });
});
```

### Barcode Lookup (UPCitemdb)

```typescript
describe('Layer 2b: Barcode Lookup', () => {
  it('should return product metadata for valid UPC', async () => {
    const barcodeService = new BarcodeProvider();
    const upc = '012345678901';

    const result = await barcodeService.lookupBarcode(upc);

    expect(result.found).to.be.true;
    expect(result.productName).to.equal('Organic Bananas');
    expect(result.brand).to.equal('Dole');
  });
});
```

**Accuracy Targets**:
- Visual search: ≥ 70% confidence (top match)
- Text parsing: ≥ 85% field accuracy
- Barcode lookup: 100% for valid UPCs (API guaranteed)

---

## Layer 3: Metadata Synthesis (Claude Sonnet Batch)

**Tested in**: Sprint 5 (Backend Mocha tests)

```typescript
describe('Layer 3: Metadata Synthesis', () => {
  it('should synthesize complete metadata from multi-source inputs', async () => {
    const sonnet = new ClaudeSonnetProvider();

    const sources = [
      goldenDataset.input.geminiAttributes,
      goldenDataset.input.visualSearchResults,
      goldenDataset.input.barcodeData,
    ];

    const result = await sonnet.synthesizeMetadata(sources, {
      userContext: { dietaryPrefs: ['vegetarian'] },
    });

    // Validate final metadata
    expect(result.name).to.equal(goldenDataset.expected.name);
    expect(result.category).to.equal(goldenDataset.expected.category);
    expect(result.expiryDays).to.equal(goldenDataset.expected.expiryDays);
    expect(result.storageMethod).to.equal(goldenDataset.expected.storageMethod);
    expect(result.confidence).to.be.at.least(0.90); // 90% synthesis target
  });

  it('should meet ≥90% accuracy across 50 samples', async () => {
    const results = await runGoldenDatasetTest('layer-3', 50);
    const accuracy = calculateAccuracy(results);

    expect(accuracy).to.be.at.least(0.90); // 90% target from ADR-006
  });
});
```

**Accuracy Target**: ≥ 90% complete metadata accuracy (ADR-006)

---

## Cost Tracking Tests

**Requirement**: Validate cost logging per COST-MODEL-001

```typescript
describe('Cost Tracking', () => {
  it('should log costs to Firestore after each AI call', async () => {
    const gemini = new GeminiProvider();
    const imageUrl = 'gs://bucket/test-image.jpg';

    await gemini.extractAttributes(imageUrl, { prompt: 'Extract attributes' });

    // Check Firestore costLogs collection
    const costLog = await admin.firestore()
      .collection('costLogs')
      .where('provider', '==', 'gemini')
      .orderBy('timestamp', 'desc')
      .limit(1)
      .get();

    expect(costLog.docs.length).to.equal(1);

    const log = costLog.docs[0].data();
    expect(log.provider).to.equal('gemini');
    expect(log.model).to.equal('gemini-2.5-flash-lite');
    expect(log.inputTokens).to.be.at.least(258); // Image tokens
    expect(log.outputTokens).to.be.at.least(50); // Min response
    expect(log.cost).to.be.at.most(0.0001); // $0.00004 per image
  });
});
```

---

## CI Integration (GitHub Actions)

**File**: `.github/workflows/ai-pipeline-tests.yml`

```yaml
name: AI Pipeline Tests

on:
  pull_request:
    branches: [main, develop]
    paths:
      - 'backend/functions/src/providers/**'
      - 'backend/functions/test/integration/**'

jobs:
  ai-pipeline-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install Dependencies
        run: |
          cd backend/functions
          npm install

      - name: Start Firebase Emulators
        run: |
          cd backend
          firebase emulators:start --only firestore,functions &
          sleep 10

      - name: Run AI Pipeline Integration Tests
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
          GOOGLE_CLOUD_PROJECT: ${{ secrets.GCP_PROJECT_ID }}
          SERPAPI_KEY: ${{ secrets.SERPAPI_KEY }}
        run: |
          cd backend/functions
          npm test -- --grep "Layer 2a|Layer 2b|Layer 3"

      - name: Upload Golden Dataset Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: golden-dataset-results
          path: backend/functions/test/results/
```

---

## Test Execution

### Local Execution

```bash
# Run all AI pipeline tests
cd backend/functions
npm test -- --grep "Layer"

# Run specific layer
npm test -- --grep "Layer 2a"

# Run golden dataset validation
npm run test:golden-dataset
```

**Expected Runtime**: 2-3 minutes (50 samples, API latency)

---

## Success Metrics

Sprint 4-5 acceptance criteria:
- [ ] Layer 1: ≥60% barcode detection accuracy
- [ ] Layer 2a: ≥80% attribute extraction accuracy
- [ ] Layer 2b: ≥70% visual search confidence, ≥85% text parsing
- [ ] Layer 3: ≥90% synthesis accuracy
- [ ] Cost logging: 100% of AI calls logged to Firestore
- [ ] All tests pass on CI before merging

---

## References

- **TEST-STRATEGY-001**: Overall test strategy
- **ADR-006**: AI Provider Selection (accuracy thresholds)
- **ADR-007**: AI Pipeline Architecture (3-layer design)
- **BENCHMARK-001**: AI Accuracy Benchmarks (golden dataset methodology)
- **COST-MODEL-001**: AI Provider Cost Analysis (cost tracking requirements)
- **CODE-EXAMPLE-010 through 018**: AI provider implementations

---

**Last Updated**: 2025-11-12
**Validated**: Sprint 4-5 acceptance criteria
**Tool**: Mocha + Chai, Golden Dataset (50 samples)
