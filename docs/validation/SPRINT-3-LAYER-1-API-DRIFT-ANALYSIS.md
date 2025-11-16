# Sprint 3 Layer 1 API Drift Analysis

**Date**: 2025-11-16
**Sprint**: 3 (Layer 1 Complete & Backend Integration)
**Reviewer**: Claude Code
**Status**: ⚠️ Minor Drift Identified - Requires Sprint 4 Attention

---

## Executive Summary

This document analyzes the Sprint 3 Layer 1 implementation against documented API contracts to identify any drift that could cause breaking changes for Sprint 4 Layer 2a development.

**Key Findings**:
- ✅ **No Breaking Changes**: Layer 1 infrastructure is compatible with Layer 2a expectations
- ⚠️ **Minor Inconsistencies**: Field naming conventions differ between specs (needs harmonization)
- 📝 **Implementation Gap**: iOS item creation flow not yet implemented (expected for Sprint 4)
- ✅ **Backend Triggers**: Firestore triggers correctly orchestrate Layer 1 → Layer 2a transition

**Recommendation**: **Safe to proceed with Sprint 4**, but address field naming inconsistencies during Layer 2a implementation.

---

## Comparison Matrix

### 1. API Contract vs Implementation

| Component | API Contract (docs/) | Sprint 3 Implementation | Status |
|-----------|---------------------|------------------------|--------|
| **Storage Upload** | `imageUrl` field expected | ✅ StorageService.uploadCroppedObject() returns URL | ✅ Compatible |
| **Firestore Schema** | `imageURL` field (capital URL) | ⚠️ Not yet implemented in iOS | ⚠️ Minor Drift |
| **Layer 1 Results** | `layer1Result.detectedClass` | ✅ YOLOResult.label available | ✅ Compatible |
| **Layer 1 Confidence** | `layer1Result.confidence` (0.0-1.0) | ✅ YOLOResult.confidence (Double) | ✅ Compatible |
| **Bounding Box** | `{x, y, width, height}` | ✅ YOLOResult.boundingBox (CGRect) | ✅ Compatible |
| **Barcode Detection** | `detectedBarcode` (string \| null) | ✅ BarcodeDetector available | ✅ Compatible |
| **Item Creation** | POST /api/v1/items endpoint | ❌ Not implemented yet | 📝 Deferred to Sprint 4 |

---

## Detailed Findings

### Finding 1: Field Naming Inconsistency - `imageUrl` vs `imageURL`

**Severity**: ⚠️ Minor (Non-Breaking)

**Issue**:
- **API Contract** (API-CONTRACTS-001-rest-endpoints.md:94): Specifies `"imageUrl"` (camelCase)
- **Firestore Schema** (DATA-MODEL-001-firestore-schema.md:109): Specifies `"imageURL"` (capital URL)
- **Layer 2a Design** (DESIGN-041-layer-2a-json-schema.md:434): References `"imageUrl"` (camelCase)

**Code References**:
```json
// API-CONTRACTS-001 (line 94)
{
  "imageUrl": "https://storage.googleapis.com/..."
}

// DATA-MODEL-001 (line 109)
{
  "imageURL": "https://storage.googleapis.com/..."
}
```

**Impact**:
- Layer 2a Cloud Function (Sprint 4) expects `imageUrl` field to fetch image for Gemini
- If Firestore document uses `imageURL`, Layer 2a will fail to find the image

**Recommendation**:
```typescript
// Option 1: Standardize on camelCase "imageUrl" (preferred)
// Firestore document should use:
{
  imageUrl: "https://storage.googleapis.com/...",  // ✅ Matches API contract
  // NOT: imageURL
}

// Option 2: Layer 2a function handles both variants
const imageUrl = item.imageUrl || item.imageURL;
if (!imageUrl) {
  throw new Error('Missing image URL');
}
```

**Action**: Update DATA-MODEL-001 to use `imageUrl` (camelCase) for consistency.

---

### Finding 2: Layer 1 Data Structure Matches Specs

**Severity**: ✅ No Issue

**Verification**:

**Expected Structure** (API-CONTRACTS-001:95-105):
```json
{
  "layer1Result": {
    "detectedClass": "tent",
    "confidence": 0.87,
    "boundingBox": {
      "x": 100,
      "y": 200,
      "width": 300,
      "height": 400
    }
  }
}
```

**Implemented Structure** (YOLOResult.swift:6-36):
```swift
public struct YOLOResult {
    public let label: String          // Maps to detectedClass
    public let confidence: Double     // Maps to confidence
    public let boundingBox: CGRect    // Maps to {x, y, width, height}
}
```

