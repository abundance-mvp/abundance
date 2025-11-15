# Foundation Models POC Plan (iOS 26)

**Phase**: Stage 2.5 (Pre-MVP Validation)
**Date**: 2025-10-24
**Purpose**: Validate iOS 26 Foundation Models architecture before full MVP
**Estimated Duration**: 3-5 business days

---

## Executive Summary

Before proceeding to full MVP development, we'll build a **lightweight proof-of-concept** to validate the on-device-first architecture with iOS 26 Foundation Models.

**Critical Questions to Answer**:
1. Can Foundation Models achieve >70% accuracy on household items?
2. Does confidence scoring work (can we trust "low" confidence items to fail)?
3. What's the actual on-device vs. cloud fallback split?
4. Is performance acceptable on iPhone 15 Pro (A17 Pro minimum)?
5. Are our cost estimates accurate?

**Deliverable**: Working iOS 26 app that demonstrates full pipeline (on-device → cloud fallback)

**Go/No-Go Criteria**:
- ✅ **GO**: Accuracy >65%, cloud fallback <35%, performance <3s on-device
- ❌ **NO-GO**: Accuracy <60%, cloud fallback >40%, major technical blockers

---

## Objectives

| **Objective** | **Success Criteria** | **Priority** | **How We Measure** |
|--------------|---------------------|--------------|-------------------|
| **Accuracy** | >70% correct name/category on 50-item test set | **MUST HAVE** | Manual validation |
| **Confidence Calibration** | "Low" confidence items actually have <70% accuracy | **MUST HAVE** | Compare confidence to actual accuracy |
| **Cloud Fallback Rate** | <30% of items require cloud fallback | **MUST HAVE** | Count low-confidence items |
| **On-Device Performance** | <2 seconds on iPhone 15 Pro | **MUST HAVE** | Instrument code |
| **Cloud Performance** | <6 seconds end-to-end | **SHOULD HAVE** | Instrument code |
| **Cost Validation** | ~$0.0065 per item (blended) | **SHOULD HAVE** | Track Firebase costs |

---

## Scope

### In Scope (POC)

✅ **On-Device (iOS 26)**:
- Camera capture with AVFoundation
- Foundation Models integration with structured JSON output
- Barcode detection with VNDetectBarcodesRequest
- Visual Intelligence integration (basic)
- Confidence-based routing (on-device vs. cloud)

✅ **Cloud (GCP)**:
- Firebase Storage for low-confidence items
- Cloud Function (triggered on upload)
- Gemini 1.5 Flash API integration
- Firestore write-back
- Real-time listener in iOS app

✅ **iOS UI**:
- Simple camera view
- Loading states (on-device vs. cloud)
- Results display with confidence indicator
- Basic manual editing

✅ **Testing**:
- 50-item curated test dataset
- Accuracy tracking spreadsheet
- Cost tracking
- Performance instrumentation

### Out of Scope (Defer to MVP)

❌ User authentication (use anonymous Firebase auth)
❌ Full inventory management (just show single item result)
❌ Barcode lookup API (test barcode *detection* only, not product data)
❌ Visual Intelligence advanced features (just basic integration)
❌ Result caching
❌ Polish and animations
❌ Error recovery and retry logic

---

## Test Dataset

Create a curated set of **50 household items** covering:

### Distribution by Category

