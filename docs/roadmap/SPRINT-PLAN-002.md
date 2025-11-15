# SPRINT-PLAN-002: Camera Capture & Backend Infrastructure

**Sprint**: 2 of 8
**Theme**: Layer 1 - Camera capture with Vision Framework object detection

---

## Sprint Goals

1. ✅ Camera preview displays real-time feed
2. ✅ Vision Framework detects household items in < 500ms
3. ✅ Barcode scanning works with > 95% accuracy
4. ✅ Backend CRUD endpoints functional (health, items)

---

## Stories

### Story 2.1: Camera Capture View

**Epic**: Epic 3 (Camera/Layer 1)

**Tasks:**
1. Create CameraFeature module with AVCaptureSession
2. Implement camera preview (SwiftUI + AVFoundation)
3. Capture button triggers photo capture
4. Request camera permissions (Info.plist + runtime prompt)
5. Unit tests for CameraViewModel

**Acceptance Criteria:**
- Camera preview shows live feed
- Tap capture button saves UIImage
- Permissions requested on first launch
- Works on iPhone 15 Pro simulator

**Files:**
- Create: Packages/Features/CameraFeature/Sources/CameraView.swift
- Create: Packages/Features/CameraFeature/Sources/CameraViewModel.swift
- Create: Packages/Features/CameraFeature/Tests/CameraViewModelTests.swift

**References:**
- [DESIGN-012-camera-capture-implementation](docs/design/DESIGN-012-camera-capture-implementation.md): Camera Capture Implementation
- [CODE-EXAMPLE-004-vision-framework-patterns](docs/design/CODE-EXAMPLE-004-vision-framework-patterns.md): Vision Framework Patterns

---

### Story 2.2: Vision Framework Integration

**Epic**: Epic 3 (Camera/Layer 1)

**Tasks:**
1. Download YOLOv3-Tiny Core ML model (34 MB)
2. Implement VNCoreMLRequest (household item detection)
3. Filter to 18 COCO classes (relevant household items)
4. Extract bounding box and crop detected object
5. Performance optimization (< 500ms target)
6. Unit tests with sample images

**Acceptance Criteria:**
- Vision detects > 60% household items (golden dataset)
- Processing time < 500ms per image
- Cropped object extracted correctly
- Unit tests pass with mock images

**Files:**
- Create: Packages/Core/Vision/Sources/HouseholdItemDetector.swift
- Create: Packages/Core/Vision/Tests/HouseholdItemDetectorTests.swift
- Add: YOLOv3-Tiny.mlmodel (34 MB, Resources/)

**References:**
- [CODE-EXAMPLE-009-household-item-detector](docs/design/CODE-EXAMPLE-009-household-item-detector.md): Household Item Detector
- [DESIGN-039-layer-1-performance-optimization](docs/design/DESIGN-039-layer-1-performance-optimization.md): Layer 1 Performance Optimization

---

### Story 2.3: Barcode Detection

**Epic**: Epic 3 (Camera/Layer 1)

**Tasks:**
1. Implement VNDetectBarcodesRequest (24 symbologies)
2. Extract barcode payload string (UPC-A, EAN-13, QR Code)
3. Integrate barcode detection with camera flow
4. Unit tests for barcode extraction

**Acceptance Criteria:**
- Barcode detection success rate > 95%
- Supports 24 symbologies (UPC-A, EAN-13, QR Code primary)
- Returns barcode string payload
- Unit tests pass with sample barcodes

**Files:**
- Create: Packages/Core/Vision/Sources/BarcodeDetector.swift
- Create: Packages/Core/Vision/Tests/BarcodeDetectorTests.swift

**References:**
- [DESIGN-014-barcode-detection-implementation](docs/design/DESIGN-014-barcode-detection-implementation.md): Barcode Detection Implementation
- [ADR-018-barcode-product-lookup-strategy](docs/adr/ADR-018-barcode-product-lookup-strategy.md): Barcode Product Lookup Strategy

---

### Story 2.4: Backend CRUD Endpoints

**Epic**: Epic 4 (Backend Functions)

**Tasks:**
1. Implement POST /api/v1/items (create item)
2. Implement GET /api/v1/items/:id (retrieve item)
3. Implement GET /api/v1/items (list user items, pagination)
4. Unit tests with Jest + Supertest

**Acceptance Criteria:**
- All endpoints require Firebase Auth token
- POST creates item in Firestore
- GET returns items filtered by userId
- Unit tests pass

**Files:**
- Create: functions/src/api/items.ts
- Create: functions/src/__tests__/items.test.ts
- Modify: functions/src/index.ts

**References:**
- [API-CONTRACTS-001-rest-endpoints](docs/design/API-CONTRACTS-001-rest-endpoints.md): REST Endpoints
- [CODE-EXAMPLE-005-cloud-functions-patterns](docs/design/CODE-EXAMPLE-005-cloud-functions-patterns.md): Cloud Functions Patterns

---

## Sprint Risks

### P1: Layer 1 Accuracy Below 60%

**Impact**: High (poor detection ruins UX)
**Mitigation**:
- Test with golden dataset (100 items)
- Tune confidence threshold (0.25-0.50 range)
- Filter to 18 relevant COCO classes
- Document edge cases (DESIGN-040)

---

## Definition of Done

- [ ] Camera captures photos successfully
- [ ] Vision detects household items > 60% accuracy
- [ ] Barcode scanning > 95% success rate
- [ ] Backend CRUD endpoints functional
- [ ] All unit tests pass
- [ ] Sprint demo shows end-to-end capture flow

---
