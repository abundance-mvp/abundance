# SPRINT-PLAN-005: AI Pipeline Layers 2b & 3 (Product ID + Synthesis)

**Sprint**: 5 of 8
**Theme**: Complete AI pipeline (barcode lookup, SerpAPI, Claude synthesis)

---

## Sprint Goals

1. ✅ Layer 2b identifies products with > 75% accuracy
2. ✅ Barcode-first optimization reduces costs
3. ✅ Layer 3 Claude synthesis resolves conflicts
4. ✅ End-to-end AI pipeline functional (< 10s processing)

---

## Stories

### Story 5.1: Barcode Provider Adapter

**Epic**: Epic 5 (AI Pipeline)

**Tasks:**
1. Implement BarcodeProvider (OpenFoodFacts → UPCitemdb fallback)
2. API integration for both services
3. Parse product information (name, brand, MSRP)
4. Unit tests with mock responses

**Acceptance Criteria:**
- OpenFoodFacts tried first (free tier)
- UPCitemdb fallback if needed
- Product info returned correctly
- Unit tests pass

**Files:**
- Create: functions/src/ai-pipeline/providers/BarcodeProvider.ts
- Create: functions/src/ai-pipeline/__tests__/BarcodeProvider.test.ts

**References:**
- [CODE-EXAMPLE-012-barcode-hybrid-lookup](../design/CODE-EXAMPLE-012-barcode-hybrid-lookup.md): Barcode Hybrid Lookup
- [ADR-018-barcode-product-lookup-strategy](../adr/ADR-018-barcode-product-lookup-strategy.md): Barcode Product Lookup Strategy

---

### Story 5.2: SerpAPI + Claude Haiku Integration

**Epic**: Epic 5 (AI Pipeline)

**Tasks:**
1. Implement SerpAPIProvider (Google Lens API)
2. Implement AnthropicProvider (Claude Haiku 4.5)
3. Parse SerpAPI results with Claude Haiku
4. Unit tests with mock responses

**Acceptance Criteria:**
- SerpAPI returns visual search results
- Claude Haiku extracts structured product info
- Cost < $0.015/search
- Unit tests pass

**Files:**
- Create: functions/src/ai-pipeline/providers/SerpAPIProvider.ts
- Create: functions/src/ai-pipeline/providers/AnthropicProvider.ts

**References:**
- [CODE-EXAMPLE-013-serpapi-google-lens](../design/CODE-EXAMPLE-013-serpapi-google-lens.md): SerpAPI Google Lens
- [CODE-EXAMPLE-014-claude-haiku-parsing](../design/CODE-EXAMPLE-014-claude-haiku-parsing.md): Claude Haiku Parsing

---

### Story 5.3: Layer 2b Orchestration

**Epic**: Epic 5 (AI Pipeline)

**Tasks:**
1. Implement onLayer2aComplete trigger → Layer 2b
2. Barcode-first routing logic
3. Store results in item.aiAnalysis.layer2b
4. Integration tests

**Acceptance Criteria:**
- Barcode route tried first if available
- SerpAPI fallback if no barcode or lookup fails
- Layer 2b accuracy > 75%
- Integration tests pass

**Files:**
- Modify: functions/src/triggers/onLayer2aComplete.ts
- Create: functions/src/ai-pipeline/layer2b/identifyProduct.ts

**References:**
- [CODE-EXAMPLE-015-layer-2b-orchestration](../design/CODE-EXAMPLE-015-layer-2b-orchestration.md): Layer 2b Orchestration

---

### Story 5.4: Layer 3 Claude Synthesis

**Epic**: Epic 5 (AI Pipeline)

**Tasks:**
1. Implement onLayer2bComplete trigger → Layer 3
2. Call Claude Sonnet 4.5 Batch API (synthesis)
3. Resolve conflicts (layer1 vs layer2a vs layer2b)
4. Store final metadata in item

**Acceptance Criteria:**
- Claude synthesizes final metadata
- Conflicts resolved per DESIGN-020 rules
- Layer 3 accuracy > 75%
- Item status = "complete"

**Files:**
- Modify: functions/src/triggers/onLayer2bComplete.ts
- Create: functions/src/ai-pipeline/layer3/synthesize.ts

**References:**
- [CODE-EXAMPLE-016-claude-sonnet-synthesis](../design/CODE-EXAMPLE-016-claude-sonnet-synthesis.md): Claude Sonnet Synthesis
- [CODE-EXAMPLE-017-conflict-resolution-patterns](../design/CODE-EXAMPLE-017-conflict-resolution-patterns.md): Conflict Resolution Patterns

---

## Sprint Risks

### P1: SerpAPI Cost Overruns

**Impact**: High (budget exceeded)
**Mitigation**:
- Monitor usage daily
- Optimize barcode-first strategy (reduce SerpAPI calls)
- Alert at 80% quota

---

## Definition of Done

- [ ] All 4 AI providers integrated
- [ ] End-to-end pipeline < 10s processing
- [ ] Layer 2b accuracy > 75%
- [ ] Layer 3 accuracy > 75%
- [ ] Cost per item < $0.018
- [ ] Sprint demo shows complete AI pipeline

---