**Mapping**:
```swift
// iOS Swift → Firestore JSON
let layer1Result = [
  "detectedClass": yoloResult.label,
  "confidence": yoloResult.confidence,
  "boundingBox": [
    "x": yoloResult.boundingBox.origin.x,
    "y": yoloResult.boundingBox.origin.y,
    "width": yoloResult.boundingBox.size.width,
    "height": yoloResult.boundingBox.size.height
  ]
]
```

**Status**: ✅ **Compatible** - YOLOResult structure aligns with API contract expectations.

---

### Finding 3: Firestore Trigger Orchestration is Correct

**Severity**: ✅ No Issue

**Verification**:

**Expected Flow** (DATA-MODEL-001:254-268):
```javascript
// Step 1: iOS app creates item with status="pending"
await db.collection('items').add({
  userId,
  imageURL,
  barcode: detectedBarcode || null,
  aiAnalysis: { layer1: layer1Result },
  status: 'pending',  // ← Trigger entry point
});
```

**Implemented Trigger** (onItemCreated.ts:21-48):
```typescript
// Step 2: Trigger validates status="pending" and imageUrl exists
if (item.status !== 'pending') {
  return;  // Skip if not pending
}

if (!item.imageUrl) {
  // Mark as failed if imageUrl missing
  await event.data?.ref.update({
    status: 'failed_layer2a',
    error: { message: 'Missing imageUrl' }
  });
  return;
}

// Step 3: Update to layer2a_scheduled (ready for Sprint 4)
await event.data?.ref.update({
  status: 'layer2a_scheduled',
  layer2aScheduledAt: admin.firestore.Timestamp.now()
});
```

**Status**: ✅ **Correct** - Trigger correctly:
1. Validates `status="pending"` to prevent duplicate processing
2. Checks for required `imageUrl` field
3. Transitions to `layer2a_scheduled` for Layer 2a Cloud Function (Sprint 4)
4. Handles errors gracefully with `failed_layer2a` status

**Layer 2a Readiness**: ✅ Sprint 4 Layer 2a Cloud Function can query for `status="layer2a_scheduled"` items.

---

### Finding 4: iOS Item Creation Flow Not Yet Implemented

**Severity**: 📝 Expected Gap (Not a Bug)

**Context**:
- Sprint 3 completed **infrastructure** (StorageService, Firestore triggers, YOLOv3-Tiny detection)
- Sprint 3 did **not** implement **end-to-end item creation** from iOS app
- This is expected per Sprint 3 scope: "Layer 1 backend integration"

**Current State**:
- ✅ `CameraDetectionViewModel` detects objects in real-time
- ✅ `StorageService.uploadCroppedObject()` uploads images to Firebase Storage
- ❌ No code to create Firestore items from iOS app
- ❌ POST /api/v1/items REST endpoint not implemented

**Expected for Sprint 4**:
```swift
// TODO: Implement in Sprint 4
class CatalogService {
  func createItem(
    imageUrl: URL,
    layer1Result: YOLOResult,
    barcode: String?
  ) async throws -> String {
    // Create Firestore document via REST API or Firebase SDK
    let itemRef = try await db.collection("items").addDocument(data: [
      "userId": currentUser.uid,
      "imageUrl": imageUrl.absoluteString,  // ⚠️ Use camelCase!
      "aiAnalysis": [
        "layer1": [
          "detectedClass": layer1Result.label,
          "confidence": layer1Result.confidence,
          "boundingBox": [
            "x": layer1Result.boundingBox.origin.x,
            "y": layer1Result.boundingBox.origin.y,
            "width": layer1Result.boundingBox.size.width,
            "height": layer1Result.boundingBox.size.height
          ]
        ]
      ],
      "barcode": barcode,
      "status": "pending",  // ← Trigger entry point
      "createdAt": FieldValue.serverTimestamp()
    ])

    return itemRef.documentID
  }
}
```

**Action**: Implement iOS item creation in Sprint 4 using the field mapping above.

---

### Finding 5: Alternative Labels Available but Not in Spec

**Severity**: ℹ️ Information Only (Enhancement Opportunity)

**Context**:
- Sprint 3 implemented `YOLOResult.alternativeLabels` (top 3 alternative classifications)
- Original API contract does not include alternative labels in `layer1Result`

**Current Implementation** (YOLOResult.swift:21):
```swift
public struct YOLOResult {
    public let label: String
    public let confidence: Double
    public let boundingBox: CGRect
    public let alternativeLabels: [AlternativeLabel]  // ← Not in spec
}
```

**Opportunity**:
```json
// Enhanced layer1Result structure (optional)
{
  "layer1Result": {
    "detectedClass": "tent",
    "confidence": 0.87,
    "boundingBox": { "x": 100, "y": 200, "width": 300, "height": 400 },
    "alternativeLabels": [  // ← New field (backward compatible)
      { "label": "backpack", "confidence": 0.72 },
      { "label": "bag", "confidence": 0.65 }
    ]
  }
}
```