| **Category** | **Count** | **Specific Examples** | **Why These Items** |
|-------------|----------|----------------------|---------------------|
| **Electronics** | 10 | iPhone 13, MacBook Pro, AirPods, USB-C cable, TV remote, Bluetooth speaker, iPad, Apple Watch, Ring doorbell, Nest thermostat | Test brand recognition, model identification |
| **Kitchenware** | 10 | KitchenAid mixer, Nespresso machine, Le Creuset pot, chef's knife, cutting board, coffee mug, wine glass, colander, whisk, food scale | Mix of branded and generic |
| **Furniture** | 8 | IKEA chair (Poäng), desk lamp, bookshelf, side table, throw pillow, picture frame, floor lamp, ottoman | Test generic item handling |
| **Tools** | 5 | DeWalt drill, hammer, screwdriver set, tape measure, level | Mix of branded and generic tools |
| **Books** | 5 | Fiction with clear cover, textbook, cookbook, children's book, graphic novel | Test text recognition |
| **Toys** | 5 | LEGO set, board game (Monopoly), stuffed animal, Barbie doll, Hot Wheels car | Test brand vs. generic |
| **Packaged Goods (barcoded)** | 7 | Coca-Cola can, Tide detergent, Cheerios box, Listerine bottle, Gillette razor, Band-Aid box, Advil bottle | Test barcode detection + brand recognition |

### Distribution by Difficulty

| **Difficulty** | **% of Dataset** | **Examples** | **Expected Confidence** |
|---------------|-----------------|--------------|------------------------|
| **Easy** | 30% (15 items) | Branded electronics, packaged goods with visible logos | High (>80%) |
| **Medium** | 50% (25 items) | Generic furniture, tools, kitchenware | Medium (60-80%) |
| **Hard** | 20% (10 items) | Handmade items, partial views, worn/damaged items, generic unmarked objects | Low (<60%) |

**Purpose**: Ensure dataset reflects real-world distribution of household items.

---

## Implementation Plan

### Day 1: iOS Foundation (On-Device)

**Goal**: Get Foundation Models working with structured JSON output

**Tasks**:
1. Create new Xcode project
   - iOS 26.0+ deployment target
   - Swift 6, SwiftUI
   - Enable Apple Intelligence capability

2. Implement camera capture
   - AVFoundation camera session
   - Simple "Capture" button
   - Save to temp directory

3. Integrate Foundation Models
   - Import FoundationModels framework
   - Create prompt with JSON schema
   - Parse JSON response
   - Display results

4. Add barcode detection
   - VNDetectBarcodesRequest
   - Display barcode string if found

**Code Milestones**:
- [ ] Camera preview displays correctly
- [ ] Capture saves image to temp
- [ ] Foundation Models returns JSON response
- [ ] JSON parsing works (ItemMetadata struct)
- [ ] Barcode detection extracts UPC/EAN

**Deliverable**: iOS app that analyzes photo on-device and shows results

**Sample Code**:
```swift
import FoundationModels
import SwiftUI

struct ItemMetadata: Codable {
    let name: String
    let category: String
    let subcategory: String?
    let brand: String?
    let color: String?
    let material: String?
    let condition: String?
    let estimatedValue: Double?
    let confidence: String // "high", "medium", "low"
    let reasoning: String?
}

actor VisionService {
    func analyzeItem(image: UIImage) async throws -> ItemMetadata {
        let model = try await FoundationModel.shared

        let prompt = """
        You are analyzing a household item photograph for a home inventory app.

        Task: Identify the item and return metadata as JSON.

        Required JSON schema:
        {
          "name": "specific item name",
          "category": "Electronics|Furniture|Kitchenware|Clothing|Tools|Books|Toys|Sports|Decor|Other",
          "subcategory": "more specific category or null",
          "brand": "brand name or null",
          "color": "primary color",
          "material": "plastic|metal|wood|fabric|glass|other or null",
          "condition": "Excellent|Good|Fair|Poor",
          "estimatedValue": 0.0,
          "confidence": "high|medium|low",
          "reasoning": "brief explanation"
        }

        Guidelines:
        - Mark confidence "low" if unsure (triggers cloud fallback)
        - Be realistic about value (used condition)
        - Focus on accurate category even if name is uncertain
        """

        let response = try await model.generateContent([
            .text(prompt),
            .image(image)
        ])

        let jsonData = response.text.data(using: .utf8)!
        return try JSONDecoder().decode(ItemMetadata.self, from: jsonData)
    }
}
```

---

### Day 2: Visual Intelligence + Confidence Routing

