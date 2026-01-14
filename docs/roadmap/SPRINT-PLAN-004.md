# SPRINT-PLAN-004: AI Pipeline Layer 2a (Attribute Extraction)

**Sprint**: 4 of 8
**Theme**: Gemini attribute extraction (category, color, material, condition)

---

## Sprint Goals

1. ✅ Vertex AI Gemini integration functional
2. ✅ Layer 2a extracts attributes with > 80% accuracy
3. ✅ JSON Schema Mode returns structured output
4. ✅ Cost tracking captures all API calls

---

## Stories

### Story 4.1: Vertex AI Provider Adapter

**Epic**: Epic 5 (AI Pipeline)

**Tasks:**

1. Implement VertexAIProvider class (Gemini 2.5 Flash-Lite)
2. Configure Application Default Credentials
3. Implement extractAttributes method (JSON Schema Mode)
4. Unit tests with mock responses

**Acceptance Criteria:**

- Gemini API calls succeed
- JSON Schema Mode returns structured attributes
- Cost logged to Firestore costLogs collection
- Unit tests pass

**Files:**

- Create: functions/src/ai-pipeline/providers/VertexAIProvider.ts
- Create: functions/src/ai-pipeline/**tests**/VertexAIProvider.test.ts

**References:**

- [CODE-EXAMPLE-010-vertex-ai-attribute-extraction](../design/CODE-EXAMPLE-010-vertex-ai-attribute-extraction.md): Vertex AI Attribute Extraction
- [DESIGN-041-layer-2a-json-schema](../design/DESIGN-041-layer-2a-json-schema.md): Layer 2a JSON Schema

---

### Story 4.2: Layer 2a Cloud Function

**Epic**: Epic 5 (AI Pipeline)

**Tasks:**

1. Implement onItemCreated trigger → Layer 2a
2. Call Vertex AI with image URL + prompt
3. Parse JSON response, store in item.aiAnalysis.layer2a
4. Update item status (processing → layer2a_complete)
5. Error handling + retry logic
6. Integration tests with Firebase Emulator

**Acceptance Criteria:**

- Trigger fires on item creation
- Gemini returns structured attributes
- Attributes stored in Firestore
- Errors logged and retried
- Integration tests pass

**Files:**

- Modify: functions/src/triggers/onItemCreated.ts
- Create: functions/src/ai-pipeline/layer2a/extractAttributes.ts

**References:**

- [CODE-EXAMPLE-011-layer-2a-cloud-function](../design/CODE-EXAMPLE-011-layer-2a-cloud-function.md): Layer 2a Cloud Function
- [DESIGN-042-layer-2a-error-handling](../design/DESIGN-042-layer-2a-error-handling.md): Layer 2a Error Handling

---

### Story 4.3: Cost Tracking Setup

**Epic**: Epic 5 (AI Pipeline)

**Tasks:**

1. Create costLogs Firestore collection schema
2. Implement cost logging middleware
3. Calculate cost per API call (tokens × price)
4. Dashboard query patterns

**Acceptance Criteria:**

- All API calls logged (provider, model, tokens, cost)
- Cost calculated accurately ($0.00004/image for Gemini)
- Query patterns documented
- Unit tests pass

**Files:**

- Create: functions/src/ai-pipeline/cost-tracking/CostLogger.ts
- Create: functions/src/ai-pipeline/**tests**/CostLogger.test.ts

**References:**

- [COST-MODEL-001-ai-cataloging-cost-per-item](../tech-stack/COST-MODEL-001-ai-cataloging-cost-per-item.md): AI Cataloging Cost Per Item

---

## Sprint Risks

### P1: Layer 2a Accuracy Below 80%

**Impact**: High (poor attribute quality)
**Mitigation**:

- Tune prompts with golden dataset
- Iterate on JSON Schema structure
- Add manual review queue if needed

---

## Definition of Done

- [ ] Gemini API integration complete
- [ ] Layer 2a accuracy > 80% (golden dataset)
- [ ] Cost tracking logs all API calls
- [ ] Error handling + retry logic working
- [ ] All unit + integration tests pass
- [ ] Sprint demo shows attribute extraction

---
