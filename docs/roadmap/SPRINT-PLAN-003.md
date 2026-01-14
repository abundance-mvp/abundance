# SPRINT-PLAN-003: Layer 1 Complete & Backend Triggers

**Sprint**: 3 of 8
**Theme**: Complete Layer 1 integration + Backend Firestore triggers setup

---

## Sprint Goals

1. ✅ Cropped images upload to Firebase Storage
2. ✅ Backend triggers fire on item creation
3. ✅ Firestore triggers ready for AI pipeline (Layer 2a)
4. ✅ End-to-end Layer 1 accuracy > 60% validated

---

## Stories

### Story 3.1: Firebase Storage Upload

**Epic**: Epic 3 (Camera/Layer 1)

**Tasks:**
1. Implement Firebase Storage upload (cropped images)
2. Generate signed URLs (1-hour expiration for SerpAPI)
3. Store URL in Firestore items collection
4. Unit tests with Firebase Emulator

**Acceptance Criteria:**
- Cropped images upload to GCS (users/{userId}/items/{itemId}/image.jpg)
- Signed URL returned and stored in Firestore
- Upload completes in < 2 seconds
- Unit tests pass

**Files:**
- Create: Packages/Core/Firebase/Sources/StorageUploader.swift
- Create: Packages/Core/Firebase/Tests/StorageUploaderTests.swift

**References:**
- [ADR-008-image-storage-architecture](../adr/ADR-008-image-storage-architecture.md): Image Storage Architecture
- [DESIGN-016-cloud-storage-upload-patterns](../design/DESIGN-016-cloud-storage-upload-patterns.md): Cloud Storage Upload Patterns

---

### Story 3.2: Firestore Triggers Setup

**Epic**: Epic 4 (Backend Functions)

**Tasks:**
1. Implement onItemCreated trigger (Firestore)
2. Implement onLayer2aComplete trigger
3. Implement onLayer2bComplete trigger
4. Add trigger routing logic
5. Unit tests with Firebase Emulator

**Acceptance Criteria:**
- onItemCreated fires when item document created
- Triggers update item status (processing → complete)
- Error handling logs failures
- Unit tests pass with emulator

**Files:**
- Create: functions/src/triggers/onItemCreated.ts
- Create: functions/src/triggers/onLayer2aComplete.ts
- Create: functions/src/triggers/onLayer2bComplete.ts
- Create: functions/src/__tests__/triggers.test.ts

**References:**
- [DESIGN-021-cloud-functions-orchestration](../design/DESIGN-021-cloud-functions-orchestration.md): Cloud Functions Orchestration
- [CODE-EXAMPLE-007-ai-pipeline-orchestration](../design/CODE-EXAMPLE-007-ai-pipeline-orchestration.md): AI Pipeline Orchestration

---

### Story 3.3: Scheduled Jobs

**Epic**: Epic 4 (Backend Functions)

**Tasks:**
1. Implement cleanupDeletedItems job (daily 2am UTC)
2. Implement checkSubscriptionExpiry job (daily 6am UTC)
3. Unit tests with mock Firestore

**Acceptance Criteria:**
- Cleanup job deletes soft-deleted items > 90 days old
- Subscription job downgrades expired premium users
- Jobs run on schedule
- Unit tests pass

**Files:**
- Create: functions/src/scheduled/cleanupDeletedItems.ts
- Create: functions/src/scheduled/checkSubscriptionExpiry.ts

**References:**
- [CLOUD-FUNCTIONS-001-function-structure](../design/CLOUD-FUNCTIONS-001-function-structure.md): Function Structure

---

### Story 3.4: Layer 1 Golden Dataset Validation

**Epic**: Epic 9 (Testing)

**Tasks:**
1. Create golden dataset (100 diverse household items)
2. Run Vision detection on all items
3. Calculate accuracy metrics (precision, recall)
4. Document edge cases and failure modes
5. Generate validation report

**Acceptance Criteria:**
- Golden dataset > 60% accuracy
- Report documents failure modes
- Edge cases cataloged (DESIGN-040)

**Files:**
- Create: tests/golden-dataset/items-100.json
- Create: tests/golden-dataset/validation-report.md

**References:**
- [TEST-EXAMPLE-004-ml-cv-testing-patterns](../test/TEST-EXAMPLE-004-ml-cv-testing-patterns.md): ML/CV Testing Patterns
- [DESIGN-040-layer-1-edge-case-handling](../design/DESIGN-040-layer-1-edge-case-handling.md): Layer 1 Edge Case Handling

---

## Sprint Risks

### P1: Firebase Trigger Latency

**Impact**: High (slow AI pipeline)
**Mitigation**:
- Use Cloud Functions 2nd gen (faster)
- Monitor trigger latency in Cloud Logging
- Set minimum instances if needed

---

## Definition of Done

- [x] Images upload to Firebase Storage successfully
- [x] Firestore triggers fire correctly
- [x] Scheduled jobs deployed and tested
- [x] YOLOv3-Tiny object detection implemented
- [x] All unit + integration tests pass
- [x] Sprint demo shows complete Layer 1 flow

**Note**: Layer 1 golden dataset validation (Story 3.4) deferred to Sprint 4 per implementation plan. YOLOv3-Tiny model integration completed in place of validation.

---