**Goal**: Add Visual Intelligence and implement on-device vs. cloud decision logic

**Tasks**:
1. Integrate Visual Intelligence
   - SemanticContentDescriptor for product lookup
   - Combine with Foundation Models results

2. Implement confidence-based routing
   - HIGH/MEDIUM → Save directly to Firestore
   - LOW → Upload to Firebase Storage (trigger cloud)

3. Add Firebase SDK
   - Firebase Storage
   - Firestore
   - Anonymous auth

4. Create Firestore data model
   ```
   items/{itemId}
   - name: string
   - category: string
   - metadata: map
   - confidence: string
   - needsCloudEnhancement: boolean
   - imageUrl: string (if uploaded)
   - createdAt: timestamp
   ```

**Code Milestones**:
- [ ] Visual Intelligence returns product info (if available)
- [ ] Routing logic works (high/medium/low)
- [ ] HIGH/MEDIUM items save to Firestore immediately
- [ ] LOW items upload image to Storage

**Deliverable**: On-device path complete (no cloud AI yet)

---

### Day 3: Cloud Function + Gemini Integration

**Goal**: Implement cloud fallback with Gemini 1.5 Flash

**Tasks**:
1. Set up Firebase project (free tier)
   - Enable Firestore
   - Enable Storage
   - Enable Cloud Functions (Blaze plan required)

2. Create Cloud Function
   - Trigger on Storage upload
   - Call Gemini 1.5 Flash (Vertex AI)
   - Parse JSON response
   - Update Firestore document

3. Configure Vertex AI
   - Enable Vertex AI API in GCP project
   - Set up service account auth

**Cloud Function Code**:
```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const {VertexAI} = require('@google-cloud/vertexai');

admin.initializeApp();

const PROMPT = `
You are analyzing a household item photograph for a home inventory app.

[Same prompt as iOS app]
`;

exports.enhanceItem = functions.storage.object().onFinalize(async (object) => {
    if (!object.name.startsWith('items-to-enhance/')) return null;

    const bucket = admin.storage().bucket();
    const file = bucket.file(object.name);
    const [imageBuffer] = await file.download();

    const vertexAI = new VertexAI({
        project: process.env.GCP_PROJECT_ID,
        location: 'us-central1'
    });

    const model = vertexAI.preview.getGenerativeModel({
        model: 'gemini-1.5-flash' // Cheaper for testing
    });

    const startTime = Date.now();

    const result = await model.generateContent([
        { text: PROMPT },
        {
            inlineData: {
                mimeType: 'image/jpeg',
                data: imageBuffer.toString('base64')
            }
        }
    ]);

    const latency = Date.now() - startTime;
    const responseText = result.response.text();

    // Extract JSON (Gemini sometimes adds markdown code blocks)
    const jsonMatch = responseText.match(/\{[\s\S]*\}/);
    const metadata = JSON.parse(jsonMatch[0]);

    // Extract itemId from filename: items-to-enhance/{itemId}.jpg
    const itemId = object.name.split('/')[1].replace('.jpg', '');

    // Update Firestore
    await admin.firestore().collection('items').doc(itemId).update({
        ...metadata,
        enhancedByCloud: true,
        cloudProcessingTime: latency,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log(`Enhanced item ${itemId} in ${latency}ms`);
    return null;
});
```

**Code Milestones**:
- [ ] Cloud Function deploys successfully
- [ ] Vertex AI API credentials work
- [ ] Gemini Flash returns valid JSON
- [ ] Firestore document updates
- [ ] iOS app receives real-time update

**Deliverable**: End-to-end pipeline works (on-device → cloud fallback → update)

---

### Day 4: Testing & Data Collection

**Goal**: Test all 50 items and collect accuracy data

**Tasks**:
1. Photograph all 50 test items
   - Consistent lighting (indoor, window light)
   - Neutral background
   - Full object visible
   - One photo per item