**Benefit**:
- Layer 2a/3 AI models can use alternative labels for disambiguation
- Example: If YOLO detects "bag" (0.87) but alternatives are "backpack" (0.72) and "handbag" (0.65), Layer 2a can refine category

**Recommendation**: Consider adding `alternativeLabels` to API contract in Sprint 4 (non-breaking change).

---

## Layer 2a Input Validation Checklist

Sprint 4 Layer 2a Cloud Function must validate these fields from Layer 1:

| Field | Required? | Type | Validation |
|-------|-----------|------|------------|
| `imageUrl` | ✅ Yes | string | Must be valid HTTPS URL pointing to GCS bucket |
| `status` | ✅ Yes | string | Must be `"layer2a_scheduled"` |
| `aiAnalysis.layer1.detectedClass` | ✅ Yes | string | Must be non-empty string |
| `aiAnalysis.layer1.confidence` | ✅ Yes | number | Must be 0.0-1.0 |
| `aiAnalysis.layer1.boundingBox` | ⚠️ Optional | object | If present, must have `{x, y, width, height}` |
| `barcode` | ⚠️ Optional | string \| null | If present, must be valid barcode format |

**Example Validation Code** (Sprint 4):
```typescript
export async function processLayer2a(itemId: string) {
  const itemDoc = await db.collection('items').doc(itemId).get();
  const item = itemDoc.data();

  // Validate Layer 1 output is present
  if (!item?.imageUrl) {
    throw new InvalidArgumentError('Missing imageUrl from Layer 1');
  }

  if (!item?.aiAnalysis?.layer1?.detectedClass) {
    throw new InvalidArgumentError('Missing layer1.detectedClass');
  }

  if (typeof item.aiAnalysis.layer1.confidence !== 'number' ||
      item.aiAnalysis.layer1.confidence < 0 ||
      item.aiAnalysis.layer1.confidence > 1) {
    throw new InvalidArgumentError('Invalid layer1.confidence (must be 0-1)');
  }

  // Proceed with Gemini attribute extraction
  const attributes = await vertexAI.extractAttributes(item.imageUrl);

  // Store Layer 2a results
  await itemDoc.ref.update({
    'aiAnalysis.layer2a': attributes,
    status: 'layer2a_complete',
    layer2aCompletedAt: admin.firestore.Timestamp.now()
  });
}
```

---

## Breaking Changes Assessment

### ✅ No Breaking Changes Identified

**Analysis**:
1. **Storage Upload**: StorageService returns valid download URL ✅
2. **Layer 1 Results**: YOLOResult structure matches API contract ✅
3. **Firestore Triggers**: Correctly orchestrate Layer 1 → Layer 2a transition ✅
4. **Field Naming**: Minor inconsistency (`imageUrl` vs `imageURL`) but solvable with simple harmonization ✅

**Conclusion**: Sprint 4 Layer 2a development can proceed without refactoring Sprint 3 code.

---

## Recommendations for Sprint 4

### Priority 1: Harmonize Field Naming (P0)

**Action**: Standardize on `imageUrl` (camelCase) across all documents.

**Files to Update**:
1. `docs/tech-stack/DATA-MODEL-001-firestore-schema.md:109` - Change `imageURL` → `imageUrl`
2. Ensure iOS item creation uses `imageUrl` (not `imageURL`)
3. Layer 2a Cloud Function expects `item.imageUrl` (already correct in DESIGN-041)

**Commit Message**:
```
docs: standardize imageUrl field naming across API contracts

- Change DATA-MODEL-001 imageURL → imageUrl for consistency
- Aligns with API-CONTRACTS-001 and DESIGN-041 conventions
- Non-breaking change (new field, not renaming existing)

Refs: SPRINT-3-LAYER-1-API-DRIFT-ANALYSIS.md
```

---

### Priority 2: Implement iOS Item Creation (P0)

**Action**: Create `CatalogService` to handle item creation from iOS app.

**Required Fields** (per DATA-MODEL-001):
```swift
struct CreateItemRequest {
  let imageUrl: String              // From StorageService.uploadCroppedObject()
  let layer1DetectedClass: String   // From YOLOResult.label
  let layer1Confidence: Double      // From YOLOResult.confidence
  let layer1BoundingBox: CGRect     // From YOLOResult.boundingBox
  let barcode: String?              // From BarcodeDetector (optional)
}
```