2. Process each item through POC
   - Note: on-device or cloud?
   - Record processing time
   - Save results to spreadsheet

3. Validate accuracy
   - Compare AI name vs. actual name
   - Compare AI category vs. actual category
   - Compare AI brand vs. actual brand
   - Rate each as: ✅ Correct, ⚠️ Partially Correct, ❌ Wrong

4. Track costs
   - Count cloud API calls
   - Check Firebase billing

**Data Collection Spreadsheet**:
| Item# | Actual Name | Actual Category | AI Name | AI Category | AI Brand | Confidence | Name Correct? | Category Correct? | Brand Correct? | Processing Time | On-Device or Cloud | Notes |
|-------|-------------|----------------|---------|-------------|----------|-----------|---------------|------------------|---------------|----------------|-------------------|-------|
| 1 | MacBook Pro 14" | Electronics | MacBook Pro | Electronics | Apple | high | ✅ | ✅ | ✅ | 0.8s | On-Device | Perfect |
| 2 | IKEA Poäng chair | Furniture | Armchair | Furniture | null | medium | ⚠️ | ✅ | ❌ | 1.2s | On-Device | Generic name |
| ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |

**Deliverable**: Complete dataset with 50 results

---

### Day 5: Analysis & Iteration

**Goal**: Analyze results and refine prompts if needed

**Tasks**:
1. Calculate accuracy metrics
   - Name accuracy: % of items with correct/partially correct name
   - Category accuracy: % with correct category
   - Brand accuracy: % with correct brand (when applicable)
   - Confidence calibration: Does "low" actually mean lower accuracy?

2. Identify failure patterns
   - Which categories struggle?
   - Which items trigger cloud fallback?
   - Are confidence scores calibrated correctly?

3. Refine prompts (if needed)
   - If accuracy <65%: Adjust prompt wording
   - If confidence uncalibrated: Add examples to prompt
   - Re-test on 10-15 worst-performing items

4. Create cost analysis
   - Count cloud calls
   - Actual Firebase costs
   - Calculate blended cost per item

**Analysis Questions**:
- ✅ Is on-device accuracy >70%? (Name + Category combined)
- ✅ Is cloud fallback rate <30%?
- ✅ Do "high" confidence items have >85% accuracy?
- ✅ Do "low" confidence items have <70% accuracy?
- ✅ Is blended cost <$0.01 per item?

**Deliverable**: POC Findings Report (see below)

---

## POC Findings Report Template

```markdown
# POC Findings Report: Foundation Models Architecture

**Date**: [Date]
**Test Dataset**: 50 household items
**Test Device**: iPhone 15 Pro (iOS 26.0)

---

## Accuracy Results

| **Metric** | **Target** | **Actual** | **Pass/Fail** |
|------------|-----------|------------|---------------|
| Name Accuracy | >70% | X% | ✅/❌ |
| Category Accuracy | >85% | X% | ✅/❌ |
| Brand Accuracy | >60% | X% | ✅/❌ |

### Confidence Calibration

| **Confidence Level** | **% of Dataset** | **Actual Accuracy** | **Expected Accuracy** | **Calibrated?** |
|---------------------|-----------------|---------------------|----------------------|-----------------|
| High (>80%) | X% | X% | >85% | ✅/❌ |
| Medium (60-80%) | X% | X% | 70-85% | ✅/❌ |
| Low (<60%) | X% | X% | <70% | ✅/❌ |

---

## Performance Results

| **Metric** | **Target** | **Actual** | **Pass/Fail** |
|------------|-----------|------------|---------------|
| On-Device Processing Time | <2s | X.Xs | ✅/❌ |
| Cloud Fallback Rate | <30% | X% | ✅/❌ |
| Cloud Processing Time | <6s | X.Xs | ✅/❌ |

---

## Cost Results

| **Component** | **Estimated** | **Actual** | **Variance** |
|--------------|--------------|------------|--------------|
| Cloud API calls (count) | 15 (30%) | X | X% |
| Gemini Flash cost | $0.48 | $X.XX | X% |
| Firebase costs | $0.01 | $X.XX | X% |
| **Blended cost per item** | **$0.0065** | **$X.XXXX** | **X%** |

---

## Key Findings

### Finding 1: [Title]
**Details**: [What we discovered]
**Implication**: [What this means for MVP]
**Recommendation**: [What we should do]

### Finding 2: [Title]
...

---

## Failure Analysis

### Top 5 Failure Cases

1. **Item**: [Name]
   - **Expected**: [What it should have identified]
   - **Actual**: [What AI said]
   - **Confidence**: [high/medium/low]
   - **Root Cause**: [Why it failed]
   - **Fix**: [How to improve]

...

---

## Go/No-Go Recommendation

**Decision**: ✅ GO / ❌ NO-GO / ⚠️ GO WITH MODIFICATIONS

**Rationale**: [Explanation based on data]

**Next Steps**: [What to do next]
```

---

## Success Criteria (Go/No-Go)

### ✅ GO - Proceed to MVP

**All of the following must be true**:
- ✅ Name accuracy >65% OR category accuracy >80%
- ✅ Cloud fallback rate <35%
- ✅ On-device processing <3s (95th percentile)
- ✅ Cloud processing <8s (95th percentile)
- ✅ Blended cost <$0.01 per item
- ✅ No critical technical blockers
- ✅ Confidence scores roughly calibrated (±15%)

**If met**: Proceed to MVP development with on-device-first architecture.

---

### ❌ NO-GO - Revise Approach

**Any of the following**:
- ❌ Name accuracy <55% AND category accuracy <75%
- ❌ Cloud fallback rate >50%
- ❌ On-device processing >5s
- ❌ Critical technical blockers (crashes, API failures)
- ❌ Cost >$0.015 per item

**If failed**: Fall back to cloud-first architecture (old research approach).

---

### ⚠️ GO WITH MODIFICATIONS

**Some criteria not met, but salvageable**:
- ⚠️ Accuracy 60-65% → Can improve with prompt tuning
- ⚠️ Cloud fallback 35-45% → Still cheaper than cloud-first
- ⚠️ Cost $0.01-0.015 → Still better than old model ($0.022)

**If met**: Proceed to MVP with modifications (e.g., better prompts, hybrid routing).

---

## Code Structure (POC)

```
abundance-poc-ios26/
├── ios/
│   ├── AbundancePOC/
│   │   ├── Views/
│   │   │   ├── CameraView.swift
│   │   │   ├── ResultsView.swift
│   │   │   └── EditView.swift
│   │   ├── Models/
│   │   │   └── ItemMetadata.swift
│   │   ├── Services/
│   │   │   ├── VisionService.swift        # Foundation Models
│   │   │   ├── VisualIntelligenceService.swift
│   │   │   └── FirebaseService.swift
│   │   ├── GoogleService-Info.plist
│   │   └── Info.plist
│   └── AbundancePOC.xcodeproj
├── firebase/
│   ├── functions/
│   │   ├── index.js                        # Cloud Function
│   │   └── package.json
│   ├── firestore.rules
│   ├── storage.rules
│   └── firebase.json
├── test-data/
│   ├── test-items.csv                      # 50 test items list
│   ├── photos/                              # Item photos
│   │   ├── 001-macbook-pro.jpg
│   │   ├── 002-ikea-chair.jpg
│   │   └── ...
│   └── results.csv                          # Test results
└── docs/
    └── poc-findings-report.md               # Analysis
```

---

## Timeline

| **Day** | **Tasks** | **Deliverable** | **Hours** |
|---------|----------|----------------|-----------|
| **Day 1** | iOS foundation (camera, Foundation Models, barcode) | On-device analysis works | 6-8 |
| **Day 2** | Visual Intelligence, confidence routing, Firebase SDK | On-device path complete | 6-8 |
| **Day 3** | Cloud Function, Gemini integration, end-to-end test | Cloud fallback works | 6-8 |
| **Day 4** | Test all 50 items, collect data | Complete dataset | 4-6 |
| **Day 5** | Analysis, iteration, reporting | POC Findings Report | 4-6 |