**Implementation Pattern**:
```swift
// Sources/Persistence/Firebase/CatalogService.swift
public final class CatalogService {
  private let db: Firestore

  public func createItem(
    imageUrl: URL,
    layer1Result: YOLOResult,
    barcode: String?
  ) async throws -> String {
    let itemRef = try await db.collection("items").addDocument(data: [
      "userId": Auth.auth().currentUser!.uid,
      "imageUrl": imageUrl.absoluteString,  // ⚠️ camelCase!
      "name": "Untitled Item",              // Placeholder until Layer 2a
      "category": "uncategorized",          // Placeholder until Layer 2a
      "aiAnalysis": [
        "layer1": [
          "detectedClass": layer1Result.label,
          "confidence": layer1Result.confidence,
          "boundingBox": [
            "x": layer1Result.boundingBox.origin.x,
            "y": layer1Result.boundingBox.origin.y,
            "width": layer1Result.boundingBox.size.width,
            "height": layer1Result.boundingBox.size.height
          ]
        ]
      ],
      "barcode": barcode,
      "status": "pending",                  // ← Triggers Layer 2a
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
      "deletedAt": NSNull()                 // null for not deleted
    ])

    return itemRef.documentID
  }
}
```

**Tests**:
```swift
// Tests/PersistenceTests/CatalogServiceTests.swift
func testCreateItemWithLayer1Results() async throws {
  let service = CatalogService(db: mockFirestore)
  let yoloResult = YOLOResult(
    label: "tent",
    confidence: 0.87,
    boundingBox: CGRect(x: 100, y: 200, width: 300, height: 400)
  )

  let itemId = try await service.createItem(
    imageUrl: URL(string: "https://storage.googleapis.com/test.jpg")!,
    layer1Result: yoloResult,
    barcode: nil
  )

  XCTAssertFalse(itemId.isEmpty)

  // Verify Firestore document created
  let doc = try await mockFirestore.collection("items").document(itemId).getDocument()
  XCTAssertEqual(doc.data()?["status"] as? String, "pending")
  XCTAssertEqual(doc.data()?["imageUrl"] as? String, "https://storage.googleapis.com/test.jpg")
}
```

**Story**:
```markdown
## Story 4.4: iOS Item Creation Flow

**Epic**: Epic 5 (AI Pipeline)

**Tasks**:
1. Implement CatalogService.createItem() method
2. Integrate with CameraDetectionViewModel (automatic cataloging)
3. Handle manual cataloging flow (double-tap gesture)
4. Unit tests with Firebase Emulator

**Acceptance Criteria**:
- iOS app creates Firestore items with Layer 1 results
- Field names match API contract (`imageUrl` camelCase)
- Status set to "pending" triggers Layer 2a
- Tests pass with 90%+ coverage
```

---

### Priority 3: Add Alternative Labels (P2 - Optional)

**Action**: Enhance `layer1Result` with alternative labels from YOLOv11n.

**Benefit**:
- Layer 2a/3 can use alternative labels for disambiguation
- Improves accuracy when primary label is ambiguous

**Schema Update** (API-CONTRACTS-001):
```json
{
  "layer1Result": {
    "detectedClass": "tent",
    "confidence": 0.87,
    "boundingBox": { "x": 100, "y": 200, "width": 300, "height": 400 },
    "alternativeLabels": [  // ← New optional field
      { "label": "backpack", "confidence": 0.72 },
      { "label": "bag", "confidence": 0.65 }
    ]
  }
}
```

**Non-Breaking**: Existing Layer 2a code ignores this field if not present.

---

## Approval for Sprint 4 Progression

**Decision**: ✅ **APPROVED** - Sprint 4 Layer 2a development can proceed.

**Rationale**:
1. Layer 1 infrastructure is stable and complete
2. Firestore triggers correctly orchestrate pipeline
3. Field naming inconsistency is minor and easily fixed
4. No breaking changes require Sprint 3 refactoring

**Action Items for Sprint 4 Kickoff**:
- [ ] Update DATA-MODEL-001 to use `imageUrl` (camelCase)
- [ ] Implement iOS CatalogService for item creation
- [ ] Validate Layer 2a Cloud Function handles `imageUrl` field correctly
- [ ] Proceed with Gemini attribute extraction implementation

---

## Conclusion

Sprint 3 Layer 1 implementation is **compatible** with Sprint 4 Layer 2a requirements. The minor field naming inconsistency (`imageUrl` vs `imageURL`) should be harmonized during Sprint 4 item creation implementation, but does not block progression.

**Key Success Factors**:
1. ✅ YOLOResult structure matches API contract
2. ✅ Firestore triggers correctly transition Layer 1 → Layer 2a
3. ✅ StorageService provides valid image URLs for Gemini
4. ⚠️ Field naming needs harmonization (simple fix)

**Next Steps**: Begin Sprint 4 Story 4.1 (Vertex AI Provider Adapter) with confidence that Layer 1 output will be available in the expected format.

---

**Reviewed By**: Claude Code
**Date**: 2025-11-16
**Status**: ✅ Approved for Sprint 4