**Total**: **26-38 hours** (3-5 business days for one developer)

---

## Estimated Costs (POC)

| **Item** | **Quantity** | **Cost** |
|---------|-------------|----------|
| Firebase (Blaze plan minimum) | 1 month | $0 (free tier sufficient) |
| Gemini 1.5 Flash API | ~15 calls (30% fallback) | $0.48 |
| Firebase Storage | 50 items × 500KB | $0.01 |
| Cloud Functions | 15 invocations | $0.00 |
| Developer time | 3-5 days | [Internal cost] |
| **Total out-of-pocket** | | **~$0.50** |

**Note**: Firebase free tier covers POC usage (1GB storage, 50K reads/writes).

---

## Required Resources

### Hardware
- iPhone 15 Pro or newer (A17 Pro required for Foundation Models)
  - OR iPhone 16/16 Pro (A18/A18 Pro)
- Mac with Xcode 16+ (for iOS 26 development)

### Software
- iOS 26.0 SDK
- Xcode 16+
- Node.js 18+ (for Cloud Functions)
- Firebase CLI

### Accounts
- Apple Developer account (for iOS 26 beta/release)
- Google Cloud Platform project (with billing enabled)
- Firebase project

### Skills
- Swift 6 / SwiftUI
- Foundation Models API (new, will need to learn)
- Firebase (Storage, Firestore, Cloud Functions)
- Vertex AI / Gemini API

---

## Risk Mitigation

| **Risk** | **Probability** | **Mitigation** |
|---------|----------------|----------------|
| **Foundation Models API not available** | Low (5%) | Verify API access before starting Day 1 |
| **Accuracy much lower than expected** | Medium (30%) | Have cloud-first backup plan ready |
| **iPhone 15 Pro performance poor** | Low (10%) | Test on iPhone 16 Pro as well |
| **Gemini API rate limits** | Low (15%) | Use small test dataset (50 items) |
| **POC takes longer than 5 days** | Medium (40%) | Reduce scope (test 30 items instead of 50) |

---

## Deliverables

1. **Working iOS 26 prototype** (source code)
   - Foundation Models integration
   - Visual Intelligence integration
   - Firebase integration
   - On-device vs. cloud routing

2. **Firebase backend** (Cloud Function + Firestore/Storage rules)

3. **Test dataset** (50 item photos + metadata)

4. **Results spreadsheet** (50 items with accuracy data)

5. **Cost tracking** (actual Firebase/GCP costs)

6. **POC Findings Report** (go/no-go recommendation)

7. **Demo video** (2-3 minutes showing on-device path + cloud fallback)

---

## Next Steps After POC

### If ✅ GO

1. **Update DESIGN-004** with validated architecture
2. **Create ADR-015**: On-Device-First Strategy
3. **Proceed to Stage 3.1**: MVP Development
   - Full inventory management UI
   - User authentication
   - Production error handling
   - Result caching
   - Cost optimization

### If ❌ NO-GO

1. **Document failure reasons** (accuracy, performance, cost)
2. **Fall back to cloud-first architecture** (old research)
3. **Revise POC**:
   - Option A: Try Gemini Pro instead of Foundation Models
   - Option B: Hybrid on-device for simple, cloud for all else
   - Option C: Simpler MVP (barcode-only for phase 1)

### If ⚠️ GO WITH MODIFICATIONS

1. **Refine prompts** based on failure analysis
2. **Re-test on 20-item subset** (worst performers)
3. **If improved**: GO
4. **If still failing**: NO-GO

---

**Document Status**: ✅ Complete
**Ready for**: Stakeholder approval + POC execution
**Next Document**: CHECKPOINT-stage-2.4-ios26-research.md

---

**End of POC Plan**
